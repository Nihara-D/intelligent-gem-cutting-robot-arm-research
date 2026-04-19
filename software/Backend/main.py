from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
from typing import List

app = FastAPI(title="Gem Valuation API")

# Enable CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Base prices (USD per carat)
BASE_PRICE = {
    "Diamond": 5000,
    "Ruby": 3000,
    "Sapphire": 2500,
    "Blue Sapphire": 2500,
    "Emerald": 2000
}

def detect_defects(image):
    """Detect defects in gemstone image"""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    
    edges = cv2.Canny(blurred, 50, 150)
    edge_pixels = cv2.countNonZero(edges)
    
    _, bright_thresh = cv2.threshold(gray, 220, 255, cv2.THRESH_BINARY)
    bright_pixels = cv2.countNonZero(bright_thresh)
    
    total_pixels = gray.shape[0] * gray.shape[1]
    defect_pixels = edge_pixels + bright_pixels
    defect_percentage = (defect_pixels / total_pixels) * 100
    
    return min(defect_percentage, 50.0)

def calculate_weight(images):
    """Estimate weight from images"""
    total_area = 0
    for image in images:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        _, thresh = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY)
        area = np.count_nonzero(thresh)
        total_area += area
    
    average_area = total_area / len(images)
    pixel_to_cm = 0.0001
    volume = average_area * pixel_to_cm
    weight_grams = volume * 3.5
    weight_carats = weight_grams / 0.2
    
    return round(max(weight_carats, 0.5), 2)

def estimate_value(gem_type, weight, defect_percentage):
    """Calculate value"""
    base_price = BASE_PRICE.get(gem_type, 1500)
    quality_factor = max(0.5, 1 - (defect_percentage / 100))
    value = base_price * weight * quality_factor
    return round(value, 2)

@app.get("/")
async def root():
    return {"message": "Gem Valuation API Running", "status": "OK"}

@app.post("/analyze-gem/")
async def analyze_gem(
    gem_type: str = Form(...),
    images: List[UploadFile] = File(...)
):
    try:
        image_list = []
        for file in images:
            contents = await file.read()
            np_img = np.frombuffer(contents, np.uint8)
            image = cv2.imdecode(np_img, cv2.IMREAD_COLOR)
            if image is not None:
                image_list.append(image)
        
        if not image_list:
            return {"error": "No valid images uploaded"}
        
        defect_percentages = [detect_defects(img) for img in image_list]
        avg_defect = round(sum(defect_percentages) / len(defect_percentages), 2)
        
        weight = calculate_weight(image_list)
        value_usd = estimate_value(gem_type, weight, avg_defect)
        
        return {
            "gem_type": gem_type,
            "defect_percentage": avg_defect,
            "weight_carats": weight,
            "estimated_value_usd": value_usd
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)