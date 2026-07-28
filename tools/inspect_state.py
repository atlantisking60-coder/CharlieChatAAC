from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
BOARDS = ROOT / 'lib' / 'data' / 'boards'
for p in sorted(BOARDS.rglob('*')):
    if 'Halloween' in str(p) or 'Religion' in str(p) or '1940 Pinocchio' in str(p):
        print(p.relative_to(BOARDS))
