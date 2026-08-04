import json
import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def slugify(name):
    s = name.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s)
    s = s.strip("_")
    return s or "board"


def fix_name(name):
    name = name.replace("_", " ")
    return " ".join(w.capitalize() for w in name.split())


def insert_before(path, marker, text):
    content = path.read_text(encoding="utf-8")
    idx = content.rfind(marker)
    if idx == -1:
        print(f"  WARNING: could not find '{marker}' in {path}")
        return False
    new_content = content[:idx] + text + content[idx:]
    path.write_text(new_content, encoding="utf-8")
    return True


def main():
    dropped = Path(sys.argv[1])
    word_list = None

    if dropped.is_dir():
        folder = dropped
    elif dropped.is_file() and dropped.suffix.lower() == ".txt":
        folder = dropped.parent
        word_list = [
            line.strip()
            for line in dropped.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.strip().startswith("#")
        ]
    else:
        print("Please drop a folder of pictures or a .txt word list.")
        input("Press Enter to exit.")
        return

    print()
    print("=" * 40)
    print("  Charlie Chat - Build Board from Pictures")
    print("=" * 40)
    print()

    name = input("Enter the name of the board: ").strip()
    if not name:
        print("Aborted - board name cannot be empty.")
        input("Press Enter to exit.")
        return

    board_id = "prebuilt_" + slugify(name)
    board_name = fix_name(name)

    exts = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
    image_files = {
        slugify(f.stem): f
        for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() in exts
    }

    if word_list is not None:
        items = [(word, image_files.get(slugify(word))) for word in word_list]
    else:
        files = sorted(image_files.values())
        items = [(f.stem, f) for f in files]

    if not items:
        print("Nothing to build.")
        input("Press Enter to exit.")
        return

    tiles = []
    for i, (word, img) in enumerate(items):
        try:
            rel = os.path.relpath(img, PROJECT_ROOT).replace("\\", "/") if img else None
        except ValueError:
            rel = img.name if img else None
        tiles.append({
            "id": f"{board_id}_tile_{i + 1}",
            "type": "image",
            "label": word,
            "category": board_name,
            "image": rel,
            "emoji": "",
            "linkedBoardName": None,
            "isFullScreenImage": False,
            "bgColor": "transparent",
            "textColor": "#000000",
            "tileSize": 1,
            "colSpan": 1,
            "rowSpan": 1,
            "customVoice": ""
        })

    cols = 5
    rows = max(1, (len(tiles) + cols - 1) // cols)

    board = {
        "id": board_id,
        "name": board_name,
        "area": "Custom",
        "columns": cols,
        "backgroundColor": "transparent",
        "adjustableLayout": False,
        "isSubBoard": False,
        "isTertiaryBoard": False,
        "isQuaternaryBoard": False,
        "isQuinaryBoard": False,
        "sortOrder": 0,
        "tier": 1,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {"rows": rows, "blankTilesAdded": 0},
        "tiles": tiles
    }

    draft_path = folder / f"{board_id}.json"
    with open(draft_path, "w", encoding="utf-8") as fh:
        json.dump(board, fh, indent=2)

    print(f"\nDraft JSON created: {draft_path}")
    print(f"Tiles: {len(tiles)}")
    print("\nMove/copy the JSON to its final location under lib\\data\\boards\\...")

    final_loc = input("\nEnter the full path to the saved JSON file: ").strip().strip('"')
    final_path = Path(final_loc)
    if not final_path.exists():
        print(f"File not found: {final_path}")
        input("Press Enter to exit.")
        return

    with open(final_path, "r", encoding="utf-8") as fh:
        final_board = json.load(fh)

    board_id = final_board.get("id") or board_id
    board_name = final_board.get("name") or board_name

    parts = final_path.parts
    area = "Custom"
    parent = None
    try:
        data_idx = parts.index("lib")
        if (
            parts[data_idx + 1] == "data"
            and parts[data_idx + 2] == "boards"
            and len(parts) > data_idx + 4
        ):
            area = parts[data_idx + 3]
            if len(parts) > data_idx + 5:
                parent = fix_name(parts[-2])
    except ValueError:
        pass

    final_board["area"] = area
    final_board["isSubBoard"] = parent is not None
    if parent:
        final_board["tier"] = 2
    with open(final_path, "w", encoding="utf-8") as fh:
        json.dump(final_board, fh, indent=2)

    hierarchy_path = PROJECT_ROOT / "lib" / "data" / "board_hierarchy.dart"
    if parent:
        h_entry = f"  BoardHierarchyEntry('{board_name}', '{area}', '{parent}'),\n"
    else:
        h_entry = f"  BoardHierarchyEntry('{board_name}', '{area}'),\n"
    h_ok = insert_before(hierarchy_path, "];", h_entry)

    index_path = PROJECT_ROOT / "lib" / "data" / "board_index.dart"
    parent_id = f"prebuilt_{slugify(parent)}" if parent else "null"
    is_sub = "true" if parent else "false"
    tier = "2" if parent else "1"
    i_entry = f"""  BoardIndexEntry(
    id: '{board_id}',
    name: '{board_name}',
    area: '{area}',
    parentBoardId: {parent_id},
    isSubBoard: {is_sub},
    isTertiaryBoard: false,
    isQuaternaryBoard: false,
    isQuinaryBoard: false,
    sortOrder: 0,
    tier: {tier},
  ),
"""
    i_ok = insert_before(index_path, "];", i_entry)

    print()
    if h_ok:
        print(f"  Updated {hierarchy_path}")
    if i_ok:
        print(f"  Updated {index_path}")
    print("  Board is now findable.")
    input("\nPress Enter to close.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nERROR: {e}")
        input("Press Enter to exit.")
