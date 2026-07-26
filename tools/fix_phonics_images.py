import json
import os
import re
import glob

BOARD_BASE = r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Common\Letters\Phonics"
ASSETS_BASE = r"C:\Users\Craig\Downloads\Charlie Chat\assets\symbols\1. Main Boards\Alphabet\Phonics"

phases = {
    4: {
        'board_json': os.path.join(BOARD_BASE, 'Phase 4 Phonics', 'prebuilt_phase_4_phonics.json'),
        'asset_dir': os.path.join(ASSETS_BASE, 'Phase 4'),
    },
    5: {
        'board_json': os.path.join(BOARD_BASE, 'Phase 5 Phonics', 'prebuilt_phase_5_phonics.json'),
        'asset_dir': os.path.join(ASSETS_BASE, 'Phase 5'),
    },
    6: {
        'board_json': os.path.join(BOARD_BASE, 'Phase 6 Phonics', 'prebuilt_phase_6_phonics.json'),
        'asset_dir': os.path.join(ASSETS_BASE, 'Phase 6'),
    },
}

# Also check Common Words folder for tricky words
COMMON_WORDS_DIR = r"C:\Users\Craig\Downloads\Charlie Chat\assets\symbols\1. Main Boards\Common"

for phase_num, info in phases.items():
    print(f"\n{'='*60}")
    print(f"PHASE {phase_num} PHONICS")
    print(f"{'='*60}")
    
    # Load board
    with open(info['board_json'], 'r', encoding='utf-8') as f:
        board = json.load(f)
    
    # Get available assets
    asset_files = {}
    if os.path.exists(info['asset_dir']):
        for fname in os.listdir(info['asset_dir']):
            if fname.lower().endswith(('.png', '.jpg', '.jpeg', '.svg')):
                name_without_ext = os.path.splitext(fname)[0]
                asset_files[name_without_ext.lower()] = fname
    
    # Also check common words for tricky words
    common_files = {}
    if os.path.exists(COMMON_WORDS_DIR):
        for fname in os.listdir(COMMON_WORDS_DIR):
            if fname.lower().endswith(('.png', '.jpg', '.jpeg', '.svg')):
                name_without_ext = os.path.splitext(fname)[0]
                common_files[name_without_ext.lower()] = fname
    
    print(f"Available assets in Phase {phase_num}: {sorted(asset_files.keys())}")
    print(f"Common word assets: {sorted(common_files.keys())}")
    print()
    
    tiles = board.get('tiles', [])
    changes = 0
    unmatched = []
    
    for tile in tiles:
        label = tile.get('label', '')
        if not label:
            continue
        
        # Skip board_link tiles
        if tile.get('isBoardLink') or tile.get('linkedBoardId'):
            continue
        
        # Strip "(phonics)" suffix
        clean_name = re.sub(r'\s*\(phonics\)\s*$', '', label, flags=re.IGNORECASE).strip()
        
        # Look for matching asset
        asset_key = clean_name.lower()
        image_path = None
        
        # Try exact match in phase folder first
        if asset_key in asset_files:
            image_path = f"assets/symbols/1. Main Boards/Alphabet/Phonics/Phase {phase_num}/{asset_files[asset_key]}"
        # Try common words folder
        elif asset_key in common_files:
            image_path = f"assets/symbols/1. Main Boards/Common/{common_files[asset_key]}"
        
        current_image = tile.get('image', '')
        
        if image_path:
            if current_image != image_path:
                tile['image'] = image_path
                changes += 1
                print(f"  MATCH: '{label}' -> '{clean_name}' -> {image_path}")
            else:
                print(f"  OK:    '{label}' already has correct image")
        else:
            unmatched.append((label, clean_name))
            print(f"  MISS:  '{label}' -> '{clean_name}' (no matching asset found)")
    
    print(f"\n  Summary: {changes} tiles updated, {len(unmatched)} unmatched")
    if unmatched:
        print(f"  Unmatched tiles:")
        for label, clean in unmatched:
            print(f"    '{label}' (clean: '{clean}')")
    
    # Write updated board
    if changes > 0:
        with open(info['board_json'], 'w', encoding='utf-8') as f:
            json.dump(board, f, indent=2, ensure_ascii=False)
        print(f"\n  Written: {info['board_json']}")
