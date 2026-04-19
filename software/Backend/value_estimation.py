BASE_PRICE = {
    "Diamond": 5000,
    "Ruby": 3000,
    "Sapphire": 2500,
    "Emerald": 2000
}

def estimate_value(gem_type, weight, defect_percentage):
    """
    Estimate gemstone value based on quality.
    """

    base_price = BASE_PRICE.get(gem_type, 1500)

    quality_factor = max(0.5, 1 - (defect_percentage / 100))

    value = base_price * weight * quality_factor

    return round(value, 2)
