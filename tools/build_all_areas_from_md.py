#!/usr/bin/env python3
"""Build/update board JSONs, hierarchy, index and pubspec from AREA_*.md files."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MD_DIR = ROOT / 'MD Files'
BOARDS_DIR = ROOT / 'lib' / 'data' / 'boards'
HIERARCHY_FILE = ROOT / 'lib' / 'data' / 'board_hierarchy.dart'
RUNTIME_FILE = ROOT / 'lib' / 'data' / 'runtime_hierarchy.json'
INDEX_FILE = ROOT / 'lib' / 'data' / 'board_index.dart'
PUBSPEC = ROOT / 'pubspec.yaml'

AREA_FILES = [
    ('Common', 'AREA_COMMON.md'),
    ('Subject Vocab', 'AREA_SUBJECT_VOCAB.md'),
    ('My School', 'AREA_MY_SCHOOL.md'),
    ('Legends', 'AREA_LEGENDS.md'),
    ('Recipes', 'AREA_RECIPES.md'),
    ('Sign', 'AREA_SIGN.md'),
    ('Personal', 'AREA_PERSONAL.md'),
]

ROOT_ALIASES = {
    'Subject Vocabulary': 'Subject Vocab',
    'Sign Main': 'Sign',
    'Recipes Main': 'Recipes',
}


DEFAULT_BOARD = {
    'rows': 4,
    'columns': 6,
    'adjustableLayout': False,
    'boxScale': 1.0,
    'tileHeight': 100.0,
    'tileWidth': 100.0,
    'backgroundColor': '#FFFFFF',
    'tiles': [],
    'version': 0,
}


def safe_id(name: str) -> str:
    if name.lower() == 'a-z of sign':
        return 'prebuilt_a_to_z_of_sign'
    safe = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')
    safe = re.sub(r'_+$', '', safe)
    return f'prebuilt_{safe}'


def is_link(name: str) -> bool:
    return name.startswith('[Link to') or name.endswith(']')


def parse_tab_order(text: str):
    """Extract top-level tab order from the first ## Tab Order table."""
    names = []
    m = re.search(r'## Tab Order.*?(\n\|[-\s\|]+\|\n.*?)(?=\n##|\n---|\Z)', text, re.S)
    if not m:
        return names
    for line in m.group(1).splitlines():
        if '|' not in line:
            continue
        parts = [p.strip() for p in line.split('|')]
        parts = [p for p in parts if p]
        if len(parts) >= 2 and parts[0].replace('.', '').isdigit():
            n = parts[1]
            if not is_link(n) and not n.startswith('*'):
                names.append(n)
    return names


def parse_full_hierarchy(text: str):
    """Parse the ``` code block as a tree (4 spaces per level)."""
    m = re.search(r'```\n(.*?)```', text, re.S)
    if not m:
        return []
    block = m.group(1)
    stack = []
    entries = []
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        if is_link(line.lstrip()):
            continue
        stripped = line.lstrip()
        if stripped.startswith('*'):
            continue
        indent = len(line) - len(stripped)
        level = indent // 4
        while len(stack) > level:
            stack.pop()
        parent = stack[-1] if stack else None
        stack.append(stripped)
        entries.append((stripped, parent))
    return entries


def parse_subboard_sections(text: str):
    """For AREA_SUBJECT_VOCAB: parse ### Parent > Sub-boards bullet lists."""
    entries = []
    for m in re.finditer(r'###\s+(.+?)\s*\n', text):
        heading = m.group(1).strip()
        if '>' not in heading:
            continue
        chain = [p.strip() for p in heading.split('>') if p.strip()]
        if not chain or chain[-1].lower().startswith('sub'):
            chain = chain[:-1]
        section_parent = chain[-1] if chain else None
        start = m.end()
        next_h = re.search(r'\n#{2,6}\s', text[start:])
        section = text[start:start + (next_h.start() if next_h else len(text))]
        stack = []
        for raw in section.splitlines():
            if not raw.strip():
                continue
            stripped = raw.lstrip()
            if not stripped.startswith('- '):
                continue
            indent = len(raw) - len(stripped)
            level = indent // 2
            name = stripped[2:].strip()
            if is_link(name):
                continue
            while len(stack) > level:
                stack.pop()
            parent = stack[-1] if stack else section_parent
            stack.append(name)
            entries.append((name, parent))
    return entries


def canonical(name: str | None) -> str | None:
    if name is None:
        return None
    return ROOT_ALIASES.get(name, name)


