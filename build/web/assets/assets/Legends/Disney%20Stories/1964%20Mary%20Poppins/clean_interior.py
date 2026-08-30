import cv2
import numpy as np
import sys
import os

def clean_interior_background(filepath, output_dir):
    print(f"Processing: {os.path.basename(filepath)}")

    img = cv2.imread(filepath, cv2.IMREAD_UNCHANGED)
    if img is None:
        print(f"Error: Could not load {filepath}")
        return

    if img.shape[2] == 3:
        b, g, r = cv2.split(img)
        a = np.full(b.shape, 255, dtype=np.uint8)
        img = cv2.merge([b, g, r, a])

    b, g, r, a = cv2.split(img)

    # Detect near-white pixels that are still opaque
    white_threshold = 220
    gray = cv2.cvtColor(cv2.merge([b, g, r]), cv2.COLOR_BGR2GRAY)
    is_light = gray >= white_threshold

    # Only target pixels that are: light-colored AND currently opaque
    interior_mask = is_light & (a > 50)

    # Use flood fill from the alpha channel edges to identify true exterior
    # Flood fill from all four corners on the alpha mask to find what's "outside"
    h, w = a.shape
    alpha_for_flood = a.copy()
    flood_mask = np.zeros((h + 2, w + 2), dtype=np.uint8)

    # Mark exterior: flood fill from corners where alpha is already transparent
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    for seed in corners:
        if alpha_for_flood[seed[1], seed[0]] < 128:
            cv2.floodFill(alpha_for_flood, flood_mask, seed, 255)

    # Exterior = pixels reachable from edges with low alpha
    exterior = alpha_for_flood < 128

    # Interior = light pixels that are NOT exterior (i.e., trapped inside the subject)
    truly_interior = interior_mask & ~exterior

    # Make interior light pixels transparent
    a[truly_interior] = 0

    # Also clean up: reduce alpha on semi-light interior pixels for smoother edges
    light_semi = (gray >= 200) & (a > 0) & (a < 200) & ~exterior
    a[light_semi] = np.clip(a[light_semi].astype(np.int16) - 80, 0, 255).astype(np.uint8)

    # Build output
    cleaned = cv2.merge([b, g, r, a])

    original_name = os.path.splitext(os.path.basename(filepath))[0]
    output_name = original_name.lower().replace("_", " ") + ".png"
    output_path = os.path.join(output_dir, output_name)
    cv2.imwrite(output_path, cleaned)
    print(f"Saved: {output_name}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: Drag PNG files onto this script or a batch file wrapper.")
        print("Output will be placed in a 'cleaned' subfolder next to the source files.")
    else:
        # Determine output directory from the first valid file's parent folder
        output_dir = None
        files_to_process = []

        for arg in sys.argv[1:]:
            if os.path.isfile(arg) and arg.lower().endswith('.png'):
                if output_dir is None:
                    output_dir = os.path.join(os.path.dirname(arg), "cleaned")
                    os.makedirs(output_dir, exist_ok=True)
                    print(f"Output folder: {output_dir}\n")
                files_to_process.append(arg)
            else:
                print(f"Skipping: {arg} (not a PNG file)")

        if not files_to_process:
            print("No PNG files to process.")
        else:
            for f in files_to_process:
                clean_interior_background(f, output_dir)
            print(f"\nDone! Processed {len(files_to_process)} file(s) into:\n  {output_dir}")
