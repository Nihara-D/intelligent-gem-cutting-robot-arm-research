from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import tensorflow as tf
import numpy as np
import pandas as pd
import joblib
from catboost import CatBoostClassifier
import json
import logging

from preprocessing import (
    preprocess_image,
    preprocess_tabular,
    stone_encoder,
    auth_encoder,
    origin_encoder
)

# =====================================================
# Logging
# =====================================================
logging.basicConfig(level=logging.INFO)

# =====================================================
# App
# =====================================================
app = FastAPI(
    title="Gem Identification & Cut Recommendation API",
    description="Unified API for Gem Identification and Cut Parameter Recommendation.",
    version="2.0"
)

# =====================================================
# CORS Middleware (Flutter-compatible)
# =====================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# Load Gem Identification Model
# =====================================================
MODEL_PATH = "gem_identification_model_enhanced.keras"
try:
    identification_model = tf.keras.models.load_model(MODEL_PATH)
    logging.info("Gem Identification model loaded successfully.")
except Exception as e:
    logging.error(f"Failed to load Gem Identification model: {e}")
    identification_model = None

# =====================================================
# Load Gem Cut Models in FastAPI
# =====================================================
family_model = None
try:
    family_model = CatBoostClassifier()
    family_model.load_model("models/cut_family_model.cbm")

    le_family = joblib.load("models/family_encoder.joblib")
    le_gem    = joblib.load("models/gemstone_encoder.joblib")

    with open("input_features.json") as f:
        INPUT_FEATURES = json.load(f)

    rank_models  = {}
    cut_encoders = {}
    param_models = {}

    for fam in le_family.classes_:
        # Try loading the full ranking model + encoder (multi-class families)
        try:
            rank_models[fam]  = joblib.load(f"models/rank_model_{fam}.joblib")
            cut_encoders[fam] = joblib.load(f"models/cut_encoder_{fam}.joblib")
            logging.info(f"Loaded ranking model and encoder for family: {fam}")
        except Exception:
            # Ranking model missing — try loading encoder only.
            # This covers single-class families (Step → Emerald, Cabochon → Cabochon)
            # whose encoder is saved by the updated notebook but have no XGBoost model.
            try:
                cut_encoders[fam] = joblib.load(f"models/cut_encoder_{fam}.joblib")
                logging.info(f"Loaded encoder-only for single-class family: {fam}")
            except Exception:
                logging.info(f"No ranking model or encoder found for family: {fam}")

        # Try loading the cutting parameter regression model (independent of above)
        try:
            param_models[fam] = joblib.load(f"models/cut_param_model_{fam}.joblib")
        except Exception:
            logging.info(f"No parameter model for family: {fam}")

    logging.info("Gem Cut Advisor models loaded successfully.")
except Exception as e:
    logging.error(f"Failed to load Gem Cut Advisor models: {e}")

# =====================================================
# Constants
# =====================================================
# Fallback cut names used when no encoder file exists at all.
# If the encoder IS available (loaded above), its classes_[0] is used instead,
# keeping labels consistent with the training data.
SINGLE_CUT_FALLBACK = {
    "Step":     "Emerald",
    "Cabochon": "Cabochon"
}

TRAINED_GEMSTONE_TYPES = [
    "Alexandrite", "Amethyst", "Aquamarine", "Blue Sapphire", "Chrysoberyl",
    "Citrine", "Garnet", "Hessonite", "Jade", "Kunzite", "Moonstone", "Morganite",
    "Opal", "Peridot", "Pink Sapphire", "Quartz", "Ruby", "Spinel", "Tanzanite",
    "Topaz", "Tourmaline", "Turquoise", "Yellow Sapphire", "Zircon"
]

# =====================================================
# Color Normalization (Gem Identification)
# =====================================================
COLOR_MAP = {
    "Purple"     : "Blue / Pink / Purple / Black (depending on type)",
    "Black"      : "Blue / Pink / Purple / Black (depending on type)",
    "Light Brown": "Colorless / Light Brown / Blue (depending on variety)",
    "Multicolor" : "Pink / Green / Blue / Red / Multicolor (depending on variety)",
    "purple"     : "Blue / Pink / Purple / Black (depending on type)",
    "black"      : "Blue / Pink / Purple / Black (depending on type)",
    "light brown": "Colorless / Light Brown / Blue (depending on variety)",
    "multicolor" : "Pink / Green / Blue / Red / Multicolor (depending on variety)",
}

def normalize_color(color: str) -> str:
    return COLOR_MAP.get(color.strip(), color.strip())

def normalize_text(x: str) -> str:
    return x.strip().lower()

TRAINED_GEMSTONE_SET = {normalize_text(g) for g in TRAINED_GEMSTONE_TYPES}

# =====================================================
# Input Schema
# =====================================================
class GemInput(BaseModel):
    gemstone_type: str
    ri: float
    carat_weight: float
    length_mm: float
    width_mm: float
    depth_mm: float

# =====================================================
# Helper Functions
# =====================================================
def encode_gemstone(value: str):
    """
    Encode gemstone type using the fitted LabelEncoder.
    Returns (encoded_value, is_unseen) where is_unseen=True means
    the gemstone was not in the training set.
    """
    norm_val = normalize_text(value)
    is_unseen = norm_val not in TRAINED_GEMSTONE_SET
    for cls in le_gem.classes_:
        if normalize_text(cls) == norm_val:
            return le_gem.transform([cls])[0], is_unseen
    return le_gem.transform(["Unknown"])[0], is_unseen

 # Preprocess user input
