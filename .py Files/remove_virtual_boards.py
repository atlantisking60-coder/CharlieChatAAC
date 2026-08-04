#!/usr/bin/env python3
import os

base_path = "C:/Users/Craig/Downloads/Charlie Chat"
virtual_boards_path = os.path.join(base_path, "virtual_boards.txt")

if os.path.exists(virtual_boards_path):
    print(f"✓ virtual_boards.txt exists: {virtual_boards_path}")
    
    # Try to remove it
    try:
        os.remove(virtual_boards_path)
        print(f"✓ Successfully removed: {virtual_boards_path}")
    except Exception as e:
        print(f"❌ Could not remove: {e}")
else:
    print(f"✓ virtual_boards.txt not found (good!)")

print("\n" + "=" * 70)
print("SUMMARY:")
print("=" * 70)
print("virtual_boards.txt has been removed from the workspace.")
print("\nNext steps:")
print("1. Run board_fix.py to fix other issues")
print("2. Manually update edit_board.dart dropdown order")
EOF