"""Restructure board JSONs into hierarchical folders."""
import json, shutil
from pathlib import Path

root = Path(r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards")
dest = Path(r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\NEW BOARD STRUCTURE")

# Load all boards
boards = {}
for f in root.rglob("*.json"):
    try:
        data = json.loads(f.read_text(encoding="utf-8"))
        bid = data.get("id", "")
        if bid:
            boards[bid] = data
            boards[bid]["_src"] = str(f)
    except:
        pass

# Also handle duplicate A-Z sign file
seen_ids = set()
for bid in list(boards.keys()):
    if bid in seen_ids:
        del boards[bid]
    else:
        seen_ids.add(bid)

# Build parent->children map
children = {}
for bid, b in boards.items():
    pid = b.get("parentBoardId", "")
    if pid:
        children.setdefault(pid, []).append(bid)


def place(board_id, dest_area, depth=0):
    b = boards.get(board_id)
    if not b:
        return
    name = b["name"]
    safe_name = name.replace("/", "-").replace("\\", "-")

    folder = dest_area / safe_name
    folder.mkdir(parents=True, exist_ok=True)

    src = Path(b["_src"])
    shutil.copy2(src, folder / src.name)
    indent = "  " * depth
    print(f"{indent}{name} -> {folder.relative_to(dest) / src.name}")

    for child_id in sorted(children.get(board_id, []), key=lambda x: boards[x]["name"]):
        place(child_id, folder, depth + 1)


for area_name in sorted(set(b.get("area", "?") for b in boards.values())):
    dest_area = dest / area_name
    dest_area.mkdir(parents=True, exist_ok=True)

    tier1 = []
    for bid, b in boards.items():
        if b.get("area") != area_name:
            continue
        pid = b.get("parentBoardId", "")
        tier = b.get("tier", 1)
        if tier == 1 and not pid:
            tier1.append(bid)

    print(f"\n=== {area_name} ===")
    for bid in sorted(tier1, key=lambda x: boards[x]["name"]):
        place(bid, dest_area)

print("\nDone!")
