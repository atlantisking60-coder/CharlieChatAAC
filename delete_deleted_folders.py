#!/usr/bin/env python3
"""Delete all _deleted folders under lib/data/boards and remove empty parents."""

import shutil
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_ROOT = PROJECT_ROOT / "lib" / "data" / "boards"


def main():
    deleted_dirs = []
    for path in list(BOARDS_ROOT.rglob("_deleted")):
        if path.is_dir():
            count = sum(1 for _ in path.rglob("*"))
            shutil.rmtree(path)
            deleted_dirs.append((path.relative_to(PROJECT_ROOT), count))

    # Remove empty parent directories bottom-up, but stop at BOARDS_ROOT
    removed_parents = []
    for dir_path in sorted(BOARDS_ROOT.rglob("*"), reverse=True):
        if dir_path.is_dir() and dir_path != BOARDS_ROOT and not any(dir_path.iterdir()):
            dir_path.rmdir()
            removed_parents.append(dir_path.relative_to(PROJECT_ROOT))

    print(f"Deleted _deleted folders: {len(deleted_dirs)}")
    for p, count in deleted_dirs:
        print(f"  - {p} ({count} item{'s' if count != 1 else ''})")

    print(f"\nRemoved empty parent dirs: {len(removed_parents)}")
    for p in removed_parents:
        print(f"  - {p}")


if __name__ == "__main__":
    main()
