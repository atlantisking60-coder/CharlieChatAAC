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

def load(p):
    with open(p, 'r', encoding='utf-8') as f:
        return json.load(f)

def save(p, data):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def safe_name(name):
    return re.sub(r'[^a-zA-Z0-9_]+', '_', name).strip('_')

def remove_dir(p):
    if p.exists():
        shutil.rmtree(p)

def copy_halloween():
    src = BOARDS_DIR / 'Legends' / 'Halloween Keywords'
    dst_common = BOARDS_DIR / 'Common' / 'Time' / 'Events & Occasions' / 'Halloween Keywords'
    remove_dir(dst_common)
    shutil.copytree(src, dst_common)

    # Common original id must match the linkedBoardName in Events & Occasions
    common_files = list(dst_common.glob('prebuilt_*.json'))
    common_new = dst_common / 'prebuilt_events_occasions_halloween_keywords.json'
    if common_files:
        common_old = common_files[0]
        if common_old.name != common_new.name:
            if common_new.exists():
                common_new.unlink()
            common_old.rename(common_new)
    d = load(common_new)
    d['id'] = 'prebuilt_events_occasions_halloween_keywords'
    d['name'] = 'Halloween Keywords'
    d['area'] = 'Common'
    d['parentBoardId'] = 'prebuilt_events_occasions'
    d['tier'] = 3
    d['isSubBoard'] = True
    d['isTertiaryBoard'] = True
    d['isQuaternaryBoard'] = False
    d['isQuinaryBoard'] = False
    d['sortOrder'] = 0
    save(common_new, d)

    # Legends copy gets a unique id
    legends_files = list(src.glob('prebuilt_*.json'))
    legends_new = src / 'prebuilt_halloween_keywords_legends.json'
    if legends_files:
        legends_old = legends_files[0]
        if legends_old.name != legends_new.name:
            if legends_new.exists():
                legends_new.unlink()
            legends_old.rename(legends_new)
    d = load(legends_new)
    d['id'] = 'prebuilt_halloween_keywords_legends'
    d['name'] = 'Halloween Keywords'
    d['area'] = 'Legends'
    d['parentBoardId'] = None
    d['tier'] = 1
    d['isSubBoard'] = False
    d['isTertiaryBoard'] = False
    d['isQuaternaryBoard'] = False
    d['isQuinaryBoard'] = False
    d['sortOrder'] = 110
    save(legends_new, d)
    print('Restored Common Halloween Keywords and updated Legends copy id')

def copy_religion():
    src = BOARDS_DIR / 'Legends' / 'Religion & Worldviews'
    dst_subject = BOARDS_DIR / 'Subject Vocab' / 'Religion & Worldviews'
    remove_dir(dst_subject)
    shutil.copytree(src, dst_subject)

    # Subject Vocab copy: promote MAIN, set original id
    src_main = dst_subject / 'MAIN' / 'prebuilt_main.json'
    subject_json = dst_subject / 'prebuilt_religion_worldviews.json'
    if src_main.exists():
        src_main.rename(subject_json)
        if (dst_subject / 'MAIN').exists():
            shutil.rmtree(dst_subject / 'MAIN')
    d = load(subject_json)
    old_id = d['id']
    d['id'] = 'prebuilt_religion_worldviews'
    d['name'] = 'Religion & Worldviews'
    d['area'] = 'Subject Vocab'
    d['parentBoardId'] = None
    d['tier'] = 1
    d['isSubBoard'] = False
    d['isTertiaryBoard'] = False
    d['isQuaternaryBoard'] = False
    d['isQuinaryBoard'] = False
    d['sortOrder'] = 0
    save(subject_json, d)
    # update internal references in Subject Vocab copy
    update_references_in_tree(dst_subject, {old_id: 'prebuilt_religion_worldviews'})
    print('Restored Subject Vocab Religion & Worldviews')

    # Legends copy: promote MAIN and rename all ids with _legends suffix
    legend_main = src / 'MAIN' / 'prebuilt_main.json'
    legend_json = src / 'prebuilt_religion_worldviews_legends.json'
    if legend_main.exists():
        legend_main.rename(legend_json)
        if (src / 'MAIN').exists():
            shutil.rmtree(src / 'MAIN')
    d = load(legend_json)
    old_main_id = d['id']
    d['id'] = 'prebuilt_religion_worldviews_legends'
    d['name'] = 'Religion & Worldviews'
    d['area'] = 'Legends'
    d['parentBoardId'] = None
    d['tier'] = 1
    d['isSubBoard'] = False
    d['isTertiaryBoard'] = False
    d['isQuaternaryBoard'] = False
    d['isQuinaryBoard'] = False
    d['sortOrder'] = 140
    save(legend_json, d)

    # build id mapping for legends sub-boards: old_id -> old_id_legends
    id_map = {old_main_id: 'prebuilt_religion_worldviews_legends'}
    for p in src.rglob('*.json'):
        if p == legend_json:
            continue
        data = load(p)
        old = data.get('id')
        if old:
            id_map[old] = old + '_legends'
    # rename files and ids for legends copy
    for p in list(src.rglob('*.json')):
        if p == legend_json:
            continue
        data = load(p)
        old = data.get('id')
        if old and old in id_map:
            data['id'] = id_map[old]
        save(p, data)
        new_name = p.with_name(id_map.get(old, old) + '.json')
        if str(p) != str(new_name):
            if new_name.exists():
                new_name.unlink()
            p.rename(new_name)
    # update references
    update_references_in_tree(src, id_map)
    print('Updated Legends Religion & Worldviews ids to avoid duplicates')

