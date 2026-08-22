import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

root = Path('C:/Users/Craig/Downloads/Charlie Chat')
boards_dir = root / 'lib' / 'data' / 'boards'

def normalize_id(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower())
    s = re.sub(r"_+", "_", s)
    return s.strip("_")

def load_json(p):
    try:
        with open(p, 'r', encoding='utf-8-sig') as f:
            return json.load(f)
    except Exception as e:
        print(f'ERROR reading {p}: {e}', file=sys.stderr)
        return None

def write_json(p, data):
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False) + '\n')

def main():
    # ---- 1. Collect current files ----
    records = []
    for f in boards_dir.rglob('*.json'):
        if f.is_relative_to(root / 'Backups') or f.is_relative_to(root / '.artifacts'):
            continue
        if '_deleted' in [p.lower() for p in f.parts]:
            continue
        if f.is_relative_to(boards_dir / '_temp'):
            continue
        data = load_json(f)
        if data is None:
            continue
        records.append({'path': f, 'data': data})

    id_to_record = {r['data'].get('id', ''): r for r in records if r['data'].get('id')}

    # ---- 2. Delete specific boards ----
    # NOTE: this list is intentionally empty. It previously contained
    # one-off cleanup entries (including `boards_dir / '_temp'`), but
    # `_temp` is a legitimate dev-server staging area for boards whose
    # canonical folder isn't known yet (see dev_server.py), not disposable
    # junk — including it here silently deleted real, not-yet-migrated
    # board content on every run. Add entries here only for a single
    # one-off cleanup pass, then remove them again immediately after.
    delete_ids = set()
    delete_paths = []

    deleted_ids = set()
    for rid in list(delete_ids):
        if rid in id_to_record:
            r = id_to_record[rid]
            r['path'].unlink()
            deleted_ids.add(rid)
            records.remove(r)
            del id_to_record[rid]

    for p in delete_paths:
        if p.exists():
            if p.is_dir():
                shutil.rmtree(p)
            else:
                p.unlink()
    # Re-collect after deletions
    records = []
    id_to_record = {}
    for f in boards_dir.rglob('*.json'):
        if f.is_relative_to(root / 'Backups') or f.is_relative_to(root / '.artifacts'):
            continue
        if '_deleted' in [p.lower() for p in f.parts]:
            continue
        if f.is_relative_to(boards_dir / '_temp'):
            continue
        data = load_json(f)
        if data is None:
            continue
        r = {'path': f, 'data': data}
        records.append(r)
        if data.get('id'):
            id_to_record[data['id']] = r

    # Derive parent/child relationships from board-link tiles.
    # Some boards have "back to parent" navigation tiles that link both ways
    # (A -> B and B -> A). Treating both as hierarchy edges creates a parent
    # cycle, which hangs the app (infinite loop walking up parentBoardId).
    # So: collect same-area edges first, drop any mutual (A<->B) pairs, then
    # only assign a parent from what's left, and never let an assignment
    # create a cycle with edges already accepted.
    # A tile link only counts as real hierarchy if the linked board's JSON file
    # actually lives in a subfolder of the parent's own folder on disk. Hub/
    # landing boards (e.g. "Subject Vocab", "My School Main", "Legends") have
    # tiles linking to every sibling top-level board purely for navigation —
    # those siblings live in their own top-level area folders, not nested
    # under the hub's folder, so they must stay top-level.
    edges = set()
    for r in records:
        data = r['data']
        pid = data.get('id')
        area = data.get('area', '')
        parent_dir = r['path'].parent
        for tile in data.get('tiles', []):
            lid = tile.get('linkedBoardId', '')
            if not lid or lid not in id_to_record or lid == pid:
                continue
            child_rec = id_to_record[lid]
            child = child_rec['data']
            if child.get('area') != area:
                continue
            if child_rec['path'].parent.parent != parent_dir:
                continue  # not nested directly under the parent's folder
            edges.add((pid, lid))

    mutual = {(a, b) for (a, b) in edges if (b, a) in edges}
    edges -= mutual

    def creates_cycle(parent_id, child_id):
        # Would assigning child_id.parentBoardId = parent_id create a cycle?
        # True if parent_id is already a descendant of child_id.
        seen = set()
        stack = [child_id]
        while stack:
            cur = stack.pop()
            if cur == parent_id:
                return True
            if cur in seen:
                continue
            seen.add(cur)
            rec = id_to_record.get(cur)
            if not rec:
                continue
            stack.append(rec['data'].get('parentBoardId'))
        return False

    for pid, lid in edges:
        child = id_to_record[lid]['data']
        if child.get('parentBoardId'):
            continue
        if creates_cycle(pid, lid):
            continue
        child['parentBoardId'] = pid
        child['isSubBoard'] = True

    # Top-level (parent null) boards are area mains, not sub-boards.
    for r in records:
        data = r['data']
        if not data.get('parentBoardId'):
            if data.get('isSubBoard') or data.get('isTertiaryBoard'):
                data['isSubBoard'] = False
                data['isTertiaryBoard'] = False
                write_json(r['path'], data)

    # ---- 3. Clean parent tiles that reference deleted ids ----
    for r in records:
        data = r['data']
        tiles = data.get('tiles', [])
        new_tiles = []
        changed = False
        for tile in tiles:
            lid = tile.get('linkedBoardId', '')
            if lid and lid in deleted_ids:
                changed = True
                continue  # drop the tile entirely
            new_tiles.append(tile)
        if changed:
            data['tiles'] = new_tiles
            write_json(r['path'], data)

    # ---- 4. (removed) ----
    # This script used to regenerate lib/data/tab_orders.json wholesale on
    # every run, which repeatedly clobbered manually-configured/UI-driven
    # tab orders (including a real data-loss incident). tab_orders.json is
    # no longer touched by this script under any circumstances — edit it
    # directly, or use the app's own reorder UI / dev-server /saveTabOrder
    # endpoint, which updates it in place without wiping other areas.
    id_to_name = {d['data']['id']: d['data']['name'] for d in records if d['data'].get('id')}
    landing_pages = {
        'Common': 'Common Words',
        'Subject Vocab': 'Subject Vocab',
        'Sign': 'Sign',
        'My School': 'My School Main',
        'Legends': 'Legends',
        'Recipes': 'Recipes',
        'Personal': 'Personal',
    }

    # ---- 5. Regenerate board_index.dart ----
    entries = []
    for r in records:
        d = r['data']
        entries.append({
            'id': d.get('id', ''),
            'name': d.get('name', ''),
            'area': d.get('area', ''),
            'parentBoardId': d.get('parentBoardId'),
            'isSubBoard': d.get('isSubBoard', False),
            'isTertiaryBoard': d.get('isTertiaryBoard', False),
            'sortOrder': d.get('sortOrder', 0),
            'tier': d.get('tier', 1),
            'iconAssetPath': d.get('iconAssetPath'),
        })
    with open(root / 'lib' / 'data' / 'board_index.dart', 'w', encoding='utf-8') as f:
        f.write('// AUTO-GENERATED by tools/fix_all.py - do not edit manually.\n\n')
        f.write('class BoardIndexEntry {\n')
        f.write('  final String id;\n')
        f.write('  final String name;\n')
        f.write('  final String area;\n')
        f.write('  final String? parentBoardId;\n')
        f.write('  final bool isSubBoard;\n')
        f.write('  final bool isTertiaryBoard;\n')
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
        f.write('    this.sortOrder = 0,\n')
        f.write('    this.tier = 1,\n')
        f.write('    this.iconAssetPath,\n')
        f.write('  });\n')
        f.write('}\n\n')
        f.write('const List<BoardIndexEntry> staticBoardIndex = [\n')
        for e in sorted(entries, key=lambda x: (x['area'], x['name'])):
            name_escaped = e['name'].replace("'", "\\'")
            f.write('  BoardIndexEntry(\n')
            f.write(f"    id: '{e['id']}',\n")
            f.write(f"    name: '{name_escaped}',\n")
            f.write(f"    area: '{e['area']}',\n")
            if e['parentBoardId']:
                f.write(f"    parentBoardId: '{e['parentBoardId']}',\n")
            f.write(f"    isSubBoard: {'true' if e['isSubBoard'] else 'false'},\n")
            f.write(f"    isTertiaryBoard: {'true' if e['isTertiaryBoard'] else 'false'},\n")
            f.write(f"    sortOrder: {e['sortOrder']},\n")
            f.write(f"    tier: {e['tier']},\n")
            if e['iconAssetPath']:
                icon_escaped = e['iconAssetPath'].replace("'", "\\'")
                f.write(f"    iconAssetPath: '{icon_escaped}',\n")
            f.write('  ),\n')
        f.write('];\n')

    # ---- 6. Regenerate board_hierarchy.dart list ----
    id_to_name = {d['data']['id']: d['data']['name'] for d in records if d['data'].get('id')}
    hierarchy = []
    for r in records:
        d = r['data']
        if d.get('id', '').startswith('link_') or d.get('id') == 'prebuilt_favorites':
            continue
        name = d.get('name', '')
        area = d.get('area', '')
        parent_id = d.get('parentBoardId')
        parent_name = id_to_name.get(parent_id) if parent_id else None
        hierarchy.append((name, area, parent_name, d.get('sortOrder', 0)))

    hierarchy_path = root / 'lib' / 'data' / 'board_hierarchy.dart'
    content = hierarchy_path.read_text(encoding='utf-8')
    start_marker = 'const List<BoardHierarchyEntry> boardHierarchy = ['
    start = content.find(start_marker)
    end = content.find('];', start)
    if start == -1 or end == -1:
        raise RuntimeError('Could not locate boardHierarchy list in board_hierarchy.dart')
    new_list = 'const List<BoardHierarchyEntry> boardHierarchy = [\n'
    for name, area, parent, _ in sorted(hierarchy, key=lambda x: (x[1], 0 if x[0] == landing_pages.get(x[1]) else 1, x[3], x[0])):
        name_esc = name.replace("'", "\\'")
        area_esc = area.replace("'", "\\'")
        if parent:
            parent_esc = parent.replace("'", "\\'")
            new_list += f"  BoardHierarchyEntry('{name_esc}', '{area_esc}', '{parent_esc}'),\n"
        else:
            new_list += f"  BoardHierarchyEntry('{name_esc}', '{area_esc}'),\n"
    new_list += '];\n'
    new_content = content[:start] + new_list + content[end+3:]
    hierarchy_path.write_text(new_content, encoding='utf-8')

    # ---- 7. Regenerate runtime_hierarchy.json ----
    subprocess.run([sys.executable, str(root / 'tools' / 'generate_runtime_hierarchy.py')], check=True)

    # ---- 8. Update pubspec.yaml ----
    subprocess.run([sys.executable, str(root / 'tools' / 'update_pubspec_assets.py')], check=True)

    print(f'Deleted ids: {deleted_ids}')
    print(f'Removed {len(delete_paths)} paths/directories')
    print(f'Boards: {len(records)}')
    print('tab_orders.json was NOT touched by this script.')

if __name__ == '__main__':
    main()
