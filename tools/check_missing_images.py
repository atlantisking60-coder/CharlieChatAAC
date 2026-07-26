import json
import os
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

PROJECT_ROOT = Path(r'C:\Users\Craig\Downloads\Charlie Chat')
BOARDS_DIR = PROJECT_ROOT / 'lib' / 'data' / 'boards'

missing = []
for board_file in BOARDS_DIR.rglob('*.json'):
    with open(board_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for tile in data.get('tiles', []):
        if tile.get('type') == 'blank' or not tile.get('label'):
            continue
        image = tile.get('image')
        if not image:
            missing.append((board_file.name, tile.get('label', ''), 'no image'))
        elif not (PROJECT_ROOT / image).exists():
            missing.append((board_file.name, tile.get('label', ''), 'missing file'))

print(f"Missing images: {len(missing)}")
for board, label, reason in missing[:50]:
    print(f"  {board}: {label} ({reason})")
if len(missing) > 50:
    print(f"  ... and {len(missing) - 50} more")
