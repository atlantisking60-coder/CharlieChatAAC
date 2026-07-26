import json
import os
import shutil

BACKUP_DIR = r"C:\Users\Craig\Downloads\Charlie Chat\BACKUP BOARDS"
BOARD_DIR = r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Common\Letters\Phonics"

targets = {
    3: 'prebuilt_phase_3_phonics',
    4: 'prebuilt_phase_4_phonics',
    5: 'prebuilt_phase_5_phonics',
    6: 'prebuilt_phase_6_phonics',
}

for phase, board_id in targets.items():
    print(f"\n=== Phase {phase} ===")
    
    # Find all backups for this board
    backups = []
    for fname in os.listdir(BACKUP_DIR):
        if not fname.startswith(board_id + '_') or not fname.endswith('.json'):
            continue
        fpath = os.path.join(BACKUP_DIR, fname)
        try:
            with open(fpath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            tile_count = len(data.get('tiles', []))
            backups.append((fname, tile_count, fpath))
        except:
            pass
    
    # Sort by tile count descending, then by filename (which contains timestamp) descending
    backups.sort(key=lambda x: (-x[1], x[0]), reverse=False)
    backups.sort(key=lambda x: (-x[1], x[0]))
    
    for fname, count, fpath in backups[:5]:
        print(f"  {fname}: {count} tiles")
    
    # Find best backup with tiles > 0
    best = None
    for fname, count, fpath in backups:
        if count > 0:
            best = (fname, count, fpath)
            break
    
    if best:
        print(f"\n  BEST: {best[0]} ({best[1]} tiles)")
        
        # Restore: read backup, write to source location
        with open(best[2], 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Determine target path
        target_dir = os.path.join(BOARD_DIR, f'Phase {phase} Phonics')
        target_path = os.path.join(target_dir, f'prebuilt_phase_{phase}_phonics.json')
        
        os.makedirs(target_dir, exist_ok=True)
        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"  RESTORED to: {target_path}")
        print(f"  Tiles: {len(data.get('tiles', []))}")
    else:
        print(f"  NO BACKUP WITH TILES FOUND!")
