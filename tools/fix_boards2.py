import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT / 'lib' / 'data' / 'boards'
HIERARCHY_BAK = ROOT / 'lib' / 'data' / 'board_hierarchy.dart.bak'
HIERARCHY_OUT = ROOT / 'lib' / 'data' / 'board_hierarchy.dart'
INDEX_OUT = ROOT / 'lib' / 'data' / 'board_index.dart'
PUBSPEC = ROOT / 'pubspec.yaml'

LEGENDS_ORDER = [
    'Gods, Titans, Heroes & Monsters',
    'Heroes & Monsters (Greek & Roman)',
    'Creatures & Races',
    'Fairy Tale Characters',
    'Disney Stories',
    'D&D',
    'Arthurian Legend',
    'Arabian & Middle Eastern Tales',
    'Asian Legends & Folklore',
    'Horror Icons',
    'Halloween Keywords',
    'Legendary Heroes & Folk Heroes',
    'Literary & Gothic Characters',
    'Religion & Worldviews',
    'Marvel',
    'X-Men',
    'DC',
    'The Muppets',
    'Star Wars',
    'Star Trek',
    'The Lord Of The Rings',
    'Computer Games',
    'Misc',
]
LEGENDS_ORDER_LOWER = {n.lower(): i for i, n in enumerate(LEGENDS_ORDER)}

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def board_id_from_folder(name):
    safe = re.sub(r"[<>:\"/\\\\|?*]", '_', name).strip()
    safe = re.sub(r'_+$', '', safe)
    safe = re.sub(r'[^a-zA-Z0-9_]+', '_', safe).strip('_')
    return 'prebuilt_' + safe.lower()

def find_parent_id(parent_dir):
    if not parent_dir.is_dir():
        return None
    for f in parent_dir.iterdir():
        if f.is_file() and f.suffix == '.json':
            try:
                return load_json(f)['id']
            except Exception:
                continue
    return None

def update_board_json(path):
    rel = path.relative_to(BOARDS_DIR)
    parts = rel.parts
    area = parts[0]
    # number of directory levels below the area root
    depth = len(parts) - 2  # area + N dirs + file -> N = len-2
    if depth < 1:
        depth = 1
    data = load_json(path)
    data['area'] = area
    data['tier'] = depth
    data['isSubBoard'] = depth >= 2
    data['isTertiaryBoard'] = depth >= 3
    data['isQuaternaryBoard'] = depth >= 4
    data['isQuinaryBoard'] = depth >= 5

    if depth <= 1:
        data['parentBoardId'] = None
        if area == 'Legends' and data.get('name'):
            name = data['name']
            if name.lower() in LEGENDS_ORDER_LOWER:
                data['sortOrder'] = (LEGENDS_ORDER_LOWER[name.lower()] + 1) * 10
    else:
        parent_dir = path.parent.parent
        parent_id = find_parent_id(parent_dir)
        if parent_id:
            data['parentBoardId'] = parent_id

    save_json(path, data)
    return data

def remove_stale_characters():
    chars_json = BOARDS_DIR / 'Legends' / 'prebuilt_characters.json'
    chars_txt = BOARDS_DIR / 'Legends' / 'Characters - Word List.txt'
    if chars_json.exists():
        chars_json.unlink()
        print('Removed stale Legends/prebuilt_characters.json')
    if chars_txt.exists():
        chars_txt.unlink()
        print('Removed stale Legends/Characters - Word List.txt')

def neutralize_people_characters_tile():
    people_json = BOARDS_DIR / 'Common' / 'People' / 'prebuilt_people.json'
    if not people_json.exists():
        return
    data = load_json(people_json)
    changed = False
    for tile in data.get('tiles', []):
        if tile.get('linkedBoardName') == 'prebuilt_characters':
            tile['type'] = 'blank'
            tile['label'] = ''
            tile['image'] = None
            tile['linkedBoardName'] = None
            tile['customVoice'] = ''
            changed = True
    if changed:
        save_json(people_json, data)
        print('Neutralized Characters tile in prebuilt_people.json')

def gather_boards():
    """Return list of (area, rel, data) sorted by area and path."""
    boards = []
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        for json_file in sorted(area_dir.rglob('*.json')):
            rel = json_file.relative_to(BOARDS_DIR)
            data = load_json(json_file)
            boards.append((area_dir.name, rel, data))
    return boards

def generate_hierarchy_list(boards):
    area_order = {'Common': 0, 'Legends': 1, 'Recipes': 2, 'Subject Vocab': 3, 'Sign': 4, 'My School': 5, 'Personal': 6}
    # sort boards by area order, then by path
    boards.sort(key=lambda t: (area_order.get(t[0], 99), str(t[1])))

    id_to_name = {b[2]['id']: b[2]['name'] for b in boards}

    lines = []
    current_area = None
    for area, rel, data in boards:
        name = data.get('name', 'Board')
        parent_id = data.get('parentBoardId')
        parent_name = id_to_name.get(parent_id) if parent_id else None
        if current_area != area:
            if current_area is not None:
                lines.append('')
            lines.append(f"  // {'─' * 46}")
            lines.append(f"  //  {area.upper()} AREA")
            lines.append(f"  // {'─' * 46}")
            current_area = area
        if parent_name:
            lines.append(f"  BoardHierarchyEntry('{_esc(name)}', '{_esc(area)}', '{_esc(parent_name)}'),")
        else:
            lines.append(f"  BoardHierarchyEntry('{_esc(name)}', '{_esc(area)}'),")
    return '\n'.join(lines) + '\n'

