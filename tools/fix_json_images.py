import json
import os
import re
from collections import defaultdict
from pathlib import Path

# Paths
PROJECT_ROOT = Path(r'C:\Users\Craig\Downloads\Charlie Chat')
ASSETS_DIR = PROJECT_ROOT / 'assets' / 'symbols'
BOARDS_DIR = PROJECT_ROOT / 'lib' / 'data' / 'boards'

IMAGE_EXTENSIONS = ('.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg')


def normalize(name):
    """Normalize a label/filename for comparison."""
    if name is None:
        return ''
    return re.sub(r'[^a-z0-9]', '', name.lower().strip())


def normalize_label(label):
    """Return a normalized label and also an alternate form."""
    base = label.lower().strip()
    return base, base.replace(' ', '-'), base.replace(' ', '_')


def base_label(label):
    """Remove parenthetical content for broader matching."""
    return re.sub(r'\s*\([^)]*\)', '', label).strip().lower()


# Special-case mappings for labels that don't have a direct filename match.
# Format: normalized label -> asset path.
SPECIAL_MAPPINGS = {
    # Numbers (words -> digits)
    'zero': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/0.png',
    'one': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/1.png',
    'two': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/2.png',
    'three': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/3.png',
    'four': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/4.png',
    'five': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/5.png',
    'six': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/6.png',
    'seven': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/7.png',
    'eight': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/8.png',
    'nine': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/9.png',
    'ten': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/10.png',
    'eleven': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/11.png',
    'twelve': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/12.png',
    'thirteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/13.png',
    'fourteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/14.png',
    'fifteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/15.png',
    'sixteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/16.png',
    'seventeen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/17.png',
    'eighteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/18.png',
    'nineteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/19.png',
    'twenty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/20.png',
    'thirty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/30.png',
    'forty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/40.png',
    'fifty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/50.png',
    'sixty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/60.png',
    'seventy': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/70.png',
    'eighty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/80.png',
    'ninety': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/90.png',
    'hundred': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/hundred.png',
    'thousand': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/thousand.png',
    'million': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/million.png',
    'billion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/billion.png',
    'trillion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/trillion.png',
    'quarillion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/quadrillion.png',
    'and': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/and.png',
    # Colours (basic colours -> Shades Of images)
    'black': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
    'grey': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
    'white': 'assets/symbols/1. Main Boards/Colours/colourless.png',
    'silver': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
    'brown': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
    'primarycolours': 'assets/symbols/1. Main Boards/Colours/primary colours.png',
    'red': 'assets/symbols/1. Main Boards/Colours/Shades Of Red.png',
    'orange': 'assets/symbols/1. Main Boards/Colours/Shades Of Orange.png',
    'yellow': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
    'green': 'assets/symbols/1. Main Boards/Colours/Shades Of Green.png',
    'darkgreen': 'assets/symbols/1. Main Boards/Colours/Shades Of Green.png',
    'secondarycolours': 'assets/symbols/1. Main Boards/Colours/secondary colours.png',
    'blue': 'assets/symbols/1. Main Boards/Colours/Shades Of Blue.png',
    'darkblue': 'assets/symbols/1. Main Boards/Colours/Shades Of Blue.png',
    'purple': 'assets/symbols/1. Main Boards/Colours/Shades Of Purple.png',
    'violet': 'assets/symbols/1. Main Boards/Colours/Shades Of Purple.png',
    'pink': 'assets/symbols/1. Main Boards/Colours/Shades Of Pink.png',
    'tertiarycolours': 'assets/symbols/1. Main Boards/Colours/tertiary colours.png',
    'maroon': 'assets/symbols/1. Main Boards/Colours/Shades Of Red.png',
    'coffee': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
    'ocher': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
    'mustard': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
    'colourwheel': 'assets/symbols/1. Main Boards/Colours/colour wheel.png',
    'beige': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
    'rainbow': 'assets/symbols/1. Main Boards/Colours/rainbow.png',
    'complimentarycolours': 'assets/symbols/1. Main Boards/Colours/complimentary colours.png',
    # Other known missing labels
    'claw': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/claw.png',
    'beakbill': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/beak.png',
    'pricklesspinesquills': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/spines.png',
    'antler': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/antler.png',
    'pincer': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/pincer.png',
    'hump': 'assets/symbols/1. Main Boards/Animals & Habitats/Animal Body Parts/hump.png',
    'kid': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/kid (goat).png',
    'hatchling': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/hatchling.png',
    'nestling': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/nestling.png',
    'eaglet': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/eaglet.png',
    'owlet': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/owlet.png',
    'cria': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/cria.png',
    'sick': 'assets/symbols/1. Main Boards/Body Parts/sick.png',
    'presentorgift': 'assets/symbols/1. Main Boards/Time/Events & Occasions/Christmas/present.png',
    'santaclaus': 'assets/symbols/1. Main Boards/Time/Events & Occasions/Christmas/santa.png',
    'yuletidechocolatelog': 'assets/symbols/1. Main Boards/Time/Events & Occasions/Christmas/yule log.png',
    'coloursofchristmas': 'assets/symbols/1. Main Boards/Time/Events & Occasions/Christmas/colours of christmas.png',
    'birdofprey': 'assets/symbols/1. Main Boards/Animals & Habitats/Birds/bird of prey.png',
    'kestrel': 'assets/symbols/1. Main Boards/Animals & Habitats/Birds/kestrel.png',
    'parakeetparrotmacaw': 'assets/symbols/1. Main Boards/Animals & Habitats/Birds/parakeet.png',
    'icerink': 'assets/symbols/1. Main Boards/Places/Buildings/ice rink.png',
    'mallorshoppingcentre': 'assets/symbols/1. Main Boards/Places/Buildings/mall or shopping centre.png',
    'storeorshop': 'assets/symbols/1. Main Boards/Places/Buildings/store or shop.png',
    'calfmoose': 'assets/symbols/1. Main Boards/Animals & Habitats/Child Animals/calf (moose).png',
    'leavorexit': 'assets/symbols/1. Main Boards/Actions/leave or exit.png',
    'mixstir': 'assets/symbols/1. Main Boards/Actions/mix & stir.png',
    '000': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/0.png',
    'fog': 'assets/symbols/1. Main Boards/Weather/foggy.png',
    'rooms': 'assets/symbols/1. Main Boards/Places/Rooms & Home/rooms.png',
    'roomshome': 'assets/symbols/1. Main Boards/Places/Rooms & Home/rooms.png',
    'mr': 'assets/symbols/1. Main Boards/People/Mr.png',
    'mrs': 'assets/symbols/1. Main Boards/People/Mrs.png',
}


