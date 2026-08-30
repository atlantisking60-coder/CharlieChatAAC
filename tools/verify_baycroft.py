import json
import os

BAY = 'lib/data/boards/My School/People at Baycroft'
TT = 'lib/data/boards/My School/Timetables'
issues = []

children = []
for root, dirs, files in os.walk(BAY):
    dirs[:] = [d for d in dirs if d.lower() != '_deleted' and d != '_temp']
    for fn in sorted(files):
        if not fn.endswith('.json'):
            continue
        p = os.path.join(root, fn)
        try:
            d = json.load(open(p, encoding='utf-8-sig'))
        except Exception as e:
            issues.append('PARSE ERROR %s: %s' % (p, e))
            continue
        parent = d.get('parentBoardId')
        print('%-42s id=%-36s name=%-40s parent=%s tiles=%d' % (
            fn, d.get('id'), d.get('name'), parent, len(d.get('tiles', []))))
        if parent and parent != '':
            children.append(d.get('id'))
        if d.get('id') == 'baycroft_people_at_school':
            issues.append('stale id baycroft_people_at_school at %s' % p)
        if d.get('parentBoardId') == 'prebuilt_people_at_baycroft':
            issues.append('stale parent prebuilt_people_at_baycroft at %s' % p)
        if d.get('parentBoardId') == '__removed__':
            issues.append('stale parent __removed__ at %s' % p)
        if 'prebuilt_people_at_baycroft' in fn:
            issues.append('prebuilt_people_at_baycroft file still present: %s' % p)

print()
print('TOTAL children with parent:', len(children))
print('Distinct children:', sorted(set(children)))
print()
if issues:
    print('ISSUES:')
    for i in issues:
        print(' -', i)
else:
    print('No issues found')

print()
d = json.load(open(os.path.join(TT, 'baycroft_timetables.json'), encoding='utf-8-sig'))
print('Timetables: id=%s name=%s parent=%s isSubBoard=%s tiles=%d' % (
    d.get('id'), d.get('name'), d.get('parentBoardId'), d.get('isSubBoard'), len(d.get('tiles', []))))