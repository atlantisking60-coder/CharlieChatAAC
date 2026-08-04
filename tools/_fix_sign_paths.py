import json
import os

BASE = 'lib/data/boards/Sign/A-Z Of Sign'

def run():
    fixed = 0
    for dp, _, fs in os.walk(BASE):
        for f in fs:
            if f == 'prebuilt_a-z_of_sign.json':
                continue
            if not f.startswith('prebuilt_') or not f.endswith('.json'):
                continue
            p = os.path.join(dp, f)
            with open(p, 'r', encoding='utf-8') as fh:
                data = json.load(fh)
            board_name = os.path.basename(dp)
            for tile in data.get('tiles', []):
                label = tile.get('label', '')
                tile['image'] = f'assets/Sign/A-Z Of Sign/{board_name}/{label}.png'
            with open(p, 'w', encoding='utf-8') as fh:
                json.dump(data, fh, indent=2, ensure_ascii=False)
                fh.write('\n')
            fixed += 1
    print(f'fixed {fixed} A-Z sign board(s)')

if __name__ == '__main__':
    run()
