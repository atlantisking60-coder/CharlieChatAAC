#!/usr/bin/env python3
"""Restore A-Z Of Sign board content from dated backups."""

import shutil
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BACKUP_DIR = PROJECT_ROOT / "Backups" / "Boards" / "Sign" / "A-Z Of Sign"
CURRENT_DIR = PROJECT_ROOT / "lib" / "data" / "boards" / "Sign" / "A-Z Of Sign"


def main():
    restored = 0
    for letter_dir in CURRENT_DIR.iterdir():
        if not letter_dir.is_dir():
            continue
        # Find current JSON
        current_files = list(letter_dir.glob("*.json"))
        if not current_files:
            print(f"SKIP: no current JSON in {letter_dir.name}")
            continue
        current_file = current_files[0]

        # Find most recent backup JSON in matching backup folder
        backup_letter_dir = BACKUP_DIR / letter_dir.name
        if not backup_letter_dir.exists():
            print(f"SKIP: no backup folder for {letter_dir.name}")
            continue
        backup_files = sorted(backup_letter_dir.glob("*.json"))
        if not backup_files:
            print(f"SKIP: no backup JSON for {letter_dir.name}")
            continue
        backup_file = backup_files[-1]

        shutil.copy2(backup_file, current_file)
        print(f"RESTORED: {current_file.relative_to(PROJECT_ROOT)} <- {backup_file.name}")
        restored += 1

    print(f"\nRestored {restored} A-Z Of Sign boards.")


if __name__ == "__main__":
    main()
