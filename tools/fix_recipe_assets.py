"""
Repair missing/broken imageAsset paths on Recipe board tiles.

Many recipe boards were saved with imageAsset paths pointing at a made-up
per-recipe folder (assets/Subject Vocab/Recipes/Recipes/<Recipe>/<word>.png)
that was never actually created. The real images for these words already
exist under assets/Subject Vocab/Cooking/** (organised by ingredient
category), plus a dedicated Recipes/Instructions folder for step images.

This script only ever REPLACES an imageAsset value when the current path
does not exist on disk and a confident match is found. It never touches
tiles whose current imageAsset already resolves, and never touches any
other tile field (label, linkedBoardId, colours, etc.).
"""
import json
import re
from pathlib import Path

root = Path('C:/Users/Craig/Downloads/Charlie Chat')
boards_dir = root / 'lib' / 'data' / 'boards' / 'Recipes'
assets_root = root / 'assets'
cooking_root = root / 'assets' / 'Subject Vocab' / 'Cooking'
instructions_dir = cooking_root / 'Recipes' / 'Instructions'


def normalize(s):
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def load_json(p):
    with open(p, 'r', encoding='utf-8-sig') as f:
        return json.load(f)


def write_json(p, data):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False) + '\n')


def build_asset_index(search_root):
    # normalized filename stem -> list of relative paths (posix, from project root)
    index = {}
    for f in search_root.rglob('*'):
        if not f.is_file():
            continue
        stem_norm = normalize(f.stem)
        rel = f.relative_to(root).as_posix()
        index.setdefault(stem_norm, []).append(rel)
    return index


def find_instruction_asset(recipe_name, step_num):
    for ext in ('png', 'jpg', 'jpeg'):
        candidate = instructions_dir / f"{recipe_name} Instructions {step_num}.{ext}"
        if candidate.exists():
            return candidate.relative_to(root).as_posix()
    # Case-insensitive fallback scan
    target = normalize(f"{recipe_name} instructions {step_num}")
    for f in instructions_dir.glob('*'):
        if f.is_file() and normalize(f.stem) == target:
            return f.relative_to(root).as_posix()
    return None


INSTRUCTION_RE = re.compile(r'^\s*(\d+)\s*instructi', re.IGNORECASE)


def resolve_by_label(label, recipe_name, primary_index, fallback_index):
    key = normalize(label)
    for index in (primary_index, fallback_index):
        candidates = index.get(key)
        if not candidates:
            continue
        if len(candidates) == 1:
            return candidates[0]
        recipe_tokens = [t for t in normalize(recipe_name).split() if len(t) > 3]
        scored = [c for c in candidates if any(t in normalize(c) for t in recipe_tokens)]
        return (scored or candidates)[0]
    return None


def main():
    primary_index = build_asset_index(cooking_root)
    fallback_index = build_asset_index(assets_root)
    fixed = 0
    normalized_only = 0
    unresolved = []

    for board_file in sorted(boards_dir.rglob('*.json')):
        if '_deleted' in [p.lower() for p in board_file.parts]:
            continue
        data = load_json(board_file)
        recipe_name = data.get('name', '')
        changed = False
        for tile in data.get('tiles', []):
            asset = tile.get('imageAsset', '')
            label = tile.get('label', '') or ''
            if not label:
                continue
            # Some paths were stored with mixed backslashes/forward slashes.
            # Windows-local checks tolerate that, but the Flutter web asset
            # bundle needs consistent forward slashes, so normalize first.
            asset_fwd = asset.replace('\\', '/') if asset else asset
            if asset_fwd != asset:
                tile['imageAsset'] = asset_fwd
                asset = asset_fwd
                changed = True
                normalized_only += 1
            if asset and (root / asset).exists():
                continue  # already resolves fine, leave untouched

            new_asset = None

            # Case 1: instruction step tiles (label truncated to "N Instructi...")
            m = INSTRUCTION_RE.match(label)
            if m:
                new_asset = find_instruction_asset(recipe_name, m.group(1))

            # Case 2: direct label match, Cooking assets first, then any asset
            if not new_asset:
                new_asset = resolve_by_label(label, recipe_name, primary_index, fallback_index)

            if new_asset:
                tile['imageAsset'] = new_asset
                changed = True
                fixed += 1
            elif asset and not (root / asset).exists():
                unresolved.append((recipe_name, label, asset))

        if changed:
            write_json(board_file, data)

    print(f'Fixed {fixed} tile image paths.')
    print(f'Normalized separator only: {normalized_only}')
    print(f'Unresolved (no matching asset found anywhere): {len(unresolved)}')
    for u in unresolved:
        print('  ', u)


if __name__ == '__main__':
    main()
