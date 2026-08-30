#!/usr/bin/env python3
"""Apply the specific audit fixes requested by the user."""

import json
import shutil
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARD_ROOT = PROJECT_ROOT / "lib" / "data" / "boards"


def load_json(path: Path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def save_json(path: Path, data: dict):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def fix_json(path: Path, updates: dict):
    data = load_json(path)
    data.update(updates)
    save_json(path, data)
    print(f"FIXED: {path.relative_to(PROJECT_ROOT)}")


def main():
    # 1. A-Z of Sign: tier 2, isTertiaryBoard false
    sign_az = BOARD_ROOT / "Sign" / "A-Z Of Sign"
    if sign_az.exists():
        for child_dir in sign_az.iterdir():
            if child_dir.is_dir():
                for json_file in child_dir.glob("*.json"):
                    fix_json(json_file, {
                        "tier": 2,
                        "isTertiaryBoard": False,
                        "isQuaternaryBoard": False,
                        "isQuinaryBoard": False,
                    })

    # 2. Sentence Creator Nouns: tier 2, isTertiaryBoard false
    nouns_file = BOARD_ROOT / "Subject Vocab" / "Sentence Creator" / "Nouns" / "prebuilt_nouns.json"
    if nouns_file.exists():
        fix_json(nouns_file, {
            "tier": 2,
            "isTertiaryBoard": False,
            "isQuaternaryBoard": False,
            "isQuinaryBoard": False,
        })

    # 3. Move X-Men boards to Legends/Superheroes/X-Men
    xmen_src = BOARD_ROOT / "Legends" / "X-Men"
    xmen_dest = BOARD_ROOT / "Legends" / "Superheroes" / "X-Men"
    if xmen_src.exists():
        xmen_dest.mkdir(parents=True, exist_ok=True)
        for child_dir in list(xmen_src.iterdir()):
            if child_dir.is_dir():
                json_files = list(child_dir.glob("*.json"))
                if not json_files:
                    continue
                src_file = json_files[0]
                dest_dir = xmen_dest / child_dir.name
                dest_dir.mkdir(parents=True, exist_ok=True)
                dest_file = dest_dir / src_file.name
                shutil.move(str(src_file), str(dest_file))
                print(f"MOVED: {src_file.relative_to(PROJECT_ROOT)} -> {dest_file.relative_to(PROJECT_ROOT)}")
                # Remove empty child_dir
                if not any(child_dir.iterdir()):
                    child_dir.rmdir()
        # Remove empty source dirs
        for d in sorted(xmen_src.rglob("*"), reverse=True):
            if d.is_dir() and not any(d.iterdir()):
                d.rmdir()
                print(f"RMDIR: {d.relative_to(PROJECT_ROOT)}")
        if xmen_src.exists() and not any(xmen_src.iterdir()):
            xmen_src.rmdir()
            print(f"RMDIR: {xmen_src.relative_to(PROJECT_ROOT)}")

    # 4. Fix too-shallow JSONs
    # 4a. Money (Maths) - depth 2, should be tier 2 sub-board
    money_file = BOARD_ROOT / "Subject Vocab" / "Maths" / "Money (Maths)" / "prebuilt_money_maths.json"
    if money_file.exists():
        fix_json(money_file, {
            "tier": 2,
            "isSubBoard": True,
            "isTertiaryBoard": False,
            "isQuaternaryBoard": False,
            "isQuinaryBoard": False,
        })

    # 4b. Famous Pirates - depth 3, should be tertiary
    pirates_file = BOARD_ROOT / "Subject Vocab" / "PEEP" / "Pirates (PEEP)" / "Famous Pirates" / "prebuilt_famous_pirates.json"
    if pirates_file.exists():
        fix_json(pirates_file, {
            "tier": 3,
            "isSubBoard": True,
            "isTertiaryBoard": True,
            "isQuaternaryBoard": False,
            "isQuinaryBoard": False,
        })

    # 4c. Special Days months - depth 4, should be quaternary
    special_days = BOARD_ROOT / "Common" / "Time" / "Events and Occasions" / "Special Days"
    if special_days.exists():
        for child_dir in special_days.iterdir():
            if child_dir.is_dir() and child_dir.name.startswith(tuple(str(i) for i in range(1, 13))):
                for json_file in child_dir.glob("*.json"):
                    fix_json(json_file, {
                        "tier": 4,
                        "isSubBoard": True,
                        "isTertiaryBoard": True,
                        "isQuaternaryBoard": True,
                        "isQuinaryBoard": False,
                    })

    # 5. Move More Symbols to Subject Vocab/Cooking/More Symbols
    more_symbols_src = BOARD_ROOT / "Subject Vocab" / "More Symbols"
    more_symbols_dest = BOARD_ROOT / "Subject Vocab" / "Cooking"
    if more_symbols_src.exists():
        more_symbols_dest.mkdir(parents=True, exist_ok=True)
        json_files = list(more_symbols_src.glob("*.json"))
        if json_files:
            src_file = json_files[0]
            dest_dir = more_symbols_dest / "More Symbols"
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest_file = dest_dir / src_file.name
            shutil.move(str(src_file), str(dest_file))
            print(f"MOVED: {src_file.relative_to(PROJECT_ROOT)} -> {dest_file.relative_to(PROJECT_ROOT)}")
            # Remove empty source dir
            if not any(more_symbols_src.iterdir()):
                more_symbols_src.rmdir()
                print(f"RMDIR: {more_symbols_src.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
