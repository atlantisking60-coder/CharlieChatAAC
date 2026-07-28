import json
from pathlib import Path
root = Path('lib/data/boards')
for p in root.rglob('*.json'):
    d = json.loads(p.read_text(encoding='utf-8'))
    if d.get('parentBoardId') == d.get('id'):
        print('self-parent', p)
print('done')