def parse_area(area: str, filename: str):
    path = MD_DIR / filename
    text = path.read_text(encoding='utf-8')
    top_level = [canonical(n) for n in parse_tab_order(text)]
    entries = parse_full_hierarchy(text)
    if not entries and area == 'Subject Vocab':
        entries = parse_subboard_sections(text)

    # Disambiguate child boards that share a name with a top-level board
    disambiguate = {
        ('Prepositions', 'Small Words'): 'Prepositions (Montessori)',
    }
    entries = [(disambiguate.get((n, p), n), p) for n, p in entries]
    # If the full hierarchy did not include a top-level entry, add from table
    present = {e[0].lower() for e in entries}
    for n in top_level:
        if n.lower() not in present:
            entries.append((n, None))
    # Canonicalise names/parents (root aliases)
    canon_entries = [(canonical(n), canonical(p)) for n, p in entries]
    # Determine the set of top-level boards
    top_set = {n.lower() for n, p in canon_entries if p is None}
    top_set.update(n.lower() for n in top_level)
    # Build children tree, ignoring entries that claim a top-level board as a child
    children = {}
    for name, parent in canon_entries:
        if name is None:
            continue
        # If a board is both a top-level and a child, the top-level wins
        if parent is not None and name.lower() in top_set:
            continue
        children.setdefault(parent, []).append(name)
    # Walk top-level boards in tab order, then recursively through children
    ordered = []
    seen = set()

    def walk(name: str, parent: str | None):
        key = name.lower()
        if key in seen:
            return
        seen.add(key)
        ordered.append((name, parent))
        for c in children.get(name, []):
            walk(c, name)

    for t in top_level:
        walk(t, None)
    # Pick up any remaining top-level entries not in the tab-order table
    for n, p in canon_entries:
        if p is None:
            walk(n, None)
    # Fallback for empty areas (e.g. Personal)
    if not ordered:
        ordered = [(area, None)]
    top_level = [n for n, p in ordered if p is None]
    return top_level, ordered


def index_existing_boards():
    by_name = {}
    by_id = {}
    by_path = {}
    for p in BOARDS_DIR.rglob('*.json'):
        try:
            data = json.loads(p.read_text(encoding='utf-8'))
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        by_path[p] = data
        if data.get('name'):
            by_name[data['name'].lower()] = data
        if data.get('id'):
            by_id[data['id'].lower()] = data
    return by_name, by_id, by_path


def get_or_compute_id(name: str, by_name, by_id):
    data = by_name.get(name.lower())
    if data and data.get('id'):
        return data['id']
    base = safe_id(name)
    uid = base
    n = 2
    while uid.lower() in by_id:
        uid = f'{base}_{n}'
        n += 1
    return uid


def compute_tier(parent_tier: int) -> int:
    return parent_tier + 1


def folder_name(name: str) -> str:
    """Convert a board name to a Windows-safe directory name."""
    n = re.sub(r'[\\/*?:"<>|]', '_', name)
    n = re.sub(r'_+', '_', n)
    n = n.strip().rstrip('. ')
    n = re.sub(r' +', ' ', n)
    return n


def determine_folder(name: str, area: str, parent: str | None, folders: dict):
    """Return a Path relative to BOARDS_DIR for the board's folder."""
    nm = folder_name(name)
    if parent is None:
        return BOARDS_DIR / area / nm
    parent_folder = folders.get(parent.lower())
    if parent_folder is None:
        return BOARDS_DIR / area / folder_name(parent) / nm
    return parent_folder / nm


