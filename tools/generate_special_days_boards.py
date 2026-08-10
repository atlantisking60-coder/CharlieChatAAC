#!/usr/bin/env python3
"""Generate Special Days month board JSONs from tools/special_days_input.txt."""

import json
import os
import re
import unicodedata
from collections import OrderedDict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'lib', 'data', 'boards', 'Common', 'Time', 'Events and Occasions', 'Special Days')
ASSET_DIR = os.path.join(BASE_DIR, 'assets', 'Common', 'Time', 'Events and Occasions', 'Special Days')
INPUT_FILE = os.path.join(BASE_DIR, 'tools', 'special_days_input.txt')

IMAGE_EXTS = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'}

MONTH_ORDER = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
}

RANGE_TILES = [
    (1, 5, '1-5'),
    (6, 10, '6-10'),
    (11, 15, '11-15'),
    (16, 20, '16-20'),
    (21, 25, '21-25'),
    (26, 30, '26-30'),
    (31, 999, '31 and others'),
]


def normalize_filename(text: str) -> str:
    """Create a filesystem-safe filename stem from an event label."""
    text = text.lower().replace('&', 'and')
    text = re.sub(r"[^a-z0-9]+", ' ', text)
    return text.strip()


def safe_id(text: str) -> str:
    """Create a board id stem from a label."""
    text = text.lower().replace('&', 'and')
    text = re.sub(r"[^a-z0-9]+", '_', text)
    text = text.strip('_')
    return text


EVENT_STOP_WORDS = {'the', 'a', 'an', 'of', 'and', '&', 'to', 'in', 'on', 'for', 'with', 'is', 'it', 'at', 'by', 'day'}


def event_search_words(label: str):
    """Return meaningful search words from an event label for image matching."""
    text = label.lower().replace('&', 'and')
    text = re.sub(r"[^a-z0-9]+", ' ', text)
    words = text.strip().split()
    if words and words[-1] == 'day':
        words = words[:-1]
    return [w for w in words if w not in EVENT_STOP_WORDS and len(w) > 2]


def find_image_file(month_files, label: str):
    """Pick the best matching image filename from the month asset folder."""
    if not month_files:
        return None
    words = event_search_words(label)
    if not words:
        # fallback to the full normalized label
        words = [normalize_filename(label)]
    candidates = []
    for filename in month_files:
        stem = os.path.splitext(filename)[0]
        n_stem = normalize_filename(stem)
        exact_bonus = 1000 if n_stem == normalize_filename(label) else 0
        score = exact_bonus + sum(1 for w in words if w in n_stem)
        if score:
            candidates.append((score, len(filename), filename))
    if not candidates:
        return None
    candidates.sort(key=lambda x: (-x[0], x[1]))
    return candidates[0][2]


def read_months():
    """Read the input text and return OrderedDict of month -> [(day, label)]"""
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        raw = f.read()

    months = OrderedDict()
    current_month = None
    line_no = 0
    for line in raw.splitlines():
        line_no += 1
        line = line.strip()
        if not line:
            continue
        # Month header: 📅 MONTH (case-insensitive, may have leading spaces)
        m = re.match(r'^\s*📅\s+([a-zA-Z]+)\s*$', line, re.UNICODE)
        if m:
            month_name = m.group(1).lower().strip()
            if month_name not in MONTH_ORDER:
                print(f'Unknown month on line {line_no}: {month_name}')
                continue
            current_month = month_name
            if current_month not in months:
                months[current_month] = []
            continue
        # Event line: number or x followed by whitespace then label
        m = re.match(r'^\s*(\d+|x)\s+(.+?)\s*$', line, re.IGNORECASE)
        if m:
            if current_month is None:
                print(f'Orphaned event on line {line_no}: {line}')
                continue
            day = m.group(1).lower()
            label = m.group(2).strip()
            months[current_month].append((day, label))
            continue
        # Ignore unknown lines
    return months


