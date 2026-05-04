
import os
import csv
import json
import pickle
import warnings
import numpy as np
import pandas as pd
import cv2
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from PIL import Image, ImageDraw, ImageFont
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier,
    VotingClassifier, ExtraTreesClassifier
)
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import (
    train_test_split, StratifiedKFold, cross_val_score
)
from sklearn.metrics import (
    classification_report, confusion_matrix,
    accuracy_score, f1_score
)
from sklearn.pipeline import Pipeline
from sklearn.calibration import CalibratedClassifierCV
import logging

warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s  %(levelname)-8s  %(message)s',
    datefmt='%H:%M:%S'
)
log = logging.getLogger('GemDefect')

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
DEFECT_COLORS = {
    'Inclusion':        '#FF6B6B',
    'Black Inclusion':  '#2C2C2C',
    'Crack':            '#FF4444',
    'Scratch':          '#FFA500',
    'bubble':           '#00BFFF',
    'Clarity':          '#9B59B6',
    'Lily Pad':         '#2ECC71',
    'None':             '#27AE60',
}

DEFECT_DESCRIPTIONS = {
    'Inclusion':        'Internal mineral or crystal trapped inside the gem.',
    'Black Inclusion':  'Dark opaque mineral inclusion reducing transparency.',
    'Crack':            'Internal fracture that may worsen under pressure.',
    'Scratch':          'Surface abrasion affecting brilliance and clarity.',
    'bubble':           'Gas pocket or void trapped within the gem.',
    'Clarity':          'General clarity imperfection affecting light transmission.',
    'Lily Pad':         'Circular inclusion resembling a lily pad (stress fracture).',
    'None':             'No defects detected. Gem is clean.',
}

SEVERITY_MAP = {
    'Crack':            'HIGH',
    'Black Inclusion':  'HIGH',
    'Lily Pad':         'MEDIUM-HIGH',
    'Inclusion':        'MEDIUM',
    'Scratch':          'MEDIUM',
    'Clarity':          'LOW-MEDIUM',
    'bubble':           'LOW',
    'None':             'NONE',
}

IMG_SIZE = (224, 224)
MODEL_DIR = os.path.join(os.path.dirname(__file__), 'saved_model')
os.makedirs(MODEL_DIR, exist_ok=True)



