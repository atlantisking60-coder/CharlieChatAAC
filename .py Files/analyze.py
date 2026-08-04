import os
import json
import shutil

print("=== STEP 1: BOARD STRUCTURE ANALYSIS ===")
print()

# Navigate to the actual workspace
workspace_path = 'C:/Users/Craig/Downloads/Charlie Chat/lib/data/boards/Legends/Characters'

if os.path.exists(workspace_path):
    print(f"✓ Characters directory exists: {workspace_path}")
    print()
    
    # List what's currently in the Characters directory
    print("Current contents of Characters directory:")
    for item in os.listdir(workspace_path):
        item_path = os.path.join(workspace_path, item)
        if item.endswith('.json'):
            print(f"  - JSON File: {item}")
            try:
                with open(item_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                if isinstance(data, dict):
                    name = data.get('name', 'Unknown')
                    area = data.get('area', 'None')
                    if area == 'Common':
                        print(f"    ^^^ AREA = 'Common' (needs to be changed to 'Legends')")
                    print(f"      Name: {name}, Area: {area}")
            except Exception as e:
                print(f"    Error: {e}")
        else:
            print(f"  - Folder: {item}")
            # Show structure of subfolders
            for subitem in os.listdir(item_path):
                if subitem.endswith('.json'):
                    print(f"    - {subitem}")
else:
    print(f"✗ Characters directory does not exist: {workspace_path}")

print()
print("=== SUMMARY ===")
print("We need to:")
print("1. Convert sub-boards from flat JSON files to index.json pattern")
print("2. Change area from 'Common' to 'Legends' for Disney sub-boards")
print("3. Add proper structure to use the index.json pattern")
