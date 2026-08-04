import json

path = r'C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Common\Small Words\prebuilt_small_words.json'

with open(path, 'rb') as f:
    raw = f.read()

print('File size:', len(raw), 'bytes')
print('First 10 bytes:', [hex(b) for b in raw[:10]])
print('Last 10 bytes:', [hex(b) for b in raw[-10:]])
print('Has BOM:', raw[:3] == b'\xef\xbb\xbf')

text = raw.decode('utf-8-sig')
d = json.loads(text)
print('Valid JSON: True')
print('Board name:', d.get('name'))
print('Tile count:', len(d.get('tiles', [])))

# Check for board_link tiles
for i, t in enumerate(d.get('tiles', [])):
    if t.get('type') == 'board_link':
        label = t.get('label')
        lbn = t.get('linkedBoardName')
        print(f'  Tile {i}: BOARD_LINK - label={label} linkedBoardName={lbn}')

# Show all tiles with their types and labels
for i, t in enumerate(d.get('tiles', [])):
    label = t.get('label', '')
    ttype = t.get('type', '')
    has_img = t.get('image') is not None or t.get('imageAsset') is not None
    has_link = t.get('linkedBoardName') is not None and t.get('linkedBoardName') != 'null'
    if ttype in ('board_link',) or has_link:
        print(f'  Tile {i}: type={ttype} label={label} linkedBoardName={t.get("linkedBoardName")} linkedBoardId={t.get("linkedBoardId")} isBoardLink={t.get("isBoardLink")} isBoardLink={t.get("isBoardLink")}')

print('No board_link tiles found' if not any(t.get('type') == 'board_link' for t in d.get('tiles', [])) else 'Found board_link tiles')
