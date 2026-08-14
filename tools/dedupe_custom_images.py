"""Replace assets/symbols/Custom images with identical existing project assets.

Matching is by exact file content (SHA-256), never by filename, so a same-named
but different image can never be substituted.

Custom images with no content match are moved into the asset folder that mirrors
the board JSON's own folder under lib/data/boards.

Usage:
    python tools/dedupe_custom_images.py            # dry run, prints report
    python tools/dedupe_custom_images.py --apply    # write changes
"""

import hashlib
import json
import os
import shutil
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
CUSTOM_DIR = ASSETS / "symbols" / "Custom"
BOARDS_DIR = ROOT / "lib" / "data" / "boards"
INDEX_DART_FILES = [
    ROOT / "lib" / "data" / "symbol_icon_assets.dart",
    ROOT / "lib" / "data" / "board_icon_assets.dart",
]

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as fp:
        for chunk in iter(lambda: fp.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def asset_rel(path):
    return "assets/" + path.relative_to(ASSETS).as_posix()


def build_asset_index():
    """content hash -> list of asset-relative paths, excluding symbols/Custom."""
    index = defaultdict(list)
    for root, _, files in os.walk(ASSETS):
        root_path = Path(root)
        if CUSTOM_DIR == root_path or CUSTOM_DIR in root_path.parents:
            continue
        for name in files:
            if Path(name).suffix.lower() not in IMAGE_EXTS:
                continue
            fp = root_path / name
            try:
                index[sha(fp)].append(asset_rel(fp))
            except Exception as e:
                print(f"  ! could not hash {fp}: {e}")
    return index


def board_json_files():
    for root, _, files in os.walk(BOARDS_DIR):
        if "_deleted" in Path(root).parts:
            continue
        for name in files:
            if name.lower().endswith(".json"):
                yield Path(root) / name


def target_asset_dir(board_file):
    """Asset folder mirroring the board JSON's folder under lib/data/boards."""
    rel = board_file.parent.relative_to(BOARDS_DIR)
    return ASSETS / rel


def iter_image_fields(board):
    for tile in board.get("tiles", []) or []:
        if isinstance(tile, dict):
            yield tile, "imageAsset"
            yield tile, "image"


def main():
    apply = "--apply" in sys.argv

    if not CUSTOM_DIR.exists():
        print("No assets/symbols/Custom directory found.")
        return

    print("Indexing project assets by content hash...")
    index = build_asset_index()
    print(f"  indexed {sum(len(v) for v in index.values())} images\n")

    custom_hashes = {}
    for fp in sorted(CUSTOM_DIR.iterdir()):
        if fp.is_file() and fp.suffix.lower() in IMAGE_EXTS:
            try:
                custom_hashes[asset_rel(fp)] = (fp, sha(fp))
            except Exception as e:
                print(f"  ! could not hash {fp}: {e}")

    # Resolve each custom reference to a replacement path.
    resolved = {}   # custom asset path -> (new path, reason)
    unmatched = {}  # custom asset path -> (file, hash)
    for custom_path, (fp, digest) in custom_hashes.items():
        matches = index.get(digest)
        if matches:
            resolved[custom_path] = (sorted(matches, key=len)[0], "identical existing asset")
        else:
            unmatched[custom_path] = (fp, digest)

    # Scan board JSONs for references.
    refs = defaultdict(list)  # custom asset path -> [(board_file, tile_id)]
    for board_file in board_json_files():
        try:
            board = json.loads(board_file.read_text(encoding="utf-8"))
        except Exception:
            continue
        for tile, field in iter_image_fields(board):
            value = tile.get(field)
            if isinstance(value, str) and value.startswith("assets/symbols/Custom/"):
                refs[value].append((board_file, tile.get("id", "?")))

    # Unmatched but referenced images get relocated next to their board.
    relocations = {}  # custom asset path -> new asset path
    for custom_path, (fp, _digest) in unmatched.items():
        locations = refs.get(custom_path)
        if not locations:
            continue
        board_file = locations[0][0]
        dest_dir = target_asset_dir(board_file)
        relocations[custom_path] = asset_rel(dest_dir / fp.name)

    # ---------------- Report ----------------
    print("=" * 78)
    print("REPLACED WITH EXISTING ASSET (matched by identical file content)")
    print("=" * 78)
    replaced_count = 0
    for custom_path in sorted(resolved):
        if custom_path not in refs:
            continue
        new_path, _ = resolved[custom_path]
        replaced_count += 1
        print(f"\n{custom_path}")
        print(f"  ->  {new_path}")
        for board_file, tile_id in refs[custom_path]:
            print(f"      used by {board_file.relative_to(ROOT).as_posix()}  [tile {tile_id}]")
    if replaced_count == 0:
        print("\n  (none)")

    print()
    print("=" * 78)
    print("MOVED TO BOARD-MATCHED FOLDER (no identical asset existed)")
    print("=" * 78)
    if relocations:
        for custom_path in sorted(relocations):
            print(f"\n{custom_path}")
            print(f"  ->  {relocations[custom_path]}")
            for board_file, tile_id in refs[custom_path]:
                print(f"      used by {board_file.relative_to(ROOT).as_posix()}  [tile {tile_id}]")
    else:
        print("\n  (none)")

    # Custom paths that only appear in the Dart symbol/board icon indexes.
    dart_refs = defaultdict(list)
    for dart_file in INDEX_DART_FILES:
        if not dart_file.exists():
            continue
        text = dart_file.read_text(encoding="utf-8")
        for custom_path in custom_hashes:
            if custom_path in text:
                dart_refs[custom_path].append(dart_file)

    print()
    print("=" * 78)
    print("DART INDEX ENTRIES DROPPED (duplicate of an existing asset)")
    print("=" * 78)
    dart_dropped = {}
    for custom_path in sorted(dart_refs):
        if custom_path in refs or custom_path not in resolved:
            continue
        new_path, _ = resolved[custom_path]
        dart_dropped[custom_path] = new_path
        print(f"\n{custom_path}")
        print(f"  ->  {new_path}")
        for dart_file in dart_refs[custom_path]:
            print(f"      listed in {dart_file.relative_to(ROOT).as_posix()}")
    if not dart_dropped:
        print("\n  (none)")

    orphans = [
        c for c in custom_hashes
        if c not in refs and c not in dart_dropped
    ]
    print()
    print("=" * 78)
    print(f"CUSTOM IMAGES LEFT UNTOUCHED (no content match, no board reference): {len(orphans)}")
    print("=" * 78)
    for c in sorted(orphans):
        note = "in dart index" if c in dart_refs else "unreferenced"
        print(f"  {c}   [{note}]")

    if not apply:
        print("\nDry run only. Re-run with --apply to write these changes.")
        return

    # ---------------- Apply ----------------
    print("\nApplying changes...")

    # Move unmatched files first so the new paths exist.
    for custom_path, new_path in relocations.items():
        src = custom_hashes[custom_path][0]
        dest = ROOT / new_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            shutil.move(str(src), str(dest))

    rewrite = dict(relocations)
    for custom_path, (new_path, _) in resolved.items():
        rewrite[custom_path] = new_path

    changed_files = 0
    for board_file in board_json_files():
        try:
            text = board_file.read_text(encoding="utf-8")
            board = json.loads(text)
        except Exception:
            continue
        dirty = False
        for tile, field in iter_image_fields(board):
            value = tile.get(field)
            if isinstance(value, str) and value in rewrite:
                tile[field] = rewrite[value]
                dirty = True
        if dirty:
            board_file.write_text(
                json.dumps(board, indent=2, ensure_ascii=False), encoding="utf-8"
            )
            changed_files += 1

    # Drop redundant Custom paths from the Dart icon index lists.
    dart_changed = 0
    for dart_file in INDEX_DART_FILES:
        if not dart_file.exists():
            continue
        text = dart_file.read_text(encoding="utf-8")
        original = text
        for custom_path in list(resolved):
            # Remove the list element, whichever position it sits in.
            text = text.replace(f"'{custom_path}', ", "")
            text = text.replace(f", '{custom_path}'", "")
        if text != original:
            dart_file.write_text(text, encoding="utf-8")
            dart_changed += 1

    # Retire the now-redundant duplicates. Nothing is deleted: they are moved
    # into assets/symbols/Custom/_replaced so they can be inspected or restored.
    retired_dir = CUSTOM_DIR / "_replaced"
    retired = 0
    for custom_path in resolved:
        src = custom_hashes[custom_path][0]
        if src.exists():
            retired_dir.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(retired_dir / src.name))
            retired += 1

    print(f"  rewrote {changed_files} board JSON files")
    print(f"  updated {dart_changed} Dart icon index files")
    print(f"  replaced {replaced_count} duplicate custom images")
    print(f"  moved {len(relocations)} custom images into board-matched folders")
    print(f"  retired {retired} redundant files to assets/symbols/Custom/_replaced")


if __name__ == "__main__":
    main()
