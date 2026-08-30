#!/usr/bin/env python3
"""Find board JSON files that are missing from board_hierarchy.dart."""

import json
import re
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards"
HIERARCHY_FILE = PROJECT_ROOT / "lib" / "data" / "board_hierarchy.dart"


def read_json(path: Path) -> dict | None:
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except Exception as e:
        print(f"Could not read {path}: {e}")
        return None


def load_hierarchy(path: Path) -> set[tuple[str, str, str | None]]:
    """Load existing (name_lower, area_lower, parent_name_lower_or_None) tuples."""
    text = path.read_text(encoding="utf-8")
    single_re = re.compile(
        r"""BoardHierarchyEntry\(\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'(?:\s*,\s*'((?:\\'|[^'])*)')?\s*\)\s*,?"""
    )
    double_re = re.compile(
        r'''BoardHierarchyEntry\(\s*"([^"]*)"\s*,\s*'([^']*)'(?:\s*,\s*'([^']*)')?\s*\)\s*,?'''
    )
    entries = set()
    for line in text.splitlines():
        m = single_re.search(line) or double_re.search(line)
        if not m:
            continue
        name = m.group(1).replace("\\'", "'").strip().lower()
        area = m.group(2).replace("\\'", "'").strip().lower()
        parent = m.group(3)
        parent = parent.replace("\\'", "'").strip().lower() if parent else None
        entries.add((name, area, parent))
    return entries


def main():
    existing = load_hierarchy(HIERARCHY_FILE)

    # Build id -> name map to resolve parentBoardId -> parent name
    id_to_name: dict[str, str] = {}
    board_infos = []
    for path in BOARDS_DIR.rglob("*.json"):
        if "_temp" in path.parts or "_deleted" in path.parts:
            continue
        data = read_json(path)
        if not data:
            continue
        bid = data.get("id")
        name = data.get("name", "").strip()
        area = data.get("area", "Common").strip()
        if bid and name:
            id_to_name[bid] = name
        board_infos.append({
            "path": path,
            "id": bid,
            "name": name,
            "area": area,
            "parentBoardId": data.get("parentBoardId"),
            "tier": data.get("tier", 1),
            "tiles": len(data.get("tiles", [])),
        })

    missing = []
    for info in board_infos:
        name = info["name"].lower()
        area = info["area"].lower()
        parent_id = info.get("parentBoardId")
        parent_name = id_to_name.get(parent_id, "").lower() if parent_id else None

        key = (name, area, parent_name)
        if key not in existing:
            missing.append(info)

    print(f"Total JSON boards scanned: {len(board_infos)}")
    print(f"Missing from board_hierarchy.dart: {len(missing)}\n")

    # Group by area/parent
    by_area_parent: dict[tuple[str, str | None], list[dict]] = {}
    for m in missing:
        pid = m.get("parentBoardId")
        parent_name = id_to_name.get(pid) if pid else None
        key = (m["area"], parent_name)
        by_area_parent.setdefault(key, []).append(m)

    for (area, parent), boards in sorted(by_area_parent.items()):
        print(f"Area: {area} | Parent: {parent or '(top-level)'}")
        for b in sorted(boards, key=lambda x: x["name"]):
            print(f"  - {b['name']} (id={b['id']}, tier={b['tier']}, tiles={b['tiles']})")
            print(f"    {b['path'].relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