def build_board(month_key: str, events, month_files=None):
    month_num = MONTH_ORDER[month_key]
    month_title = month_key.title()
    board_name = f'{month_num}. {month_title}'
    month_id = f'prebuilt_{month_num}_{month_key}'
    asset_month = f'{month_num} {month_title}'
    month_files = month_files or []

    tiles = []

    # Range tiles and their events
    event_index = 0
    for start, end, range_label in RANGE_TILES:
        # Add the range icon tile
        tiles.append(make_range_tile(month_id, range_label))

        # Events that fall in this day range
        for day, label in events:
            try:
                d = int(day)
            except ValueError:
                d = 100  # x / extra events go into the last "31 and others" group
            if start <= d <= end:
                tiles.append(make_event_tile(month_id, asset_month, day, label, event_index, month_files))
                event_index += 1

    # Pad to a 6x9 grid (54 tiles) with blanks
    while len(tiles) < 54:
        tiles.append(make_blank_tile(month_id, len(tiles) + 1))

    board = OrderedDict([
        ('id', month_id),
        ('name', board_name),
        ('area', 'Common'),
        ('columns', 6),
        ('backgroundColor', 'transparent'),
        ('adjustableLayout', False),
        ('isSubBoard', True),
        ('isTertiaryBoard', True),
        ('isQuaternaryBoard', False),
        ('isQuinaryBoard', False),
        ('sortOrder', 0),
        ('tier', 3),
        ('iconAssetPath', f'assets/Common/Time/Months/{month_key}.png'),
        ('tileIconAssetPath', f'assets/BOARDS/Time, Months, Events/{month_title}.png'),
        ('version', 0),
        ('boxScale', 1),
        ('tileHeight', 100),
        ('tileWidth', 100),
        ('layout', OrderedDict([('rows', 9), ('blankTilesAdded', 0)])),
        ('tiles', tiles),
        ('parentBoardId', 'prebuilt_special_days'),
    ])
    return board


def make_range_tile(month_id: str, range_label: str):
    safe = safe_id(range_label)
    display = range_label.replace('-', ' ')
    return OrderedDict([
        ('id', f'{month_id}_{safe}'),
        ('type', 'vocabulary'),
        ('label', display),
        ('category', 'Custom'),
        ('imageAsset', f'assets/Common/Time/Events and Occasions/Special Days/{range_label}.png'),
        ('emoji', ''),
        ('isBoardLink', False),
        ('linkedBoardId', ''),
        ('linkedBoardName', None),
        ('isFullScreenImage', False),
        ('bgColor', 'transparent'),
        ('textColor', '#000000'),
        ('tileSize', 1),
        ('colSpan', 1),
        ('rowSpan', 1),
        ('customVoice', ''),
    ])


def make_event_tile(month_id: str, asset_month: str, day: str, label: str, event_index: int, month_files=None):
    # x / extra events use day 'x' in the label but 'extra' in the id
    if day.lower() == 'x':
        day_part = f'x{event_index}'
    else:
        day_part = day
    safe = safe_id(label) or f'event_{event_index}'
    tile_id = f'{month_id}_{day_part}_{safe}'
    display = label.lower()
    best_file = find_image_file(month_files or [], label)
    if best_file:
        image_asset = f'assets/Common/Time/Events and Occasions/Special Days/{asset_month}/{best_file}'
    else:
        image_asset = None
    return OrderedDict([
        ('id', tile_id),
        ('type', 'vocabulary'),
        ('label', display),
        ('category', 'Custom'),
        ('imageAsset', image_asset),
        ('emoji', ''),
        ('isBoardLink', False),
        ('linkedBoardId', ''),
        ('linkedBoardName', None),
        ('isFullScreenImage', False),
        ('bgColor', 'transparent'),
        ('textColor', '#000000'),
        ('tileSize', 1),
        ('colSpan', 1),
        ('rowSpan', 1),
        ('customVoice', ''),
    ])


def make_blank_tile(month_id: str, index: int):
    return OrderedDict([
        ('id', f'{month_id}_tile_{index}'),
        ('type', 'blank'),
        ('label', ''),
        ('category', 'Custom'),
        ('imageAsset', None),
        ('emoji', ''),
        ('isBoardLink', False),
        ('linkedBoardId', ''),
        ('linkedBoardName', None),
        ('isFullScreenImage', False),
        ('bgColor', 'transparent'),
        ('textColor', '#000000'),
        ('tileSize', 1),
        ('colSpan', 1),
        ('rowSpan', 1),
        ('customVoice', ''),
    ])


def main():
    months = read_months()
    os.makedirs(DATA_DIR, exist_ok=True)
    for month_key, events in months.items():
        # January already exists, so don't overwrite it.
        if month_key == 'january':
            continue
        month_num = MONTH_ORDER[month_key]
        month_dir = os.path.join(DATA_DIR, f'{month_num}. {month_key.title()}')
        os.makedirs(month_dir, exist_ok=True)
        asset_month = f'{month_num} {month_key.title()}'
        month_asset_dir = os.path.join(ASSET_DIR, asset_month)
        month_files = []
        if os.path.isdir(month_asset_dir):
            month_files = [
                f for f in os.listdir(month_asset_dir)
                if os.path.splitext(f.lower())[1] in IMAGE_EXTS
            ]
        board = build_board(month_key, events, month_files)
        out_path = os.path.join(month_dir, f'prebuilt_{month_num}_{month_key}.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(board, f, indent=2, ensure_ascii=False)
            f.write('\n')
        print(f'Wrote {out_path} ({len(board["tiles"])} tiles)')


if __name__ == '__main__':
    main()