def scan_assets():
    """Scan all image assets and return a dict: normalized -> list of paths."""
    asset_map = defaultdict(list)
    for root, dirs, files in os.walk(ASSETS_DIR):
        for f in files:
            if f.lower().endswith(IMAGE_EXTENSIONS):
                full_path = Path(root) / f
                rel_path = full_path.relative_to(PROJECT_ROOT).as_posix()
                name_no_ext = os.path.splitext(f)[0]
                key = normalize(name_no_ext)
                if rel_path not in asset_map[key]:
                    asset_map[key].append(rel_path)
                # Also add a suffix-stripped key for duplicate icons like 'you (1).png'
                stripped = re.sub(r'\s*\(\d+\)$', '', name_no_ext).strip()
                if stripped.lower() != name_no_ext.lower():
                    stripped_key = normalize(stripped)
                    if rel_path not in asset_map[stripped_key]:
                        asset_map[stripped_key].append(rel_path)
    return asset_map


def infer_board_folders(board_name):
    """Infer likely asset folders for a board name."""
    name = board_name.lower()
    # Mapping of board names to likely asset folders
    hints = {
        'common words': ['1. Main Boards/Common'],
        'feelings': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'colours': ['1. Main Boards/Colours'],
        'sad': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'mad': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'scared': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'joyful': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'strong': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'calm': ['1. Main Boards/Feelings & Emotions', 'BOARDS/Feelings'],
        'shades of colours': ['1. Main Boards/Colours'],
        'prepositions': ['1. Main Boards/Prepositions'],
        'people': ['1. Main Boards/People', 'BOARDS/People'],
        'school people': ['1. Main Boards/People', 'BOARDS/People'],
        'animals': ['1. Main Boards/Animals & Habitats', 'BOARDS/Animals'],
        'mammals': ['1. Main Boards/Animals & Habitats/Mammals'],
        'birds': ['1. Main Boards/Animals & Habitats/Birds'],
        'reptiles': ['1. Main Boards/Animals & Habitats/Reptiles'],
        'amphibians': ['1. Main Boards/Animals & Habitats/Amphibians'],
        'insects': ['1. Main Boards/Animals & Habitats/Insects'],
        'arachnids': ['1. Main Boards/Animals & Habitats/Arachnids'],
        'invertebrates': ['1. Main Boards/Animals & Habitats/Invertebrates'],
        'fish': ['1. Main Boards/Animals & Habitats/Fish'],
        'habitats': ['1. Main Boards/Animals & Habitats/Habitats', 'BOARDS/English'],
        'sealife': ['1. Main Boards/Animals & Habitats/Sealife'],
        'nature vocabulary': ['1. Main Boards/Animals & Habitats/Nature'],
        'body parts of animals': ['1. Main Boards/Animals & Habitats/Body Parts of Animals'],
        'child animals': ['1. Main Boards/Animals & Habitats/Child Animals'],
        'groups of animals': ['1. Main Boards/Animals & Habitats/Groups of Animals'],
        'common actions': ['1. Main Boards/Actions'],
        'movement': ['1. Main Boards/Movement'],
        'buildings': ['1. Main Boards/Places/Buildings', 'BOARDS/English'],
        'rooms & home': ['1. Main Boards/Places/Rooms & Home', 'BOARDS/English'],
        'furniture': ['1. Main Boards/Places/Furniture', 'BOARDS/English'],
        'local places': ['1. Main Boards/Places', 'BOARDS/English'],
        'jobs & careers': ['1. Main Boards/Careers', 'BOARDS/English'],
        'weather': ['1. Main Boards/Weather'],
        'disasters': ['1. Main Boards/Weather', 'BOARDS/English'],
        'seasons': ['1. Main Boards/Weather', 'BOARDS/English'],
        'events & occasions': ['1. Main Boards/Time/Events & Occasions', 'BOARDS/English'],
        'easter keywords': ['1. Main Boards/Time/Easter Keywords'],
        'halloween keywords': ['1. Main Boards/Time/Halloween Keywords'],
        'bonfire night keywords': ['1. Main Boards/Time/Bonfire Night Keywords'],
        'christmas keywords': ['1. Main Boards/Time/Christmas Keywords'],
        'body parts': ['1. Main Boards/Body Parts'],
        'medical': ['1. Main Boards/Body Parts', 'BOARDS/English'],
        'internal organs': ['1. Main Boards/Body Parts/Internal Organs'],
        'time (clocks)': ['1. Main Boards/Time'],
        'months': ['1. Main Boards/Time'],
        'class equipment': ['1. Main Boards/Classroom Equipment'],
        'thinking skills': ['1. Main Boards'],
        'when things go wrong': ['1. Main Boards'],
        'lessons': ['1. Main Boards'],
        'tutor timetables': ['1. Main Boards'],
        'people at school': ['Baycroft Specific'],
        'baycroft expects': ['Baycroft Specific'],
        'actions': ['1. Main Boards/Actions'],
        'phonics': ['1. Main Boards/Phonics'],
        'phase 2 phonics': ['1. Main Boards/Phonics'],
        'phase 3 phonics': ['1. Main Boards/Phonics'],
        'phase 4 phonics': ['1. Main Boards/Phonics'],
        'phase 5 phonics': ['1. Main Boards/Phonics'],
        'phase 6 phonics': ['1. Main Boards/Phonics'],
        'alphabet': ['1. Main Boards/Alphabet'],
        'numbers': ['1. Main Boards/Numbers'],
        'places': ['1. Main Boards/Places', 'BOARDS/English'],
        'clothes': ['1. Main Boards/Clothes', 'BOARDS/English'],
        'money': ['1. Main Boards'],
        'interests': ['1. Main Boards/Common Interests'],
        'characters': ['1. Main Boards/People', 'BOARDS/People'],
    }
    return hints.get(name, [])


