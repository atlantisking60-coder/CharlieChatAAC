import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

root = Path('C:/Users/Craig/Downloads/Charlie Chat')
boards_dir = root / 'lib' / 'data' / 'boards'

DRY_RUN = '--dry-run' in sys.argv

def normalize_id(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower())
    s = re.sub(r"_+", "_", s)
    return s.strip("_")

def is_deleted(path):
    return '_deleted' in [p.lower() for p in path.parts]

def load_json(p):
    try:
        with open(p, 'r', encoding='utf-8-sig') as f:
            return json.load(f)
    except Exception as e:
        print(f'ERROR reading {p}: {e}', file=sys.stderr)
        return None

def to_json_string(data):
    return json.dumps(data, indent=2, ensure_ascii=False) + '\n'

def canonical_bonus(r):
    """Prefer files whose stem/id matches the containing folder name."""
    data = r['data']
    path = r['path']
    bid = data.get('id', '')
    stem = path.stem
    parent_norm = normalize_id(path.parent.name)
    name_norm = normalize_id(data.get('name', ''))
    bonus = 0
    if stem == bid:
        bonus += 10000
    if parent_norm and (parent_norm in bid or parent_norm in name_norm):
        bonus += 5000
    return bonus

def score(r):
    tiles = r['data'].get('tiles', [])
    non_blank = len([t for t in tiles if t.get('type') != 'blank'])
    redundant = -1 if is_link_redundant(r) else 0
    return (redundant,
            canonical_bonus(r),
            r['data'].get('version', 0) or 0,
            non_blank,
            r['mtime'])

def new_id_from_name(old_id, old_name, new_name):
    """Replace the name-derived tail of old_id with the normalized new_name."""
    old_tail = normalize_id(old_name)
    new_tail = normalize_id(new_name)
    if old_tail and old_tail in old_id:
        idx = old_id.rfind(old_tail)
        prefix = old_id[:idx]
    else:
        prefix = 'prebuilt_'
    return prefix + new_tail

def target_of_link(data):
    """Return the linkedBoardId from a link board, if any."""
    for tile in data.get('tiles', []):
        if tile.get('type') == 'board_link' or tile.get('isBoardLink'):
            return tile.get('linkedBoardId', '')
    return ''

def is_link_redundant(r):
    """A link board is redundant if the prebuilt target lives in the same directory."""
    rid = r['data'].get('id', '')
    if not rid.startswith('link_'):
        return False
    target = target_of_link(r['data'])
    if not target:
        return False
    return (r['path'].parent / f'{target}.json').exists()

