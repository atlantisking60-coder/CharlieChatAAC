"""Populate empty Montessori sub-boards from .txt word lists + PNG images."""
import json
import os
import re
from pathlib import Path

ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
MONTESORI = ROOT / "assets" / "Common" / "Small Words" / "Montessori"
BOARDS = ROOT / "lib" / "data" / "boards" / "Common" / "Small Words"

# Same spec as generate_montessori_boards.py
BOARD_SPEC = [
    ("Noun", "Nouns", 1),
    ("Proper Noun", "Proper Nouns", 2),
    ("Abstract Noun", "Abstract Nouns", 3),
    ("Collective Noun", "Collective Nouns", 4),
    ("Article", "Articles", 5),
    ("Pronoun", "Pronouns", 6),
    ("Adjective", "Adjectives", 7),
    (None, "Verbs", 8, ["Transitive Verb", "Intransitive Verb", "Linking Verb", "Auxiliary Verb"]),
    ("Transitive Verb", "Transitive Verbs", 9),
    ("Intransitive Verb", "Intransitive Verbs", 10),
    ("Linking Verb", "Linking Verbs", 11),
    ("Auxiliary Verb", "Auxiliary Verbs", 12),
    ("Adverb", "Adverbs", 13),
    ("Preposition", "Prepositions", 14),
    ("Conjunction", "Conjunctions", 15),
    ("Interjection", "Interjections", 16),
    ("Gerund", "Gerunds", 17),
    ("Participle", "Participles", 18),
    ("Other", "Others", 19),
]

def to_id(name):
    return "prebuilt_" + re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_") + "_montessori"

def to_snake(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")

def read_words(folder):
    txt = MONTESORI / f"{folder}.txt"
    if txt.exists():
        with open(txt, "r", encoding="utf-8") as f:
            return [line.strip() for line in f if line.strip()]
    return []

def build_board(folder, display_name, sort_order, sources=None):
    if sources:
        words = []
        seen = set()
        for src in sources:
            for w in read_words(src):
                w = w.strip().lower()
                if w and w not in seen:
                    seen.add(w)
                    words.append((w, src))
    else:
        raw = read_words(folder)
        words = [(w, folder) for w in raw]

    board_id = to_id(display_name)
    columns = 5
    rows = (len(words) + columns - 1) // columns
    if rows == 0:
        rows = 1

    tiles = []
    for i, (word, img_folder) in enumerate(words, start=1):
        word_lower = word.lower().strip()
        img_path = f"assets/Common/Small Words/Montessori/{img_folder}/{word_lower}.png"
        tiles.append({
            "id": f"{board_id}_{word_lower}",
            "type": "vocabulary",
            "label": word_lower,
            "category": "Custom",
            "imageAsset": img_path,
            "emoji": "",
            "isBoardLink": False,
            "linkedBoardId": "",
            "linkedBoardName": "",
            "isFullScreenImage": False,
            "bgColor": "transparent",
            "textColor": "#000000",
            "tileSize": 1,
            "colSpan": 1,
            "rowSpan": 1,
            "customVoice": ""
        })

    board = {
        "id": board_id,
        "name": display_name,
        "area": "Common",
        "columns": columns,
        "backgroundColor": "transparent",
        "adjustableLayout": False,
        "isSubBoard": True,
        "isTertiaryBoard": False,
        "isQuaternaryBoard": False,
        "isQuinaryBoard": False,
        "sortOrder": sort_order,
        "tier": 2,
        "parentBoardId": "prebuilt_small_words",
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {
            "rows": rows,
            "blankTilesAdded": 0
        },
        "tiles": tiles
    }

    out_dir = BOARDS / f"{display_name} (Montessori)"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{board_id}.json"
    
    return board, out_file, len(tiles)

def main():
    for spec in BOARD_SPEC:
        folder, display, sort, *rest = spec
        sources = rest[0] if rest else None
        board, out_file, tile_count = build_board(folder, display, sort, sources)
        
        existing = None
        if out_file.exists():
            with open(out_file, "r", encoding="utf-8") as f:
                existing = json.load(f)
            existing_tiles = len(existing.get("tiles", []))
            if existing_tiles > 0:
                print(f"Skipping {out_file.name} (already has {existing_tiles} tiles)")
                continue
            # Preserve extra fields
            for k, v in existing.items():
                if k not in board and k != "tiles":
                    board[k] = v
        
        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(board, f, indent=2)
        print(f"Wrote {out_file.name} ({tile_count} tiles)")

if __name__ == "__main__":
    main()
