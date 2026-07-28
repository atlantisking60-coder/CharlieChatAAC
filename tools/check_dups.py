import json
from pathlib import Path
p = Path('lib/data/boards')
ids = {}
for f in p.rglob('*.json'):
    try:
        d = json.loads(f.read_text(encoding='utf-8'))
        bid = d.get('id')
        if bid:
            if bid in ids:
                print('DUPLICATE', bid, '\n ', ids[bid], '\n ', f)
            else:
                ids[bid] = f
    except Exception as e:
        print('ERR', f, e)
print('total unique ids:', len(ids))
