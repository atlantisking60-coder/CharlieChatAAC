#!/usr/bin/env python3
"""Move the specified temp Legends boards to their actual area folders and update metadata."""

import json
import shutil
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_ROOT = PROJECT_ROOT / "lib" / "data" / "boards"
TEMP_DIR = BOARDS_ROOT / "_temp" / "Legends"

# Board filename -> (destination area folder, parent board id)
# The destination folder inside the area uses the board's name.
MOVE_MAP = {
    # Animations (Not Disney)
    "prebuilt_1997_anastasia.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_1999_the_iron_giant.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2000_the_road_to_el_dorado.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2001_shrek.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2002_ice_age.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2007_enchanted.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2010_despicable_me_and_minions.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    "prebuilt_2010_how_to_train_your_dragon.json": ("Legends/Animations (Not Disney)", "prebuilt_not_disney_animations"),
    # Cartoons and Puppets
    "prebuilt_gargoyles.json": ("Legends/Cartoons and Puppets", "prebuilt_cartoons_and_puppets"),
    "prebuilt_sesame_street.json": ("Legends/Cartoons and Puppets", "prebuilt_cartoons_and_puppets"),
}


def main():
    for filename, (area_path, parent_id) in MOVE_MAP.items():
        src = TEMP_DIR / filename
        if not src.exists():
            print(f"SKIP (not found): {src.relative_to(PROJECT_ROOT)}")
            continue

        # Read board metadata to determine folder name
        with open(src, "r", encoding="utf-8-sig") as f:
            data = json.load(f)

        board_name = data.get("name", filename.replace("prebuilt_", "").replace(".json", ""))
        dest_dir = BOARDS_ROOT / area_path / board_name
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / filename

        # Ensure parentBoardId matches the destination
        data["parentBoardId"] = parent_id
        # Keep area as Legends and tier as 2
        data["area"] = "Legends"
        data["tier"] = 2
        data["isSubBoard"] = True

        # Write to destination
        with open(dest, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")

        # Remove source
        src.unlink()
        print(f"MOVED: {src.relative_to(PROJECT_ROOT)} -> {dest.relative_to(PROJECT_ROOT)}")

    # Remove _temp/Legends if empty
    if TEMP_DIR.exists() and not any(TEMP_DIR.iterdir()):
        TEMP_DIR.rmdir()
        print(f"REMOVED EMPTY: {TEMP_DIR.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
