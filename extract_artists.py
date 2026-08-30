#!/usr/bin/env python3
"""Extract all tiles from art-related boards for artist-name review."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
ART_DIRS = [
    PROJECT_ROOT / "lib" / "data" / "boards" / "Subject Vocab" / "Art",
    PROJECT_ROOT / "lib" / "data" / "boards" / "Subject Vocab" / "Photography" / "Artists, Context, Process, Assessment",
]
OUT = PROJECT_ROOT / "ART_BOARD_TILES.md"


def main():
    lines = ["# Art Board Tiles\n"]
    for art_dir in ART_DIRS:
        if not art_dir.exists():
            continue
        for json_file in art_dir.rglob("*.json"):
            data = json.load(open(json_file, "r", encoding="utf-8-sig"))
            lines.append(f"## {data.get('name', json_file.name)} ({json_file.relative_to(PROJECT_ROOT)})\n")
            for tile in data.get("tiles", []):
                label = tile.get("label", "")
                image = tile.get("imageAsset", "")
                if label:
                    lines.append(f"- `{label}` → `{image}`")
            lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Created {OUT.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
