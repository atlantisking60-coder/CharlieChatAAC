from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
for p in [
    ROOT / 'lib' / 'data' / 'boards' / 'Common' / 'prebuilt_1940_pinocchio.json',
    ROOT / 'lib' / 'data' / 'boards' / 'Subject Vocab' / 'prebuilt_religion_worldviews.json',
]:
    if p.exists():
        p.unlink()
        print('Removed', p)
