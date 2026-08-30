import json
import os
import re
import shutil

ROOT = os.path.join(os.getcwd(), 'lib', 'data', 'boards')
BAY = os.path.join(ROOT, 'My School', 'People at Baycroft')
TT = os.path.join(ROOT, 'My School', 'Timetables')
NEW_PARENT = 'baycroft_people_at_baycroft'

removed = []
moved = []
fixed = []


def remap_parent_text(text, target):
    # Rewrite any parentBoardId value (old parent id, prebuilt_people_at_baycroft,
    # or __removed__) to the target parent id.
    text = text.replace('baycroft_people_at_school', target)
    text = text.replace('prebuilt_people_at_baycroft', target)
    text = re.sub(r'"parentBoardId"\s*:\s*"__removed__"', '"parentBoardId": "' + target + '"', text)
    return text


# ---- 1. Create the canonical parent board ----
parent_src = os.path.join(BAY, '_deleted', 'baycroft_people_at_school.json')
data = json.load(open(parent_src, encoding='utf-8-sig'))
data['id'] = NEW_PARENT
data['name'] = 'People at Baycroft'
parent_out = os.path.join(BAY, NEW_PARENT + '.json')
with open(parent_out, 'w', encoding='utf-8', newline='') as f:
    f.write(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
removed.append(os.path.join(BAY, '_deleted', 'baycroft_people_at_school.json'))
removed.append(os.path.join(BAY, 'prebuilt_people_at_baycroft.json'))

# ---- 2. Fix + dedupe the 22 child boards ----
# Special restores/moves first.
# 7NGr: the real board lives in _deleted; cache file is the prebuilt_ copy.
ngr_deleted = os.path.join(BAY, '7NGr', '_deleted', 'baycroft_7ngr.json')
if os.path.exists(ngr_deleted):
    with open(ngr_deleted, encoding='utf-8-sig') as f:
        raw = f.read()
    raw = remap_parent_text(raw, NEW_PARENT)
    with open(os.path.join(BAY, '7NGr', 'baycroft_7ngr.json'), 'w', encoding='utf-8', newline='') as f:
        f.write(raw)
    moved.append(('7NGr/_deleted/baycroft_7ngr.json', '7NGr/baycroft_7ngr.json'))
    os.remove(ngr_deleted)

# Remove empty prebuilt/_deleted duplicates
dups = [
    os.path.join(BAY, '7EmS', 'prebuilt_7ems.json'),
    os.path.join(BAY, '7EmS', '_deleted', 'baycroft_7ems.json'),
    os.path.join(BAY, '7NGr', 'prebuilt_7ngr.json'),
    os.path.join(BAY, '8LBr', 'prebuilt_8lbr.json'),
    os.path.join(BAY, '8LBr', '_deleted', 'baycroft_8lbr.json'),
    os.path.join(BAY, 'Helpful People', 'prebuilt_helpful_people.json'),
]
for d in dups:
    if os.path.exists(d):
        removed.append(d)

for root_dir, dirs, files in os.walk(BAY):
    dirs[:] = [d for d in dirs if d not in ('_deleted', '_temp')]
    for fn in files:
        if not fn.endswith('.json'):
            continue
        path = os.path.join(root_dir, fn)
        if os.path.basename(path) == NEW_PARENT + '.json':
            continue
        with open(path, encoding='utf-8-sig') as f:
            raw = f.read()
        if 'baycroft_people_at_school' in raw or 'prebuilt_people_at_baycroft' in raw or '"__removed__"' in raw:
            fixed.append(os.path.relpath(path, BAY))
            raw = remap_parent_text(raw, NEW_PARENT)
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.write(raw)

# ---- 3. Restore Timetables ----
tt_src = os.path.join(TT, '_deleted', 'baycroft_timetables.json')
with open(tt_src, encoding='utf-8-sig') as f:
    raw = f.read()
data = json.loads(raw)
data['parentBoardId'] = None
data['isSubBoard'] = False
with open(os.path.join(TT, 'baycroft_timetables.json'), 'w', encoding='utf-8', newline='') as f:
    f.write(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
moved.append(('Timetables/_deleted/baycroft_timetables.json', 'Timetables/baycroft_timetables.json'))
os.remove(tt_src)
removed.append(os.path.join(TT, 'prebuilt_timetables.json'))
removed.append(os.path.join(TT, 'link_prebuilt_timetables.json'))

# ---- 4. _temp strays ----
strays = [
    os.path.join(ROOT, '_temp', 'Common', 'baycroft_timetables.json'),
    os.path.join(ROOT, '_temp', 'Common', 'prebuilt_baycroft_7ngr.json'),
    os.path.join(ROOT, '_temp', 'Common', 'prebuilt_baycroft_8lbr.json'),
    os.path.join(ROOT, '_temp', 'Unassigned', 'prebuilt_baycroft_8lbr.json'),
]
for s in strays:
    if os.path.exists(s):
        removed.append(s)
unassigned = os.path.join(ROOT, '_temp', 'Unassigned')
if os.path.isdir(unassigned) and not os.listdir(unassigned):
    removed.append(unassigned)

for r in removed:
    if os.path.isdir(r):
        try:
            os.rmdir(r)
            print('REMOVED dir :', os.path.relpath(r, ROOT))
            continue
        except OSError:
            pass
    if os.path.exists(r):
        os.remove(r)
        print('REMOVED     :', os.path.relpath(r, ROOT))

for m in moved:
    print('RESTORED    :', m)

for fr in fixed:
    print('PARENT FIXED:', fr)

print('Bridged parent JSON written:', os.path.relpath(parent_out, ROOT))