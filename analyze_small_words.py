import os, json

root = r'C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Common\Small Words'

for dirpath, dirnames, filenames in os.walk(root):
    for fn in sorted(filenames):
        if fn.endswith('.json'):
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root)

            with open(full, 'rb') as f:
                raw = f.read()

            has_bom = raw[:3] == b'\xef\xbb\xbf'
            encoding = raw.decode('utf-8-sig')

            try:
                d = json.loads(encoding)
            except Exception as e:
                print(f'{rel}: JSON ERROR: {e}')
                continue

            tile_keys = set()
            for t in d.get('tiles', []):
                tile_keys.update(t.keys())

            uses_image = any('image' in t for t in d.get('tiles', []) if t.get('type') and t.get('type') != 'blank')
            uses_imageAsset = any('imageAsset' in t for t in d.get('tiles', []) if t.get('type') and t.get('type') != 'blank')

            area = d.get('area')
            parent = d.get('parentBoardId')
            tid = d.get('id')
            tname = d.get('name')

            issues = []
            if has_bom:
                issues.append('BOM')
            if uses_image and not uses_imageAsset:
                issues.append('old format (image)')
            if uses_imageAsset and not uses_image:
                issues.append('new format (imageAsset)')

            empty = len(d.get('tiles', [])) == 0
            if empty:
                issues.append('EMPTY (0 tiles)')

            print(f'{rel}: id={tid} name={tname} | tiles={len(d.get("tiles",[]))} | area={area} | parent={parent} | issues={issues} | keys={sorted(tile_keys)}')
