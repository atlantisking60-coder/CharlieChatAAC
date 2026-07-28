import json
import re
import shutil
from pathlib import Path

ROOT = Path('lib/data/boards/Legends')
CHARACTERS_DIR = ROOT / 'Characters'

LEGENDS_CHARACTERS_ORDER = [
    'Gods, Titans, Heroes & Monsters',
    'Heroes & Monsters (Greek & Roman)',
    'Fairy Tale Characters',
    'Disney Stories',
    'D&D',
    'Arthurian Legend',
    'Arabian & Middle Eastern Tales',
    'Asian Legends & Folklore',
    'Horror Icons',
    'Halloween Keywords',
    'Legendary Heroes & Folk Heroes',
    'Literary & Gothic Characters',
    'Religion & Worldviews',
    'Marvel',
    'X-Men',
    'DC',
    'The Muppets',
    'Star Wars',
    'Star Trek',
    'The Lord Of The Rings',
    'Computer Games',
]

def load(p):
    with open(p, 'r', encoding='utf-8') as f:
        return json.load(f)

def save(p, data):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def slugify(name):
    n = name.lower()
    n = ''.join(c if c.isalnum() else '_' for c in n)
    n = re.sub(r"_+", "_", n).strip('_')
    return n

# create Characters directory
CHARACTERS_DIR.mkdir(parents=True, exist_ok=False)

def json_in_folder(folder):
    for f in folder.rglob('*.json'):
        if f.is_file() and f.name.startswith('prebuilt_'):
            return f
    return None

# Move listed folders into Characters and collect child board ids
tiles = []
for i, name in enumerate(LEGENDS_CHARACTERS_ORDER):
    src = ROOT / name
    if not src.exists():
        print(f"WARNING: {src} does not exist, skipping")
        continue
    dst = CHARACTERS_DIR / name
    shutil.move(str(src), str(dst))
    print(f"Moved {name} -> Characters/{name}")

    # Find JSON and update sortOrder/parent
    json_file = json_in_folder(dst)
    if json_file:
        data = load(json_file)
        data['sortOrder'] = (i + 1) * 10
        data['isSubBoard'] = True
        data['isTertiaryBoard'] = False
        data['isQuaternaryBoard'] = False
        data['isQuinaryBoard'] = False
        data['tier'] = 2
        data['parentBoardId'] = 'prebuilt_characters'
        save(json_file, data)
        board_id = data['id']
    else:
        # generate id from name
        board_id = f"prebuilt_{slugify(name)}"
        print(f"WARNING: no JSON found for {name}, using id {board_id}")

    tiles.append({
        "id": f"prebuilt_characters_{slugify(name)}",
        "type": "board_link",
        "label": name,
        "category": "Characters",
        "image": None,
        "emoji": "",
        "linkedBoardName": board_id,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": ""
    })

# Create Characters board JSON
characters_board = {
    "id": "prebuilt_characters",
    "name": "Characters",
    "area": "Legends",
    "columns": 5,
    "backgroundColor": "transparent",
    "adjustableLayout": True,
    "isSubBoard": False,
    "isTertiaryBoard": False,
    "isQuaternaryBoard": False,
    "isQuinaryBoard": False,
    "sortOrder": 10,
    "tier": 1,
    "boxScale": 1,
    "tileHeight": 100,
    "tileWidth": 100,
    "layout": {
        "rows": (len(tiles) + 4) // 5,
        "blankTilesAdded": 0
    },
    "tiles": tiles
}
save(CHARACTERS_DIR / 'prebuilt_characters.json', characters_board)
print(f"Created Characters board with {len(tiles)} tiles")
