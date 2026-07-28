import json
import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT / 'lib' / 'data' / 'boards'
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

def safe_folder_to_id(name):
    # matches board_service._boardFolderName and hierarchy id generator
    safe = re.sub(r"[<>:\"/\\\\|?*]", '_', name).strip()
    safe = re.sub(r'_+$', '', safe)
    safe = re.sub(r'[^a-zA-Z0-9_]+', '_', safe).strip('_')
    return 'prebuilt_' + safe.lower()

def find_parent_board_id(rel_parts):
    """Given path parts after the area root, return the parent board id or None."""
    if len(rel_parts) <= 2:  # area/board_folder/file.json
        return None
    parent_dir = BOARDS_DIR.joinpath(*rel_parts[:-2])
    # parent dir is at rel_parts[-2] (board folder)
    for f in parent_dir.iterdir():
        if f.is_file() and f.suffix == '.json':
            try:
                data = load_json(f)
                return data.get('id')
            except Exception:
                continue
    # fallback: derive from folder name
    return safe_folder_to_id(rel_parts[-2])

def update_board_json(path):
    rel = path.relative_to(BOARDS_DIR)
    parts = rel.parts
    area = parts[0]
    depth = len(parts) - 1  # number of directory components under area (file counts as last)
    data = load_json(path)
    data['area'] = area

    # tier / flags
    data['tier'] = depth
    data['isSubBoard'] = depth >= 2
    data['isTertiaryBoard'] = depth >= 3
    data['isQuaternaryBoard'] = depth >= 4
    data['isQuinaryBoard'] = depth >= 5

    if depth <= 1:
        data['parentBoardId'] = None
        # set top-level sort order for Legends
        if area == 'Legends' and data.get('name'):
            name = data['name']
            if name.lower() in LEGENDS_ORDER_LOWER:
                data['sortOrder'] = (LEGENDS_ORDER_LOWER[name.lower()] + 1) * 10
    else:
        parent_id = find_parent_board_id(parts)
        if parent_id:
            data['parentBoardId'] = parent_id

    save_json(path, data)
    return data

def move_board_to_legends(src, dst_name):
    dst = BOARDS_DIR / 'Legends' / dst_name
    if src.exists() and not dst.exists():
        shutil.move(str(src), str(dst))
        print(f'Moved {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}')
    elif src.exists() and dst.exists():
        # stale duplicate, remove source
        shutil.rmtree(src)
        print(f'Removed duplicate source {src.relative_to(ROOT)}')
    return dst

def remove_characters_board():
    chars_json = BOARDS_DIR / 'Legends' / 'prebuilt_characters.json'
    chars_txt = BOARDS_DIR / 'Legends' / 'Characters - Word List.txt'
    if chars_json.exists():
        chars_json.unlink()
        print('Removed stale Legends/prebuilt_characters.json')
    if chars_txt.exists():
        chars_txt.unlink()
        print('Removed stale Legends/Characters - Word List.txt')

def neutralize_characters_tile_in_people():
    people_json = BOARDS_DIR / 'Common' / 'People' / 'prebuilt_people.json'
    if not people_json.exists():
        return
    data = load_json(people_json)
    tiles = data.get('tiles', [])
    changed = False
    for tile in tiles:
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

