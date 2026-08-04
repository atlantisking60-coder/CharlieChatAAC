import json
import re
import os

path = r'lib\data\boards\Sign\A-Z Of Sign\prebuilt_a-z_of_sign.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for tile in data.get('tiles', []):
    tid = tile.get('id', '')
    m = re.search(r'^prebuilt_a-z_of_sign_([a-z])_sign$', tid)
    if m:
        letter = m.group(1)
        tile['type'] = 'board_link'
        tile['linkedBoardName'] = f'prebuilt_{letter}_sign'

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'Updated {len(data.get("tiles", []))} A-Z of Sign tiles in {path}')
