#!/usr/bin/env python3
"""Clean up lib/data/boards/_temp JSON files when a newer version exists in an actual area.

For every JSON in lib/data/boards/_temp, read its board id and look for a file
with the same id under lib/data/boards excluding _temp. If the actual-area file
has more populated tiles (or the same tile count but is edited later), delete the
temp file. Empty temp folders are removed afterwards.
"""

import json
import os
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_ROOT = PROJECT_ROOT / "lib" / "data" / "boards"
TEMP_ROOT = BOARDS_ROOT / "_temp"


def json_files(root: Path):
    return list(root.rglob("*.json"))


def read_json(path: Path) -> dict | None:
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except Exception as e:
        print(f"Could not read {path}: {e}")
        return None


def read_id(path: Path) -> str | None:
    data = read_json(path)
    return data.get("id") if data else None


def populated_tile_count(data: dict | None) -> int:
    if not data:
        return 0
    tiles = data.get("tiles") or []
    return sum(
        1
        for t in tiles
        if (t.get("label") or "").strip()
           or (t.get("imageAsset") or "").strip()
           or (t.get("emoji") or "").strip()
    )


def main():
    if not TEMP_ROOT.exists():
        print(f"Temp root not found: {TEMP_ROOT}")
        return

    temp_files = json_files(TEMP_ROOT)
    actual_files = [
        p for p in json_files(BOARDS_ROOT)
        if not p.is_relative_to(TEMP_ROOT)
    ]

    # Map id -> list of actual-area files
    actual_by_id: dict[str, list[Path]] = {}
    # Map normalized name -> list of actual-area files
    actual_by_name: dict[str, list[Path]] = {}
    for p in actual_files:
        bid = read_id(p)
        if bid:
            actual_by_id.setdefault(bid, []).append(p)
        data = read_json(p)
        if data:
            name = (data.get("name") or "").strip().lower()
            if name:
                actual_by_name.setdefault(name, []).append(p)

    # Known area prefixes that may have been baked into a temp board name.
    AREA_PREFIXES = [
        "recipes ", "common ", "subject vocab ", "sign ",
        "my school ", "legends ", "personal ", "unassigned ",
    ]

    kept: list[Path] = []
    deleted: list[Path] = []
    failed: list[tuple[Path, str]] = []

    for temp_path in temp_files:
        temp_data = read_json(temp_path)
        if temp_data is None:
            print(f"SKIP (unreadable): {temp_path.relative_to(PROJECT_ROOT)}")
            kept.append(temp_path)
            continue

        bid = temp_data.get("id")
        temp_name = (temp_data.get("name") or "").strip().lower()

        # Collect candidate actual-area files: exact id match, then exact name match,
        # then name match after stripping a leading area prefix from the temp name.
        candidate_files: list[Path] = []
        if bid:
            candidate_files.extend(actual_by_id.get(bid, []))
        if temp_name:
            candidate_files.extend(actual_by_name.get(temp_name, []))
            for prefix in AREA_PREFIXES:
                if temp_name.startswith(prefix):
                    stripped = temp_name[len(prefix):].strip()
                    candidate_files.extend(actual_by_name.get(stripped, []))

        # De-duplicate while preserving order
        seen = set()
        actual_matches = []
        for p in candidate_files:
            if p not in seen:
                seen.add(p)
                actual_matches.append(p)

        if not actual_matches:
            print(f"KEEP (no actual match): {temp_path.relative_to(PROJECT_ROOT)}")
            kept.append(temp_path)
            continue

        temp_tiles = populated_tile_count(temp_data)
        temp_mtime = temp_path.stat().st_mtime

        # A temp file is deletable if an actual-area version is "better":
        #   - strictly more populated tiles, OR
        #   - same tile count but edited later.
        def actual_is_better(p: Path) -> bool:
            actual_tiles = populated_tile_count(read_json(p))
            if actual_tiles > temp_tiles:
                return True
            if actual_tiles == temp_tiles:
                return p.stat().st_mtime >= temp_mtime
            return False

        better_matches = [p for p in actual_matches if actual_is_better(p)]

        if better_matches:
            try:
                temp_path.unlink()
                print(f"DELETE: {temp_path.relative_to(PROJECT_ROOT)} (temp tiles: {temp_tiles})")
                for a in better_matches:
                    actual_tiles = populated_tile_count(read_json(a))
                    actual_mtime = a.stat().st_mtime
                    print(f"  matched by: {a.relative_to(PROJECT_ROOT)} (tiles: {actual_tiles}, mtime: {actual_mtime})")
                deleted.append(temp_path)
            except Exception as e:
                failed.append((temp_path, str(e)))
        else:
            print(f"KEEP: {temp_path.relative_to(PROJECT_ROOT)} (temp tiles: {temp_tiles})")
            for a in actual_matches:
                actual_tiles = populated_tile_count(read_json(a))
                actual_mtime = a.stat().st_mtime
                print(f"  actual: {a.relative_to(PROJECT_ROOT)} (tiles: {actual_tiles}, mtime: {actual_mtime})")
            kept.append(temp_path)

    # Remove empty temp directories bottom-up
    removed_dirs: list[Path] = []
    if TEMP_ROOT.exists():
        for dir_path in sorted(TEMP_ROOT.rglob("*"), reverse=True):
            if dir_path.is_dir() and not any(dir_path.iterdir()):
                try:
                    dir_path.rmdir()
                    print(f"RMDIR: {dir_path.relative_to(PROJECT_ROOT)}")
                    removed_dirs.append(dir_path)
                except Exception as e:
                    print(f"Could not remove {dir_path}: {e}")

    print("\n--- Summary ---")
    print(f"Temp JSONs inspected: {len(temp_files)}")
    print(f"Deleted: {len(deleted)}")
    print(f"Kept: {len(kept)}")
    print(f"Failed: {len(failed)}")
    print(f"Empty dirs removed: {len(removed_dirs)}")

    if kept:
        print("\nKept files:")
        for p in kept:
            print(f"  {p.relative_to(PROJECT_ROOT)}")

    if failed:
        print("\nFailed deletions:")
        for p, err in failed:
            print(f"  {p.relative_to(PROJECT_ROOT)}: {err}")


if __name__ == "__main__":
    main()
