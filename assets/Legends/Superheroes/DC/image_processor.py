import cv2
import numpy as np
import sys
import os

def process_image(filepath):
    print(f"Processing: {os.path.basename(filepath)}")

    # Load image
    img = cv2.imread(filepath)
    if img is None:
        print(f"Error: Could not load {filepath}")
        return

    # Original dimensions
    h_orig, w_orig = img.shape[:2]

    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Find the largest contour for initial bounding box
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Initial bounding box - start with full image if nothing found
    rect = (0, 0, w_orig, h_orig)

    if contours:
        largest = max(contours, key=cv2.contourArea)
        rect = cv2.boundingRect(largest)

    # GrabCut for Background Removal
    mask = np.zeros(img.shape[:2], np.uint8)
    bgdModel = np.zeros((1, 65), np.float64)
    fgdModel = np.zeros((1, 65), np.float64)

    try:
        # If the rectangle is invalid, use full image
        if rect[2] <= 0 or rect[3] <= 0:
             rect = (0, 0, w_orig, h_orig)
        cv2.grabCut(img, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)
    except Exception as e:
        print(f"GrabCut failed: {e}")

    # Initial mask: 0/2 = background, 1/3 = foreground
    mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype('uint8')

    # --- IMPROVEMENT 1: INTERNAL COLOR PRESERVATION ---
    # Find contours in the mask and fill them to ensure internal parts are solid
    contours, _ = cv2.findContours(mask2, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        # Create a clean filled mask from the outer boundary
        filled_mask = np.zeros(mask2.shape, dtype=np.uint8)
        cv2.drawContours(filled_mask, contours, -1, 1, thickness=cv2.FILLED)
        mask2 = filled_mask

    # Find the bounding box of the isolated subject
    coords = cv2.findNonZero(mask2)
    if coords is not None:
        x_tight, y_tight, w_tight, h_tight = cv2.boundingRect(coords)

        # Add 5 pixels margin
        margin = 5

        # --- IMPROVEMENT 2: SQUARE 128px OUTPUT ---
        # Calculate square dimension (side of the square)
        side = max(w_tight, h_tight) + (2 * margin)

        # Create a new transparent square canvas
        canvas = np.zeros((side, side, 4), dtype=np.uint8)

        # Calculate crop boundaries (clamped to image limits)
        # We center the tight box inside the square 'side'
        # Start by finding where the tight box would sit relative to the original image
        # with the margin included.

        src_x1 = max(0, x_tight - margin)
        src_y1 = max(0, y_tight - margin)
        src_x2 = min(w_orig, x_tight + w_tight + margin)
        src_y2 = min(h_orig, y_tight + h_tight + margin)

        # Image data to extract (including actual pixels + alpha)
        # Convert original image to BGRA
        b, g, r = cv2.split(img)
        a = (mask2 * 255).astype('uint8')
        img_bgra = cv2.merge([b, g, r, a])

        subject_crop = img_bgra[src_y1:src_y2, src_x1:src_x2]

        # Calculate position to paste subject into center of canvas
        crop_h, crop_w = subject_crop.shape[:2]
        paste_x = (side - crop_w) // 2
        paste_y = (side - crop_h) // 2

        canvas[paste_y:paste_y+crop_h, paste_x:paste_x+crop_w] = subject_crop

        # Final Resize to 128x128
        final_128 = cv2.resize(canvas, (128, 128), interpolation=cv2.INTER_AREA)

        # Save as PNG with original name (lowercase, spaces instead of underscores)
        original_name = os.path.splitext(os.path.basename(filepath))[0]
        output_name = original_name.lower().replace("_", " ") + ".png"
        output_path = os.path.join(os.path.dirname(filepath), output_name)
        cv2.imwrite(output_path, final_128)
        print(f"Saved: {output_name} (128x128 square)")
    else:
        print(f"Could not isolate subject for {filepath}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: Drag images onto this script or a batch file wrapper.")
    else:
        for arg in sys.argv[1:]:
            if os.path.isfile(arg):
                process_image(arg)
            else:
                print(f"Skipping: {arg} is not a file.")
