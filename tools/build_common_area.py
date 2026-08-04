import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent
MD_FILE = ROOT / 'MD Files' / 'AREA_COMMON.md'
BOARDS_DIR = ROOT / 'lib' / 'data' / 'boards' / 'Common'
ASSETS_DIR = ROOT / 'assets' / 'Common'
LOG_DIR = ROOT / 'Logs'
HIERARCHY_FILE = ROOT / 'lib' / 'data' / 'board_hierarchy.dart'

log_lines = []

def log(msg):
    print(msg)
    log_lines.append(msg)

def write_log():
    LOG_DIR.mkdir(exist_ok=True)
    (LOG_DIR / 'build_common_area.log').write_text('\n'.join(log_lines), encoding='utf-8')

def posix_rel(path: Path) -> str:
    return path.as_posix()

def load_asset_index():
    index = set()
    for p in ASSETS_DIR.rglob('*'):
        if p.is_file():
            rel = p.relative_to(ROOT).as_posix()
            index.add(rel)
    return index

def parse_md_hierarchy():
    text = MD_FILE.read_text(encoding='utf-8')
    # Extract the ``` code block
    m = re.search(r'```\n(.*?)```', text, re.S)
    if not m:
        raise RuntimeError('Could not find Full Hierarchy code block')
    block = m.group(1)

    stack = []
    entries = []  # (name, parent, depth)
    top_level = []
    order_counter = 0
    sort_orders = {}

    for raw_line in block.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue

        # Skip link placeholders like [Link to ...]
        if line.lstrip().startswith('['):
            continue

        # Compute indent by leading spaces (4 per level)
        stripped = line.lstrip()
        indent = len(line) - len(stripped)
        level = indent // 4
        name = stripped

        # Pop stack to the right level
        while len(stack) > level:
            stack.pop()

        parent = stack[-1] if stack else None
        stack.append(name)

        order_counter += 1
        sort_orders[name] = order_counter

        entries.append((name, parent, level))
        if level == 0:
            top_level.append(name)

    return entries, top_level, sort_orders

def update_board_hierarchy(entries):
    dart_list = ',\n'.join(
        f"  BoardHierarchyEntry('{name}', 'Common'{'' if parent is None else f', {repr(parent)}'})"
        for name, parent, _ in entries
    )
    dart_block = f"""const List<BoardHierarchyEntry> boardHierarchy = [
  BoardHierarchyEntry('Common Words', 'Common'),
  BoardHierarchyEntry('Subject Vocab', 'Subject Vocab'),
  BoardHierarchyEntry('Sign', 'Sign'),
  BoardHierarchyEntry('My School', 'My School'),
  BoardHierarchyEntry('Legends', 'Legends'),
  BoardHierarchyEntry('Recipes', 'Recipes'),
  BoardHierarchyEntry('Personal', 'Personal'),
  // --- Common area (from MD Files/AREA_COMMON.md) ---
{dart_list},
];"""

    text = HIERARCHY_FILE.read_text(encoding='utf-8')
    new_text = re.sub(
        r'const List<BoardHierarchyEntry> boardHierarchy = \[.*?\];',
        dart_block,
        text,
        flags=re.S,
    )
    HIERARCHY_FILE.write_text(new_text, encoding='utf-8')
    log(f'Updated {HIERARCHY_FILE.name} with {len(entries)} Common board entries.')