def update_json(path: Path, data: dict, name: str, area: str, parent_id: str | None, sort_order: int, tier: int):
    data['id'] = data.get('id') or safe_id(name)
    data['name'] = name
    data['area'] = area
    data['parentBoardId'] = parent_id
    data['sortOrder'] = sort_order
    data['tier'] = tier
    data['isSubBoard'] = tier >= 2
    data['isTertiaryBoard'] = tier >= 3
    data['isQuaternaryBoard'] = tier >= 4
    data['isQuinaryBoard'] = tier >= 5
    for k, v in DEFAULT_BOARD.items():
        if k not in data:
            data[k] = v
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def main():
    by_name, by_id, by_path = index_existing_boards()
    data_to_path = {id(d): p for p, d in by_path.items()}
    folder_for = {}
    for p, d in by_path.items():
        if d.get('name'):
            folder_for[d['name'].lower()] = p.parent
    all_entries = []  # (name, area, parent)
    area_top = {}
    sort_counter = 0
    id_for = {}       # lower name -> id
    # folder_for already initialised from existing boards
    created = 0
    updated = 0
    skipped_links = 0

    for area, filename in AREA_FILES:
        top_level, ordered = parse_area(area, filename)
        area_top[area] = top_level
        # Build map from name to actual id
        for name, _ in ordered:
            id_for[name.lower()] = get_or_compute_id(name, by_name, by_id)

        for idx, (name, parent) in enumerate(ordered, start=1):
            if is_link(name):
                skipped_links += 1
                continue
            sort_counter += 1
            parent_id = id_for.get(parent.lower()) if parent else None
            tier = 1
            if parent:
                # find parent's tier from already processed entries; fallback to 1
                # We don't have tier map until we process, so compute by depth walking parent
                # The MD entries are DFS, parent before children
                pass
            all_entries.append((name, area, parent))

    # Compute tier by walking parent chains
    name_to_parent = {n.lower(): (p.lower() if p else None) for n, a, p in all_entries}
    tiers = {}

    def t_of(n):
        if n in tiers:
            return tiers[n]
        p = name_to_parent.get(n)
        if p is None:
            return 1
        tiers[n] = t_of(p) + 1
        return tiers[n]

    for n, _, _ in all_entries:
        tiers[n.lower()] = t_of(n.lower())

    # Second pass: create/update JSON
    for name, area, parent in all_entries:
        if is_link(name):
            continue
        data = by_name.get(name.lower())
        if not data:
            # find by computed id
            bid = id_for[name.lower()]
            data = by_id.get(bid.lower())
        if data:
            path = data_to_path.get(id(data))
        else:
            path = None
        if not data:
            data = {}
        bid = id_for[name.lower()]
        parent_id = id_for[parent.lower()] if parent else None
        sort_counter_global = 0  # assigned later; placeholder
        tier = tiers[name.lower()]
        folder = determine_folder(name, area, parent, folder_for)
        folder_for[name.lower()] = folder
        if path is None:
            path = folder / f'{bid}.json'
        if not path.exists() or (data and not data.get('tiles')):
            # Create new
            if not path.exists():
                path.parent.mkdir(parents=True, exist_ok=True)
                created += 1
            else:
                updated += 1
        else:
            updated += 1
        # Determine sort order: use global position among all entries for now
        # This will be fixed in a second step using ordered list.

    # Second pass: create/update JSON
    for i, (name, area, parent) in enumerate(all_entries):
        if is_link(name):
            continue
        data = by_name.get(name.lower())
        if not data:
            bid = id_for[name.lower()]
            data = by_id.get(bid.lower())
        if not data:
            bid = id_for[name.lower()]
            data = {}
            created += 1
        else:
            bid = data.get('id', id_for[name.lower()])
        folder = folder_for[name.lower()]
        path = data_to_path.get(id(data)) if data else None
        if not path:
            path = folder / f'{bid}.json'
        parent_id = id_for[parent.lower()] if parent else None
        update_json(path, data, name, area, parent_id, i + 1, tiers[name.lower()])
        by_path[path] = data
        data_to_path[id(data)] = path
        by_name[name.lower()] = data
        by_id[bid.lower()] = data

    # Update board_hierarchy.dart
    dart_lines = []
    for area, _ in AREA_FILES:
        dart_lines.append(f"  // --- {area.upper()} AREA ---")
        for name, a, parent in all_entries:
            if a == area:
                if parent:
                    dart_lines.append(f"  BoardHierarchyEntry('{name.replace(chr(39), chr(92)+chr(39))}', '{a}', '{parent.replace(chr(39), chr(92)+chr(39))}'),")
                else:
                    dart_lines.append(f"  BoardHierarchyEntry('{name.replace(chr(39), chr(92)+chr(39))}', '{a}'),")
    dart_block = 'const List<BoardHierarchyEntry> boardHierarchy = [\n' + '\n'.join(dart_lines) + '\n];'
    old_text = HIERARCHY_FILE.read_text(encoding='utf-8')
    new_text = re.sub(r'const List<BoardHierarchyEntry> boardHierarchy = \[.*?\];', dart_block, old_text, flags=re.S)
    HIERARCHY_FILE.write_text(new_text, encoding='utf-8')

    # Update runtime_hierarchy.json
    runtime_entries = []
    for name, a, parent in all_entries:
        e = {'name': name, 'area': a}
        if parent:
            e['parentName'] = parent
        runtime_entries.append(e)
    RUNTIME_FILE.write_text(json.dumps({'entries': runtime_entries}, indent=2, ensure_ascii=False), encoding='utf-8')

    # Regenerate board_index.dart
    boards = []
    for p in sorted(BOARDS_DIR.rglob('*.json')):
        try:
            d = json.loads(p.read_text(encoding='utf-8'))
        except Exception:
            continue
        if not isinstance(d, dict):
            continue
        boards.append(d)
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        f.write('// AUTO-GENERATED by tools/build_all_areas_from_md.py - do not edit manually.\n\n')
        f.write('class BoardIndexEntry {\n')
        for line in [
            '  final String id;',
            '  final String name;',
            '  final String area;',
            '  final String? parentBoardId;',
            '  final bool isSubBoard;',
            '  final bool isTertiaryBoard;',
            '  final bool isQuaternaryBoard;',
            '  final bool isQuinaryBoard;',
            '  final int sortOrder;',
            '  final int tier;',
            '  final String? iconAssetPath;',
            '',
            '  const BoardIndexEntry({',
            '    required this.id,',
            '    required this.name,',
            '    required this.area,',
            '    this.parentBoardId,',
            '    this.isSubBoard = false,',
            '    this.isTertiaryBoard = false,',
            '    this.isQuaternaryBoard = false,',
            '    this.isQuinaryBoard = false,',
            '    this.sortOrder = 0,',
            '    this.tier = 1,',
            '    this.iconAssetPath,',
            '  });',
            '}',
            '',
            'const List<BoardIndexEntry> staticBoardIndex = [',
        ]:
            f.write(line + '\n')
        for d in boards:
            f.write('  BoardIndexEntry(\n')
            f.write(f"    id: '{d.get('id', '')}',\n")
            name = d.get('name', 'Board').replace("'", "\\'")
            f.write(f"    name: '{name}',\n")
            f.write(f"    area: '{d.get('area', 'Common')}',\n")
            if d.get('parentBoardId'):
                f.write(f"    parentBoardId: '{d['parentBoardId']}',\n")
            f.write(f"    isSubBoard: {str(d.get('isSubBoard', False)).lower()},\n")
            f.write(f"    isTertiaryBoard: {str(d.get('isTertiaryBoard', False)).lower()},\n")
            f.write(f"    isQuaternaryBoard: {str(d.get('isQuaternaryBoard', False)).lower()},\n")
            f.write(f"    isQuinaryBoard: {str(d.get('isQuinaryBoard', False)).lower()},\n")
            f.write(f"    sortOrder: {d.get('sortOrder', 0)},\n")
            f.write(f"    tier: {d.get('tier', 1)},\n")
            if d.get('iconAssetPath'):
                f.write(f"    iconAssetPath: '{d['iconAssetPath']}',\n")
            f.write('  ),\n')
        f.write('];\n')

    # Rebuild pubspec assets
    if PUBSPEC.exists():
        text = PUBSPEC.read_text(encoding='utf-8')
        lines = text.splitlines(keepends=True)
        assets_start = None
        assets_end = None
        for i, line in enumerate(lines):
            if assets_start is None and line.strip() == 'assets:':
                assets_start = i
            elif assets_start is not None:
                if line.strip() and not line.startswith(' ') and not line.startswith('\t'):
                    assets_end = i
                    break
        if assets_start is not None:
            keep = []
            for line in lines[assets_start + 1:assets_end]:
                if re.search(r"lib/data/boards/([^'\"\s]+)", line):
                    continue
                keep.append(line)
            board_entries = []
            for area_dir in sorted(BOARDS_DIR.iterdir()):
                if not area_dir.is_dir():
                    continue
                board_entries.append(f"    - lib/data/boards/{area_dir.name}/\n")
                for sub in sorted(area_dir.rglob('*')):
                    if sub.is_dir():
                        rel = sub.relative_to(ROOT)
                        board_entries.append(f"    - {rel.as_posix()}/\n")
            out = lines[:assets_start + 1] + keep + board_entries + lines[assets_end:]
            PUBSPEC.write_text(''.join(out), encoding='utf-8')

    print(f'Created {created} new JSON board(s).')
    print(f'Updated {updated} existing JSON board metadata.')
    print(f'Skipped {skipped_links} [Link to ...] entries.')
    print(f'Registered {len(all_entries)} entries in hierarchy.')


if __name__ == '__main__':
    main()
