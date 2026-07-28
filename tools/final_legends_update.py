import json
import re
import shutil
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

def load_json(p):
    with open(p, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(p, data):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def safe_id(name):
    safe = re.sub(r"[<>:\"/\\\\|?*]", '_', name).strip()
    safe = re.sub(r'_+$', '', safe)
    safe = re.sub(r'[^a-zA-Z0-9_]+', '_', safe).strip('_')
    return 'prebuilt_' + safe.lower()

def remove_if_exists(p):
    if not p.exists():
        return False
    if p.is_dir():
        shutil.rmtree(p)
    else:
        p.unlink()
    return True

def delete_origins():
    """Remove the original Common/Subject Vocab locations that are now in Legends."""
    origins = [
        BOARDS_DIR / 'Common' / 'People' / 'Characters',
        BOARDS_DIR / 'Common' / 'Time' / 'Events & Occasions' / 'Halloween Keywords',
        BOARDS_DIR / 'Subject Vocab' / 'Religion & Worldviews',
    ]
    for p in origins:
        if remove_if_exists(p):
            print(f'Removed origin {p.relative_to(ROOT)}')

def delete_stale_legends_root():
    for p in [BOARDS_DIR / 'Legends' / 'prebuilt_characters.json',
              BOARDS_DIR / 'Legends' / 'Characters - Word List.txt']:
        if p.exists():
            p.unlink()
            print(f'Removed stale {p.relative_to(ROOT)}')

def neutralize_characters_tile():
    people = BOARDS_DIR / 'Common' / 'People' / 'prebuilt_people.json'
    if not people.exists():
        return
    data = load_json(people)
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
        save_json(people, data)
        print('Neutralized Characters tile in prebuilt_people.json')

def move_main_boards():
    """Promote MAIN/prebuilt_main.json in any area root to the parent folder."""
    for area_dir in BOARDS_DIR.iterdir():
        if not area_dir.is_dir():
            continue
        main_dir = area_dir / 'MAIN'
        main_json = main_dir / 'prebuilt_main.json'
        if not main_json.exists():
            continue
        data = load_json(main_json)
        folder_name = area_dir.name
        new_id = safe_id(folder_name)
        old_id = data['id']
        new_path = area_dir / f'{new_id}.json'
        # avoid collision
        if new_path.exists():
            new_path = area_dir / f'{new_id}_main.json'
        data['id'] = new_id
        data['name'] = folder_name
        save_json(new_path, data)
        shutil.rmtree(main_dir)
        print(f'Promoted {main_json.relative_to(ROOT)} to {new_path.relative_to(ROOT)}')
        # update references across all JSONs
        if old_id != new_id:
            for p in BOARDS_DIR.rglob('*.json'):
                try:
                    d = load_json(p)
                except Exception:
                    continue
                changed = False
                if d.get('parentBoardId') == old_id:
                    d['parentBoardId'] = new_id
                    changed = True
                for tile in d.get('tiles', []):
                    if tile.get('linkedBoardName') == old_id:
                        tile['linkedBoardName'] = new_id
                        changed = True
                if changed:
                    save_json(p, d)

def load_all_jsons():
    boards = {}
    for p in BOARDS_DIR.rglob('*.json'):
        try:
            boards[p] = load_json(p)
        except Exception:
            pass
    return boards

def get_board_dirs():
    """Return mapping from directory path to the .json board file it contains (if any)."""
    dirs = {}
    for p, data in load_all_jsons().items():
        if p.parent in dirs:
            # prefer existing? Should be only one per board dir; keep first
            pass
        else:
            dirs[p.parent] = p
    return dirs

def find_parent_id(path, board_dirs):
    """Find nearest ancestor directory that is a board dir (not the current folder)."""
    parent = path.parent.parent
    while True:
        if parent in board_dirs:
            candidate = board_dirs[parent]
            candidate_data = load_json(candidate)
            # ensure we don't return the file itself (should not happen)
            if candidate != path:
                return candidate_data['id'], candidate_data.get('tier', 1)
        if parent == BOARDS_DIR or parent.parent == parent:
            break
        parent = parent.parent
    return None, 0

def compute_tier(path, board_dirs):
    """Count board dirs along path from area root up to and including this board."""
    area_root = BOARDS_DIR / path.relative_to(BOARDS_DIR).parts[0]
    current = path.parent
    count = 0
    # walk up until area root exclusive
    while current != area_root and current != BOARDS_DIR and current != current.parent:
        if current in board_dirs:
            count += 1
        current = current.parent
    # this board itself is a board dir
    if path.parent in board_dirs:
        count += 1
    return max(1, count)

def update_legends_jsons():
    """Update all Legends board JSONs with correct area, tier, parent and sort order."""
    all_boards = load_all_jsons()
    board_dirs = get_board_dirs()

    # update all Legends files
    for p, data in all_boards.items():
        rel = p.relative_to(BOARDS_DIR)
        if rel.parts[0] != 'Legends':
            continue
        tier = compute_tier(p, board_dirs)
        parent_id, parent_tier = find_parent_id(p, board_dirs)
        if parent_id:
            data['parentBoardId'] = parent_id
        else:
            data['parentBoardId'] = None
        data['area'] = 'Legends'
        data['tier'] = tier
        data['isSubBoard'] = tier >= 2
        data['isTertiaryBoard'] = tier >= 3
        data['isQuaternaryBoard'] = tier >= 4
        data['isQuinaryBoard'] = tier >= 5
        if tier == 1:
            name = data.get('name', '')
            if name.lower() in LEGENDS_ORDER_LOWER:
                data['sortOrder'] = (LEGENDS_ORDER_LOWER[name.lower()] + 1) * 10
        save_json(p, data)
    print('Updated all Legends JSON files')

def gather_hierarchy_entries():
    area_order = {'Common': 0, 'Legends': 1, 'Recipes': 2, 'Subject Vocab': 3, 'Sign': 4, 'My School': 5, 'Personal': 6}
    entries = []
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        area = area_dir.name
        files = sorted(area_dir.rglob('*.json'))
        # collect (rel, data)
        for p in files:
            data = load_json(p)
            entries.append((area, str(p.relative_to(BOARDS_DIR)), data))
    entries.sort(key=lambda t: (area_order.get(t[0], 99), t[1]))
    return entries

def rebuild_hierarchy():
    with open(HIERARCHY_BAK, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    start_line = end_line = None
    for i, line in enumerate(lines):
        if start_line is None and 'const List<BoardHierarchyEntry> boardHierarchy = [' in line:
            start_line = i
        elif start_line is not None and end_line is None and line.strip() == '];':
            end_line = i
            break
    if start_line is None or end_line is None:
        raise RuntimeError('Hierarchy markers not found')

    entries = gather_hierarchy_entries()
    id_to_name = {e[2]['id']: e[2]['name'] for e in entries}

    def esc(s):
        return s.replace("'", "\\'")
    list_lines = []
    current_area = None
    for area, rel, data in entries:
        name = data.get('name', 'Board')
        pid = data.get('parentBoardId')
        pname = id_to_name.get(pid) if pid else None
        if current_area != area:
            if current_area is not None:
                list_lines.append('')
            list_lines.append(f"  // {'─' * 46}")
            list_lines.append(f"  //  {area.upper()} AREA")
            list_lines.append(f"  // {'─' * 46}")
            current_area = area
        if pname:
            list_lines.append(f"  BoardHierarchyEntry('{esc(name)}', '{esc(area)}', '{esc(pname)}'),")
        else:
            list_lines.append(f"  BoardHierarchyEntry('{esc(name)}', '{esc(area)}'),")

    out = lines[:start_line + 1] + ['\n'.join(list_lines) + '\n'] + lines[end_line:]
    with open(HIERARCHY_OUT, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Rebuilt {HIERARCHY_OUT}')

def regenerate_board_index():
    entries = gather_hierarchy_entries()
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

        for area, rel, data in entries:
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
    print(f'Regenerated {INDEX_OUT} with {len(entries)} entries')

def update_pubspec():
    with open(PUBSPEC, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    assets_start = assets_end = None
    for i, line in enumerate(lines):
        if assets_start is None and line.strip() == 'assets:':
            assets_start = i
        elif assets_start is not None:
            if line.strip() and not line.startswith(' ') and not line.startswith('\t'):
                assets_end = i
                break
    if assets_start is None:
        print('WARNING: no assets section in pubspec.yaml')
        return

    keep = []
    for line in lines[assets_start + 1:assets_end]:
        m = re.search(r"lib/data/boards/([^'\"\s]+)", line)
        if m:
            # drop old board asset entries; we regenerate them
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
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Updated {PUBSPEC} with {len(board_entries)} board asset entries')

def main():
    delete_origins()
    delete_stale_legends_root()
    neutralize_characters_tile()
    move_main_boards()
    update_legends_jsons()
    rebuild_hierarchy()
    regenerate_board_index()
    update_pubspec()

if __name__ == '__main__':
    main()
