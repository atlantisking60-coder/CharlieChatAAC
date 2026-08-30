#!/usr/bin/env python3
"""Add missing board entries to board_hierarchy.dart without truncating the file."""

import json
import re
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards"
HIERARCHY_FILE = PROJECT_ROOT / "lib" / "data" / "board_hierarchy.dart"

# Exclude link boards from hierarchy additions.
SKIP_LINK_BOARDS = True


def read_json(path: Path) -> dict | None:
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except Exception as e:
        print(f"Could not read {path}: {e}")
        return None


def parse_hierarchy_file(path: Path) -> tuple[list[str], list[dict], list[str]]:
    """Return (lines_before_list, entries, lines_after_closing_bracket)."""
    lines = path.read_text(encoding="utf-8").splitlines()

    list_start = None
    for i, line in enumerate(lines):
        if "const List<BoardHierarchyEntry> boardHierarchy = [" in line:
            list_start = i
            break
    if list_start is None:
        raise ValueError("Could not find boardHierarchy list start")

    list_end = None
    for i in range(list_start + 1, len(lines)):
        if lines[i].strip() == "];":
            list_end = i
            break
    if list_end is None:
        raise ValueError("Could not find boardHierarchy list end")

    single_re = re.compile(
        r"""\s*BoardHierarchyEntry\(\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'(?:\s*,\s*'((?:\\'|[^'])*)')?\s*\)\s*,?"""
    )
    double_re = re.compile(
        r'''\s*BoardHierarchyEntry\(\s*"([^"]*)"\s*,\s*'([^']*)'(?:\s*,\s*'([^']*)')?\s*\)\s*,?'''
    )

    entries = []
    for line in lines[list_start + 1:list_end]:
        m = single_re.match(line) or double_re.match(line)
        if not m:
            continue
        entries.append({
            "name": m.group(1).replace("\\'", "'"),
            "area": m.group(2).replace("\\'", "'"),
            "parent": m.group(3).replace("\\'", "'") if m.group(3) else None,
            "line": line,
        })

    return lines[:list_start + 1], entries, lines[list_end:]


def format_entry(name: str, area: str, parent: str | None) -> str:
    escaped_name = name.replace("'", "\\'")
    escaped_area = area.replace("'", "\\'")
    if parent:
        escaped_parent = parent.replace("'", "\\'")
        return f"  BoardHierarchyEntry('{escaped_name}', '{escaped_area}', '{escaped_parent}'),"
    return f"  BoardHierarchyEntry('{escaped_name}', '{escaped_area}'),"


def main():
    before, entries, after = parse_hierarchy_file(HIERARCHY_FILE)

    # Build id -> name map
    id_to_name: dict[str, str] = {}
    board_infos = []
    for path in BOARDS_DIR.rglob("*.json"):
        if "_temp" in path.parts or "_deleted" in path.parts:
            continue
        data = read_json(path)
        if not data:
            continue
        bid = data.get("id")
        name = (data.get("name") or "").strip()
        area = (data.get("area") or "Common").strip()
        if bid and name:
            id_to_name[bid] = name
        board_infos.append({
            "id": bid,
            "name": name,
            "area": area,
            "parentBoardId": data.get("parentBoardId"),
            "is_link": str(bid).startswith("link_") if bid else False,
        })

    existing_keys = {(e["name"].lower(), e["area"].lower(), (e["parent"] or "").lower()) for e in entries}

    missing = []
    for info in board_infos:
        if SKIP_LINK_BOARDS and info.get("is_link"):
            continue
        parent_id = info.get("parentBoardId")
        parent_name = id_to_name.get(parent_id) if parent_id else None
        key = (info["name"].lower(), info["area"].lower(), (parent_name or "").lower())
        if key not in existing_keys:
            missing.append({
                "name": info["name"],
                "area": info["area"],
                "parent": parent_name,
            })

    if not missing:
        print("No missing boards to add.")
        return

    print(f"Adding {len(missing)} missing boards to hierarchy:\n")
    for m in sorted(missing, key=lambda x: (x["area"], x["parent"] or "", x["name"])):
        print(f"  {m['name']} ({m['area']}, parent={m['parent']})")

    for new in missing:
        new_line = format_entry(new["name"], new["area"], new["parent"])
        insert_idx = len(entries)
        for i, e in enumerate(entries):
            if e["area"].lower() != new["area"].lower():
                if i > 0 and entries[i - 1]["area"].lower() == new["area"].lower():
                    insert_idx = i
                    break
                continue
            e_parent = (e["parent"] or "").lower()
            n_parent = (new["parent"] or "").lower()
            if e_parent != n_parent:
                if e_parent > n_parent:
                    insert_idx = i
                    break
                continue
            if e["name"].lower() > new["name"].lower():
                insert_idx = i
                break
        entries.insert(insert_idx, {"name": new["name"], "area": new["area"], "parent": new["parent"], "line": new_line})

    # Rebuild file content
    out_lines = before.copy()
    for e in entries:
        out_lines.append(e["line"])
    out_lines.extend(after)

    HIERARCHY_FILE.write_text("\n".join(out_lines), encoding="utf-8")
    print(f"\nUpdated {HIERARCHY_FILE}")


if __name__ == "__main__":
    main()