def find_best_match(label, candidates, board_name, default_folder):
    """Choose the best asset match for a label."""
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    # Prefer candidates in the defaultIconFolder
    if default_folder:
        default_folder_norm = default_folder.lower().replace('\\', '/').replace('assets/symbols/', '')
        for c in candidates:
            if default_folder_norm in c.lower():
                return c

    # Prefer candidates in the board's likely folders
    likely_folders = infer_board_folders(board_name)
    for folder in likely_folders:
        folder_lower = folder.lower()
        for c in candidates:
            if folder_lower in c.lower():
                return c

    # Fallback: first candidate
    return candidates[0]


def process_board_file(path, asset_map):
    """Process a single JSON board file and update missing images."""
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    board_name = data.get('name', '')
    default_folder = data.get('defaultIconFolder')
    tiles = data.get('tiles', [])

    # Track which labels have been assigned, and how many times, for duplicate handling
    label_assignment_counts = defaultdict(int)
    # Track asset assignments per tile to handle duplicates
    assigned_per_tile = {}

    changed = False
    tiles_to_remove = []
    for i, tile in enumerate(tiles):
        tile_type = tile.get('type', 'vocabulary')
        label = tile.get('label') or ''
        image = tile.get('image')

        if tile_type == 'blank' or not label:
            continue

        # Skip if image already exists and file is present
        if image and image.strip():
            rel_path = PROJECT_ROOT / image.replace('assets/', 'assets/')
            if (PROJECT_ROOT / image).exists():
                continue

        # Label corrections
        if label == '000)':
            label = '000'
            tile['label'] = label
        if label == 'fog':
            label = 'foggy'
            tile['label'] = label
        if label == 'риз':
            # Remove corrupted tile from Body Parts
            tiles_to_remove.append(i)
            continue

        # Special-case mappings first
        special_key = normalize(label)
        if special_key in SPECIAL_MAPPINGS:
            mapped = SPECIAL_MAPPINGS[special_key]
            if (PROJECT_ROOT / mapped).exists():
                tile['image'] = mapped
                changed = True
                print(f"  {path.name}: {label} -> {mapped} (special)")
                continue

        # Find matching assets
        candidates = []
        keys = [normalize(label)]
        base, slug1, slug2 = normalize_label(label)
        keys += [normalize(base), normalize(slug1), normalize(slug2), normalize(base_label(label))]
        for k in keys:
            if k in asset_map:
                for c in asset_map[k]:
                    if c not in candidates:
                        candidates.append(c)

        # Partial matching for single-word labels
        if not candidates:
            label_norm = normalize(label)
            label_words = [w for w in re.split(r'[^a-z0-9]', label.lower()) if len(w) > 2]
            for key, paths in asset_map.items():
                if len(label_norm) > 3 and (key == label_norm or label_norm in key or key in label_norm):
                    for c in paths:
                        if c not in candidates:
                            candidates.append(c)
                elif label_words:
                    for word in label_words:
                        if len(word) > 3 and word in key:
                            for c in paths:
                                if c not in candidates:
                                    candidates.append(c)
                            break

        if not candidates:
            continue

        # Handle duplicates with (1) and (2) suffixes
        assignment_key = normalize(label)
        count = label_assignment_counts[assignment_key]
        label_assignment_counts[assignment_key] += 1

        # Prefer candidates with exact filename match first
        exact_candidates = []
        for c in candidates:
            filename = os.path.splitext(os.path.basename(c))[0].lower()
            if filename == label.lower() or filename == base.lower() or filename == base_label(label):
                exact_candidates.append(c)
        if exact_candidates:
            candidates = exact_candidates

        # Also prefer files with numeric suffixes when duplicates are expected
        suffix_candidates = []
        if count > 0:
            for c in candidates:
                filename = os.path.splitext(os.path.basename(c))[0]
                if re.search(r'\s*\(1\)|\s*\(2\)|\s*1$|\s*2$', filename):
                    suffix_candidates.append(c)
            if suffix_candidates:
                candidates = suffix_candidates

        if len(candidates) >= 2:
            best = find_best_match(label, candidates, board_name, default_folder)
            others = [c for c in candidates if c != best]
            if count > 0 and others:
                chosen = find_best_match(label, others, board_name, default_folder)
            else:
                chosen = best
        else:
            chosen = find_best_match(label, candidates, board_name, default_folder)

        if chosen:
            tile['image'] = chosen
            changed = True
            print(f"  {path.name}: {label} -> {chosen}")

    if tiles_to_remove:
        for i in sorted(tiles_to_remove, reverse=True):
            tiles.pop(i)
        changed = True
        print(f"  {path.name}: removed {len(tiles_to_remove)} corrupted tile(s)")

    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print(f"Saved {path}")


def main():
    asset_map = scan_assets()
    print(f"Scanned {sum(len(v) for v in asset_map.values())} image assets.")

    board_files = list(BOARDS_DIR.rglob('*.json'))
    print(f"Found {len(board_files)} board JSON files.")

    for board_file in board_files:
        process_board_file(board_file, asset_map)


if __name__ == '__main__':
    main()
