import cv2
import numpy as np

GEM_DENSITY = {
    "Diamond": 3.51,
    "Ruby": 4.0,
    "Sapphire": 4.0,
    "Emerald": 2.76
}

def calculate_weight(images, gem_type):
    """
    Estimate gemstone weight using multiple images.
    Returns weight in carats.
    """

    total_area = 0

    for image in images:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        _, thresh = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY)
        area = np.count_nonzero(thresh)
        total_area += area

    average_area = total_area / len(images)

    pixel_to_cm = 0.0001  # calibration constant
    volume = average_area * pixel_to_cm

    density = GEM_DENSITY.get(gem_type, 3.0)
    weight_grams = volume * density

    weight_carats = weight_grams / 0.2

    return round(weight_carats, 2)