def main():
    records = []
    for f in boards_dir.rglob('*.json'):
        if f.is_relative_to(root / 'Backups') or f.is_relative_to(root / '.artifacts'):
            continue
        if is_deleted(f):
            continue
        data = load_json(f)
        if data is None:
            continue
        records.append({'path': f, 'data': data, 'mtime': f.stat().st_mtime})

    for r in records:
        r['score'] = score(r)

    by_id = defaultdict(list)
    by_name = defaultdict(list)
    for r in records:
        bid = r['data'].get('id', '')
        if bid:
            by_id[bid].append(r)
        name = r['data'].get('name', '')
        if name and not bid.startswith('link_'):
            by_name[name].append(r)

    # renames[old_id][area] = new_id
    renames = defaultdict(dict)
    to_delete = set()
    kept_records = []

    # ---- 1. Duplicate IDs (same id in multiple files) ----
    for bid, recs in by_id.items():
        if len(recs) <= 1:
            continue
        by_area = defaultdict(list)
        for r in recs:
            by_area[r['data'].get('area', '')].append(r)
        area_survivors = {}
        for area, area_recs in by_area.items():
            area_recs_sorted = sorted(area_recs, key=lambda x: x['score'], reverse=True)
            survivor = area_recs_sorted[0]
            area_survivors[area] = survivor
            for loser in area_recs_sorted[1:]:
                to_delete.add(loser['path'])
                renames[bid][area] = survivor['data']['id']  # will be overwritten if survivor renamed
        if len(area_survivors) > 1:
            # Rename every survivor to include its area
            for area, r in area_survivors.items():
                old_id = r['data']['id']
                old_name = r['data']['name']
                suffix = f' ({area})'
                if not old_name.endswith(suffix):
                    new_name = old_name + suffix
                else:
                    new_name = old_name
                new_id = new_id_from_name(old_id, old_name, new_name)
                renames[old_id][area] = new_id
                r['data']['name'] = new_name
                r['data']['id'] = new_id
        else:
            area, r = next(iter(area_survivors.items()))
            renames[bid][area] = r['data']['id']

    # ---- 2. Duplicate names among non-link prebuilt boards ----
    remaining = [r for r in records if r['path'] not in to_delete]
    by_name2 = defaultdict(list)
    for r in remaining:
        name = r['data'].get('name', '')
        if name and not r['data'].get('id', '').startswith('link_'):
            by_name2[name].append(r)
    for name, recs in by_name2.items():
        if len(recs) <= 1:
            continue
        by_area = defaultdict(list)
        for r in recs:
            by_area[r['data'].get('area', '')].append(r)
        multi_area = len(by_area) > 1
        for area, area_recs in by_area.items():
            area_recs_sorted = sorted(area_recs, key=lambda x: x['score'], reverse=True)
            survivor = area_recs_sorted[0]
            old_surv_id = survivor['data']['id']
            for loser in area_recs_sorted[1:]:
                to_delete.add(loser['path'])
                renames[loser['data']['id']][area] = old_surv_id
            if multi_area:
                suffix = f' ({area})'
                if not survivor['data']['name'].endswith(suffix):
                    new_name = survivor['data']['name'] + suffix
                else:
                    new_name = survivor['data']['name']
                new_id = new_id_from_name(old_surv_id, survivor['data']['name'], new_name)
                if new_id != old_surv_id:
                    renames[old_surv_id][area] = new_id
                    survivor['data']['name'] = new_name
                    survivor['data']['id'] = new_id

    # ---- 3. Drop any link board that is still redundant after duplicate handling ----
    # This only maps link ids to their target if no non-redundant copy survived.
    for r in records:
        if r['path'] in to_delete:
            continue
        rid = r['data'].get('id', '')
        if not rid.startswith('link_') or not is_link_redundant(r):
            continue
        area = r['data'].get('area', '')
        # If a non-redundant copy of this link id already survived, don't remap;
        # just delete this redundant one.
        if rid in renames and area in renames[rid] and renames[rid][area] != rid:
            to_delete.add(r['path'])
        else:
            target = target_of_link(r['data'])
            to_delete.add(r['path'])
            renames[rid][area] = target

    # ---- 4. Build resolution helper ----
    def resolve(old_id, board_area):
        if old_id not in renames:
            return old_id
        mapping = renames[old_id]
        if board_area in mapping:
            return mapping[board_area]
        if len(mapping) == 1:
            return next(iter(mapping.values()))
        # Fallback: choose the mapping whose area is alphabetically closest
        return mapping.get(sorted(mapping.keys(), key=lambda a: (a != board_area, a))[0], old_id)

    if DRY_RUN:
        print('=== DRY RUN ===')
        print(f'Files to delete: {len(to_delete)}')
        for p in sorted(to_delete):
            print(f'  DELETE {p}')
        print('\nID renames/moves:')
        for old_id in sorted(renames):
            for area, new_id in sorted(renames[old_id].items()):
                print(f'  {old_id} [{area}] -> {new_id}')
        return

    # ---- 5. Apply deletions ----
    for p in to_delete:
        p.unlink()
        d = p.parent
        while d != boards_dir and d.exists() and not any(d.iterdir()):
            d.rmdir()
            d = d.parent

    # ---- 6. Apply data updates and file moves for survivors ----
    for r in records:
        if r['path'] in to_delete:
            continue
        old_id = r['data'].get('id', '')
        area = r['data'].get('area', '')
        if old_id in renames and area in renames[old_id]:
            r['data']['id'] = renames[old_id][area]
        new_path = r['path'].parent / f"{r['data']['id']}.json"
        if new_path != r['path']:
            new_path.parent.mkdir(parents=True, exist_ok=True)
            r['path'].rename(new_path)
            r['path'] = new_path

    # Update references and write back
    for r in records:
        if r['path'] in to_delete:
            continue
        data = r['data']
        area = data.get('area', '')
        if data.get('parentBoardId'):
            data['parentBoardId'] = resolve(data['parentBoardId'], area)
        for tile in data.get('tiles', []):
            if tile.get('linkedBoardId'):
                tile['linkedBoardId'] = resolve(tile['linkedBoardId'], area)
            if tile.get('linkedBoardName'):
                tile['linkedBoardName'] = resolve(tile['linkedBoardName'], area)
        with open(r['path'], 'w', encoding='utf-8') as f:
            f.write(to_json_string(data))

    # ---- 7. Reload from disk ----
    records = []
    for f in boards_dir.rglob('*.json'):
        if is_deleted(f):
            continue
        data = load_json(f)
        if data:
            records.append({'path': f, 'data': data})

    id_to_name = {r['data']['id']: r['data']['name'] for r in records if r['data'].get('id')}

    # ---- 8. Regenerate board_index.dart ----
    board_index_path = root / 'lib' / 'data' / 'board_index.dart'
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
    with open(board_index_path, 'w', encoding='utf-8') as f:
        f.write('// AUTO-GENERATED by tools/rebuild_board_lists.py - do not edit manually.\n\n')
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

    # ---- 9. Regenerate boardHierarchy list in board_hierarchy.dart ----
    hierarchy_entries = []
    for r in records:
        d = r['data']
        if d.get('id', '').startswith('link_') or d.get('id') == 'prebuilt_favorites':
            continue
        name = d.get('name', '')
        area = d.get('area', '')
        parent_id = d.get('parentBoardId')
        parent_name = id_to_name.get(parent_id) if parent_id else None
        hierarchy_entries.append((name, area, parent_name))

    hierarchy_path = root / 'lib' / 'data' / 'board_hierarchy.dart'
    content = hierarchy_path.read_text(encoding='utf-8')
    start_marker = 'const List<BoardHierarchyEntry> boardHierarchy = ['
    start = content.find(start_marker)
    end = content.find('];', start)
    if start == -1 or end == -1:
        raise RuntimeError('Could not locate boardHierarchy list in board_hierarchy.dart')
    new_list = 'const List<BoardHierarchyEntry> boardHierarchy = [\n'
    for name, area, parent in sorted(hierarchy_entries, key=lambda x: (x[1], x[0])):
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

    # ---- 10. Regenerate runtime_hierarchy.json ----
    subprocess.run([sys.executable, str(root / 'tools' / 'generate_runtime_hierarchy.py')], check=True)

    # ---- 11. Regenerate tab_orders.json ----
    area_to_top = defaultdict(list)
    parent_to_children = defaultdict(list)
    for r in records:
        d = r['data']
        if d.get('id', '').startswith('link_') or d.get('id') == 'prebuilt_favorites':
            continue
        if not d.get('parentBoardId'):
            area_to_top[d.get('area', '')].append(d['name'])
        for tile in d.get('tiles', []):
            if tile.get('type') == 'board_link' or tile.get('isBoardLink'):
                child_id = tile.get('linkedBoardId', '')
                if child_id and child_id in id_to_name:
                    parent_to_children[d['id']].append(id_to_name[child_id])
    tab_orders = {}
    for area, names in area_to_top.items():
        key = 'prebuilt_' + normalize_id(area)
        tab_orders[key] = sorted(set(names))
    for parent_id, children in parent_to_children.items():
        seen = []
        for c in children:
            if c not in seen:
                seen.append(c)
        tab_orders[parent_id] = seen
    with open(root / 'lib' / 'data' / 'tab_orders.json', 'w', encoding='utf-8') as f:
        json.dump(tab_orders, f, indent=2, ensure_ascii=False)

    # ---- 12. Update pubspec.yaml ----
    subprocess.run([sys.executable, str(root / 'tools' / 'update_pubspec_assets.py')], check=True)

    print('Done.')
    print(f'  Deleted files: {len(to_delete)}')
    print(f'  Renamed/moved boards: {len(set(v for m in renames.values() for v in m.values()) - set(renames.keys()))}')

if __name__ == '__main__':
    main()