def generate_board_hierarchy():
    entries = []
    # Order areas: Common, Legends, Recipes, Subject Vocab, Sign, My School, Personal
    area_order = {'Common': 0, 'Legends': 1, 'Recipes': 2, 'Subject Vocab': 3, 'Sign': 4, 'My School': 5, 'Personal': 6}
    for area_dir in sorted(BOARDS_DIR.iterdir(), key=lambda d: area_order.get(d.name, 99)):
        if not area_dir.is_dir():
            continue
        for json_file in sorted(area_dir.rglob('*.json')):
            rel = json_file.relative_to(BOARDS_DIR)
            parts = rel.parts
            depth = len(parts) - 1
            data = load_json(json_file)
            name = data.get('name', 'Board')
            area = data.get('area', area_dir.name)
            parent_id = data.get('parentBoardId')
            parent_name = None
            if parent_id:
                # find parent board name by scanning
                for pfile in area_dir.rglob('*.json'):
                    try:
                        pdata = load_json(pfile)
                        if pdata.get('id') == parent_id:
                            parent_name = pdata.get('name')
                            break
                    except Exception:
                        continue
            entries.append((area, rel, name, parent_name))

    # Build the static list text
    lines = []
    current_area = None
    for area, rel, name, parent in entries:
        if current_area != area:
            if current_area is not None:
                lines.append('')
            lines.append(f"  // ──────────────────────────────────────────────")
            lines.append(f"  //  {area.upper()} AREA")
            lines.append(f"  // ──────────────────────────────────────────────")
            current_area = area
        if parent:
            lines.append(f"  BoardHierarchyEntry('{_escape(name)}', '{_escape(area)}', '{_escape(parent)}'),")
        else:
            lines.append(f"  BoardHierarchyEntry('{_escape(name)}', '{_escape(area)}'),")

    return '\n'.join(lines) + '\n'

def _escape(s):
    return s.replace("'", "\\'")

