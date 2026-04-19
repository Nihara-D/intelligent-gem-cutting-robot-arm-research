import cv2
import numpy as np
import matplotlib.pyplot as plt

def detect_and_localize_inclusions(image_path: str, output_path: str = "defects_marked.jpg"):
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError("Image not loaded")
    
    original = image.copy()
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    height, width = gray.shape
    total_pixels = height * width
    
    detected = []
    
    # 1. Fractures/Feathers: Strong edges
    edges = cv2.Canny(blurred, 50, 150)
    edge_pct = (cv2.countNonZero(edges) / total_pixels) * 100
    if edge_pct > 1.5:
        detected.append("Fractures/Feathers")
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cv2.drawContours(image, contours, -1, (0, 0, 255), 2)  # Red lines
    
    # 2. Pinpoints/Crystals: Bright spots
    _, bright = cv2.threshold(gray, 220, 255, cv2.THRESH_BINARY)
    bright_pct = (cv2.countNonZero(bright) / total_pixels) * 100
    if bright_pct > 0.4:
        detected.append("Pinpoints/Crystals")
        contours, _ = cv2.findContours(bright, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in contours:
            if cv2.contourArea(cnt) > 10:  # Filter noise
                x, y, w, h = cv2.boundingRect(cnt)
                cv2.rectangle(image, (x, y), (x+w, y+h), (255, 255, 0), 2)  # Cyan boxes
    
    # 3. Needles: Long thin lines
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=50, minLineLength=40, maxLineGap=10)
    if lines is not None and len(lines) > 6:
        detected.append("Needles")
        for line in lines:
            x1, y1, x2, y2 = line[0]
            cv2.line(image, (x1, y1), (x2, y2), (0, 255, 255), 3)  # Yellow lines
    
    # 4. Clouds/Hazy: Low contrast areas
    if gray.std() < 60:
        detected.append("Clouds/Hazy")
        # Mask low-variance regions
        var = cv2.Laplacian(gray, cv2.CV_64F).var()
        if var < 100:
            mask = cv2.threshold(cv2.Laplacian(gray, cv2.CV_64F), 10, 255, cv2.THRESH_BINARY)[1]
            image = cv2.bitwise_and(image, image, mask=cv2.bitwise_not(mask.astype(np.uint8)))
            cv2.putText(image, "Hazy Cloud Area", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
    
    # 5. Three-phase/Fingerprints: Approximate with fluid-like healed fractures (veils)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    dilated = cv2.dilate(edges, kernel)
    if cv2.countNonZero(dilated) / total_pixels * 100 > 3:
        detected.append("Possible Fingerprints/Three-Phase Veils")
        cv2.drawContours(image, cv2.findContours(dilated, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)[0], -1, (255, 0, 255), 2)
    
    # Save and show marked image
    cv2.imwrite(output_path, image)
    print("Detected inclusions:", detected if detected else ["Clean/Minimal"])
    print(f"Marked image saved as {output_path}")
    
    # Display with matplotlib
    plt.figure(figsize=(12, 8))
    plt.subplot(1, 2, 1)
    plt.title("Original")
    plt.imshow(cv2.cvtColor(original, cv2.COLOR_BGR2RGB))
    plt.axis("off")
    
    plt.subplot(1, 2, 2)
    plt.title("Defects Localized")
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.axis("off")
    plt.show()

# Usage: Replace with your gem image path
detect_and_localize_inclusions("your_gem_image.jpg")