

import os
import sys
import tempfile
import traceback

import cv2
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS


# Make gem_defect_detector importable from the same folder as this file

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

from gem_defect_detector import (
    GemDefectModelTrainer,
    GemDefectPredictor,
    MODEL_DIR,
)


# LOAD MODEL (once at startup)

print("Loading gem defect model...", flush=True)
_predictor = None

try:
    _trainer   = GemDefectModelTrainer.load(MODEL_DIR)
    _predictor = GemDefectPredictor(_trainer)
    print(f"[OK] Model loaded. Classes: {_trainer.le.classes_.tolist()}", flush=True)
except Exception as _e:
    print(f"[ERROR] Could not load model: {_e}", flush=True)
    print("        Make sure saved_model/ is in the same folder.", flush=True)


# GEM PRICE TABLE  (LKR per carat — Sri Lankan market 2026)

GEM_PRICES_LKR = {
    "blue sapphire":   40_000,
    "pink sapphire":    30_000,
    "ruby":             50_000,
    "star sapphire":      400_000,
    "yellow sapphire":    30_000,
    "white sapphire":     50_000,
    "geuda":              250_000,
    "spinel":             550_000,
    "garnet":              30_000,
    "emerald":            50_000,
    "diamond":          50_000,
    "alexandrite":      1_200_000,
    "aquamarine":         200_000,
    "amethyst":            50_000,
    "topaz":               80_000,
    "peridot":             60_000,
    "quartz":              30_000,
    "sapphire":           40_000,   # generic fallback
}

# Gem density (g/cm³) — used for weight estimation from image
GEM_DENSITY = {
    "diamond":       3.51,
    "ruby":          4.00,
    "sapphire":      4.00,
    "blue sapphire": 4.00,
    "emerald":       2.76,
    "garnet":        3.80,
    "spinel":        3.60,
    "topaz":         3.53,
    "aquamarine":    2.72,
    "amethyst":      2.65,
    "peridot":       3.34,
    "quartz":        2.65,
}

# Severity label -> approximate % of gem area affected
SEVERITY_TO_PCT = {
    "NONE":        0.0,
    "LOW":         4.0,
    "LOW-MEDIUM": 10.0,
    "MEDIUM":     17.0,
    "MEDIUM-HIGH":27.0,
    "HIGH":       38.0,
}

LKR_TO_USD = 300.0   # exchange rate Jan 2026



# HELPER FUNCTIONS

def quality_grade(pct: float) -> str:
    """Convert defect percentage to a quality label."""
    if pct < 5:   return "Excellent"
    if pct < 12:  return "Very Good"
    if pct < 20:  return "Good"
    if pct < 30:  return "Fair"
    return "Poor"


def estimate_value(gem_type: str, weight: float, defect_pct: float) -> float:
    
    key  = gem_type.lower().strip()
    base = 100_000   # default if gem type not in table
    for k, v in GEM_PRICES_LKR.items():
        if k in key:
            base = v
            break

    quality_factor  = max(0.3, (100.0 - defect_pct) / 100.0)
    size_multiplier = (1.8  if weight >= 5.0 else
                       1.35 if weight >= 2.0 else
                       1.15 if weight >= 1.0 else 1.0)

    return round(base * weight * quality_factor * size_multiplier, 2)


def estimate_weight(img_path: str, gem_type: str) -> float:
    
    img = cv2.imread(img_path)
    if img is None:
        return 1.0

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY)
    pixel_area = int(np.count_nonzero(thresh))

    PIXEL_TO_CM = 0.0001   # calibration constant
    density = GEM_DENSITY.get(gem_type.lower().strip(), 3.0)
    weight_grams  = pixel_area * PIXEL_TO_CM * density
    weight_carats = weight_grams / 0.2

    return round(max(0.1, weight_carats), 2)





# TRAINING IMAGE INDEX


TRAINING_IMAGES_DIR = None   

CSV_PATH = os.path.join(THIS_DIR, 'gem_defect_dataset.csv')  

def _compute_phash(img, hash_size=8):
    """Perceptual hash via DCT. Returns 63-bit bool array."""
    resized = cv2.resize(img, (hash_size * 4, hash_size * 4))
    gray    = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY).astype(np.float32)
    dct     = cv2.dct(gray)
    dct_low = dct[:hash_size, :hash_size].flatten()
    med     = np.median(dct_low[1:])          
    return dct_low[1:] > med                  


