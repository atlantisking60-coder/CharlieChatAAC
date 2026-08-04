import os, json

base = r'C:\Users\Craig\Downloads\Charlie Chat'
sw = os.path.join(base, 'lib', 'data', 'boards', 'Common', 'Small Words')

print('=== SMALL WORDS SUBDIRECTORY FILES ===')
print()
for dirpath, dirnames, filenames in os.walk(sw):
    for fn in sorted(filenames):
        if fn.endswith('.json') and fn != 'prebuilt_small_words.json':
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, sw)

            with open(full, 'rb') as f:
                raw = f.read(3)
            bom = 'BOM' if raw == b'\xef\xbb\xbf' else 'OK'

            with open(full, 'r', encoding='utf-8-sig') as f:
                d = json.load(f)

            tiles = d.get('tiles', [])
            has_imageAsset = any('imageAsset' in t for t in tiles)
            has_image = any('image' in t for t in tiles)
            has_isBoardLink = any('isBoardLink' in t for t in tiles)

            ids = [t.get('id') for t in tiles if t.get('id')]
            dup_ids = len(ids) != len(set(ids))
            null_ids = any(t.get('id') is None for t in tiles)

            issues = []
            if bom == 'BOM': issues.append('BOM')
            if len(tiles) == 0: issues.append('EMPTY(0 tiles)')
            if has_image and not has_imageAsset: issues.append('uses legacy image field')
            if null_ids: issues.append('has null tile IDs')
            if dup_ids: issues.append('has duplicate tile IDs')

            status = ', '.join(issues) if issues else 'OK'
            print(f'{rel}: {status} ({len(tiles)} tiles, bom={bom})')
            if tiles:
                t0 = tiles[0]
                print(f'  tile[0] keys: {sorted(t0.keys())}')
                print(f'  tile[0]: type={t0.get("type")}, has_isBoardLink={("isBoardLink" in t0)}, has_imageAsset={("imageAsset" in t0)}')
