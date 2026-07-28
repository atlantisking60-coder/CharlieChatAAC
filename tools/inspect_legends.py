import os, json, glob, sys
root = 'lib/data/boards/Legends'
files = sorted(glob.glob(os.path.join(root, '**/*.json'), recursive=True))
with open('tools/inspect_legends_out.txt', 'w', encoding='utf-8') as out:
    print('Total JSON:', len(files), file=out)
    for f in files:
        with open(f, encoding='utf-8') as fh:
            data = json.load(fh)
        rel = os.path.relpath(f, root)
        print(rel, '|', data.get('area','?'), '|', data.get('name','?'), '|', data.get('parentBoardId','None'), '|', data.get('isSubBoard','?'), '|', data.get('tier','?'), file=out)
