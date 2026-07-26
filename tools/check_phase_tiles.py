import json
import os
import re

BOARD_DIR = r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Common\Letters\Phonics"

for phase in [4, 5, 6]:
    fname = os.path.join(BOARD_DIR, f"Phase {phase} Phonics", f"prebuilt_phase_{phase}_phonics.json")
    if not os.path.exists(fname):
        print(f"\nPhase {phase}: FILE NOT FOUND at {fname}")
        continue
    with open(fname, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    tiles = data.get('tiles', [])
    phase2_tiles = [t for t in tiles if 'Phonics - Phase 2' in t.get('imageAsset', '')]
    all_with_images = [t for t in tiles if t.get('imageAsset')]
    
    print(f"\n=== Phase {phase} Phonics ===")
    print(f"  Board name: {data.get('name', 'N/A')}")
    print(f"  Total tiles: {len(tiles)}")
    print(f"  Tiles with ANY image: {len(all_with_images)}")
    print(f"  Tiles using 'Phonics - Phase 2.png': {len(phase2_tiles)}")
    
    if phase2_tiles:
        for t in phase2_tiles:
            label = t.get('label', '')
            clean_name = re.sub(r'\s*\(phonics\)\s*$', '', label, flags=re.IGNORECASE).strip()
            print(f"    label='{label}' -> clean_name='{clean_name}'")
    
    # Show all non-blank tiles
    print(f"\n  All non-blank tiles:")
    for t in tiles:
        label = t.get('label', '')
        img = t.get('imageAsset', '')
        if label or img:
            short_img = img if not img else ('...' + img[-60:] if len(img) > 60 else img)
            print(f"    label='{label}' image='{short_img}'")
