#!/usr/bin/env python3
"""Verify the specific boards the user asked about."""

import json
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARD_ROOT = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends"

# Current locations for the requested boards.
BOARD_PATHS = [
    BOARD_ROOT / "Computer Games" / "Streets Of Rage" / "prebuilt_streets_of_rage.json",
    BOARD_ROOT / "Computer Games" / "Legacy Of Kain" / "prebuilt_legacy_of_kain.json",
    BOARD_ROOT / "Computer Games" / "Golden Axe" / "prebuilt_golden_axe.json",
    BOARD_ROOT / "Computer Games" / "Kid Chameleon" / "prebuilt_kid_chameleon.json",
    BOARD_ROOT / "Animations (Not Disney)" / "1998 The Prince Of Egypt" / "prebuilt_1998_the_prince_of_egypt.json",
    BOARD_ROOT / "Computer Games" / "Street Fighter" / "prebuilt_street_fighter.json",
    BOARD_ROOT / "Animations (Not Disney)" / "1982 The Secret Of Nimh" / "prebuilt_1982_the_secret_of_nimh.json",
    BOARD_ROOT / "Computer Games" / "prebuilt_computer_games.json",
    BOARD_ROOT / "Animations (Not Disney)" / "prebuilt_not_disney_animations.json",
]

EXPECTED = {
    "prebuilt_computer_games.json": {"tier": 1, "parent": None},
    "prebuilt_not_disney_animations.json": {"tier": 1, "parent": None},
    "prebuilt_streets_of_rage.json": {"tier": 2, "parent": "prebuilt_computer_games"},
    "prebuilt_legacy_of_kain.json": {"tier": 2, "parent": "prebuilt_computer_games"},
    "prebuilt_golden_axe.json": {"tier": 2, "parent": "prebuilt_computer_games"},
    "prebuilt_kid_chameleon.json": {"tier": 2, "parent": "prebuilt_computer_games"},
    "prebuilt_street_fighter.json": {"tier": 2, "parent": "prebuilt_computer_games"},
    "prebuilt_1998_the_prince_of_egypt.json": {"tier": 2, "parent": "prebuilt_not_disney_animations"},
    "prebuilt_1982_the_secret_of_nimh.json": {"tier": 2, "parent": "prebuilt_not_disney_animations"},
}


def load_json(path: Path):
    try:
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    except Exception as e:
        return {"error": f"JSON load failed: {e}"}


def main():
    all_ok = True
    print("Verifying requested boards...\n")
    for path in BOARD_PATHS:
        rel = path.relative_to(PROJECT_ROOT)
        exists = path.exists()
        data = load_json(path) if exists else {"error": "FILE NOT FOUND"}
        expected = EXPECTED.get(path.name, {})

        print(f"{rel}")
        print(f"  exists: {exists}")

        if "error" in data:
            print(f"  ERROR: {data['error']}")
            all_ok = False
        else:
            bid = data.get("id", "MISSING")
            name = data.get("name", "MISSING")
            area = data.get("area", "MISSING")
            tier = data.get("tier", "MISSING")
            parent = data.get("parentBoardId")
            is_sub = data.get("isSubBoard")
            tiles = len(data.get("tiles", []))

            print(f"  id: {bid}")
            print(f"  name: {name}")
            print(f"  area: {area}")
            print(f"  tier: {tier} (expected {expected.get('tier', '?')})")
            print(f"  parentBoardId: {parent} (expected {expected.get('parent', '?')})")
            print(f"  isSubBoard: {is_sub}")
            print(f"  tiles: {tiles}")

            if tier != expected.get("tier"):
                print(f"  ⚠ TIER MISMATCH")
                all_ok = False
            if parent != expected.get("parent"):
                print(f"  ⚠ PARENT MISMATCH")
                all_ok = False
        print()

    if all_ok:
        print("All requested boards load and have correct tier/parent.")
    else:
        print("Some requested boards have problems.")


if __name__ == "__main__":
    main()