def preprocess_input(data: GemInput):
    """
    Convert GemInput into the feature DataFrame expected by the cut advisor models.
    Returns (X, is_unseen_gem).
    """
    df = pd.DataFrame([data.model_dump()])
    # Encode gem type 
    gem_encoded, unseen_gem = encode_gemstone(df.loc[0, "gemstone_type"])
    df["gemstone_type"] = gem_encoded

    # Physics-based feature engineering (mirrors the notebook)
    df["aspect_ratio"] = df["length_mm"] / df["width_mm"]
    df["depth_ratio"]  = df["depth_mm"]  / df["width_mm"]
    df["elongation"]   = (
        np.maximum(df["length_mm"], df["width_mm"]) /
        np.minimum(df["length_mm"], df["width_mm"])
    )
    df["roundness"] = np.abs(df["length_mm"] - df["width_mm"]) / df["width_mm"]

    return df[INPUT_FEATURES], unseen_gem


def predict_top_k_cuts_safe(X, family: str, unseen_gem: bool, k: int = 3):
    """
    Return the top-k cut recommendations for a given cut family.

    Handles three cases:
      1. Multi-class family  → use the trained XGBoost ranking model.
      2. Single-class family → the model is None; return the one known cut
                               from the saved encoder (or SINGLE_CUT_FALLBACK).
      3. Completely unknown  → generic fallback with low confidence.

    Confidence is scaled down by 30 % for unseen gemstone types.
    """
    confidence_scale = 0.7 if unseen_gem else 1.0

    # ── Case 1: full ranking model available ──────────────────────────────
    if family in rank_models:
        rank_model = rank_models[family]
        encoder    = cut_encoders[family]
        probs      = rank_model.predict_proba(X)[0]
        top_idx    = np.argsort(probs)[::-1][:k]
        return [
            {
                "cut":        encoder.inverse_transform([i])[0],
                "confidence": round(float(probs[i]) * confidence_scale, 2)
            }
            for i in top_idx
        ]

    # ── Case 2: single-class family (Step / Cabochon) ─────────────────────
    if family in SINGLE_CUT_FALLBACK:
        # Prefer the encoder's label so it stays in sync with training data.
        # Fall back to the hardcoded constant only if the encoder wasn't loaded.
        cut_name = (
            cut_encoders[family].classes_[0]
            if family in cut_encoders
            else SINGLE_CUT_FALLBACK[family]
        )
        return [{"cut": cut_name, "confidence": round(1.0 * confidence_scale, 2)}]

    # ── Case 3: completely unknown family ─────────────────────────────────
    return [{"cut": f"{family} Cut", "confidence": round(0.5 * confidence_scale, 2)}]

# =====================================================
# API Endpoints
# =====================================================
@app.get("/")
def health_check():
    return {"status": "Gem Unified API is running"}


@app.post("/predict")
async def predict_gem(
    image: UploadFile = File(...),
    ri: float = Form(...),
    sg: float = Form(...),
    hardness: float = Form(...),
    color: str = Form(...)
):
    """Identify a gemstone by uploading an image with physical properties."""
    if not identification_model:
        return JSONResponse(status_code=500, content={"error": "Identification model not loaded."})
    try:
        image_bytes    = await image.read()
        img_input      = preprocess_image(image_bytes)
        color_canonical = normalize_color(color)
        tab_input      = preprocess_tabular(ri, sg, hardness, color_canonical)

        pred_stone, pred_auth, pred_origin = identification_model.predict(
            [img_input, tab_input], verbose=0
        )

        return JSONResponse(content={
            "stone": {
                "label":      stone_encoder.classes_[int(np.argmax(pred_stone, axis=1)[0])],
                "confidence": float(np.max(pred_stone))
            },
            "authentication": {
                "label":      auth_encoder.classes_[int(np.argmax(pred_auth, axis=1)[0])],
                "confidence": float(np.max(pred_auth))
            },
            "origin": {
                "label":      origin_encoder.classes_[int(np.argmax(pred_origin, axis=1)[0])],
                "confidence": float(np.max(pred_origin))
            }
        })
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})


@app.post("/recommend-cut")
def recommend_cut(data: GemInput):
    """Recommend cut type and cutting parameters for a gemstone."""
    if not family_model:
        return JSONResponse(status_code=500, content={"error": "Cut recommendation model not loaded."})

    X, unseen_gem = preprocess_input(data)

    
    # Stage 1 — predict cut family
    fam_enc = family_model.predict(X).ravel()[0]
    fam     = le_family.inverse_transform([fam_enc])[0]

    # Stage 2 — predict top-3 exact cuts within that family
    top3 = predict_top_k_cuts_safe(X, fam, unseen_gem)

    # Stage 3 — predict cutting parameters for the family
    params = {}
    if fam in param_models:
        preds = param_models[fam].predict(X)[0]
        params = {
            "pavilion_angle":     round(float(preds[0]), 2),
            "crown_angle":        round(float(preds[1]), 2),
            "table_percent":      round(float(preds[2]), 2),
            "depth_percent":      round(float(preds[3]), 2),
            "facet_count":        round(float(preds[4]), 2),
            "length_width_ratio": round(float(preds[5]), 2),
        }

    return {
        "Predicted Cut Family":            fam,
        "Top-3 Exact Cut Recommendations": top3,
        "Best Exact Cut Recommendation":   top3[0]["cut"] if top3 else None,
        "Recommended Cutting Parameters":  params,
        "Warning": (
            "Unseen gemstone type. Recommendations are based on geometric similarity "
            "and learned cutting patterns, not gemstone-specific certification."
        ) if unseen_gem else None,
        "Note": "This output is an AI-generated recommendation and should be validated by a gemology expert."
    }
