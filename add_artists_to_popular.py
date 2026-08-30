#!/usr/bin/env python3
"""Add artists found in Subject Vocab Art boards to Popular Artists board."""

import json
import re
from pathlib import Path
from math import ceil

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
POPULAR_FILE = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Real Life Heroes" / "Popular Artists" / "prebuilt_popular_artists.json"

# Artists discovered in the Art boards and their asset paths.
NEW_ARTISTS = [
    ("Carolee Clark", "assets/Subject Vocab/Art/8/carolee clark.png"),
    ("Keith Haring", "assets/Subject Vocab/Art/8/keith haring.png"),
    ("Mr. Doodle", "assets/Subject Vocab/Art/8/mr. doodle.png"),
    ("Claes Oldenburg", "assets/Subject Vocab/Art/8/claes oldenburg.png"),
    ("Wassily Kandinsky", "assets/Subject Vocab/Art/8/wassily kandinsky.png"),
    ("Robert Delaunay", "assets/Subject Vocab/Art/8/robert delaunay.png"),
    ("Andy Goldsworthy", "assets/Subject Vocab/Art/8/andy goldsworthy.png"),
    ("L.S. Lowry", "assets/Subject Vocab/Art/9/l.s.lowry.png"),
    ("Hundertwasser", "assets/Subject Vocab/Art/9/hundertwasser.png"),
    ("Gaudi", "assets/Subject Vocab/Art/9/gaudi.png"),
    ("Tony Cragg", "assets/Subject Vocab/Art/9/tony cragg.png"),
    ("Barbara Hepworth", "assets/Subject Vocab/Art/9/barbara hepworth.png"),
    ("Henry Moore", "assets/Subject Vocab/Art/9/henry moore.png"),
    ("Roy Lichtenstein", "assets/Subject Vocab/Art/7/roy lichtenstein.png"),
    ("Joseph William Turner", "assets/Subject Vocab/Art/7/joseph william turner.png"),
]

# Existing tiles whose imageAsset should be updated from the art boards.
ASSET_OVERRIDES = {
    "Banksy": "assets/Subject Vocab/Art/8/banksy.png",
    "Andy Warhol": "assets/Subject Vocab/Art/7/andy warhol.png",
}


def slugify(text: str) -> str:
    s = text.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = s.strip("_")
    return s


def make_tile(board_id: str, label: str, image_asset: str) -> dict:
    return {
        "id": f"{board_id}_{slugify(label)}",
        "type": "vocabulary",
        "label": label,
        "category": "Custom",
        "imageAsset": image_asset,
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
        "customVoice": ""
    }


def main():
    data = json.load(open(POPULAR_FILE, "r", encoding="utf-8-sig"))
    board_id = data["id"]
    existing_labels = {t["label"].lower() for t in data["tiles"]}

    # Update assets for existing artists found in art boards.
    updated = 0
    for tile in data["tiles"]:
        label = tile["label"]
        if label in ASSET_OVERRIDES:
            tile["imageAsset"] = ASSET_OVERRIDES[label]
            updated += 1

    # Append new artists not already present.
    added = 0
    for label, asset in NEW_ARTISTS:
        if label.lower() in existing_labels:
            continue
        data["tiles"].append(make_tile(board_id, label, asset))
        added += 1
        existing_labels.add(label.lower())

    data["layout"]["rows"] = ceil(len(data["tiles"]) / data["columns"])

    json.dump(data, open(POPULAR_FILE, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(POPULAR_FILE, "a", encoding="utf-8").write("\n")
    print(f"Updated {updated} existing artists, added {added} new artists. Total tiles: {len(data['tiles'])}")


if __name__ == "__main__":
    main()
