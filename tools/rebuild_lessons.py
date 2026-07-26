import json
import os
from pathlib import Path

root = Path(r'C:\Users\Craig\Downloads\Charlie Chat')
board_path = root / 'lib' / 'data' / 'boards' / 'My School' / 'prebuilt_lessons.json'

with open(board_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

tiles = data['tiles']

# Remove blank tiles
vocab_tiles = [t for t in tiles if t.get('type') != 'blank']

# Add new tiles if missing
new_labels = {
    'Health & Social Care': 'assets/symbols/Subjects/Health & Social Care.png',
    'Public Services': 'assets/symbols/Subjects/Public Services.png',
    'Design Technology': 'assets/symbols/Subjects/Design Technology.png',
}

existing_labels = {t['label'] for t in vocab_tiles if t.get('label')}
for label, image in new_labels.items():
    if label not in existing_labels:
        vocab_tiles.append({
            'id': f'prebuilt_lessons_t{len(vocab_tiles)+1}',
            'type': 'vocabulary',
            'label': label,
            'image': image,
            'linkedBoardName': None,
        })

# Special image fixes
image_overrides = {
    'PEEP': 'assets/symbols/Subjects/PEEP.png',
    'construction engineering': 'assets/symbols/Subjects/Construction.png',
    'P.E': 'assets/symbols/Subjects/P.E.png',
    'performing arts': 'assets/symbols/Subjects/Performing Arts.png',
    'resistant materials': 'assets/symbols/Subjects/Resistant Materials.png',
    'textiles': 'assets/symbols/Subjects/Textiles.png',
    'religion & worldviews': 'assets/symbols/Subjects/Religion & Worldviews.png',
    'sustainability': 'assets/symbols/Subjects/Sustainability.png',
    'cooking': 'assets/symbols/Subjects/Cooking.png',
    'horticulture': 'assets/symbols/Subjects/Horticulture.png',
    'retail': 'assets/symbols/Subjects/Retail.png',
    'photography': 'assets/symbols/Subjects/Photography.png',
    'living life skills': 'assets/symbols/Subjects/Living Life Skills.png',
    'prepare for adulthood': 'assets/symbols/Subjects/Prepare For Adulthood.png',
    'hair & beauty': 'assets/symbols/Subjects/Hair & Beauty.png',
    'information technology': 'assets/symbols/Subjects/I.T.png',
    'T.F.L': 'assets/symbols/Subjects/TFL.png',
    'english': 'assets/symbols/Subjects/English.png',
    'maths': 'assets/symbols/Subjects/Maths.png',
    'science': 'assets/symbols/Subjects/Science.png',
    'art': 'assets/symbols/Subjects/Art.png',
    'music': 'assets/symbols/Subjects/Music.png',
    'breaktime': 'assets/symbols/Subjects/Breaktime.png',
    'lunchtime': 'assets/symbols/Subjects/Lunchtime.png',
    'tutor time': 'assets/symbols/Subjects/Tutor Time.png',
    'personal development': 'assets/symbols/Subjects/P.D.png',
    'geography': 'assets/symbols/Subjects/Science.png',  # fallback
    'history': 'assets/symbols/Subjects/PEEP.png',  # fallback
    'languages': 'assets/symbols/Subjects/English.png',  # fallback
    'EPIC': 'assets/symbols/Subjects/EPIC.png',
}

for t in vocab_tiles:
    label = t.get('label', '')
    if label in image_overrides:
        t['image'] = image_overrides[label]

# Sort alphabetically by label (case-insensitive)
vocab_tiles.sort(key=lambda t: (t.get('label') or '').lower())

# Reassign ids
for i, t in enumerate(vocab_tiles, start=1):
    t['id'] = f'prebuilt_lessons_t{i}'

# Add blanks to fill grid
columns = data['columns']
rows = data['layout']['rows']
total_slots = columns * rows
needed_blanks = total_slots - len(vocab_tiles)

final_tiles = vocab_tiles[:]
for i in range(max(0, needed_blanks)):
    final_tiles.append({
        'id': f'prebuilt_lessons_blank_{i}',
        'type': 'blank',
        'label': None,
        'image': None,
        'linkedBoardName': None,
    })

data['tiles'] = final_tiles

with open(board_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print(f'Rebuilt {board_path} with {len(vocab_tiles)} tiles + {len(final_tiles) - len(vocab_tiles)} blanks')
