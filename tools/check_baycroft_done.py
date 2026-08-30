import json
import os

ROOT = 'lib/data/boards'
bad = []
count = 0
for root, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d.lower() not in ('_deleted', '_temp', 'backups', '.artifacts')]
    for fn in files:
        if not fn.endswith('.json'):
            continue
        p = os.path.join(root, fn)
        count += 1
        try:
            json.load(open(p, encoding='utf-8-sig'))
        except Exception as e:
            bad.append('%s -> %s' % (p, e))

print('Parsed %d JSON files' % count)
if bad:
    print('FAILURES:')
    for b in bad:
        print(' -', b)
else:
    print('All boards parse OK')

# Verify no double-version rows referenced anywhere in data dirs for baycroft
print()
print('baycroft ids found in board_index.dart:')
src = open('lib/data/board_index.dart', encoding='utf-8').read()
for token in ('baycroft_people_at_baycroft', 'baycroft_timetables', 'prebuilt_people_at_baycroft', 'baycroft_people_at_school'):
    print('  %s: %d' % (token, src.count(token)))