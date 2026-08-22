import sys
import os
from PIL import Image

BLANK_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets', 'BOARDS', 'BLANK.png')
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets', 'BOARDS', 'z NEWLY CREATED')

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
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, basename + '.png')
    composite.save(output_path, 'PNG')
    print(f'Created: {output_path}')
    return True

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: Drag an image file onto this script')
        input('Press Enter to exit...')
        sys.exit(1)

    image_path = sys.argv[1]

    if not os.path.isfile(image_path):
        print(f'ERROR: File not found: {image_path}')
        input('Press Enter to exit...')
        sys.exit(1)

    success = create_folder_icon(image_path)
    if success:
        print('Folder icon created successfully!')
    else:
        print('Failed to create folder icon.')
    input('Press Enter to exit...')
