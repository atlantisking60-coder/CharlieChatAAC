#!/usr/bin/env python3
"""Find all board JSONs in lib/data/boards/Legends that are missing images."""
import json, os

BOARDS_BASE = r"C:/Users/Craig/Downloads/Charlie Chat/lib/data/boards/Legends"
ASSETS_BASE = r"C:/Users/Craig/Downloads/Charlie Chat/assets/Legends"

issues = []

for root, dirs, files in os.walk(BOARDS_BASE):
    for f in sorted(files):
        if not f.startswith("prebuilt_") or not f.endswith(".json"):
            continue
        
        board_path = os.path.join(root, f)
        rel_board = os.path.relpath(board_path, BOARDS_BASE)
        
        with open(board_path, encoding="utf-8") as bf:
            try:
                board = json.load(bf)
            except:
                continue
        
        tiles = board.get("tiles", [])
        image_count = sum(1 for t in tiles if t.get("imageAsset"))
        
        if image_count == 0:
            # Check if there are images in the corresponding asset folder
            # Map board path to asset path
            # Board: Characters\Disney Stories\1937 Snow White.../prebuilt_1937_snow_white_...json
            # Asset: Characters\Disney Stories\1937 Snow White.../
            
            # The board folder structure mirrors the asset folder structure
            board_dir = os.path.dirname(board_path)
            rel_board_dir = os.path.relpath(board_dir, BOARDS_BASE)
            
            asset_dir = os.path.join(ASSETS_BASE, rel_board_dir.replace("/", "\\"))
            
            asset_images = []
            if os.path.isdir(asset_dir):
                for af in os.listdir(asset_dir):
                    full = os.path.join(asset_dir, af)
                    if os.path.isfile(full) and af.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                        asset_images.append(af)
            
            if asset_images:
                issues.append({
                    "board": rel_board,
                    "tiles": len(tiles),
                    "images": image_count,
                    "asset_images": len(asset_images),
                    "asset_dir": os.path.relpath(asset_dir, ASSETS_BASE) if os.path.isdir(asset_dir) else "NOT FOUND",
                    "parentBoardId": board.get("parentBoardId"),
                    "isTertiaryBoard": board.get("isTertiaryBoard"),
                    "isSubBoard": board.get("isSubBoard"),
                    "sample_assets": asset_images[:5]
                })
            elif len(tiles) <= 1:
                # Empty board with no assets - that's okay
                pass
            else:
                issues.append({
                    "board": rel_board,
                    "tiles": len(tiles),
                    "images": image_count,
                    "asset_images": 0,
                    "asset_dir": "NOT FOUND" if not os.path.isdir(asset_dir) else "",
                    "parentBoardId": board.get("parentBoardId"),
                    "isTertiaryBoard": board.get("isTertiaryBoard"),
                    "isSubBoard": board.get("isSubBoard"),
                    "sample_assets": []
                })

print(f"Found {len(issues)} board JSONs with 0 images but assets available:")
for issue in issues:
    print(f"\n  {issue['board']}: {issue['tiles']} tiles, {issue['images']} images")
    print(f"    Asset dir: {issue['asset_dir']}")
    print(f"    Asset images: {issue['asset_images']}")
    print(f"    parentBoardId: {issue['parentBoardId']}")
    print(f"    isTertiaryBoard: {issue['isTertiaryBoard']}, isSubBoard: {issue['isSubBoard']}")
    if issue['sample_assets']:
        print(f"    Sample assets: {issue['sample_assets']}")
