#!/usr/bin/env python3
"""Populate each Montessori sub-board JSON with tiles from its asset folder."""
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOARDS = ROOT / "lib" / "data" / "boards" / "Common" / "Small Words"
ASSETS = ROOT / "assets" / "Common" / "Small Words" / "Montessori"

ORDER = [
    "Nouns",
    "Proper Nouns",
    "Abstract Nouns",
    "Collective Nouns",
    "Articles",
    "Pronouns",
    "Adjectives",
    "Verbs",
    "Transitive Verbs",
    "Intransitive Verbs",
    "Linking Verbs",
    "Auxiliary Verbs",
    "Adverbs",
    "Prepositions",
    "Conjunctions",
    "Interjections",
    "Gerunds",
    "Participles",
    "Others",
]

SINGULAR = {
    "Nouns": "Noun",
    "Proper Nouns": "Proper Noun",
    "Abstract Nouns": "Abstract Noun",
    "Collective Nouns": "Collective Noun",
    "Articles": "Article",
    "Pronouns": "Pronoun",
    "Adjectives": "Adjective",
    "Verbs": "Verb",
    "Transitive Verbs": "Transitive Verb",
    "Intransitive Verbs": "Intransitive Verb",
    "Linking Verbs": "Linking Verb",
    "Auxiliary Verbs": "Auxiliary Verb",
    "Adverbs": "Adverb",
    "Prepositions": "Preposition",
    "Conjunctions": "Conjunction",
    "Interjections": "Interjection",
    "Gerunds": "Gerund",
    "Participles": "Participle",
    "Others": "Other",
}


def snake(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower().strip()).strip("_")


def tile_label(filename):
    name = Path(filename).stem
    return name.replace("_", " ").title()


def build_tiles(base, board_id, asset_dir):
    tiles = []
    for f in sorted(asset_dir.iterdir()):
        if not f.is_file() or f.suffix.lower() != ".png":
            continue
        fname = f.name
        tile_id = f"{board_id}_{snake(fname)}"
        tiles.append({
            "id": tile_id,
            "type": "vocabulary",
            "label": tile_label(fname),
            "category": base,
            "imageAsset": f"assets/Common/Small Words/Montessori/{SINGULAR[base]}/{fname}",
            "emoji": "",
            "isBoardLink": False,
            "linkedBoardId": "",
            "linkedBoardName": None,
            "isFullScreenImage": False,
            "bgColor": "transparent",
            "textColor": "#000000",
            "tileSize": 1,
            "colSpan": 1,
            "rowSpan": 1,
            "customVoice": "",
        })
    return tiles


def main():
    for base in ORDER:
        board_name = f"{base} (Montessori)"
        board_id = f"prebuilt_{snake(base)}_montessori"
        board_json = BOARDS / f"{base} (Montessori)" / f"{board_id}.json"
        if not board_json.exists():
            print(f"Board not found: {board_json}")
            continue

        asset_dir = ASSETS / SINGULAR[base]
        if not asset_dir.exists():
            print(f"No assets for {base}: {asset_dir}")
            continue

        with open(board_json, "r", encoding="utf-8-sig") as fp:
            data = json.load(fp)

        tiles = build_tiles(base, board_id, asset_dir)
        columns = data.get("columns", 7)
        if not columns or columns < 1:
            columns = 7
        rows = math.ceil(len(tiles) / columns)

        data["tiles"] = tiles
        data["layout"] = {"rows": rows, "blankTilesAdded": 0}
        data["columns"] = columns

        with open(board_json, "w", encoding="utf-8") as fp:
            json.dump(data, fp, indent=2, ensure_ascii=False)

        print(f"{board_name}: {len(tiles)} tiles, {columns} columns, {rows} rows")


if __name__ == "__main__":
    main()
