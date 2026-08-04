import sys
import os
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BLANK_PATH = os.path.join(SCRIPT_DIR, 'BLANK.png')
OUTPUT_DIR = SCRIPT_DIR

def create_folder_icon(char_path):
    if not os.path.exists(BLANK_PATH):
        print(f'ERROR: BLANK.png not found at {BLANK_PATH}')
        return False

    try:
        blank = Image.open(BLANK_PATH).convert('RGBA')
    except Exception as e:
        print(f'ERROR: Cannot open BLANK.png: {e}')
        return False

    blank_w, blank_h = blank.size

    try:
        char_img = Image.open(char_path).convert('RGBA')
    except Exception as e:
        print(f'ERROR: Cannot open image: {e}')
        return False

    target_size = int(blank_w * 0.58)
    char_img.thumbnail((target_size, target_size), Image.LANCZOS)

    composite = blank.copy()
    char_w, char_h = char_img.size
    x = (blank_w - char_w) // 2
    y = int(blank_h * 0.52) - char_h // 2 + 7
    composite.paste(char_img, (x, y), char_img)

    basename = os.path.splitext(os.path.basename(char_path))[0]
    basename = basename.title()
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, basename + '.png')
    composite.save(output_path, 'PNG')
    print(f'Created: {basename}.png')
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: Drag image files onto this script (up to 50)')
        input('Press Enter to exit...')
        sys.exit(1)

    files = sys.argv[1:]

    if len(files) > 50:
        print(f'ERROR: Too many files ({len(files)}). Maximum is 50.')
        input('Press Enter to exit...')
        sys.exit(1)

    print(f'Processing {len(files)} file(s)...\n')

    success_count = 0
    fail_count = 0

    for image_path in files:
        if not os.path.isfile(image_path):
            print(f'SKIP: File not found: {image_path}')
            fail_count += 1
            continue

        if create_folder_icon(image_path):
            success_count += 1
        else:
            fail_count += 1

    print(f'\nDone: {success_count} created, {fail_count} failed')
    input('Press Enter to exit...')
