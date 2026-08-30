#!/usr/bin/env python3
"""Extract people lists from Real Life Heroes sub-boards to a markdown file."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Real Life Heroes"
OUT = PROJECT_ROOT / "REAL_LIFE_HEROES_PEOPLE.md"


def main():
    lines = ["# Real Life Heroes — People Lists\n"]
    for sub in sorted(BOARDS_DIR.iterdir()):
        if not sub.is_dir():
            continue
        files = list(sub.glob("*.json"))
        if not files:
            continue
        data = json.load(open(files[0], "r", encoding="utf-8-sig"))
        lines.append(f"## {data['name']}\n")
        for tile in data["tiles"]:
            lines.append(f"- {tile['label']}")
        lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Created {OUT.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
