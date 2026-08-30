#!/usr/bin/env python3
"""Move Roman Numerals and fix remaining tier/flag audit issues."""

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
    # 1. Move Roman Numerals into Roman Empire (27 BC – 476)
    roman_numerals_src = BOARD_ROOT / "Subject Vocab" / "PEEP" / "Roman Numerals"
    roman_empire_dir = BOARD_ROOT / "Subject Vocab" / "PEEP" / "Roman Empire (27 BC – 476)"
    if roman_numerals_src.exists() and roman_empire_dir.exists():
        src_file = roman_numerals_src / "prebuilt_roman_numerals.json"
        dest_dir = roman_empire_dir / "Roman Numerals"
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest_file = dest_dir / "prebuilt_roman_numerals.json"
        shutil.move(str(src_file), str(dest_file))
        print(f"MOVED: {src_file.relative_to(PROJECT_ROOT)} -> {dest_file.relative_to(PROJECT_ROOT)}")
        # Remove empty source dir
        if not any(roman_numerals_src.iterdir()):
            roman_numerals_src.rmdir()
            print(f"RMDIR: {roman_numerals_src.relative_to(PROJECT_ROOT)}")

    # 2. TFL / IT years — isTertiaryBoard should be false
    tfl_dir = BOARD_ROOT / "Subject Vocab" / "TFL _ IT"
    if tfl_dir.exists():
        for year in ["TFL - Year 7", "TFL - Year 8", "TFL - Year 9"]:
            f = tfl_dir / year / f"prebuilt_{year.lower().replace(' - ', '_').replace(' ', '_')}.json"
            # Try a glob in case filename differs
            matches = list((tfl_dir / year).glob("*.json")) if (tfl_dir / year).exists() else []
            if matches:
                fix_json(matches[0], {"isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})

    # 3. Sentence Creator sub-boards — tier 2, isTertiaryBoard false
    sc_dir = BOARD_ROOT / "Subject Vocab" / "Sentence Creator"
    for sub in ["Advanced Sentence Building", "Adverbs", "No Small Words", "Verbs", "With Small Words"]:
        matches = list((sc_dir / sub).glob("*.json")) if (sc_dir / sub).exists() else []
        if matches:
            fix_json(matches[0], {"tier": 2, "isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})

    # 4. Electrical Safety — tier 2, isTertiaryBoard false
    elec = BOARD_ROOT / "Subject Vocab" / "Science" / "Electrical Safety" / "prebuilt_electrical_safety.json"
    if elec.exists():
        fix_json(elec, {"tier": 2, "isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})

    # 5. Retail sub-boards — tier 2, isTertiaryBoard false
    retail_dir = BOARD_ROOT / "Subject Vocab" / "Retail"
    for sub in ["Marketing", "Operations", "Payment and Finance", "Staff (Retail)"]:
        matches = list((retail_dir / sub).glob("*.json")) if (retail_dir / sub).exists() else []
        if matches:
            fix_json(matches[0], {"tier": 2, "isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})

    # 6. Statistics — tier 2, isTertiaryBoard false
    stats = BOARD_ROOT / "Subject Vocab" / "Maths" / "Statistics" / "prebuilt_statistics.json"
    if stats.exists():
        fix_json(stats, {"tier": 2, "isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})

    # 7. Common/Time/Months — tier 2, isTertiaryBoard false
    months = BOARD_ROOT / "Common" / "Time" / "Months" / "prebuilt_months.json"
    if months.exists():
        fix_json(months, {"tier": 2, "isTertiaryBoard": False, "isQuaternaryBoard": False, "isQuinaryBoard": False})


if __name__ == "__main__":
    main()
