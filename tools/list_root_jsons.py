from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT / 'lib' / 'data' / 'boards'
for area_dir in sorted(BOARDS_DIR.iterdir()):
    if not area_dir.is_dir():
        continue
    for f in sorted(area_dir.iterdir()):
        if f.is_file() and f.suffix == '.json':
            print(f)