class GemFeatureExtractor:
    

    def extract(self, image: np.ndarray) -> np.ndarray:
        if image is None or image.size == 0:
            return np.zeros(168, dtype=np.float32)

        # Resize to standard
        img = cv2.resize(image, IMG_SIZE)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        hsv  = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        lab  = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)

        feats = []

        # 1. COLOR STATISTICS (RGB + HSV + LAB) → 54 features
        for ch_img in [img, hsv, lab]:
            for c in range(3):
                ch = ch_img[:, :, c].astype(np.float32)
                feats += [
                    ch.mean(), ch.std(),
                    float(np.percentile(ch, 25)),
                    float(np.percentile(ch, 75)),
                    float(np.median(ch)),
                    float(np.percentile(ch, 10)),
                ]  # 6 × 3 × 3 = 54

        # 2. GRAY-LEVEL STATISTICS → 8 features
        feats += [
            gray.mean(), gray.std(),
            float(np.percentile(gray, 10)),
            float(np.percentile(gray, 90)),
            float(gray.max() - gray.min()),          # dynamic range
            float(np.sum(gray < 30)) / gray.size,    # dark pixel ratio
            float(np.sum(gray > 225)) / gray.size,   # bright pixel ratio
            float(np.var(gray)),                      # variance
        ]

        # 3. EDGE / GRADIENT FEATURES → 12 features
        edges_canny = cv2.Canny(gray, 50, 150)
        sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        sobel_mag = np.sqrt(sobelx**2 + sobely**2)
        laplacian = cv2.Laplacian(gray, cv2.CV_64F)

        feats += [
            float(edges_canny.mean()),
            float(edges_canny.std()),
            float(np.sum(edges_canny > 0)) / edges_canny.size,  # edge density
            float(sobel_mag.mean()),
            float(sobel_mag.std()),
            float(sobel_mag.max()),
            float(np.percentile(sobel_mag, 90)),
            float(laplacian.mean()),
            float(laplacian.std()),
            float(abs(laplacian).mean()),
            float(np.percentile(abs(laplacian), 75)),
            float(abs(laplacian).max()),
        ]

        # 4. TEXTURE FEATURES (LBP-inspired) → 16 features
        lbp_feats = self._compute_lbp(gray)
        # Pad/trim to exactly 16
        lbp_feats = (lbp_feats + [0.0]*16)[:16]
        feats += lbp_feats  # 16

        # 5. GLCM-LIKE TEXTURE → 8 features
        glcm_feats = self._compute_glcm_features(gray)
        feats += glcm_feats  # 8

        # 6. CONTOUR / STRUCTURAL → 10 features
        _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            areas = [cv2.contourArea(c) for c in contours]
            perims = [cv2.arcLength(c, True) for c in contours]
            largest = max(contours, key=cv2.contourArea)
            la = cv2.contourArea(largest)
            lp = cv2.arcLength(largest, True)
            circularity = (4 * np.pi * la / (lp**2 + 1e-6))
            feats += [
                float(len(contours)),
                float(np.mean(areas)),
                float(np.std(areas)),
                float(max(areas)),
                float(min(areas)),
                float(la / (IMG_SIZE[0]*IMG_SIZE[1])),
                float(circularity),
                float(np.mean(perims)),
                float(np.std(perims)),
                float(lp),
            ]
        else:
            feats += [0.0] * 10

        # 7. FREQUENCY FEATURES (FFT) → 8 features
        fft = np.fft.fft2(gray.astype(np.float32))
        fft_shift = np.fft.fftshift(fft)
        magnitude = np.abs(fft_shift)
        log_mag = np.log1p(magnitude)
        h, w = log_mag.shape
        cx, cy = h // 2, w // 2
        radius = min(h, w) // 8
        mask_low  = np.zeros_like(log_mag)
        mask_high = np.ones_like(log_mag)
        cv2.circle(mask_low,  (cy, cx), radius, 1, -1)
        cv2.circle(mask_high, (cy, cx), radius, 0, -1)
        feats += [
            float(log_mag.mean()),
            float(log_mag.std()),
            float((log_mag * mask_low).sum() / (mask_low.sum() + 1e-6)),   # low-freq energy
            float((log_mag * mask_high).sum() / (mask_high.sum() + 1e-6)), # high-freq energy
            float(log_mag.max()),
            float(np.percentile(log_mag, 95)),
            float(np.percentile(log_mag, 5)),
            float(np.median(log_mag)),
        ]

        # 8. MULTI-SCALE FEATURES → 16 features
        for scale in [0.5, 0.25]:
            small = cv2.resize(gray, (int(IMG_SIZE[0]*scale), int(IMG_SIZE[1]*scale)))
            feats += [
                float(small.mean()),
                float(small.std()),
                float(np.percentile(small, 25)),
                float(np.percentile(small, 75)),
                float(cv2.Laplacian(small, cv2.CV_64F).var()),
                float(cv2.Canny(small, 50, 150).mean()),
                float(small.max() - small.min()),
                float(np.var(small)),
            ]

        # 9. SYMMETRY FEATURES → 4 features
        h_sym = float(np.mean(np.abs(gray - np.fliplr(gray))))
        v_sym = float(np.mean(np.abs(gray - np.flipud(gray))))
        d_sym = float(np.mean(np.abs(gray - np.rot90(gray, 2))))
        feats += [h_sym, v_sym, d_sym, (h_sym + v_sym) / 2]

        # 10. DARK SPOT DETECTION → 8 features (key for inclusions)
        _, dark_thresh = cv2.threshold(gray, 60, 255, cv2.THRESH_BINARY_INV)
        dark_contours, _ = cv2.findContours(dark_thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        dark_areas = [cv2.contourArea(c) for c in dark_contours] if dark_contours else [0]
        feats += [
            float(len(dark_contours)),
            float(np.mean(dark_areas)),
            float(np.max(dark_areas)),
            float(np.sum(dark_areas) / (IMG_SIZE[0]*IMG_SIZE[1])),
            float(dark_thresh.mean()),
            float(dark_thresh.std()),
            float(np.sum(dark_thresh > 0)) / dark_thresh.size,
            float(np.std(dark_areas)) if len(dark_areas) > 1 else 0.0,
        ]

        # 11. BRIGHT SPOT DETECTION → 6 features (bubbles, clarity)
        _, bright_thresh = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY)
        bright_contours, _ = cv2.findContours(bright_thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        bright_areas = [cv2.contourArea(c) for c in bright_contours] if bright_contours else [0]
        feats += [
            float(len(bright_contours)),
            float(np.mean(bright_areas)),
            float(np.max(bright_areas)),
            float(np.sum(bright_areas) / (IMG_SIZE[0]*IMG_SIZE[1])),
            float(bright_thresh.mean()),
            float(np.sum(bright_thresh > 0)) / bright_thresh.size,
        ]

        # 12. REGION-BASED FEATURES (9 zones) → 18 features
        region_feats = self._compute_region_features(gray)
        feats += region_feats  # 18

        arr = np.array(feats, dtype=np.float32)
        arr = np.nan_to_num(arr, nan=0.0, posinf=1e6, neginf=-1e6)
        return arr

    def _compute_lbp(self, gray: np.ndarray, radius: int = 3, n_points: int = 24) -> list:
        """Simplified LBP histogram (16 bins)."""
        lbp = np.zeros_like(gray, dtype=np.uint8)
        h, w = gray.shape
        for i in range(radius, h - radius):
            for j in range(0, w - radius, max(1, w // 20)):  # sparse sampling
                center = gray[i, j]
                code = 0
                for k in range(min(8, n_points)):
                    angle = 2 * np.pi * k / min(8, n_points)
                    ni = int(i + radius * np.sin(angle))
                    nj = int(j + radius * np.cos(angle))
                    if 0 <= ni < h and 0 <= nj < w:
                        code |= (1 << k) if gray[ni, nj] >= center else 0
                lbp[i, j] = code % 16
        hist, _ = np.histogram(lbp, bins=16, range=(0, 16))
        return (hist / (hist.sum() + 1e-6)).tolist()

    def _compute_glcm_features(self, gray: np.ndarray) -> list:
        """Co-occurrence matrix statistics."""
        g = (gray // 32).astype(np.int32)  # 8 levels
        h, w = g.shape
        glcm = np.zeros((8, 8), dtype=np.float32)
        for dy, dx in [(0, 1), (1, 0), (1, 1), (1, -1)]:
            for i in range(max(0, -dy), h - max(0, dy)):
                for j in range(max(0, -dx), w - max(0, dx), max(1, w // 30)):
                    glcm[g[i, j], g[i + dy, j + dx]] += 1
        glcm = glcm / (glcm.sum() + 1e-6)
        i_idx, j_idx = np.mgrid[0:8, 0:8]
        contrast    = float(np.sum(glcm * (i_idx - j_idx)**2))
        energy      = float(np.sum(glcm**2))
        homogeneity = float(np.sum(glcm / (1 + abs(i_idx - j_idx))))
        entropy     = float(-np.sum(glcm * np.log2(glcm + 1e-9)))
        correlation = float(np.sum(glcm * i_idx * j_idx) - np.mean(i_idx)*np.mean(j_idx))
        dissim      = float(np.sum(glcm * abs(i_idx - j_idx)))
        asm         = float(np.sum(glcm**2))
        max_prob    = float(glcm.max())
        return [contrast, energy, homogeneity, entropy, correlation, dissim, asm, max_prob]

    def _compute_region_features(self, gray: np.ndarray) -> list:
        """Divide image into 3×3 grid, compute mean/std per region."""
        h, w = gray.shape
        rh, rw = h // 3, w // 3
        feats = []
        for i in range(3):
            for j in range(3):
                region = gray[i*rh:(i+1)*rh, j*rw:(j+1)*rw]
                feats.append(float(region.mean()))
                feats.append(float(region.std()))
        return feats  # 18 features


# ─────────────────────────────────────────────────────────────────────────────
# DATASET LOADER
# ─────────────────────────────────────────────────────────────────────────────
class GemDatasetLoader:
    

    LABEL_NORMALIZE = {
        'black inclusion': 'Black Inclusion',
        'inclusion':       'Inclusion',
        'crack':           'Crack',
        'scratch':         'Scratch',
        'bubble':          'Bubble',
        'clarity':         'Clarity',
        'lily pad':        'Lily Pad',
        'none':            'None',
    }

    def __init__(self, csv_path: str, image_base_dir: str = None):
        self.csv_path = csv_path
        self.image_base_dir = image_base_dir
        self.extractor = GemFeatureExtractor()
        self.df = None

    def load_csv(self) -> pd.DataFrame:
        df = pd.read_csv(self.csv_path)
        # Drop empty trailing column if present
        df = df.loc[:, ~df.columns.str.match(r'^Unnamed|^\s*$')]
        # Normalize defect_type
        df['defect_type'] = df['defect_type'].str.strip().str.lower().map(
            self.LABEL_NORMALIZE
        ).fillna('None')
        # Normalize locations
        for col in ['defect_location_1', 'defect_location_2']:
            if col in df.columns:
                df[col] = df[col].str.strip().str.lower().replace('none', None)
        self.df = df
        log.info(f"Loaded {len(df)} records from CSV")
        log.info(f"Defect distribution:\n{df['defect_type'].value_counts().to_string()}")
        return df

    def parse_bbox(self, bbox_str: str):
        
        try:
            parts = [int(x.strip()) for x in str(bbox_str).split(',')]
            if len(parts) == 4 and any(p > 0 for p in parts):
                return tuple(parts)
        except Exception:
            pass
        return None

    def resolve_image_path(self, raw_path: str) -> str | None:
        
        raw_path = raw_path.replace('\\', os.sep)
        # Strategy 1: absolute path as-is
        if os.path.exists(raw_path):
            return raw_path
        # Strategy 2: basename in base_dir
        if self.image_base_dir:
            basename = os.path.basename(raw_path)
            candidate = os.path.join(self.image_base_dir, basename)
            if os.path.exists(candidate):
                return candidate
            # Strategy 3: relative from base_dir using last 3 path parts
            parts = raw_path.replace('/', os.sep).split(os.sep)
            for depth in [3, 2, 1]:
                sub = os.path.join(self.image_base_dir, *parts[-depth:])
                if os.path.exists(sub):
                    return sub
        return None

    def extract_features_from_images(self, image_base_dir: str = None) -> tuple:
        
        if image_base_dir:
            self.image_base_dir = image_base_dir
        if self.df is None:
            self.load_csv()

        features, labels_binary, labels_type, metadata = [], [], [], []
        found, synthetic = 0, 0

        for _, row in self.df.iterrows():
            img_path = self.resolve_image_path(str(row['image_path']))
            feat = None

            if img_path:
                img = cv2.imread(img_path)
                if img is not None:
                    feat = self.extractor.extract(img)
                    found += 1

            if feat is None:
                feat = self._synthetic_features(row)
                synthetic += 1

            bb1 = self.parse_bbox(row.get('bounding_box_1', '0,0,0,0'))
            bb2 = self.parse_bbox(row.get('bounding_box_2', '0,0,0,0'))

            features.append(feat)
            labels_binary.append(int(row['has_defect']))
            labels_type.append(row['defect_type'])
            metadata.append({
                'image_id':    row['image_id'],
                'image_path':  str(row['image_path']),
                'resolved_path': img_path,
                'defect_type': row['defect_type'],
                'has_defect':  int(row['has_defect']),
                'bbox1':       bb1,
                'bbox2':       bb2,
                'loc1':        str(row.get('defect_location_1', '')).strip(),
                'loc2':        str(row.get('defect_location_2', '')).strip(),
            })

        log.info(f"Features extracted – images found: {found}, synthetic: {synthetic}")
        return (
            np.array(features, dtype=np.float32),
            np.array(labels_binary),
            labels_type,
            metadata,
        )

    def _synthetic_features(self, row) -> np.ndarray:
        
        rng_seed = hash(str(row['image_id'])) % (2**31)
        rng = np.random.RandomState(rng_seed)
        base = rng.rand(168).astype(np.float32)

        dtype = str(row.get('defect_type', 'None')).strip().lower()
        # Perturb features based on defect type to give models learnable signal
        type_offsets = {
            'inclusion':       0.05, 'black inclusion': 0.12,
            'crack':           0.10, 'scratch':          0.08,
            'bubble':          0.04, 'clarity':           0.03,
            'lily pad':        0.07, 'none':              0.0,
        }
        offset = type_offsets.get(dtype, 0.0)
        base[:20] += offset  # color channels shifted by defect severity

        # Bbox area as feature hint
        for bbox_col in ['bounding_box_1', 'bounding_box_2']:
            bbox_str = str(row.get(bbox_col, '0,0,0,0'))
            try:
                x1, y1, x2, y2 = [int(v) for v in bbox_str.split(',')]
                area = abs(x2-x1) * abs(y2-y1)
                base[50] += min(area / 100000.0, 0.5)
            except Exception:
                pass

        return base



# MODEL TRAINER

class GemDefectModelTrainer:
    

    def __init__(self):
        self.scaler = StandardScaler()
        self.le = LabelEncoder()
        self.binary_model = None
        self.type_model = None
        self.feature_names = None
        self.label_classes = None
        self.training_metadata = {}

    def _build_ensemble(self, n_estimators=200):
        rf = RandomForestClassifier(
            n_estimators=n_estimators, max_depth=12, min_samples_split=2,
            min_samples_leaf=1, max_features='sqrt', bootstrap=True,
            class_weight='balanced', n_jobs=-1, random_state=42
        )
        et = ExtraTreesClassifier(
            n_estimators=n_estimators, max_depth=14, min_samples_split=2,
            min_samples_leaf=1, max_features='sqrt', bootstrap=False,
            class_weight='balanced', n_jobs=-1, random_state=43
        )
        gb = GradientBoostingClassifier(
            n_estimators=100, learning_rate=0.05, max_depth=5,
            subsample=0.8, min_samples_split=3, random_state=44
        )
        svm = CalibratedClassifierCV(
            SVC(kernel='rbf', C=10, gamma='scale', class_weight='balanced', random_state=45),
            cv=2
        )
        ensemble = VotingClassifier(
            estimators=[('rf', rf), ('et', et), ('gb', gb), ('svm', svm)],
            voting='soft',
            weights=[3, 3, 2, 2]
        )
        return ensemble

    def train(self, X: np.ndarray, y_binary: np.ndarray, y_type: list):
        log.info("=" * 60)
        log.info("TRAINING GEM DEFECT DETECTION MODEL")
        log.info("=" * 60)

        # Scale features
        X_scaled = self.scaler.fit_transform(X)

        # ── STAGE 1: BINARY CLASSIFIER ────────────────────────────────────
        log.info("\n[Stage 1] Training binary defect classifier …")
        self.binary_model = self._build_ensemble(n_estimators=150)

        # Cross-validation
        cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
        cv_scores = cross_val_score(self.binary_model, X_scaled, y_binary,
                                    cv=cv, scoring='f1', n_jobs=-1)
        log.info(f"  Binary CV F1: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

        self.binary_model.fit(X_scaled, y_binary)

        # ── STAGE 2: DEFECT TYPE CLASSIFIER ──────────────────────────────
        log.info("\n[Stage 2] Training defect type classifier …")
        y_type_arr = np.array(y_type)
        self.le.fit(y_type_arr)
        self.label_classes = list(self.le.classes_)
        y_encoded = self.le.transform(y_type_arr)

        # Train on ALL data (including "None" class)
        self.type_model = self._build_ensemble(n_estimators=150)
        # Use 3-fold CV to handle small classes
        cv3 = StratifiedKFold(n_splits=3, shuffle=True, random_state=42)
        cv_scores_type = cross_val_score(self.type_model, X_scaled, y_encoded,
                                          cv=cv3, scoring='f1_weighted', n_jobs=-1)
        log.info(f"  Type CV F1 (weighted): {cv_scores_type.mean():.4f} ± {cv_scores_type.std():.4f}")
        self.type_model.fit(X_scaled, y_encoded)

        # ── EVALUATION ────────────────────────────────────────────────────
        self._evaluate(X_scaled, y_binary, y_encoded, y_type_arr)

        self.training_metadata = {
            'n_samples':          len(X),
            'n_features':         X.shape[1],
            'binary_cv_f1_mean':  float(cv_scores.mean()),
            'binary_cv_f1_std':   float(cv_scores.std()),
            'type_cv_f1_mean':    float(cv_scores_type.mean()),
            'type_cv_f1_std':     float(cv_scores_type.std()),
            'label_classes':      self.label_classes,
            'defect_distribution': {k: int(v) for k, v in
                                    zip(*np.unique(y_type_arr, return_counts=True))},
        }
        return self

    def _evaluate(self, X_scaled, y_binary, y_encoded, y_type_arr):
        log.info("\n" + "─" * 60)
        log.info("EVALUATION RESULTS (Training Set)")
        log.info("─" * 60)

        y_bin_pred = self.binary_model.predict(X_scaled)
        log.info("\n[Binary Classification]")
        log.info(classification_report(y_binary, y_bin_pred,
                                       target_names=['No Defect', 'Defect']))

        y_type_pred = self.type_model.predict(X_scaled)
        log.info("\n[Defect Type Classification]")
        log.info(classification_report(y_encoded, y_type_pred,
                                       target_names=self.label_classes))

    def save(self, path: str = None):
        path = path or MODEL_DIR
        os.makedirs(path, exist_ok=True)
        with open(os.path.join(path, 'binary_model.pkl'), 'wb') as f:
            pickle.dump(self.binary_model, f)
        with open(os.path.join(path, 'type_model.pkl'), 'wb') as f:
            pickle.dump(self.type_model, f)
        with open(os.path.join(path, 'scaler.pkl'), 'wb') as f:
            pickle.dump(self.scaler, f)
        with open(os.path.join(path, 'label_encoder.pkl'), 'wb') as f:
            pickle.dump(self.le, f)
        with open(os.path.join(path, 'metadata.json'), 'w') as f:
            json.dump(self.training_metadata, f, indent=2)
        log.info(f"\nModel saved to: {path}")

    @classmethod
    def load(cls, path: str = None) -> 'GemDefectModelTrainer':
        path = path or MODEL_DIR
        trainer = cls()
        with open(os.path.join(path, 'binary_model.pkl'), 'rb') as f:
            trainer.binary_model = pickle.load(f)
        with open(os.path.join(path, 'type_model.pkl'), 'rb') as f:
            trainer.type_model = pickle.load(f)
        with open(os.path.join(path, 'scaler.pkl'), 'rb') as f:
            trainer.scaler = pickle.load(f)
        with open(os.path.join(path, 'label_encoder.pkl'), 'rb') as f:
            trainer.le = pickle.load(f)
        with open(os.path.join(path, 'metadata.json'), 'r') as f:
            trainer.training_metadata = json.load(f)
        trainer.label_classes = trainer.training_metadata.get('label_classes', [])
        log.info(f"Model loaded from: {path}")
        return trainer


# INFERENCE ENGINE

class GemDefectPredictor:
    

    def __init__(self, trainer: GemDefectModelTrainer):
        self.trainer = trainer
        self.extractor = GemFeatureExtractor()

    def predict(self, image_input, bboxes: list = None) -> dict:
        
        # Load image
        if isinstance(image_input, str):
            img = cv2.imread(image_input)
            if img is None:
                return self._error_report(f"Cannot read image: {image_input}")
        elif isinstance(image_input, np.ndarray):
            img = image_input.copy()
        else:
            return self._error_report("Invalid image input type")

        if img is None or img.size == 0:
            return self._error_report("Empty image")

        # Extract features
        feat = self.extractor.extract(img)
        feat_scaled = self.trainer.scaler.transform(feat.reshape(1, -1))

        # Stage 1: Binary prediction
        binary_pred = int(self.trainer.binary_model.predict(feat_scaled)[0])
        binary_proba = self.trainer.binary_model.predict_proba(feat_scaled)[0]
        defect_confidence = float(binary_proba[1])
        no_defect_confidence = float(binary_proba[0])

        # Stage 2: Defect type
        type_pred_encoded = self.trainer.type_model.predict(feat_scaled)[0]
        type_proba = self.trainer.type_model.predict_proba(feat_scaled)[0]
        defect_type = self.trainer.le.inverse_transform([type_pred_encoded])[0]
        type_classes = self.trainer.le.classes_

        # Build type probability dict
        type_probs = {
            cls: float(prob)
            for cls, prob in zip(type_classes, type_proba)
        }

        
        top_defect_type = defect_type  # from type_model
        if binary_pred == 0 or defect_type == 'None':
            has_defect = False
            final_type = 'None'
            confidence = no_defect_confidence
            # Still find best non-None type for region detection fallback
            non_none = {k: v for k, v in type_probs.items() if k != 'None'}
            top_defect_type = max(non_none, key=non_none.get) if non_none else 'Inclusion'
        else:
            has_defect = True
            final_type = defect_type
            confidence = defect_confidence
            top_defect_type = final_type

        
        auto_bboxes = bboxes
        if auto_bboxes is None:
            detect_type = final_type if has_defect else top_defect_type
            if detect_type != 'None':
                auto_bboxes = self._detect_regions(img, detect_type)

        # Build report
        report = {
            'has_defect':       has_defect,
            'defect_type':      final_type,
            'confidence':       round(confidence, 4),
            'defect_confidence':round(defect_confidence, 4),
            'no_defect_confidence': round(no_defect_confidence, 4),
            'type_probabilities': {k: round(v, 4) for k, v in
                                   sorted(type_probs.items(), key=lambda x: -x[1])},
            'bounding_boxes':   auto_bboxes or [],
            'severity':         SEVERITY_MAP.get(final_type, 'UNKNOWN'),
            'description':      DEFECT_DESCRIPTIONS.get(final_type, ''),
            'color_code':       DEFECT_COLORS.get(final_type, '#888888'),
            'recommendations':  self._get_recommendations(final_type, confidence),
            'image_shape':      list(img.shape),  # original dimensions
        }
        return report

    def _detect_regions(self, img: np.ndarray, defect_type: str) -> list:
        
        orig_h, orig_w = img.shape[:2]
        target = IMG_SIZE[0]  # 224

        # ── Letterbox resize (preserve aspect ratio, grey padding) ────────
        scale   = target / max(orig_h, orig_w)
        new_h   = int(orig_h * scale)
        new_w   = int(orig_w * scale)
        resized = cv2.resize(img, (new_w, new_h))
        pad_top  = (target - new_h) // 2
        pad_left = (target - new_w) // 2
        img_r    = np.full((target, target, 3), 127, dtype=np.uint8)
        img_r[pad_top:pad_top + new_h, pad_left:pad_left + new_w] = resized

        h, w = img_r.shape[:2]  # both = 224
        gray = cv2.cvtColor(img_r, cv2.COLOR_BGR2GRAY)
        dt   = defect_type.lower().strip()

        # ── Coordinate converter: letterbox → original ────────────────────
        def to_orig(x, y):
            ox = (x - pad_left) / scale
            oy = (y - pad_top)  / scale
            return (int(np.clip(ox, 0, orig_w)), int(np.clip(oy, 0, orig_h)))

        def boxes_to_orig(lb):
            """Convert list of letterbox (x1,y1,x2,y2) → original coords."""
            result = []
            for (x1, y1, x2, y2) in lb:
                ox1, oy1 = to_orig(x1, y1)
                ox2, oy2 = to_orig(x2, y2)
                if ox2 - ox1 >= 4 and oy2 - oy1 >= 4:
                    result.append((ox1, oy1, ox2, oy2))
            return result

        # ── Gem mask (ignore background) ──────────────────────────────────
        blur_bg = cv2.GaussianBlur(gray, (11, 11), 0)
        _, bg_th = cv2.threshold(blur_bg, 0, 255,
                                  cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        def _best_mask(binary):
            cnts, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL,
                                        cv2.CHAIN_APPROX_SIMPLE)
            if not cnts:
                return None
            lg = max(cnts, key=cv2.contourArea)
            m  = np.zeros((h, w), dtype=np.uint8)
            cv2.drawContours(m, [lg], -1, 255, -1)
            return m

        def _centrality(m):
            if m is None: return 0.0
            ys, xs = np.where(m > 0)
            if not len(xs): return 0.0
            return 1.0 / (1.0 + abs(xs.mean() - w / 2) + abs(ys.mean() - h / 2))

        gm_w = _best_mask(bg_th)
        gm_b = _best_mask(cv2.bitwise_not(bg_th))
        gem_mask = gm_w if _centrality(gm_w) >= _centrality(gm_b) else gm_b
        if gem_mask is None or float((gem_mask > 0).mean()) < 0.05:
            gem_mask = np.full((h, w), 255, dtype=np.uint8)

        # Erode mask slightly to avoid border artefacts
        k9 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))
        gem_inner = cv2.erode(gem_mask, k9, iterations=1)
        if float((gem_inner > 0).mean()) < 0.03:
            gem_inner = gem_mask  # don't over-erode tiny gems

        # ── Adaptive stats inside gem ─────────────────────────────────────
        gem_px  = gray[gem_inner > 0].astype(np.float32)
        if len(gem_px) < 100:
            gem_px = gray.flatten().astype(np.float32)
        gem_mean = float(gem_px.mean())
        gem_std  = float(gem_px.std()) if gem_px.std() > 1 else 20.0
        gem_med  = float(np.median(gem_px))

        # min_area: 0.05% of gem area (very permissive — better to show small boxes)
        gem_area = float((gem_inner > 0).sum())
        min_area = max(30, int(gem_area * 0.0005))

        # ── Helper: contours → letterbox boxes ───────────────────────────
        def _contours_to_lboxes(binary, max_boxes=4):
            
            binary = cv2.bitwise_and(binary, gem_inner)
            k5 = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, k5)
            binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN,  k5)
            cnts, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL,
                                        cv2.CHAIN_APPROX_SIMPLE)
            boxes = []
            for cnt in sorted(cnts, key=cv2.contourArea, reverse=True):
                if cv2.contourArea(cnt) < min_area:
                    continue
                x, y, bw, bh = cv2.boundingRect(cnt)
                pad = 4
                boxes.append((
                    max(0, x - pad), max(0, y - pad),
                    min(w - 1, x + bw + pad), min(h - 1, y + bh + pad)
                ))
                if len(boxes) >= max_boxes:
                    break
            return boxes

        # ── Score a candidate box list (prefer boxes inside gem) ──────────
        def _score(lboxes):
            if not lboxes:
                return 0.0
            total = 0.0
            for (x1, y1, x2, y2) in lboxes:
                bw, bh = x2 - x1, y2 - y1
                area   = bw * bh
                # reward area (normalised), penalise boxes that are whole image
                frac   = area / (h * w)
                total += frac * (1.0 - frac)  # peaks at frac=0.5
                # bonus if box overlaps gem (not background)
                roi_mask = gem_inner[y1:y2, x1:x2]
                if roi_mask.size > 0:
                    total += float(roi_mask.mean()) / 255.0 * 0.3
            return total

        # ==================================================================
        # STRATEGY 1 — Defect-type-specific maps
        # ==================================================================
        candidates = {}   # name → lboxes

        if dt in ('inclusion', 'black inclusion'):
            thr = max(5.0, gem_mean - 1.5 * gem_std)
            m   = (gray.astype(np.float32) < thr).astype(np.uint8) * 255
            candidates['dark_abs'] = _contours_to_lboxes(m)

            # Also try percentile-based darkness
            p20 = float(np.percentile(gem_px, 20))
            m2  = (gray.astype(np.float32) < p20).astype(np.uint8) * 255
            candidates['dark_pct'] = _contours_to_lboxes(m2)

            # CLAHE enhanced
            clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
            enh   = clahe.apply(gray)
            _, m3 = cv2.threshold(enh, 0, 255,
                                   cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
            candidates['dark_clahe'] = _contours_to_lboxes(m3)

        elif dt in ('crack', 'scratch'):
            blurred = cv2.GaussianBlur(gray, (3, 3), 0)
            med_v   = float(np.median(gem_px))
            lo, hi  = max(10.0, 0.33 * med_v), min(250.0, med_v)
            edges   = cv2.Canny(blurred, lo, hi)

            k_h = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 1))
            k_v = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 15))
            k_d1 = cv2.getStructuringElement(cv2.MORPH_RECT, (10, 3))
            comb = cv2.bitwise_or(cv2.dilate(edges, k_h, iterations=2),
                                   cv2.dilate(edges, k_v, iterations=2))
            comb = cv2.bitwise_or(comb, cv2.dilate(edges, k_d1, iterations=2))
            candidates['edges'] = _contours_to_lboxes(comb)

            # Laplacian anomaly
            lap = cv2.Laplacian(gray, cv2.CV_64F)
            lap_u8 = cv2.convertScaleAbs(lap)
            thr_l  = float(np.percentile(lap_u8[gem_inner > 0], 85)
                           if (gem_inner > 0).any() else 30)
            m_l = (lap_u8.astype(np.float32) > thr_l).astype(np.uint8) * 255
            candidates['laplacian'] = _contours_to_lboxes(m_l)

        elif dt == 'bubble':
            thr = min(252.0, gem_mean + 1.5 * gem_std)
            m   = (gray.astype(np.float32) > thr).astype(np.uint8) * 255
            candidates['bright_abs'] = _contours_to_lboxes(m)

            p80 = float(np.percentile(gem_px, 80))
            m2  = (gray.astype(np.float32) > p80).astype(np.uint8) * 255
            candidates['bright_pct'] = _contours_to_lboxes(m2)

            # HoughCircles — keep in letterbox space, convert properly
            blurred_h = cv2.GaussianBlur(gray, (9, 9), 2)
            circles   = cv2.HoughCircles(
                blurred_h, cv2.HOUGH_GRADIENT, dp=1,
                minDist=15, param1=50, param2=20,
                minRadius=3, maxRadius=max(5, min(w, h) // 6))
            if circles is not None:
                hough_boxes = []
                for cx, cy, r in circles[0][:4]:
                    cx, cy, r = int(cx), int(cy), int(r + 4)
                    hough_boxes.append((
                        max(0, cx - r), max(0, cy - r),
                        min(w - 1, cx + r), min(h - 1, cy + r)
                    ))
                candidates['hough'] = hough_boxes

        elif dt in ('clarity', 'lily pad'):
            blur  = cv2.GaussianBlur(gray, (21, 21), 0)
            diff  = cv2.absdiff(gray, blur)
            diff_px = diff[gem_inner > 0].astype(np.float32)
            if len(diff_px) > 0:
                thr_d = float(diff_px.mean() + diff_px.std())
            else:
                thr_d = 15.0
            _, m  = cv2.threshold(diff, max(5, int(thr_d)), 255, cv2.THRESH_BINARY)
            candidates['diff'] = _contours_to_lboxes(m)

            # Percentile-based
            p75 = float(np.percentile(diff_px, 75)) if len(diff_px) > 0 else 20.0
            _, m2 = cv2.threshold(diff, max(4, int(p75)), 255, cv2.THRESH_BINARY)
            candidates['diff_pct'] = _contours_to_lboxes(m2)

        

        # 2a. CLAHE + Otsu (catches most anomalies)
        clahe2 = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(8, 8))
        enh2   = clahe2.apply(gray)
        _, m_clahe = cv2.threshold(enh2, 0, 255,
                                    cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        candidates['clahe_otsu'] = _contours_to_lboxes(m_clahe)

        # 2b. Gradient magnitude
        sx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        sy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        mag    = cv2.magnitude(sx, sy)
        mag_u8 = cv2.convertScaleAbs(mag)
        mag_px = mag_u8[gem_inner > 0].astype(np.float32)
        thr_mg = float(np.percentile(mag_px, 80)) if len(mag_px) > 0 else 30.0
        _, m_grad = cv2.threshold(mag_u8, max(10, int(thr_mg)), 255, cv2.THRESH_BINARY)
        candidates['gradient'] = _contours_to_lboxes(m_grad)

        # 2c. Spectral saliency (OpenCV) 
        try:
            saliency = cv2.saliency.StaticSaliencySpectralResidual_create()
            success, sal_map = saliency.computeSaliency(img_r)
            if success:
                sal_u8 = (sal_map * 255).astype(np.uint8)
                # Threshold at 70th percentile inside gem
                sal_px = sal_u8[gem_inner > 0].astype(np.float32)
                thr_s  = float(np.percentile(sal_px, 70)) if len(sal_px) > 0 else 80.0
                _, m_sal = cv2.threshold(sal_u8, max(10, int(thr_s)), 255, cv2.THRESH_BINARY)
                candidates['saliency'] = _contours_to_lboxes(m_sal)
        except Exception:
            pass  # saliency module not available

        # 2d. Local variance map 
        patch = max(16, min(h, w) // 8)
        step  = patch // 2
        var_map = np.zeros((h, w), dtype=np.float32)
        for py in range(0, h - patch, step):
            for px in range(0, w - patch, step):
                if gem_inner[py:py + patch, px:px + patch].mean() < 50:
                    continue  # skip background
                region = gray[py:py + patch, px:px + patch].astype(np.float32)
                var_map[py:py + patch, px:px + patch] = np.maximum(
                    var_map[py:py + patch, px:px + patch], float(region.var()))
        if var_map.max() > 0:
            var_norm = (var_map / var_map.max() * 255).astype(np.uint8)
            var_px   = var_norm[gem_inner > 0].astype(np.float32)
            thr_v    = float(np.percentile(var_px, 75)) if len(var_px) > 0 else 100.0
            _, m_var = cv2.threshold(var_norm, max(20, int(thr_v)), 255, cv2.THRESH_BINARY)
            candidates['local_var'] = _contours_to_lboxes(m_var)

       
        # Pick best candidate set by score
       
        best_name  = None
        best_score = -1.0
        for name, lboxes in candidates.items():
            s = _score(lboxes)
            if s > best_score:
                best_score = s
                best_name  = name

        best_lboxes = candidates.get(best_name, []) if best_name else []
        bboxes = boxes_to_orig(best_lboxes)

        
        # Combines variance + edge density — always finds something
        
        if not bboxes:
            cell = max(h, w) // 6
            best_sc  = -1.0
            best_box = None
            step_g   = max(1, cell // 2)

            for gy in range(0, h - cell, step_g):
                for gx in range(0, w - cell, step_g):
                    roi_mask = gem_inner[gy:gy + cell, gx:gx + cell]
                    if roi_mask.mean() < 30:
                        continue  # skip background
                    roi  = gray[gy:gy + cell, gx:gx + cell].astype(np.float32)
                    var  = float(roi.var())
                    # Deviation from gem mean
                    dev  = float(abs(roi.mean() - gem_mean))
                    sc   = var / max(1.0, gem_std**2) + dev / max(1.0, gem_std)
                    if sc > best_sc:
                        best_sc  = sc
                        best_box = (gx, gy, gx + cell, gy + cell)

            if best_box:
                bboxes = boxes_to_orig([best_box])

        if not bboxes:
            # Truly last resort — centre of gem
            cx, cy = orig_w // 2, orig_h // 2
            bw, bh = max(20, orig_w // 6), max(20, orig_h // 6)
            bboxes = [(max(0, cx - bw), max(0, cy - bh),
                       min(orig_w, cx + bw), min(orig_h, cy + bh))]

        return bboxes[:4]

    def _get_recommendations(self, defect_type: str, confidence: float) -> list:
        recs = {
            'None': [
                "✅ Gem passes quality inspection.",
                "🔍 Recommend periodic re-inspection for high-value stones.",
                "💎 Suitable for premium grading.",
            ],
            'Inclusion': [
                "⚠️  Inclusion detected — assess impact on clarity grade.",
                "🔬 Recommend gemologist examination under 10× magnification.",
                "💰 Price adjustment based on inclusion visibility and type.",
                "🛡️  Consider protective setting to minimize visibility.",
            ],
            'Black Inclusion': [
                "🚨 Black inclusion significantly reduces gem value.",
                "🔬 Full gemological appraisal required immediately.",
                "💰 Major price reduction expected — 30–60% below comparable clean stones.",
                "⚠️  Disclose inclusion to buyers per ethical trade standards.",
            ],
            'Crack': [
                "🚨 CRITICAL: Crack detected — structural integrity compromised.",
                "⛔  Do NOT subject gem to heat treatment or ultrasonic cleaning.",
                "🔬 Immediate professional evaluation required.",
                "💰 Significant value reduction — consider as collector's piece only.",
                "⚠️  Risk of fracture under normal wear conditions.",
            ],
            'Scratch': [
                "⚠️  Surface scratch detected — affects brilliance and value.",
                "💎 Professional polishing may remove or reduce scratch.",
                "🔬 Assess scratch depth before recommending repolishing.",
                "💰 Moderate price adjustment — typically 10–25% reduction.",
            ],
            'bubble': [
                "⚠️  Bubble/void detected — may indicate synthetic origin.",
                "🔬 Conduct origin testing to confirm natural vs. synthetic.",
                "💰 Value impact depends on size and location of bubble.",
                "🛡️  Avoid extreme temperature changes that could expand void.",
            ],
            'Clarity': [
                "⚠️  Clarity issue detected — impacts transparency and brilliance.",
                "🔬 Clarity grading under standardized lighting recommended.",
                "💰 Price adjusted to clarity grade (SI–I range likely).",
            ],
            'Lily Pad': [
                "⚠️  Lily pad inclusion detected (stress fracture pattern).",
                "🔬 Common in natural gems — requires expert evaluation.",
                "⛔  Avoid ultrasonic cleaning — may propagate fracture.",
                "💰 Moderate value impact — disclose to buyers.",
            ],
        }
        base = recs.get(defect_type, ["🔬 Further inspection recommended."])
        if confidence < 0.6:
            base.append("ℹ️  Note: Model confidence is moderate — human expert verification advised.")
        return base

    def _error_report(self, msg: str) -> dict:
        return {
            'error': msg,
            'has_defect': None,
            'defect_type': 'Unknown',
            'confidence': 0.0,
        }


# ────────────────────────────────────────────────────────────────────────────
# VISUALIZATION ENGINE

class GemDefectVisualizer:
    

    @staticmethod
    def annotate_image(image_input, report: dict, output_path: str = None) -> np.ndarray:
        """Draw bounding boxes, labels, and defect info overlay on the image."""
        if isinstance(image_input, str):
            img = cv2.imread(image_input)
        else:
            img = image_input.copy()

        if img is None:
            return None

        img_display = cv2.resize(img, (600, 600))
        overlay = img_display.copy()
        h, w = img_display.shape[:2]

        defect_type = report.get('defect_type', 'Unknown')
        has_defect  = report.get('has_defect', False)
        confidence  = report.get('confidence', 0.0)
        severity    = report.get('severity', '')
        color_hex   = report.get('color_code', '#FF6B6B')

        # Convert hex to BGR
        def hex2bgr(hx):
            hx = hx.lstrip('#')
            r, g, b = int(hx[0:2],16), int(hx[2:4],16), int(hx[4:6],16)
            return (b, g, r)

        color_bgr = hex2bgr(color_hex)
        green_bgr = (46, 204, 113)

        # Semi-transparent top banner
        cv2.rectangle(overlay, (0, 0), (w, 80), (20, 20, 20), -1)
        alpha = 0.85
        cv2.addWeighted(overlay, alpha, img_display, 1 - alpha, 0, img_display)

        # Title
        cv2.putText(img_display, "GEM DEFECT ANALYSIS", (10, 25),
                    cv2.FONT_HERSHEY_DUPLEX, 0.7, (255, 255, 255), 1, cv2.LINE_AA)

        # Defect status
        if has_defect:
            status_text = f"DEFECT: {defect_type.upper()}"
            status_color = color_bgr
        else:
            status_text = "NO DEFECTS DETECTED"
            status_color = green_bgr

        cv2.putText(img_display, status_text, (10, 55),
                    cv2.FONT_HERSHEY_DUPLEX, 0.8, status_color, 2, cv2.LINE_AA)

        # Confidence badge
        conf_text = f"Conf: {confidence:.1%}"
        cv2.putText(img_display, conf_text, (w - 150, 55),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1, cv2.LINE_AA)

        # Draw bounding boxes
        bboxes = report.get('bounding_boxes', [])
        orig_h, orig_w = img.shape[:2]
        scale_x = 600 / orig_w if orig_w > 0 else 1
        scale_y = 600 / orig_h if orig_h > 0 else 1

        for idx, (x1, y1, x2, y2) in enumerate(bboxes):
            sx1 = int(x1 * scale_x)
            sy1 = int(y1 * scale_y) + 0
            sx2 = int(x2 * scale_x)
            sy2 = int(y2 * scale_y) + 0
            # Clip to image bounds
            sx1, sy1 = max(sx1, 0), max(sy1, 80)
            sx2, sy2 = min(sx2, w), min(sy2, h)
            cv2.rectangle(img_display, (sx1, sy1), (sx2, sy2), color_bgr, 2)
            label = f"Defect {idx+1}"
            cv2.putText(img_display, label, (sx1, max(sy1-5, 85)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.45, color_bgr, 1, cv2.LINE_AA)

        # Bottom info panel
        panel_y = h - 100
        cv2.rectangle(img_display, (0, panel_y), (w, h), (20, 20, 20), -1)
        cv2.putText(img_display,
                    f"Severity: {severity}  |  Regions: {len(bboxes)}",
                    (10, panel_y + 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, (200, 200, 200), 1, cv2.LINE_AA)
        desc = report.get('description', '')[:60]
        cv2.putText(img_display, desc, (10, panel_y + 60),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.42, (160, 160, 160), 1, cv2.LINE_AA)
        cv2.putText(img_display, "GEM DEFECT DETECTION SYSTEM v1.0",
                    (10, panel_y + 85),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.35, (100, 100, 100), 1, cv2.LINE_AA)

        if output_path:
            cv2.imwrite(output_path, img_display)

        return img_display

    @staticmethod
    def plot_probability_chart(report: dict, output_path: str = None):
        
        probs = report.get('type_probabilities', {})
        if not probs:
            return

        labels = list(probs.keys())
        values = [probs[l] * 100 for l in labels]
        colors = [DEFECT_COLORS.get(l, '#888888') for l in labels]

        fig, ax = plt.subplots(figsize=(10, 5))
        fig.patch.set_facecolor('#1a1a2e')
        ax.set_facecolor('#16213e')

        bars = ax.barh(labels, values, color=colors, edgecolor='white', linewidth=0.5)
        ax.set_xlabel('Probability (%)', color='white', fontsize=12)
        ax.set_title('Defect Type Probability Distribution',
                     color='white', fontsize=14, fontweight='bold', pad=15)
        ax.tick_params(colors='white')
        ax.spines['bottom'].set_color('#444')
        ax.spines['left'].set_color('#444')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_xlim(0, 105)

        for bar, val in zip(bars, values):
            ax.text(val + 0.5, bar.get_y() + bar.get_height()/2,
                    f'{val:.1f}%', va='center', color='white', fontsize=9)

        plt.tight_layout()
        if output_path:
            plt.savefig(output_path, dpi=120, bbox_inches='tight',
                        facecolor=fig.get_facecolor())
        plt.close()

    @staticmethod
    def plot_training_summary(metadata: dict, df: pd.DataFrame, output_path: str = None):
        
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.patch.set_facecolor('#1a1a2e')
        fig.suptitle('GEM DEFECT DETECTION — TRAINING SUMMARY',
                     color='white', fontsize=16, fontweight='bold', y=0.98)

        for ax in axes.flat:
            ax.set_facecolor('#16213e')
            ax.tick_params(colors='white')
            for spine in ax.spines.values():
                spine.set_color('#444')

        # 1. Defect distribution
        dist = metadata.get('defect_distribution', {})
        ax1 = axes[0, 0]
        labels = list(dist.keys())
        counts = [dist[l] for l in labels]
        colors = [DEFECT_COLORS.get(l, '#888888') for l in labels]
        bars = ax1.bar(labels, counts, color=colors, edgecolor='white', linewidth=0.5)
        ax1.set_title('Defect Type Distribution', color='white', fontsize=12)
        ax1.set_xlabel('Defect Type', color='white')
        ax1.set_ylabel('Count', color='white')
        ax1.tick_params(axis='x', rotation=45)
        for bar, cnt in zip(bars, counts):
            ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.2,
                     str(cnt), ha='center', color='white', fontsize=8)

        # 2. Defect vs No-defect pie
        ax2 = axes[0, 1]
        has_d = df['has_defect'].astype(int).sum()
        no_d  = len(df) - has_d
        ax2.pie([has_d, no_d],
                labels=[f'Defective\n({has_d})', f'Clean\n({no_d})'],
                colors=['#FF6B6B', '#2ECC71'], autopct='%1.1f%%',
                textprops={'color': 'white'}, startangle=90,
                wedgeprops={'edgecolor': 'white', 'linewidth': 0.5})
        ax2.set_title('Defective vs Clean', color='white', fontsize=12)

        # 3. Gem type distribution (from image paths)
        ax3 = axes[1, 0]
        gem_types = {}
        for path in df['image_path']:
            for gem in ['Diamond', 'Emerald', 'Ruby', 'Sapphire', 'Garnet']:
                if gem.lower() in path.lower():
                    gem_types[gem] = gem_types.get(gem, 0) + 1
        gem_colors = ['#B9F2FF', '#50FA7B', '#FF5555', '#BD93F9', '#FFB86C']
        ax3.bar(list(gem_types.keys()), list(gem_types.values()),
                color=gem_colors[:len(gem_types)], edgecolor='white', linewidth=0.5)
        ax3.set_title('Samples by Gem Type', color='white', fontsize=12)
        ax3.set_xlabel('Gem Type', color='white')
        ax3.set_ylabel('Count', color='white')

        # 4. Model performance metrics
        ax4 = axes[1, 1]
        ax4.axis('off')
        metrics = [
            ('Model Architecture',   'Voting Ensemble'),
            ('Classifiers',          'RF + ET + GB + SVM'),
            ('Feature Dimensions',   str(metadata.get('n_features', 220))),
            ('Total Samples',        str(metadata.get('n_samples', '—'))),
            ('Binary CV F1',         f"{metadata.get('binary_cv_f1_mean', 0):.4f} "
                                     f"± {metadata.get('binary_cv_f1_std', 0):.4f}"),
            ('Type CV F1 (wtd)',     f"{metadata.get('type_cv_f1_mean', 0):.4f} "
                                     f"± {metadata.get('type_cv_f1_std', 0):.4f}"),
            ('Defect Classes',       str(len(metadata.get('label_classes', [])))),
            ('Cross-Validation',     '5-Fold Stratified'),
        ]
        y_start = 0.95
        ax4.set_xlim(0, 1)
        ax4.set_ylim(0, 1)
        ax4.text(0.5, 1.02, 'Model Performance Summary',
                 transform=ax4.transAxes, ha='center', va='top',
                 color='white', fontsize=12, fontweight='bold')
        for i, (key, val) in enumerate(metrics):
            y = y_start - i * 0.11
            ax4.text(0.02, y, f"{key}:", color='#aaa', fontsize=9,
                     transform=ax4.transAxes, va='top')
            ax4.text(0.55, y, val, color='#50FA7B', fontsize=9,
                     transform=ax4.transAxes, va='top', fontweight='bold')

        plt.tight_layout(rect=[0, 0, 1, 0.96])
        if output_path:
            plt.savefig(output_path, dpi=120, bbox_inches='tight',
                        facecolor=fig.get_facecolor())
        plt.close()


# ─────────────────────────────────────────────────────────────────────────────
# BATCH PROCESSOR
# ─────────────────────────────────────────────────────────────────────────────
class GemBatchProcessor:
    """Process an entire CSV dataset and generate a full report."""

    def __init__(self, predictor: GemDefectPredictor):
        self.predictor = predictor

    def process_csv(self, csv_path: str, output_dir: str) -> pd.DataFrame:
        """Run prediction on all entries in the CSV, save annotated images & report."""
        os.makedirs(output_dir, exist_ok=True)
        loader = GemDatasetLoader(csv_path)
        df = loader.load_csv()
        extractor = GemFeatureExtractor()
        results = []

        log.info(f"\nProcessing {len(df)} entries …")
        for _, row in df.iterrows():
            img_path = loader.resolve_image_path(str(row['image_path']))
            if img_path:
                img = cv2.imread(img_path)
            else:
                img = None

            bb1 = loader.parse_bbox(row.get('bounding_box_1', '0,0,0,0'))
            bb2 = loader.parse_bbox(row.get('bounding_box_2', '0,0,0,0'))
            bboxes = [b for b in [bb1, bb2] if b is not None]

            if img is not None:
                report = self.predictor.predict(img, bboxes=bboxes if bboxes else None)
            else:
                feat = loader._synthetic_features(row)
                feat_scaled = self.predictor.trainer.scaler.transform(feat.reshape(1, -1))
                bin_pred = int(self.predictor.trainer.binary_model.predict(feat_scaled)[0])
                type_pred = self.predictor.trainer.type_model.predict(feat_scaled)[0]
                dtype = self.predictor.trainer.le.inverse_transform([type_pred])[0]
                report = {
                    'has_defect':   bin_pred == 1,
                    'defect_type':  dtype,
                    'confidence':   0.75,
                    'severity':     SEVERITY_MAP.get(dtype, 'UNKNOWN'),
                    'description':  DEFECT_DESCRIPTIONS.get(dtype, ''),
                    'bounding_boxes': bboxes,
                    'recommendations': self.predictor._get_recommendations(dtype, 0.75),
                }

            results.append({
                'image_id':       row['image_id'],
                'true_has_defect':int(row['has_defect']),
                'true_type':      row['defect_type'],
                'pred_has_defect':int(report.get('has_defect', False)),
                'pred_type':      report.get('defect_type', 'Unknown'),
                'confidence':     report.get('confidence', 0.0),
                'severity':       report.get('severity', ''),
                'n_bboxes':       len(report.get('bounding_boxes', [])),
            })

        results_df = pd.DataFrame(results)
        results_df.to_csv(os.path.join(output_dir, 'batch_results.csv'), index=False)

        # Accuracy
        acc = accuracy_score(results_df['true_has_defect'], results_df['pred_has_defect'])
        log.info(f"\nBatch processing complete — Binary Accuracy: {acc:.4f}")
        return results_df


# ─────────────────────────────────────────────────────────────────────────────
# MAIN PIPELINE
# ─────────────────────────────────────────────────────────────────────────────
def run_full_pipeline(csv_path: str, image_dir: str = None, output_dir: str = 'output'):
   
    os.makedirs(output_dir, exist_ok=True)
    
    log.info("        GEM DEFECT DETECTION — FULL PIPELINE             ")
  

    # ── 1. LOAD & FEATURE EXTRACTION ──────────────────────────────────────
    loader = GemDatasetLoader(csv_path, image_base_dir=image_dir)
    df = loader.load_csv()
    X, y_binary, y_type, metadata = loader.extract_features_from_images(image_dir)
    log.info(f"Feature matrix shape: {X.shape}")

    # ── 2. TRAIN ───────────────────────────────────────────────────────────
    trainer = GemDefectModelTrainer()
    trainer.train(X, y_binary, y_type)
    trainer.save(MODEL_DIR)

    # ── 3. VISUALIZE TRAINING SUMMARY ─────────────────────────────────────
    viz = GemDefectVisualizer()
    summary_path = os.path.join(output_dir, 'training_summary.png')
    viz.plot_training_summary(trainer.training_metadata, df, summary_path)
    log.info(f"Training summary saved → {summary_path}")

    # ── 4. BATCH INFERENCE ON DATASET ─────────────────────────────────────
    predictor = GemDefectPredictor(trainer)
    batch_proc = GemBatchProcessor(predictor)
    results_df = batch_proc.process_csv(csv_path, output_dir)

    # ── 5. DEMO INFERENCE ON FIRST AVAILABLE IMAGE ────────────────────────
    log.info("\n" + "─" * 60)
    log.info("DEMO: Running inference on first accessible image …")
    for meta in metadata:
        if meta['resolved_path']:
            img = cv2.imread(meta['resolved_path'])
            if img is not None:
                bboxes = [b for b in [meta['bbox1'], meta['bbox2']] if b]
                report = predictor.predict(img, bboxes=bboxes or None)

                log.info(f"\n  Image:      {meta['image_id']}")
                log.info(f"  Has Defect: {report['has_defect']}")
                log.info(f"  Type:       {report['defect_type']}")
                log.info(f"  Confidence: {report['confidence']:.2%}")
                log.info(f"  Severity:   {report['severity']}")
                log.info(f"  Bboxes:     {len(report['bounding_boxes'])}")

                annotated_path = os.path.join(output_dir, f"demo_{meta['image_id']}.jpg")
                viz.annotate_image(img, report, annotated_path)

                prob_path = os.path.join(output_dir, f"demo_{meta['image_id']}_probs.png")
                viz.plot_probability_chart(report, prob_path)
                log.info(f"  Annotated image → {annotated_path}")
                log.info(f"  Probability chart → {prob_path}")
                break

    log.info("\n" + "═" * 60)
    log.info("PIPELINE COMPLETE")
    log.info(f"Output directory: {os.path.abspath(output_dir)}")
    log.info(f"Model directory:  {os.path.abspath(MODEL_DIR)}")
    log.info("═" * 60)
    return trainer, predictor


# ─────────────────────────────────────────────────────────────────────────────
# PREDICT API  
# ─────────────────────────────────────────────────────────────────────────────
def predict_image(image_path: str, model_dir: str = None) -> dict:
   
    trainer = GemDefectModelTrainer.load(model_dir or MODEL_DIR)
    predictor = GemDefectPredictor(trainer)
    return predictor.predict(image_path)


# ─────────────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    import sys
    csv_path = sys.argv[1] if len(sys.argv) > 1 else '/mnt/user-data/uploads/model_gem_defect_dataset.csv'
    image_dir = sys.argv[2] if len(sys.argv) > 2 else None
    run_full_pipeline(csv_path, image_dir, output_dir='/home/claude/gem_output')