import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

root = Path('C:/Users/Craig/Downloads/Charlie Chat')


def normalize_id(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower())
    s = re.sub(r"_+", "_", s)
    return s.strip("_")


def old_board_hierarchy():
    """Parse the original, ordered boardHierarchy list from git HEAD."""
    result = subprocess.run(
        ['git', 'show', 'HEAD:lib/data/board_hierarchy.dart'],
        cwd=root,
        capture_output=True,
        text=True,
        encoding='utf-8',
    )
    text = result.stdout

    single_re = re.compile(
        r"BoardHierarchyEntry\(\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'(?:\s*,\s*'((?:\\'|[^'])*)')?\s*\)\s*,?"
    )
    double_re = re.compile(
        r'BoardHierarchyEntry\(\s*"([^"]*)"\s*,\s*\'([^\']*)\'(?:\s*,\s*\'([^\']*)\')?\s*\)\s*,?'
    )

    entries = []
    for line in text.splitlines():
        m = single_re.search(line) or double_re.search(line)
        if not m:
            continue
        name = m.group(1).replace("\\'", "'")
        area = m.group(2).replace("\\'", "'")
        parent = m.group(3)
        if parent is not None:
            parent = parent.replace("\\'", "'")
        entries.append((name, area, parent))
    return entries


def current_boards():
    boards = {}
    for f in (root / 'lib' / 'data' / 'boards').rglob('*.json'):
        if '_deleted' in [p.lower() for p in f.parts]:
            continue
        try:
            with open(f, 'r', encoding='utf-8-sig') as fp:
                d = json.load(fp)
        except Exception:
            continue
        if d.get('id'):
            boards[(d['area'], d['name'])] = d['id']
    return boards


def current_runtime():
    path = root / 'lib' / 'data' / 'runtime_hierarchy.json'
    with open(path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    return data.get('entries', [])


def map_old_to_current(old_name, area, runtime):
    """Find the current board name for an original (name, area)."""
    for e in runtime:
        if e['area'] != area:
            continue
        cur = e['name']
        if cur == old_name or cur.startswith(old_name + ' ('):
            return cur
    return old_name


def main():
    old = old_board_hierarchy()
    runtime = current_runtime()
    boards = current_boards()

    mapped = []
    for name, area, parent in old:
        cur = map_old_to_current(name, area, runtime)
        parent_cur = map_old_to_current(parent, area, runtime) if parent else None
        mapped.append((cur, area, parent_cur))

    tab_orders = defaultdict(list)
    seen = defaultdict(set)
    for cur, area, parent in mapped:
        if parent is None:
            key = boards.get((area, area), 'prebuilt_' + normalize_id(area))
        else:
            key = boards.get((area, parent))
            if not key:
                key = 'prebuilt_' + normalize_id(parent)
        if not key:
            continue
        if cur not in seen[key]:
            tab_orders[key].append(cur)
            seen[key].add(cur)

    with open(root / 'lib' / 'data' / 'tab_orders.json', 'w', encoding='utf-8') as f:
        json.dump(dict(tab_orders), f, indent=2, ensure_ascii=False)

    print(f'Wrote {len(tab_orders)} tab order entries.')


if __name__ == '__main__':
    main()