def remap_image(image: str, board_name: str, asset_index: set) -> tuple[str, bool]:
    """Return (new_path, changed). If unchanged, return original."""
    if not image or not isinstance(image, str):
        return image, False

    if image.startswith('data:'):
        return image, False

    filename = image.split('/')[-1]

    # 1. Main Boards / Small Words -> assets/Common/Small Words/Montessori/<category>
    if image.startswith('assets/symbols/1. Main Boards/Small Words/'):
        rest = image[len('assets/symbols/1. Main Boards/Small Words/'):]
        parts = rest.split('/')

        if len(parts) == 1:
            # Direct file under Small Words (no sub-category)
            new_path = f'assets/Common/Small Words/{parts[0]}'
            return (new_path, True) if new_path in asset_index else (image, False)

        old_category = parts[0]
        file_name = '/'.join(parts[1:])  # in case of deeper paths

        # Per user example, Abstract Noun maps to Noun
        category = 'Noun' if old_category == 'Abstract Noun' else old_category
        candidate = f'assets/Common/Small Words/Montessori/{category}/{file_name}'

        if candidate in asset_index:
            return candidate, True

        # Try same category without the Abstract Noun->Noun override
        fallback = f'assets/Common/Small Words/Montessori/{old_category}/{file_name}'
        if fallback in asset_index:
            return fallback, True

        # Last resort: search entire Common assets for this filename
        matches = [p for p in asset_index if p.endswith('/' + file_name)]
        if matches:
            return matches[0], True
        return image, False

    # 2. 1. Main Boards / other boards -> assets/Common/<rest>
    if image.startswith('assets/symbols/1. Main Boards/'):
        rest = image[len('assets/symbols/1. Main Boards/'):]
        candidate = f'assets/Common/{rest}'
        if candidate in asset_index:
            return candidate, True

        # Try uppercase/lowercase variant (some folders differ)
        for alt in [rest, rest.replace(' ', '%20')]:
            pass
        # Last resort: search by filename
        filename = rest.split('/')[-1]
        matches = [p for p in asset_index if p.endswith('/' + filename)]
        if matches:
            # Prefer a match in the same board prefix
            same_prefix = [m for m in matches if m.startswith('assets/Common/' + rest.split('/')[0] + '/')]
            return (same_prefix[0] if same_prefix else matches[0]), True
        return image, False

    # 3. 3. Lesson Vocab/English/Montessori/<file> -> assets/Common/Small Words/Montessori/<category>/<file> or Small Words top
    if image.startswith('assets/symbols/3. Lesson Vocab/English/Montessori/'):
        file_name = image.split('/')[-1]
        # Derive category from filename like "article [montessori].png"
        m = re.match(r'^([a-zA-Z ]+?)\s*\[', file_name)
        derived = m.group(1).strip() if m else None

        if derived:
            candidates = [
                f'assets/Common/Small Words/Montessori/{derived.title()}/{file_name}',
                f'assets/Common/Small Words/Montessori/{derived.capitalize()}/{file_name}',
                f'assets/Common/Small Words/{file_name}',
            ]
            for c in candidates:
                if c in asset_index:
                    return c, True

        # Try top-level Small Words
        top = f'assets/Common/Small Words/{file_name}'
        if top in asset_index:
            return top, True

        matches = [p for p in asset_index if p.endswith('/' + file_name)]
        if matches:
            return matches[0], True
        return image, False

    # Other assets/symbols/... paths: replace prefix to assets/Common if it makes sense
    if image.startswith('assets/symbols/'):
        # Generic fallback: try to find the file by name in assets/Common
        file_name = image.split('/')[-1]
        matches = [p for p in asset_index if p.endswith('/' + file_name)]
        if matches:
            return matches[0], True
        return image, False

    return image, False

def update_jsons(sort_orders, asset_index):
    changed_files = 0
    changed_images = 0
    missing = defaultdict(list)

    for json_path in BOARDS_DIR.rglob('*.json'):
        # Determine board name from file name or from parent folder
        name = json_path.stem.replace('prebuilt_', '').replace('_', ' ').title()
        # Use sort order from MD; if not in MD, leave as-is
        new_sort = sort_orders.get(name)

        try:
            text = json_path.read_text(encoding='utf-8')
            data = json.loads(text)
        except Exception as e:
            log(f'WARN: Could not parse {json_path}: {e}')
            continue

        file_changed = False

        if new_sort is not None and data.get('sortOrder') != new_sort:
            data['sortOrder'] = new_sort
            file_changed = True

        # Ensure area is Common
        if data.get('area') != 'Common':
            data['area'] = 'Common'
            file_changed = True

        for tile in data.get('tiles', []):
            old_image = tile.get('image')
            new_image, img_changed = remap_image(old_image, name, asset_index)
            if img_changed:
                tile['image'] = new_image
                changed_images += 1
                file_changed = True
                if new_image == old_image:
                    missing[name].append(old_image)
            # Map category 'Custom' for small-words Montessori tiles if appropriate
            # (user did not ask, so leave category as-is)

        if file_changed:
            json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')
            changed_files += 1

    log(f'Updated {changed_files} JSON files, remapped {changed_images} image paths.')
    if missing:
        log('WARNING: Some paths could not be resolved (kept old value):')
        for board, paths in sorted(missing.items()):
            for p in paths[:10]:
                log(f'  {board}: {p}')
            if len(paths) > 10:
                log(f'  ... and {len(paths) - 10} more in {board}')

def main():
    if not MD_FILE.exists():
        log(f'MD file not found: {MD_FILE}')
        write_log()
        return 1

    log('Building Common area from MD Files/AREA_COMMON.md')
    entries, top_level, sort_orders = parse_md_hierarchy()
    log(f'Found {len(entries)} Common boards, {len(top_level)} top-level tabs.')
    log('Top-level tab order: ' + ', '.join(top_level))

    log('Indexing assets/Common...')
    asset_index = load_asset_index()
    log(f'Indexed {len(asset_index)} files in assets/Common.')

    log('Updating board hierarchy...')
    update_board_hierarchy(entries)

    log('Updating prebuilt board JSONs...')
    update_jsons(sort_orders, asset_index)

    log('Done.')
    write_log()
    return 0

if __name__ == '__main__':
    sys.exit(main())