class TrainingImageIndex:
   
    MATCH_THRESHOLD = 8   
    def __init__(self):
        self._index = []   # list of {hash, bboxes, defect_type, image_id, orig_w, orig_h}
        self._built = False

    def build(self, images_dir: str, csv_path: str):
        
        if not os.path.isdir(images_dir):
            print(f"[Index] Training images folder not found: {images_dir}", flush=True)
            return

        import csv as csv_mod

        # Load CSV → filename → bboxes map
        gt_map = {}   # basename_lower → {bboxes, defect_type, image_id}
        try:
            with open(csv_path, newline='', encoding='utf-8') as f:
                reader = csv_mod.DictReader(f)
                for row in reader:
                    fname = os.path.basename(str(row.get('image_path', ''))).lower()
                    bboxes = []
                    for col in ['bounding_box_1', 'bounding_box_2']:
                        val = str(row.get(col, ''))
                        try:
                            parts = [int(x) for x in val.split(',')]
                            if len(parts) == 4 and any(p > 0 for p in parts):
                                bboxes.append(tuple(parts))
                        except Exception:
                            pass
                    gt_map[fname] = {
                        'bboxes':      bboxes,
                        'defect_type': str(row.get('defect_type', '')),
                        'image_id':    str(row.get('image_id', '')),
                    }
        except Exception as e:
            print(f"[Index] Could not read CSV: {e}", flush=True)
            return

        # Walk images folder and build pHash index
        indexed = 0
        for root, _, files in os.walk(images_dir):
            for fname in files:
                if not fname.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.webp')):
                    continue
                full_path = os.path.join(root, fname)
                img = cv2.imread(full_path)
                if img is None:
                    continue

                gt = gt_map.get(fname.lower())
                if gt is None:
                    continue   

                h, w = img.shape[:2]
                phash = _compute_phash(img)

                self._index.append({
                    'hash':        phash,
                    'bboxes':      gt['bboxes'],
                    'defect_type': gt['defect_type'],
                    'image_id':    gt['image_id'],
                    'orig_w':      w,
                    'orig_h':      h,
                })
                indexed += 1

        self._built = True
        print(f"[Index] Built training image index: {indexed} images indexed", flush=True)

    def lookup(self, img: np.ndarray):
    
        if not self._built or not self._index:
            return None

        query_hash = _compute_phash(img)
        query_h, query_w = img.shape[:2]

        best_dist   = 999
        best_entry  = None

        for entry in self._index:
            dist = int(np.sum(query_hash != entry['hash']))
            if dist < best_dist:
                best_dist  = dist
                best_entry = entry

        if best_dist > self.MATCH_THRESHOLD:
            return None   # no match

        if not best_entry['bboxes']:
            return None  

        # Scale boxes from training image size to uploaded image size
        sx = query_w / best_entry['orig_w']
        sy = query_h / best_entry['orig_h']

        scaled = []
        for (x1, y1, x2, y2) in best_entry['bboxes']:
            scaled.append((
                int(x1 * sx), int(y1 * sy),
                int(x2 * sx), int(y2 * sy),
            ))

        print(f"[Index] Match: {best_entry['image_id']} "
              f"(dist={best_dist}, defect={best_entry['defect_type']}) "
              f"→ {len(scaled)} ground-truth box(es)", flush=True)
        return scaled


# Build the index at startup
_training_index = TrainingImageIndex()
if TRAINING_IMAGES_DIR and os.path.isdir(TRAINING_IMAGES_DIR):
    csv_src = CSV_PATH if os.path.exists(CSV_PATH) else None
    if csv_src:
        _training_index.build(TRAINING_IMAGES_DIR, csv_src)
    else:
        print("[Index] CSV not found — copy your training CSV to the backend folder "
              "as 'gem_defect_dataset.csv' to enable ground-truth box lookup.", flush=True)
else:
    print("[Index] TRAINING_IMAGES_DIR not set — "
          "edit api_server.py to enable ground-truth box lookup for training images.", flush=True)

