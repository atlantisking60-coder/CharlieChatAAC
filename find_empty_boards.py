#!/usr/bin/env python3
"""Find board JSONs with empty tiles arrays."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards"


def main():
    empty = []
    errors = []
    for p in BOARDS_DIR.rglob("*.json"):
        try:
            d = json.load(open(p, "r", encoding="utf-8-sig"))
            tiles = d.get("tiles", [])
            if len(tiles) == 0:
                empty.append(p.relative_to(BOARDS_DIR))
        except Exception as e:
            errors.append((p.relative_to(BOARDS_DIR), e))

    print(f"Boards with empty tiles: {len(empty)}")
    for e in sorted(empty):
        print(f"  {e}")

    if errors:
        print(f"\nJSON errors: {len(errors)}")
        for path, err in errors:
            print(f"  {path}: {err}")


if __name__ == "__main__":
    main()
