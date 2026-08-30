import os, re, sys

skip_root = os.path.normpath('lib/data/boards/My School')
ids = ['prebuilt_my_school_main','prebuilt_baycroft_expects','prebuilt_blank_levels',
       'prebuilt_class_equipment','prebuilt_food_options','prebuilt_my_school_lessons',
       'prebuilt_other_useful_stuff','prebuilt_school_events','prebuilt_thinking_skills',
       'prebuilt_when_things_go_wrong']

def walk(d):
    for root, dirs, files in os.walk(d):
        dirs[:] = [x for x in dirs if x not in ('_temp','Backups','.artifacts') and x.lower() != '_deleted']
        for f in files:
            yield os.path.join(root, f)

roots = ['lib/data', 'lib']
for root in roots:
    for p in walk(root):
        if not (p.endswith('.dart') or p.endswith('.json') or p.endswith('.txt')):
            continue
        if os.path.normpath(p).startswith(skip_root):
            continue
        try:
            txt = open(p, encoding='utf-8', errors='replace').read()
        except Exception:
            continue
        hits = [i for i in ids if i in txt]
        if hits:
            print(os.path.normpath(p), '->', hits)