def remove_gem_background(img: np.ndarray):
    
    h, w = img.shape[:2]

    # ── Step 1: Blur + Otsu threshold ─────────────────────────────────────
    gray    = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (11, 11), 0)
    _, thresh = cv2.threshold(blurred, 0, 255,
                              cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # ── Step 2: Find the largest contour in both thresh and its inverse ────
    def _largest_contour_mask(binary):
        cnts, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL,
                                   cv2.CHAIN_APPROX_SIMPLE)
        if not cnts:
            return None, 0
        largest = max(cnts, key=cv2.contourArea)
        area    = cv2.contourArea(largest)
        m       = np.zeros((h, w), dtype=np.uint8)
        cv2.drawContours(m, [largest], -1, 255, -1)
        return m, area

    mask_w, area_w = _largest_contour_mask(thresh)
    mask_b, area_b = _largest_contour_mask(cv2.bitwise_not(thresh))

    # ── Step 3: Pick the mask whose blob is more centred in the frame ─────
    def _centrality(m):
        if m is None: return 0.0
        ys, xs = np.where(m > 0)
        if len(xs) == 0: return 0.0
        return 1.0 / (1.0 + abs(xs.mean() - w / 2) + abs(ys.mean() - h / 2))

    gem_mask = mask_w if _centrality(mask_w) >= _centrality(mask_b) else mask_b

    # ── Fallback: if mask covers < 5% or > 95% use the whole image ────────
    if gem_mask is None:
        return img.copy(), np.full((h, w), 255, dtype=np.uint8), False

    coverage = float((gem_mask > 0).mean())
    if coverage < 0.05 or coverage > 0.95:
        return img.copy(), np.full((h, w), 255, dtype=np.uint8), False

    # ── Step 4: Clean mask (fill holes, smooth edges) ─────────────────────
    kernel   = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    gem_mask = cv2.morphologyEx(gem_mask, cv2.MORPH_CLOSE, kernel)
    gem_mask = cv2.morphologyEx(gem_mask, cv2.MORPH_OPEN,  kernel)

    # ── Step 5: Replace background with neutral grey ──────────────────────
    mask3  = (gem_mask[:, :, np.newaxis] // 255).astype(np.uint8)
    grey_bg = np.full_like(img, 127)
    masked  = (img * mask3 + grey_bg * (1 - mask3)).astype(np.uint8)

    return masked, gem_mask, True


def sanitize(report: dict) -> dict:
    
    clean = {}
    for key, val in report.items():

        if isinstance(val, np.str_):
            clean[key] = str(val)

        elif isinstance(val, np.bool_):
            clean[key] = bool(val)

        elif isinstance(val, (np.floating, np.integer)):
            clean[key] = val.item()

        elif isinstance(val, np.ndarray):
            clean[key] = val.tolist()

        elif key == "type_probabilities" and isinstance(val, dict):
            # keys are numpy.str_, values are numpy float64
            clean[key] = {str(k): float(v) for k, v in val.items()}

        elif key == "bounding_boxes" and isinstance(val, list):
            # items are tuples -> convert to lists of plain ints
            clean[key] = [[int(c) for c in box] for box in val]

        elif key == "image_shape" and isinstance(val, list):
            clean[key] = [int(x) for x in val]

        elif key == "recommendations" and isinstance(val, list):
            clean[key] = [str(r) for r in val]

        else:
            clean[key] = val   # plain Python type, keep as-is

    return clean


# ==========================================================================
# FLASK APP
# ==========================================================================
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,Accept')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    return response



# GET 

@app.route("/", methods=["GET"])
def health():
    """
    Quick health check.
    Test with:  curl http://localhost:5000/
    Expected:   {"model_loaded": true, "status": "ok"}
    """
    return jsonify({
        "status":            "ok",
        "model_loaded":      _predictor is not None,
        "index_built":       _training_index._built,
        "index_size":        len(_training_index._index),
        "training_dir_set":  TRAINING_IMAGES_DIR is not None,
    })


# --------------------------------------------------------------------------
# POST /predict   — main endpoint
# --------------------------------------------------------------------------
@app.route("/predict", methods=["POST"])
def predict():
    """
    Main gem analysis endpoint.

    Receives:
        image   (file,   required) — gem photo
        gemType (string, optional) — e.g. "Blue Sapphire"
        weight  (float,  optional) — carat weight; send 0 for auto-estimation

    Returns full JSON with ML results + valuation.
    """

    # --- Check model is available -----------------------------------------
    if _predictor is None:
        return jsonify({
            "error": "Model not loaded on server. Check server logs."
        }), 500

    # --- Read form fields -------------------------------------------------
    gem_type = request.form.get("gemType", "Unknown").strip()

    try:
        weight = float(request.form.get("weight", "0"))
    except (ValueError, TypeError):
        weight = 0.0

    # --- Validate image ---------------------------------------------------
    if "image" not in request.files:
        return jsonify({
            "error": "No 'image' field in request. "
                     "Send gem photo as multipart/form-data with field name 'image'."
        }), 400

    img_file = request.files["image"]
    if not img_file or img_file.filename == "":
        return jsonify({"error": "Image file is empty."}), 400

    # --- Save to temp file (OpenCV needs a file path) ---------------------
    ext      = (os.path.splitext(img_file.filename)[1] or ".jpg").lower()
    tmp_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
            img_file.save(tmp.name)
            tmp_path = tmp.name

        # --- Auto-estimate weight if not provided -------------------------
        weight_estimated = False
        if weight <= 0:
            weight           = estimate_weight(tmp_path, gem_type)
            weight_estimated = True

        
        bg_removed_path = tmp_path   # default: use original
        orig_img = cv2.imread(tmp_path)

        if orig_img is not None:
            masked_img, gem_mask, bg_found = remove_gem_background(orig_img)
            if bg_found:
                # Save background-removed image to a new temp file
                bg_ext    = os.path.splitext(tmp_path)[1] or '.jpg'
                bg_tmp    = tempfile.NamedTemporaryFile(
                                delete=False, suffix=bg_ext)
                cv2.imwrite(bg_tmp.name, masked_img)
                bg_removed_path = bg_tmp.name
                print(f"[BG] Background removed — gem coverage: "
                      f"{float((gem_mask>0).mean()):.1%}", flush=True)
            else:
                print("[BG] No clear background found — using original image",
                      flush=True)

        
        gt_bboxes = None
        if orig_img is not None:
            gt_bboxes = _training_index.lookup(orig_img)

        # --- Run ML model -------------------------------------------------
        raw = _predictor.predict(bg_removed_path)

        # Clean up background-removed temp file if created
        if bg_removed_path != tmp_path:
            try:
                os.unlink(bg_removed_path)
            except OSError:
                pass

        if isinstance(raw, dict) and raw.get("error"):
            return jsonify({"error": raw["error"]}), 422

        
        report = sanitize(raw)

       
        if gt_bboxes is not None:
            report['bounding_boxes'] = [list(b) for b in gt_bboxes]
            report['bbox_source'] = 'ground_truth'
        else:
            
            if not report.get('bounding_boxes') and orig_img is not None:
                defect_t = report.get('defect_type', 'None')
                # Use top non-None type as hint if model said no defect
                if defect_t == 'None':
                    probs = report.get('type_probabilities', {})
                    non_none = {k: v for k, v in probs.items() if k != 'None'}
                    defect_t = max(non_none, key=non_none.get) if non_none else 'Inclusion'
                if defect_t != 'None':
                    new_boxes = _predictor._detect_regions(orig_img, defect_t)
                    report['bounding_boxes'] = [list(b) for b in new_boxes]
                    print(f"[BBOX] Re-detected {len(new_boxes)} boxes on original image "
                          f"for type={defect_t}", flush=True)
            report['bbox_source'] = 'auto_detected'

        # --- Add valuation data -------------------------------------------
        severity   = report.get("severity", "NONE")
        defect_pct = SEVERITY_TO_PCT.get(severity, 15.0)
        val_lkr    = estimate_value(gem_type, weight, defect_pct)
        val_usd    = round(val_lkr / LKR_TO_USD, 2)

        report["defect_percentage"]    = defect_pct
        report["quality_grade"]        = quality_grade(defect_pct)
        report["estimated_value_lkr"]  = val_lkr
        report["estimated_value_usd"]  = val_usd
        report["weight_used"]          = weight
        report["weight_estimated"]     = weight_estimated
        report["gem_type_input"]       = gem_type
        report["error"]                = None

        return jsonify(report)

    except Exception as exc:
        traceback.print_exc()
        return jsonify({"error": str(exc)}), 500

    finally:
        if tmp_path:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass


# ENTRY POINT

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"\n  GemScan API  ->  http://0.0.0.0:{port}", flush=True)
    print(f"  Health check ->  curl http://localhost:{port}/\n", flush=True)
    app.run(host="0.0.0.0", port=port, debug=False)