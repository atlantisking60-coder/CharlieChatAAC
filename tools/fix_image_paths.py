import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'assets'
BOARDS = ROOT / 'lib' / 'data' / 'boards'

# Index every image under assets/ by lower-case filename.
image_index = {}
for p in ASSETS.rglob('*'):
    if p.is_file() and p.suffix.lower() in {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.bmp'}:
        key = p.name.lower()
        rel = p.relative_to(ASSETS).as_posix()
        image_index.setdefault(key, []).append(rel)


def find_best_match(filename, canonical_dir, original_rel):
    filename = filename.lower()
    matches = image_index.get(filename, [])
    if not matches:
        return None

    # 1. If the image was written as assets/symbols/<rest>, try assets/<rest>
    if original_rel.startswith('symbols/'):
        stripped = original_rel[len('symbols/'):]
        if (ASSETS / stripped).is_file():
            return stripped

    # 2. Prefer the canonical asset directory for this board's location
    if canonical_dir:
        for m in matches:
            if m.startswith(canonical_dir + '/'):
                return m

        # 3. Prefer a match inside the board's area
        area = canonical_dir.split('/')[0]
        for m in matches:
            if m.lower().startswith(area.lower() + '/') and m.lower().endswith('/' + filename):
                return m

    # 4. Fall back to the only / first match found
    return matches[0]


def process_json_file(json_path):
    try:
        data = json.loads(json_path.read_text(encoding='utf-8'))
    except Exception:
        return 0

    if not isinstance(data, dict) or not isinstance(data.get('tiles'), list):
        return 0

    # Work out the canonical asset directory from the file's location
    canonical = None
    try:
        canonical = json_path.parent.relative_to(BOARDS).as_posix()
    except ValueError:
        try:
            canonical = json_path.parent.relative_to(ASSETS).as_posix()
        except ValueError:
            pass

    changed = 0
    for tile in data['tiles']:
        img = tile.get('image', '')
        if not img or not isinstance(img, str) or not img.startswith('assets/'):
            continue

        rel = img[len('assets/'):]  # e.g. symbols/Common/Movement/crawl.png
        target = ASSETS / rel
        if target.is_file():
            continue  # path already resolves

        filename = img.split('/')[-1]
        new_rel = find_best_match(filename, canonical, rel)
        if new_rel and new_rel != rel:
            tile['image'] = 'assets/' + new_rel
            changed += 1

    if changed:
        json_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + os.linesep,
            encoding='utf-8',
        )
        print(f'Fixed {changed} image(s) in {json_path}')
    return changed


def main():
    changed_total = 0
    for f in sorted(BOARDS.rglob('*.json')):
        changed_total += process_json_file(f)
    for f in sorted(ASSETS.rglob('*.json')):
        changed_total += process_json_file(f)
    print(f'Total images fixed: {changed_total}')


if __name__ == '__main__':
    main()