def update_references_in_tree(tree_dir, id_map):
    for p in tree_dir.rglob('*.json'):
        data = load(p)
        changed = False
        pid = data.get('parentBoardId')
        if pid and pid in id_map:
            data['parentBoardId'] = id_map[pid]
            changed = True
        for tile in data.get('tiles', []):
            ln = tile.get('linkedBoardName')
            if ln and ln in id_map:
                tile['linkedBoardName'] = id_map[ln]
                changed = True
        if changed:
            save(p, data)

def board_id_in_dir(d):
    """Return the id of the first prebuilt JSON found in a directory, or None."""
    if not d.is_dir():
        return None
    for f in sorted(d.iterdir()):
        if f.is_file() and f.suffix == '.json':
            try:
                return load(f).get('id')
            except Exception:
                continue
    return None

def fix_tree(root_dir, area_name, set_legends_sort=False):
    """Recompute area, parent, and tier for every JSON under root_dir."""
    for p in sorted(root_dir.rglob('*.json')):
        data = load(p)
        data['area'] = area_name
        # Count ancestor board folders between root_dir (exclusive) and this board's parent.
        parent_dir = p.parent.parent
        parent_id = None
        tier = 1
        while parent_dir != root_dir and parent_dir != parent_dir.parent:
            bid = board_id_in_dir(parent_dir)
            if bid and bid != data.get('id'):
                parent_id = bid
                tier += 1
                # continue counting further ancestors to get true tier?
                # For tier, we need total number of ancestor board folders.
            parent_dir = parent_dir.parent
        # Recompute tier by walking all ancestors from root_dir to board parent
        ancestor = p.parent.parent
        tier = 1
        parent_id = None
        while ancestor != root_dir and ancestor != ancestor.parent:
            bid = board_id_in_dir(ancestor)
            if bid and bid != data.get('id'):
                parent_id = bid
                tier += 1
            ancestor = ancestor.parent
        data['parentBoardId'] = parent_id
        data['tier'] = tier
        data['isSubBoard'] = tier >= 2
        data['isTertiaryBoard'] = tier >= 3
        data['isQuaternaryBoard'] = tier >= 4
        data['isQuinaryBoard'] = tier >= 5
        if set_legends_sort and tier == 1 and data.get('name'):
            name = data['name']
            if name.lower() in LEGENDS_ORDER_LOWER:
                data['sortOrder'] = (LEGENDS_ORDER_LOWER[name.lower()] + 1) * 10
        save(p, data)

def delete_stale_files():
    for p in [
        BOARDS_DIR / 'Common' / 'prebuilt_1940_pinocchio.json',
        BOARDS_DIR / 'Subject Vocab' / 'Prebuilt Religion Worldviews.Json',
        BOARDS_DIR / 'Subject Vocab' / 'prebuilt_religion_worldviews.json',
    ]:
        if p.exists():
            p.unlink()
            print(f'Deleted stale {p.relative_to(ROOT)}')

def gather():
    boards = []
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        area = area_dir.name
        for p in sorted(area_dir.rglob('*.json')):
            data = load(p)
            boards.append((area, str(p.relative_to(BOARDS_DIR)), data))
    area_order = {'Common': 0, 'Legends': 1, 'Recipes': 2, 'Subject Vocab': 3, 'Sign': 4, 'My School': 5, 'Personal': 6}
    boards.sort(key=lambda t: (area_order.get(t[0], 99), t[1]))
    return boards

def esc(s):
    return s.replace("'", "\\'")

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
    boards = gather()
    id_to_name = {b[2]['id']: b[2]['name'] for b in boards}
    out_lines = []
    current = None
    for area, rel, data in boards:
        name = data.get('name', 'Board')
        pid = data.get('parentBoardId')
        pname = id_to_name.get(pid) if pid else None
        if current != area:
            if current is not None:
                out_lines.append('')
            out_lines.append(f"  // {'─' * 46}")
            out_lines.append(f"  //  {area.upper()} AREA")
            out_lines.append(f"  // {'─' * 46}")
            current = area
        if pname:
            out_lines.append(f"  BoardHierarchyEntry('{esc(name)}', '{esc(area)}', '{esc(pname)}'),")
        else:
            out_lines.append(f"  BoardHierarchyEntry('{esc(name)}', '{esc(area)}'),")
    out = lines[:start_line + 1] + ['\n'.join(out_lines) + '\n'] + lines[end_line:]
    with open(HIERARCHY_OUT, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Rebuilt {HIERARCHY_OUT}')

def rebuild_index():
    boards = gather()
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
    print(f'Regenerated {INDEX_OUT} ({len(boards)} entries)')

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
    keep = []
    for line in lines[assets_start + 1:assets_end]:
        if re.search(r"lib/data/boards/", line):
            continue
        keep.append(line)
    entries = []
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        entries.append(f"    - lib/data/boards/{area_dir.name}/\n")
        for sub in sorted(area_dir.rglob('*')):
            if sub.is_dir():
                rel = sub.relative_to(ROOT)
                entries.append(f"    - {rel.as_posix()}/\n")
    out = lines[:assets_start + 1] + keep + entries + lines[assets_end:]
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print(f'Updated {PUBSPEC}')

def main():
    copy_halloween()
    copy_religion()
    for area_dir in sorted(BOARDS_DIR.iterdir()):
        if not area_dir.is_dir():
            continue
        fix_tree(area_dir, area_dir.name, set_legends_sort=(area_dir.name == 'Legends'))
    delete_stale_files()
    rebuild_hierarchy()
    rebuild_index()
    update_pubspec()

if __name__ == '__main__':
    main()
