#!/usr/bin/env python3
"""Merge board JSONs from the old 'Not Disney Animations' folder into
'Animations (Not Disney)', keeping the version with more populated tiles when
both exist. The old folder is removed afterwards if empty.
"""

import json
import shutil
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
WRONG = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Not Disney Animations"
RIGHT = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Animations (Not Disney)"


def read_json(path: Path) -> dict | None:
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except Exception as e:
        print(f"  ERROR reading {path}: {e}")
        return None


def tile_count(data: dict | None) -> int:
    if not data:
        return 0
    return sum(
        1
        for t in data.get("tiles", [])
        if (t.get("label") or "").strip()
        or (t.get("imageAsset") or "").strip()
        or (t.get("emoji") or "").strip()
    )


def find_in_right(filename: str) -> Path | None:
    matches = list(RIGHT.rglob(filename))
    return matches[0] if matches else None


def main():
    if not WRONG.exists():
        print(f"Nothing to do: {WRONG} does not exist")
        return

    moved = []
    kept_right = []
    kept_wrong_removed = []
    skipped = []

    for src in WRONG.rglob("*.json"):
        filename = src.name
        rel = src.relative_to(WRONG)
        # The parent board goes directly into RIGHT
        if filename == "prebuilt_not_disney_animations.json":
            dest = RIGHT / filename
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
            src.unlink()
            print(f"PARENT MOVED: {rel} -> {dest.relative_to(PROJECT_ROOT)}")
            moved.append(str(rel))
            continue

        # Sub-board: place in RIGHT/<Board Name>/filename
        data = read_json(src)
        if data is None:
            skipped.append(str(rel))
            continue

        board_name = data.get("name", filename.replace("prebuilt_", "").replace(".json", ""))
        dest_dir = RIGHT / board_name
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / filename

        if dest.exists():
            right_data = read_json(dest)
            left_tiles = tile_count(data)
            right_tiles = tile_count(right_data)
            if left_tiles >= right_tiles:
                shutil.copy2(src, dest)
                print(f"MERGED (kept left, {left_tiles} >= {right_tiles} tiles): {rel}")
                moved.append(str(rel))
            else:
                print(f"MERGED (kept right, {right_tiles} > {left_tiles} tiles): {rel}")
                kept_right.append(str(rel))
            src.unlink()
        else:
            shutil.move(str(src), str(dest))
            print(f"MOVED: {rel} -> {dest.relative_to(PROJECT_ROOT)}")
            moved.append(str(rel))

    # Remove empty directories in WRONG bottom-up
    removed_dirs = []
    if WRONG.exists():
        for dir_path in sorted(WRONG.rglob("*"), reverse=True):
            if dir_path.is_dir() and not any(dir_path.iterdir()):
                dir_path.rmdir()
                removed_dirs.append(dir_path.relative_to(PROJECT_ROOT))
        if not any(WRONG.iterdir()):
            WRONG.rmdir()
            removed_dirs.append(WRONG.relative_to(PROJECT_ROOT))

    print("\n--- Summary ---")
    print(f"Moved / merged: {len(moved)}")
    print(f"Kept right-side version: {len(kept_right)}")
    print(f"Skipped: {len(skipped)}")
    print(f"Removed dirs: {len(removed_dirs)}")


if __name__ == "__main__":
    main()
