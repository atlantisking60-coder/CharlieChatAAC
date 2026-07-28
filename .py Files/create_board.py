"""Charlie Chat - Board Creator
Double-click the accompanying CREATE BOARD.bat to run this.
"""
import json, re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent


def normalize_image_path(raw):
    """Strip anything before 'assets/' and ensure forward slashes."""
    raw = raw.replace("\\", "/")
    idx = raw.lower().find("assets/")
    if idx >= 0:
        raw = raw[idx:]
    return raw


def main():
    print()
    print("=" * 40)
    print("  Charlie Chat - Board Creator")
    print("=" * 40)
    print()

    # 1. Area
    print("Available areas:")
    print("  1. Common")
    print("  2. Sign")
    print("  3. Subject Vocab")
    print("  4. My School")
    print("  5. Personal")
    areas = ["Common", "Sign", "Subject Vocab", "My School", "Personal"]
    area_idx = input("Choose area [1-5]: ").strip()
    try:
        area_idx = int(area_idx)
    except ValueError:
        area_idx = 1
    if area_idx < 1 or area_idx > 5:
        area_idx = 1
    area = areas[area_idx - 1]
    print(f"  -> {area}")

    # 2. Board name
    print()
    name = input("Board name: ").strip()
    if not name:
        print("Aborted - name cannot be empty.")
        input("Press Enter to exit.")
        return

    board_id = "prebuilt_" + re.sub(r"[^a-z0-9]+", "_", name.lower()).rstrip("_")
    category = " ".join(w.capitalize() for w in name.split())

    # 1b. Folder path within area
    print()
    print("Where should this board sit in the folder hierarchy?")
    print("Type the path using / as separator.")
    print("Examples:")
    print("  Feelings              -> boards/Common/Feelings/")
    print("  Feelings/Sad          -> boards/Common/Feelings/Sad/")
    print("  Animals/Mammals       -> boards/Common/Animals/Mammals/")
    print("  (blank)               -> boards/Common/")
    folder_path = input("Folder path: ").strip().strip("/")
    if folder_path:
        folder_path = folder_path.replace("\\", "/")
        print(f"  -> {area}/{folder_path}/")
    else:
        print(f"  -> {area}/")

    # 3. Words
    print()
    print("Enter your word list (one word per line).")
    print("Press Enter on an empty line when done.")
    words = []
    while True:
        line = input("  ").strip()
        if not line:
            if words:
                break
            continue
        words.append(line)
    print(f"  -> {len(words)} words entered.")

    # 4. Asset folders
    print()
    print("Enter asset folder paths where the images live.")
    print("One path per line. Press Enter on empty line when done.")
    print("Example: assets/symbols/1. Main Boards/Common")
    asset_folders = []
    while True:
        line = input("  ").strip()
        if not line:
            if asset_folders:
                break
            continue
        asset_folders.append(normalize_image_path(line))
    if not asset_folders:
        print("  No asset folders set - images will be left blank.")

    # 5. Confirm
    print()
    print("-" * 40)
    print(f"  Board:   {name}")
    print(f"  Area:    {area}")
    if folder_path:
        print(f"  Path:    {area}/{folder_path}/")
    print(f"  Words:   {len(words)}")
    print("-" * 40)
    print()
    confirm = input("Save? (y/n) [y]: ").strip().lower()
    if confirm == "n":
        print("Aborted.")
        input("Press Enter to exit.")
        return

    # Build tiles
    tiles = []
    for i, word in enumerate(words):
        image = None
        if asset_folders:
            for folder in asset_folders:
                candidate = f"{folder}/{word}.png"
                if (SCRIPT_DIR / candidate).exists():
                    image = candidate
                    break
            if image is None:
                image = f"{asset_folders[0]}/{word}.png"

        tiles.append({
            "id": word,
            "type": "vocabulary",
            "label": word,
            "category": category,
            "image": image,
            "emoji": "",
            "linkedBoardName": None,
            "isFullScreenImage": False,
            "bgColor": "transparent",
            "textColor": "#000000",
            "tileSize": 1,
            "colSpan": 1,
            "rowSpan": 1,
            "customVoice": "",
        })

    # Build board
    board = {
        "id": board_id,
        "name": name,
        "area": area,
        "columns": 5,
        "backgroundColor": "transparent",
        "adjustableLayout": True,
        "isSubBoard": False,
        "isTertiaryBoard": False,
        "sortOrder": 0,
        "tier": 1,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {"rows": 6, "blankTilesAdded": 0},
        "tiles": tiles,
    }

    # Save
    if folder_path:
        save_dir = SCRIPT_DIR / "lib" / "data" / "boards" / area / folder_path
    else:
        save_dir = SCRIPT_DIR / "lib" / "data" / "boards" / area
    save_dir.mkdir(parents=True, exist_ok=True)
    save_path = save_dir / f"{board_id}.json"
    json_str = json.dumps(board, indent=2)
    save_path.write_text(json_str, encoding="utf-8")
    print()
    print(f"  Saved: {save_path}")

    print()
    print("=" * 40)
    print("  Done!")
    print("=" * 40)
    print()
    print("Next steps:")
    print("  1. Run Web Live Preview or desktop app")
    print(f"  2. Board appears in the {area} area")
    print("  3. Use Board Editor to tweak images/layout")
    print()
    input("Press Enter to exit.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nERROR: {e}")
        input("Press Enter to exit.")
