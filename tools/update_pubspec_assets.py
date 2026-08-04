import os
from pathlib import Path

# project root is two levels up from this script
root = Path(__file__).resolve().parent.parent
pubspec = root / "pubspec.yaml"

def collect_dirs(base):
    """Recursively collect all directory paths under base, skipping broken/locked ones."""
    dirs = []
    for dirpath, dirnames, _ in os.walk(base, onerror=lambda e: None):
        rel = os.path.relpath(dirpath, root).replace("\\", "/") + "/"
        dirs.append(rel)
        for d in dirnames:
            d_full = os.path.join(dirpath, d)
            d_rel = os.path.relpath(d_full, root).replace("\\", "/") + "/"
            dirs.append(d_rel)
    return dirs

dirs = []

# All asset directories
assets_dir = root / "assets"
if assets_dir.exists():
    dirs.extend(collect_dirs(assets_dir))

# All board JSON directories
boards_dir = root / "lib/data/boards"
if boards_dir.exists():
    dirs.extend(collect_dirs(boards_dir))

# Sort, remove duplicates, and exclude paths with URI fragment/query characters
BAD_DIRS = {
    "lib/data/boards/Subject Vocab/",
    "lib/data/boards/Subject Vocab/E.P.I.C/",
    "lib/data/boards/Subject Vocab/E.P.I.C./",
    "lib/data/boards/Subject Vocab/P.D/",
    "lib/data/boards/Subject Vocab/P.D./",
}
unique_dirs = sorted({d for d in set(dirs) if '#' not in d and '?' not in d and d not in BAD_DIRS})

# Read pubspec.yaml up to and including the `assets:` line
with open(pubspec, "r", encoding="utf-8") as f:
    lines = f.readlines()

before = []
in_assets = False
for line in lines:
    if in_assets:
        continue
    before.append(line.rstrip("\n"))
    if line.strip().startswith("assets:"):
        in_assets = True
        break

# If no assets: section found, keep all lines and just append
if not in_assets:
    before = [l.rstrip("\n") for l in lines]

new_lines = before + [f'    - "{d}"' for d in unique_dirs]

with open(pubspec, "w", encoding="utf-8") as f:
    f.write("\n".join(new_lines) + "\n")

print(f"Updated {pubspec} with {len(unique_dirs)} asset directories")