def _esc(s):
    return s.replace("'", "\\'")

def rebuild_hierarchy():
    with open(HIERARCHY_BAK, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    start_line = None
    end_line = None
    for i, line in enumerate(lines):
        if start_line is None and 'const List<BoardHierarchyEntry> boardHierarchy = [' in line:
            start_line = i
        if start_line is not None and end_line is None and line.strip() == '];':
            end_line = i
            break

    if start_line is None or end_line is None:
        raise RuntimeError(f'Could not locate const list markers in {HIERARCHY_BAK}')

    boards = gather_boards()
    new_list = generate_hierarchy_list(boards)

    out = lines[:start_line + 1] + [new_list] + lines[end_line:]
    with open(HIERARCHY_OUT, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Rebuilt {HIERARCHY_OUT}')

def generate_board_index():
    boards = gather_boards()
    with open(INDEX_OUT, 'w', encoding='utf-8') as f:
        f.write('// AUTO-GENERATED by tools/generate_board_index.py - do not edit manually.\n\n')
        f.write('class BoardIndexEntry {\n')
        f.write('  final String id;\n')
        f.write('  final String name;\n')
        f.write('  final String area;\n')
        f.write('  final String? parentBoardId;\n')
        f.write('  final bool isSubBoard;\n')
        f.write('  final bool isTertiaryBoard;\n')
        f.write('  final bool isQuaternaryBoard;\n')
        f.write('  final bool isQuinaryBoard;\n')
        f.write('  final int sortOrder;\n')
        f.write('  final int tier;\n')
        f.write('  final String? iconAssetPath;\n\n')
        f.write('  const BoardIndexEntry({\n')
        f.write('    required this.id,\n')
        f.write('    required this.name,\n')
        f.write('    required this.area,\n')
        f.write('    this.parentBoardId,\n')
        f.write('    this.isSubBoard = false,\n')
        f.write('    this.isTertiaryBoard = false,\n')
        f.write('    this.isQuaternaryBoard = false,\n')
        f.write('    this.isQuinaryBoard = false,\n')
        f.write('    this.sortOrder = 0,\n')
        f.write('    this.tier = 1,\n')
        f.write('    this.iconAssetPath,\n')
        f.write('  });\n')
        f.write('}\n\n')
        f.write('const List<BoardIndexEntry> staticBoardIndex = [\n')

        for area, rel, data in boards:
            name = data.get('name', 'Board').replace("'", "\\'")
            f.write('  BoardIndexEntry(\n')
            f.write(f"    id: '{data.get('id', '')}',\n")
            f.write(f"    name: '{name}',\n")
            f.write(f"    area: '{data.get('area', 'Common')}',\n")
            if data.get('parentBoardId'):
                f.write(f"    parentBoardId: '{data['parentBoardId']}',\n")
            f.write(f"    isSubBoard: {'true' if data.get('isSubBoard') else 'false'},\n")
            f.write(f"    isTertiaryBoard: {'true' if data.get('isTertiaryBoard') else 'false'},\n")
            f.write(f"    isQuaternaryBoard: {'true' if data.get('isQuaternaryBoard') else 'false'},\n")
            f.write(f"    isQuinaryBoard: {'true' if data.get('isQuinaryBoard') else 'false'},\n")
            f.write(f"    sortOrder: {data.get('sortOrder', 0)},\n")
            f.write(f"    tier: {data.get('tier', 1)},\n")
            if data.get('iconAssetPath'):
                f.write(f"    iconAssetPath: '{data['iconAssetPath']}',\n")
            f.write('  ),\n')
        f.write('];\n')
    print(f'Regenerated {INDEX_OUT} with {len(boards)} entries')

def rebuild_pubspec_assets():
    with open(PUBSPEC, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    assets_start = None
    assets_end = None
    for i, line in enumerate(lines):
        if assets_start is None and line.strip() == 'assets:':
            assets_start = i
        elif assets_start is not None:
            # end when a line is not indented (and not blank)
            if line.strip() and not line.startswith(' ') and not line.startswith('\t'):
                assets_end = i
                break
    if assets_start is None:
        print('WARNING: no assets section in pubspec.yaml')
        return

    # keep all non-board asset lines and any board area directory lines for non-data/boards
    keep = []
    for line in lines[assets_start + 1:assets_end]:
        m = re.search(r"lib/data/boards/([^'\"\s]+)", line)
        if m:
            # skip all existing lib/data/boards entries; we'll regenerate them
            continue
        keep.append(line)

    board_entries = []
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        # paths relative to project root
        board_entries.append(f"    - lib/data/boards/{area_dir.name}/\n")
        for sub in sorted(area_dir.rglob('*')):
            if sub.is_dir():
                rel = sub.relative_to(ROOT)
                board_entries.append(f"    - {rel.as_posix()}/\n")

    out = lines[:assets_start + 1] + keep + board_entries + lines[assets_end:]
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Rebuilt pubspec.yaml asset entries ({len(board_entries)} board dirs)')

def main():
    remove_stale_characters()
    neutralize_people_characters_tile()
    for json_file in BOARDS_DIR.rglob('*.json'):
        if json_file.is_file():
            update_board_json(json_file)

    rebuild_hierarchy()
    generate_board_index()
    rebuild_pubspec_assets()

if __name__ == '__main__':
    main()
