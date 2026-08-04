#!/usr/bin/env python3
"""One-off: remove old non-Montessori Small Words ghosts and fix parent link tiles."""
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SMALL_WORDS = ROOT / "lib" / "data" / "boards" / "Common" / "Small Words"
TEMP_COMMON = ROOT / "lib" / "data" / "boards" / "_temp" / "Common"
PARENT = SMALL_WORDS / "prebuilt_small_words.json"

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


def snake(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().strip()).strip("_")


def main():
    # 1. Wipe old non-Montessori Small Words JSONs from _temp/Common.
    old_ids = {f"prebuilt_{snake(b)}.json" for b in ORDER}
    old_ids.add("prebuilt_montessori_prepositions.json")
    if TEMP_COMMON.exists():
        for f in TEMP_COMMON.glob("prebuilt_*.json"):
            if f.name in old_ids:
                f.unlink()
                print(f"Deleted temp ghost: {f}")

    # 2. Fix the Small Words parent board.
    with open(PARENT, "r", encoding="utf-8") as f:
        parent = json.load(f)

    existing_links = {}
    other_tiles = []
    for tile in parent.get("tiles", []):
        if tile.get("isBoardLink") or tile.get("type") == "board_link":
            lid = tile.get("linkedBoardId", "")
            existing_links[lid] = tile
            # Also index by base non-montessori id for matching
            if lid.endswith("_montessori"):
                existing_links[lid.replace("_montessori", "")] = tile
        else:
            other_tiles.append(tile)

    new_tiles = []
    for i, base in enumerate(ORDER, start=1):
        target_id = f"prebuilt_{snake(base)}_montessori"
        tile = existing_links.get(target_id) or existing_links.get(snake(base))
        if tile is None:
            tile = {}
        tile = dict(tile)
        tile["id"] = f"prebuilt_small_words_{snake(base)}"
        tile["type"] = "board_link"
        tile["label"] = base
        tile["category"] = "Assets"
        tile["isBoardLink"] = True
        tile["linkedBoardId"] = target_id
        tile["linkedBoardName"] = f"{base} (Montessori)"
        tile["isFullScreenImage"] = False
        tile["bgColor"] = "#000000"
        tile["textColor"] = "#FFFFFF"
        tile["tileSize"] = 1
        tile["colSpan"] = 1
        tile["rowSpan"] = 1
        tile["customVoice"] = ""
        if not tile.get("imageAsset"):
            singular = base[:-1] if base.endswith("s") and base not in {"Others", "News"} else base
            tile["imageAsset"] = f"assets/BOARDS/English/Montessori/{singular}.png"
        new_tiles.append(tile)

    parent["tiles"] = new_tiles + other_tiles
    parent["sortOrder"] = 2
    parent["tier"] = 1
    parent["isSubBoard"] = False
    parent["parentBoardId"] = None
    with open(PARENT, "w", encoding="utf-8") as f:
        json.dump(parent, f, indent=2, ensure_ascii=False)
    print(f"Rewrote {PARENT} with {len(new_tiles)} Montessori links")

    # 3. Ensure all Montessori board JSONs are parented to Small Words.
    for base in ORDER:
        folder = SMALL_WORDS / f"{base} (Montessori)"
        if not folder.exists():
            print(f"Folder not found: {folder}")
            continue
        for json_path in folder.glob("*.json"):
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            data["name"] = f"{base} (Montessori)"
            data["sortOrder"] = ORDER.index(base) + 1
            data["parentBoardId"] = "prebuilt_small_words"
            data["isSubBoard"] = True
            data["tier"] = 2
            with open(json_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
