import json
import os
import shutil

BOARDS = 'lib/data/boards'

# old id -> new id (My School area -> profile-specific baycroft_* ids)
RENAME = {
    'prebuilt_my_school_main': 'baycroft_my_school_main',
    'prebuilt_baycroft_expects': 'baycroft_expects',
    'prebuilt_blank_levels': 'baycroft_blank_levels',
    'prebuilt_class_equipment': 'baycroft_class_equipment',
    'prebuilt_food_options': 'baycroft_food_options',
    'prebuilt_my_school_lessons': 'baycroft_my_school_lessons',
    'prebuilt_other_useful_stuff': 'baycroft_other_useful_stuff',
    'prebuilt_school_events': 'baycroft_school_events',
    'prebuilt_thinking_skills': 'baycroft_thinking_skills',
    'prebuilt_when_things_go_wrong': 'baycroft_when_things_go_wrong',
}
REVERSE = {v: k for k, v in RENAME.items()}


def rewrite_refs(path, data):
    """Recursively rewrite any id/linkedBoardId/linkedBoardName/parentBoardId
    that references a renamed board, matching exact string equality so tile ids
    and unrelated ids are never touched."""
    changed = False

    def fix_str(s):
        nonlocal changed
        if s in RENAME:
            changed = True
            return RENAME[s]
        return s

    def walk(v):
        if isinstance(v, dict):
            out = {}
            for k, val in v.items():
                if isinstance(val, str):
                    if k in ('id', 'linkedBoardId', 'linkedBoardName', 'parentBoardId'):
                        out[k] = fix_str(val)
                    else:
                        out[k] = val
                elif isinstance(val, list):
                    out[k] = walk_list(val)
                elif isinstance(val, dict):
                    out[k] = walk(val)
                else:
                    out[k] = val
            return out
        return v

    def walk_list(v):
        return [walk(x) if isinstance(x, dict) else (fix_str(x) if isinstance(x, str) and x in RENAME else x) for x in v]

    return walk(data), changed


# 1. Rename the actual My School board files + their ids.
for root, dirs, files in os.walk(BOARDS):
    dirs[:] = [d for d in dirs if d not in ('_temp', 'Backups', '.artifacts') and d.lower() != '_deleted']
    for f in files:
        if not f.endswith('.json'):
            continue
        p = os.path.join(root, f)
        try:
            data = json.load(open(p, encoding='utf-8-sig'))
        except Exception:
            continue
        bid = data.get('id', '')
        if bid not in RENAME:
            continue
        new_id = RENAME[bid]
        data['id'] = new_id
        # Rename any link fields inside the board itself.
        data, _ = rewrite_refs(p, data)
        json.dump(data, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
        new_file = os.path.join(root, new_id + '.json')
        if os.path.abspath(p) != os.path.abspath(new_file):
            os.remove(new_file) if os.path.exists(new_file) else None
            shutil.move(p, new_file)
            print('RENAMED', os.path.relpath(p, BOARDS), '-> id', new_id)

# 2. Update references in every other board JSON.
for root, dirs, files in os.walk(BOARDS):
    dirs[:] = [d for d in dirs if d not in ('_temp', 'Backups', '.artifacts') and d.lower() != '_deleted']
    for f in files:
        if not f.endswith('.json'):
            continue
        p = os.path.join(root, f)
        try:
            data = json.load(open(p, encoding='utf-8-sig'))
        except Exception:
            continue
        new_data, changed = rewrite_refs(p, data)
        if changed:
            json.dump(new_data, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
            print('UPDATED REFS in', os.path.normpath(p))

# 3. Delete stale prebuilt_timetables.json (superseded by baycroft_timetables.json).
stale = os.path.join(BOARDS, 'My School', 'Timetables', 'prebuilt_timetables.json')
if os.path.exists(stale):
    os.remove(stale)
    print('DELETED stale', os.path.normpath(stale))

# 4. Report any remaining references to the old ids anywhere in lib/.
old_tokens = list(RENAME.keys())
remaining = []
for root, dirs, files in os.walk('lib'):
    dirs[:] = [d for d in dirs if d not in ('.dart_tool',)]
    for f in files:
        if not (f.endswith('.json') or f.endswith('.dart') or f.endswith('.txt') or f.endswith('.md')):
            continue
        p = os.path.join(root, f)
        try:
            txt = open(p, encoding='utf-8', errors='replace').read()
        except Exception:
            continue
        for tok in old_tokens:
            if tok in txt:
                remaining.append((os.path.normpath(p), tok))
# Ignore the Favorites/blank-levels tile id which keeps its own prefix, and board_index (regenerated later).
for r, tok in sorted(set(remaining)):
    print('REMAINING?', r, '->', tok)