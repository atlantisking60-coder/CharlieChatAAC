#!/usr/bin/env python3
"""Fix JSON metadata and asset paths for Animations (Not Disney) boards."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARD_DIR = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Animations (Not Disney)"
PARENT_ID = "prebuilt_not_disney_animations"

REPLACEMENTS = {
    "assets/Legends/Not Disney Animations/": "assets/Legends/Animations (Not Disney)/",
    "assets/BOARDS/Legends/Characters/Non-Disney Animations/": "assets/BOARDS/Legends/Characters/Animations (Not Disney)/",
}


def fix_path(value):
    if not isinstance(value, str):
        return value
    for old, new in REPLACEMENTS.items():
        if old in value:
            return value.replace(old, new)
    return value


def process_json(path: Path):
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            data = json.load(f)
    except Exception as e:
        print(f"  ERROR reading {path}: {e}")
        return

    changed = False

    # Ensure correct parent for sub-boards
    if data.get("id") != PARENT_ID:
        if data.get("parentBoardId") != PARENT_ID:
            data["parentBoardId"] = PARENT_ID
            changed = True

    # Update asset paths at top level
    for key in ("iconAssetPath", "tileIconAssetPath"):
        if key in data:
            new_val = fix_path(data[key])
            if new_val != data[key]:
                data[key] = new_val
                changed = True

    # Update tile imageAsset paths
    if "tiles" in data:
        for tile in data["tiles"]:
            if "imageAsset" in tile:
                new_val = fix_path(tile["imageAsset"])
                if new_val != tile["imageAsset"]:
                    tile["imageAsset"] = new_val
                    changed = True

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"UPDATED: {path.relative_to(PROJECT_ROOT)}")


def main():
    for path in BOARD_DIR.rglob("*.json"):
        process_json(path)


if __name__ == "__main__":
    main()