def update_board_hierarchy_file():
    hierarchy_path = ROOT / 'lib' / 'data' / 'board_hierarchy.dart'
    # preserve everything before `const List<BoardHierarchyEntry> boardHierarchy = [` and after `];`
    with open(hierarchy_path, 'r', encoding='utf-8') as f:
        original = f.read()

    start_marker = 'const List<BoardHierarchyEntry> boardHierarchy = ['
    end_marker = '];'
    start_idx = original.find(start_marker)
    if start_idx == -1:
        print('ERROR: could not find boardHierarchy start marker')
        return
    # find the end of the list (first `];` after start)
    list_start = original.find('[', start_idx + len(start_marker))
    end_idx = original.find(end_marker, list_start)
    if end_idx == -1:
        print('ERROR: could not find boardHierarchy end marker')
        return

    new_list = generate_board_hierarchy()
    new_content = original[:list_start + 1] + '\n' + new_list + original[end_idx:]
    with open(hierarchy_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Updated lib/data/board_hierarchy.dart')

def generate_board_index():
    board_index = []
    for root, dirs, files in os.walk(BOARDS_DIR):
        for file in files:
            if file.endswith('.json'):
                file_path = Path(root) / file
                try:
                    data = load_json(file_path)
                    board_index.append({
                        'id': data.get('id', ''),
                        'name': data.get('name', 'Board'),
                        'area': data.get('area', 'Common'),
                        'parentBoardId': data.get('parentBoardId'),
                        'isSubBoard': data.get('isSubBoard', False),
                        'isTertiaryBoard': data.get('isTertiaryBoard', False),
                        'isQuaternaryBoard': data.get('isQuaternaryBoard', False),
                        'isQuinaryBoard': data.get('isQuinaryBoard', False),
                        'sortOrder': data.get('sortOrder', 0),
                        'tier': data.get('tier', 1),
                        'iconAssetPath': data.get('iconAssetPath'),
                    })
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    output_path = ROOT / 'lib' / 'data' / 'board_index.dart'
    with open(output_path, 'w', encoding='utf-8') as f:
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

        for entry in board_index:
            name_escaped = entry['name'].replace("'", "\\'")
            f.write('  BoardIndexEntry(\n')
            f.write(f"    id: '{entry['id']}',\n")
            f.write(f"    name: '{name_escaped}',\n")
            f.write(f"    area: '{entry['area']}',\n")
            if entry['parentBoardId']:
                f.write(f"    parentBoardId: '{entry['parentBoardId']}',\n")
            f.write(f"    isSubBoard: {'true' if entry['isSubBoard'] else 'false'},\n")
            f.write(f"    isTertiaryBoard: {'true' if entry['isTertiaryBoard'] else 'false'},\n")
            f.write(f"    isQuaternaryBoard: {'true' if entry['isQuaternaryBoard'] else 'false'},\n")
            f.write(f"    isQuinaryBoard: {'true' if entry['isQuinaryBoard'] else 'false'},\n")
            f.write(f"    sortOrder: {entry['sortOrder']},\n")
            f.write(f"    tier: {entry['tier']},\n")
            if entry['iconAssetPath']:
                f.write(f"    iconAssetPath: '{entry['iconAssetPath']}',\n")
            f.write('  ),\n')

        f.write('];\n')

    print(f"Board index generated with {len(board_index)} entries at {output_path}")

def update_pubspec_assets():
    pubspec_path = ROOT / 'pubspec.yaml'
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # find flutter/assets section boundaries
    in_assets = False
    start_idx = None
    end_idx = None
    for i, line in enumerate(lines):
        if line.strip().startswith('assets:'):
            in_assets = True
            start_idx = i
            continue
        if in_assets:
            # end when a new top-level key appears (no leading spaces) or section ends
            if line.strip() and not line.startswith(' ') and not line.startswith('\t'):
                end_idx = i
                break
    if start_idx is None:
        print('WARNING: no assets section found in pubspec.yaml')
        return

    asset_lines = lines[start_idx + 1:end_idx]
    # keep lines not under data/boards/Common/People/Characters or Subject Vocab/Religion & Worldviews or Common/Time/Events & Occasions/Halloween Keywords
    keep = []
    for line in asset_lines:
        m = re.search(r"lib/data/boards/([^'\"]+)", line)
        if m:
            p = m.group(1).strip('/')
            if p.startswith('Common/People/Characters'):
                continue
            if p == 'Subject Vocab/Religion & Worldviews' or p.startswith('Subject Vocab/Religion & Worldviews/'):
                continue
            if p == 'Common/Time/Events & Occasions/Halloween Keywords' or p.startswith('Common/Time/Events & Occasions/Halloween Keywords/'):
                continue
        keep.append(line)

    # Generate new asset entries for Legends and Recipes
    new_entries = []
    for area in ['Legends', 'Recipes']:
        area_dir = BOARDS_DIR / area
        if not area_dir.exists():
            continue
        new_entries.append(f"    - lib/data/boards/{area}/\n")
        for sub in sorted(area_dir.rglob('*')):
            if sub.is_dir():
                rel = sub.relative_to(BOARDS_DIR).as_posix()
                new_entries.append(f"    - lib/data/boards/{rel}/\n")

    # also add Recipes placeholder if empty? The loop above only adds area dir if exists.

    # reconstruct
    before = lines[:start_idx + 1]
    after = lines[end_idx:] if end_idx is not None else []
    new_lines = before + keep + new_entries + after
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print('Updated pubspec.yaml asset entries')

def main():
    # 1. Move the two linked boards into Legends
    halloween_src = BOARDS_DIR / 'Common' / 'Time' / 'Events & Occasions' / 'Halloween Keywords'
    move_board_to_legends(halloween_src, 'Halloween Keywords')

    religion_src = BOARDS_DIR / 'Subject Vocab' / 'Religion & Worldviews'
    move_board_to_legends(religion_src, 'Religion & Worldviews')

    # 2. Remove the stale Characters board and neutralize its tile in People
    remove_characters_board()
    neutralize_characters_tile_in_people()

    # 3. Update all board JSONs with correct area/parent/tier
    for json_file in BOARDS_DIR.rglob('*.json'):
        if json_file.is_file():
            update_board_json(json_file)

    # 4. Regenerate board_hierarchy and board_index
    update_board_hierarchy_file()
    generate_board_index()

    # 5. Update pubspec assets
    update_pubspec_assets()

if __name__ == '__main__':
    main()
