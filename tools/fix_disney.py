import json
import re
from pathlib import Path

ROOT = Path('lib/data/boards/Legends/Disney Stories')
DISNEY_JSON = ROOT / 'prebuilt_disney_stories.json'
ICON_DIR = Path('assets/symbols/BOARDS/English/Characters')

def load_json(p):
    with open(p, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(p, data):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def slugify(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text

# Load all available icon file paths
icon_files = {}
icon_norm = {}
if ICON_DIR.exists():
    for f in ICON_DIR.iterdir():
        if f.is_file() and f.suffix.lower() == '.png':
            name = f.stem
            icon_files[name] = f"assets/symbols/BOARDS/English/Characters/{name}.png"
            norm = re.sub(r"[^a-z0-9]", "", name.lower())
            icon_norm.setdefault(norm, icon_files[name])

def find_icon(label):
    # Exact match
    if label in icon_files:
        return icon_files[label]
    # Normalize label and try again
    norm = re.sub(r"[^a-z0-9]", "", label.lower())
    if norm in icon_norm:
        return icon_norm[norm]
    # Remove spaces and ampersands etc
    return None

def json_file_for_folder(folder):
    expected = "prebuilt_" + slugify(folder.name) + ".json"
    for f in folder.iterdir():
        if f.is_file() and f.suffix == '.json':
            return f
    # Some existing folders may have a different filename; look for any prebuilt_*.json
    for f in folder.iterdir():
        if f.is_file() and f.name.startswith('prebuilt_') and f.suffix == '.json':
            return f
    return folder / expected

def tile_label_from_folder(folder):
    name = folder.name
    if name == "Mickey & Friends":
        return name
    m = re.match(r"^(\d{4})\s+(.+)$", name)
    if m:
        return m.group(2)
    return name

def tile_id_from_board(board_id):
    # prebuilt_1937_snow_white_... -> prebuilt_disney_stories_snow_white_... (drop year)
    suffix = board_id
    if suffix.startswith('prebuilt_'):
        suffix = suffix[len('prebuilt_'):]
    suffix = re.sub(r"^\d{4}_", "", suffix, count=1)
    return f"prebuilt_disney_stories_{suffix}"

def sort_key(folder):
    name = folder.name
    if name == "Mickey & Friends":
        return (0, 0, "")
    m = re.match(r"^(\d{4})\s+(.+)$", name)
    if m:
        return (1, int(m.group(1)), m.group(2).lower())
    return (1, 9999, name.lower())

# Load Disney board
disney = load_json(DISNEY_JSON)

# Find sub-board folders
folders = [p for p in ROOT.iterdir() if p.is_dir()]
folders.sort(key=sort_key)

# Create missing board JSON for 2001 Monsters, Inc (empty folder) if needed
for folder in folders:
    if folder.name == '2001 Monsters, Inc':
        json_file = json_file_for_folder(folder)
        if not json_file.exists():
            board_data = {
                "id": "prebuilt_2001_monsters_inc",
                "name": "2001 Monsters, Inc",
                "area": "Legends",
                "columns": 5,
                "backgroundColor": "transparent",
                "adjustableLayout": False,
                "isSubBoard": True,
                "isTertiaryBoard": False,
                "isQuaternaryBoard": False,
                "isQuinaryBoard": False,
                "sortOrder": 0,
                "tier": 2,
                "boxScale": 1,
                "tileHeight": 100,
                "tileWidth": 100,
                "layout": {"rows": 1, "blankTilesAdded": 0},
                "tiles": [],
                "parentBoardId": "prebuilt_disney_stories"
            }
            save_json(json_file, board_data)
            print(f"Created missing board JSON: {json_file}")

# Rebuild order and update each sub-board
tiles = []
columns = disney.get('columns', 5)

for i, folder in enumerate(folders):
    json_file = json_file_for_folder(folder)
    if not json_file.exists():
        print(f"Warning: no JSON for {folder.name}, skipping")
        continue
    board_data = load_json(json_file)
    board_id = board_data.get('id')
    board_data['sortOrder'] = (i + 1) * 10
    board_data['isSubBoard'] = True
    board_data['isTertiaryBoard'] = False
    board_data['isQuaternaryBoard'] = False
    board_data['isQuinaryBoard'] = False
    board_data['tier'] = 2
    board_data['parentBoardId'] = "prebuilt_disney_stories"
    save_json(json_file, board_data)

    label = tile_label_from_folder(folder)
    icon = find_icon(label)
    tile = {
        "id": tile_id_from_board(board_id),
        "type": "board_link",
        "label": label,
        "category": "Characters",
        "image": icon,
        "emoji": "",
        "linkedBoardName": board_id,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": ""
    }
    tiles.append(tile)

# Update Disney board
disney['tiles'] = tiles
disney['layout'] = {"rows": (len(tiles) + columns - 1) // columns, "blankTilesAdded": 0}
disney['adjustableLayout'] = True
save_json(DISNEY_JSON, disney)
print(f"Updated {DISNEY_JSON} with {len(tiles)} tiles")
