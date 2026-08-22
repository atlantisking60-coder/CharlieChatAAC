import json
from pathlib import Path
from collections import defaultdict

root = Path('C:/Users/Craig/Downloads/Charlie Chat')
boards_dir = root / 'lib' / 'data' / 'boards'

by_id = defaultdict(list)
by_name = defaultdict(list)
folder_counts = defaultdict(list)
area_mismatches = []

for f in boards_dir.rglob('*.json'):
    if not f.is_relative_to(boards_dir):
        continue
    try:
        with open(f, 'r', encoding='utf-8-sig') as fp:
            data = json.load(fp)
    except Exception as e:
        print(f'ERROR reading {f}: {e}')
        continue
    bid = data.get('id')
    name = data.get('name')
    area = data.get('area', '')
    folder = f.parent.relative_to(boards_dir)
    if bid:
        by_id[bid].append((str(f), name, area, folder))
    if name:
        by_name[name].append((str(f), bid, area, folder))
    folder_counts[f.parent].append((f.name, bid, name))

print('=== Duplicate IDs (same id in multiple files) ===')
dup_id_count = 0
for bid, items in sorted(by_id.items()):
    if len(items) > 1:
        dup_id_count += 1
        print(f'\n{bid}:')
        for path, name, area, folder in items:
            print(f'  {path}  (name={name}, area={area})')

print(f'\n=== Duplicate Names (same name in multiple files/areas) ===')
dup_name_count = 0
for name, items in sorted(by_name.items()):
    if len(items) > 1:
        dup_name_count += 1
        print(f'\n{name}:')
        for path, bid, area, folder in items:
            print(f'  {path}  (id={bid}, area={area})')

print('\n=== Folders with more than one JSON ===')
multi_count = 0
for folder, files in sorted(folder_counts.items(), key=lambda x: str(x[0])):
    if len(files) > 1:
        multi_count += 1
        print(f'\n{folder.relative_to(root)} ({len(files)} files):')
        for fname, bid, name in files:
            print(f'  {fname}  (id={bid}, name={name})')

print(f'\nSUMMARY: {dup_id_count} duplicate ids, {dup_name_count} duplicate names, {multi_count} folders with multiple JSONs')
