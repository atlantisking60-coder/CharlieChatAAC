#!/usr/bin/env python3
"""Compare current board JSON tile counts with latest backup to detect data loss."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards"
BACKUP_DIRS = [
    PROJECT_ROOT / "Backups" / "Boards",
    PROJECT_ROOT / "Backups" / "lib_data_boards_7316",
]


def tile_count(path: Path) -> int:
    try:
        d = json.load(open(path, "r", encoding="utf-8-sig"))
        return len(d.get("tiles", []))
    except Exception:
        return -1


def main():
    candidates = []
    for current in BOARDS_DIR.rglob("*.json"):
        name = current.name
        backups = []
        for base in BACKUP_DIRS:
            backups.extend(base.rglob(name))
        if not backups:
            continue
        latest = max(backups, key=lambda p: p.stat().st_mtime)
        cur_tiles = tile_count(current)
        bak_tiles = tile_count(latest)
        if bak_tiles > cur_tiles:
            candidates.append({
                "current": current.relative_to(PROJECT_ROOT),
                "current_tiles": cur_tiles,
                "backup": latest.relative_to(PROJECT_ROOT),
                "backup_tiles": bak_tiles,
            })

    print(f"Found {len(candidates)} boards where a backup has more tiles than the current file:\n")
    for c in sorted(candidates, key=lambda x: x["backup_tiles"] - x["current_tiles"], reverse=True):
        print(f"{c['current']}")
        print(f"  current: {c['current_tiles']} tiles")
        print(f"  backup:  {c['backup_tiles']} tiles ({c['backup']})")
        print()


if __name__ == "__main__":
    main()
