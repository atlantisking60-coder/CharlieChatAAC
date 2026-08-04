#!/usr/bin/env python3
"""Generate Montessori sub-board JSONs under lib/data/boards/Common/Small Words."""

import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MONTESORI = ROOT / "assets" / "Common" / "Small Words" / "Montessori"
BOARDS = ROOT / "lib" / "data" / "boards" / "Common" / "Small Words"

BOARD_SPEC = [
    # (asset folder, display name, sort order, [extra source folders for combined lists])
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


def ensure_dir(path):
    path.mkdir(parents=True, exist_ok=True)
    return path


def build_board(folder, display_name, sort_order, sources=None):
    if sources:
        # Combined board (e.g. Verbs): collect (word, source_folder) tuples
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

    snake = to_snake(display_name)
    board_id = to_id(display_name)

    columns = 5
    rows = (len(words) + columns - 1) // columns
    if rows == 0:
        rows = 1

    tiles = []
    for i, (word, img_folder) in enumerate(words, start=1):
        img_path = f"assets/Common/Small Words/Montessori/{img_folder}/{word}.png"
        tiles.append({
            "id": f"{board_id}_tile_{i}",
            "type": "image",
            "label": word,
            "category": display_name.replace(" (Montessori)", "").rstrip("s"),
            "image": img_path,
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
    ensure_dir(out_dir)
    out_file = out_dir / f"{board_id}.json"
    if out_file.exists():
        print(f"Skipping {out_file} (already exists)")
        return board_id, display_name
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(board, f, indent=2)
    print(f"Wrote {out_file} ({len(tiles)} tiles)")
    return board_id, display_name


def build_small_words(links):
    columns = 7
    rows = 3
    tiles = []
    for i, (bid, label) in enumerate(links, start=1):
        tiles.append({
            "id": f"prebuilt_small_words_tile_{i}",
            "type": "board_link",
            "label": label,
            "category": "Small Words",
            "image": None,
            "emoji": "",
            "isBoardLink": True,
            "linkedBoardId": bid,
            "linkedBoardName": label,
            "isFullScreenImage": False,
            "bgColor": "transparent",
            "textColor": "#000000",
            "tileSize": 1,
            "colSpan": 1,
            "rowSpan": 1,
            "customVoice": ""
        })
    # Fill remaining cells with blanks
    for i in range(len(tiles), rows * columns):
        tiles.append({
            "id": f"prebuilt_small_words_blank_{i - len(tiles) + 1}",
            "type": "blank",
            "label": "",
            "category": "Small Words",
            "image": None,
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

    board = {
        "id": "prebuilt_small_words",
        "name": "Small Words",
        "area": "Common",
        "columns": columns,
        "backgroundColor": "transparent",
        "adjustableLayout": False,
        "isSubBoard": False,
        "isTertiaryBoard": False,
        "isQuaternaryBoard": False,
        "isQuinaryBoard": False,
        "sortOrder": 2,
        "tier": 1,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {
            "rows": rows,
            "blankTilesAdded": 0
        },
        "tiles": tiles
    }
    out_file = BOARDS / "prebuilt_small_words.json"
    if out_file.exists():
        try:
            with open(out_file, "r", encoding="utf-8") as f:
                existing = f.read()
            if "prebuilt_nouns_montessori" in existing:
                print(f"Skipping {out_file} (Montessori links already present)")
                return
        except Exception:
            pass
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(board, f, indent=2)
    print(f"Wrote {out_file} ({len(tiles)} tiles)")


def main():
    links = []
    for spec in BOARD_SPEC:
        folder, display, sort, *rest = spec
        sources = rest[0] if rest else None
        bid, label = build_board(folder, display, sort, sources)
        links.append((bid, label))
    build_small_words(links)


if __name__ == "__main__":
    main()
