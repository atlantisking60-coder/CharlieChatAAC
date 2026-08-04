import json
import os
import re
from pathlib import Path

# Root is two levels up from this script (tools/)
root = Path(__file__).resolve().parent.parent
hierarchy_file = root / "lib" / "data" / "board_hierarchy.dart"
boards_dir = root / "lib" / "data" / "boards"
EMPTY_IMAGE = "assets/Empty Board.png"


def prebuilt_id(name: str) -> str:
    """Mimic Dart prebuiltBoardId()."""
    lower = name.lower()
    if lower == "a-z of sign":
        return "prebuilt_a-z_of_sign"
    normalized = re.sub(r"[^a-z0-9]+", "_", lower).strip("_")
    return f"prebuilt_{normalized}"


def safe_folder_name(name: str) -> str:
    """Make a Windows-safe folder name that matches the existing board folders."""
    # Replace characters that are invalid in Windows directory names
    sanitized = re.sub(r'[\\/*?:"<>|\x00-\x1f]', "_", name)
    # Collapse multiple spaces
    sanitized = re.sub(r" +", " ", sanitized)
    # Remove trailing dots/spaces which Windows rejects
    return sanitized.strip(" .")


entry_pattern = re.compile(
    r"BoardHierarchyEntry\('([^']*)',\s*'([^']*)'(?:,\s*'([^']*)')?\s*\)"
)

entries = []
with open(hierarchy_file, "r", encoding="utf-8") as f:
    for line in f:
        m = entry_pattern.search(line)
        if m:
            name = m.group(1)
            area = m.group(2)
            parent = m.group(3)
            entries.append((name, area, parent))

# Top-level tabs are entries with no parent.
missing = []
created = 0
for name, area, parent in entries:
    if parent is not None:
        continue
    board_id = prebuilt_id(name)
    board_dir = boards_dir / area / safe_folder_name(name)
    json_path = board_dir / f"{board_id}.json"

    if json_path.exists():
        continue

    board_dir.mkdir(parents=True, exist_ok=True)
    relative_path = json_path.relative_to(root)
    missing.append((name, area, board_id, str(relative_path)))

    board_json = {
        "id": board_id,
        "name": name,
        "area": area,
        "columns": 1,
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
        "layout": {"rows": 1, "blankTilesAdded": 0},
        "tiles": [
            {
                "id": f"{board_id}_empty",
                "type": "symbol",
                "label": name,
                "category": "Custom",
                "imageAsset": EMPTY_IMAGE,
                "emoji": "",
                "linkedBoardName": "",
                "isFullScreenImage": False,
                "bgColor": "#000000",
                "textColor": "#FFFFFF",
                "tileSize": 1,
                "colSpan": 1,
                "rowSpan": 1,
                "customVoice": "",
            }
        ],
    }

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(board_json, f, indent=2)
        f.write("\n")
    created += 1

print("Missing top-level tabs (created):")
for name, area, board_id, rel in missing:
    print(f"  - {name!r} ({area}) -> {rel}")
print(f"\nCreated {created} missing board JSON file(s).")
