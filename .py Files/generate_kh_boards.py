#!/usr/bin/env python3
"""Generate Kingdom Hearts board JSONs (Legends/Computer Games/Kingdom Hearts).

Boards:
  Kingdom Hearts (root): 40 character PNGs + link tiles to Heartless and Nobodies
  Heartless:             478 enemy PNGs ordered by first appearance across
                         the Kingdom Hearts games
  Nobodies:              37 PNGs in alphabetical order

Output mirrors the asset tree under
  lib/data/boards/Legends/Computer Games/Kingdom Hearts/<...>/prebuilt_*.json
Uses the same JSON format as generate_legends_boards.py (image, linkedBoardName).
"""

import json
import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
ASSETS_ROOT = PROJECT_ROOT / "assets" / "Legends" / "Computer Games" / "Kingdom Hearts"
BOARDS_ROOT = (
    PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Computer Games" / "Kingdom Hearts"
)


def board_id(name: str) -> str:
    raw = name.lower()
    buf = []
    for ch in raw:
        if ch == ' ' or ch == '-':
            buf.append('_')
        elif ch == '_' or (ch.isascii() and ch.isalnum()):
            buf.append(ch)
    return 'prebuilt_' + ''.join(buf)


def snake_case(s: str) -> str:
    s = s.replace('ω', 'omega').replace('χ', 'chi')
    return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')


# ──────────────────────────────────────────────────────────────────────────────
# Heartless first-appearance ordering (stem names, in display order)
# Grouped by game of first introduction, world-ordered within each game where
# practical. Unlisted files are appended alphabetically by the generator.
# ──────────────────────────────────────────────────────────────────────────────

KH1 = [
    # Destiny Islands / tutorial
    "shadow", "darkside",
    # Traverse Town
    "soldier", "large body", "red nocturne", "blue rhapsody", "yellow opera",
    "green requiem", "opposite armor", "clay armor",
    # Wonderland
    "trickmaster", "barrel spider",
    # Deep Jungle
    "air soldier", "powerwild", "white mushroom", "pink agaricus",
    "rare truffle", "sniper wild", "bouncywild",
    # Agrabah
    "bandit", "fat bandit", "pot spider", "pot centipede", "pot scorpion",
    # Atlantica
    "screwdiver", "misslediver", "aquatank",
    # Halloween Town
    "pumpkin soldier",
    # Neverland
    "chimera",
    # Hollow Bastion
    "wight knight", "bookmaster", "wizard", "defender", "grand ghost",
    "gargoyle knight", "gargoyle warrior", "stealth soldier", "angel star",
    "detonator", "air pirate", "wyvern", "red armor",
    # End of the World
    "behemoth", "large armor", "solid armor", "darkball", "invisible",
    # Sora's heartless / bosses / specials
    "shadow sora", "anti sora", "sora heartless", "sora heartless form",
    "sora giant heartless", "guardian", "phantom", "kurt zisa",
    "ansem, seeker of darkness",
    # Final Mix additions
    "arch behemoth", "destroyed behemoth", "jet balloon",
    # Gummi heartless (first appeared in KH1 gummi missions)
    "crawler", "hunter", "hunter x", "reaper's wheel",
    "submarine", "pirate ship", "prize box", "stardust", "heavy laser",
    "flower guardian", "astrowarrior", "comet crawler", "frost penguin",
    "sonic diver", "rocket manta", "octoship", "dragonfly", "driller b",
    "strike shuttle", "wing spinner", "dreadshark", "scarlet shark",
    "glacial fortress", "colossus pyramid", "microsix", "schwarzgeist",
    "blue gummi saucer", "green gummi saucer", "red gummi saucer",
    "gummi hammer", "gummi hound", "red gummi copter",
]

COM = [
    "guard armor", "powered armor",
    # Castle Oblivion additions
    "black fungus", "creeper plant artwork", "gargoyle re co m",
]

KH2 = [
    # Twilight Town
    "mushroom xiii group",
    # Hollow Bastion II
    "armored knight", "deserter", "lance soldier", "lance warrior",
    "hammer frame", "iron hammer", "silver hammer frame", "gold hammer frame",
    "morning star", "nightwalker", "parasite cage", "ice cannon",
    # Land of Dragons
    "assault rider", "bolt tower", "shaman", "driller mole", "red bandit",
    # Beast's Castle
    "dire plant", "fire plant", "poison plant",
    "dark plant", "dark thorn", "thresholder",
    # Pride Lands
    "aerial knocker", "silver rock", "lion headliner",
    # Space Paranoids
    "rapid thruster", "spring metal",
    # Timeless River
    "hot rod", "aeroplane", "gilled glider", "emerald blues", "crimson jazz",
    "black ballade", "scarlet tango", "grey caprice",
    # Port Royal
    "pirate", "hook bat", "golden hook bat", "living bone", "leechgrave",
    "rabid dog",
    # Christmas Town
    "toy soldier", "trick ghost", "eggster bunny", "warlock step",
    "tornado step", "large snowman", "huge snowman", "ringmaster",
    "raging reindeer", "bully dog", "snapper dog", "rush sheep",
    # 100 Acre Wood / misc
    "ferocious fins", "icy beast", "eggcognito", "shenaneggan",
    "huge shenaneggan", "eggscapade", "growth egg", "prize egg", "munny egg",
    # Hollow Bastion / misc
    "bulky vendor", "rare vendor", "fortuneteller", "cannon gun",
    "red rose", "white rose", "search ghost", "hover ghost", "carrier ghost",
    "living pod", "rush ghost", "shred ghost", "sheltering zone",
    "flare note", "bubble beat", "rainy loudmouth", "terrible tomte",
    # The World That Never Was
    "graveyard", "diver", "high soldier",
    "neoshadow",
    # Final Mix / Cavern of Remembrance additions
    "air viking", "crescendo", "icy cube", "magnum loader",
    "mad bumper", "perplex", "silent launcher",
]

DAYS = [
    "antlion", "orcus", "dustflier", "zip slasher", "stalwart blade",
    "dual blade", "dual durandal", "heat saber", "chill ripper", "blitz spear",
    "air battler", "aerial master", "aerial champ", "artful flyer",
    "sky grappler", "armored archer", "sleep archer", "paralysis archer",
    "poison archer", "chomper egg", "wind up leaf cake", "creeper bouquet",
    "prank bouquet", "nosy mole", "pester jester", "wibble wobble",
    "strange tree", "circus clown", "tricky monkey", "cymbal monkey",
    "creepworm", "luna bandit", "magic phantom", "barrier master",
    "rune master", "storm bomb", "minute bomb", "switch launcher",
    "strafer", "devastator", "reckless", "destroyer", "surveillance robot",
    "eliminator", "necromancer", "spiked crawler",
    "striped aria", "pink concerto", "turquoise march", "sapphire elegy",
    "emerald serenade", "violet waltz", "emerald sonata", "amber opera",
    "sparkler",
    # Additional 358/2 Days heartless (researched)
    "blizzard plant", "skater", "scorching star", "shadow glob",
    "land armor", "jumbo cannon", "infernal engine", "novashadow",
    "avalanche", "wavecrest", "phantomtail", "tailbunker", "windstorm",
    "rulerofthe sky",
]

BBS = [
    "dark hide",
]

RECODED = [
    "core blox", "golden mushroom",
]

KHX = [
    # Darklings / possessors
    "darkling", "darklings", "possessor", "possessors", "massive possessor",
    "pink possessor", "cloudy sunrise", "shadow stalker",
    # Bug heartless
    "block bug", "damage bug", "metal bug", "prize bug",
    # Shadow family
    "gigant shadow", "mega shadow", "gift shadow", "shadow witch",
    "shadow magician",
    # Apple / rider heartless
    "lion dancer", "candy apple", "poison apple", "flower rider",
    "rodeo rider", "wayward wardrobe",
    # Gargoyles / statues
    "chocolate gargoyle", "white chocolate statue", "gargoyle wizard",
    # Misc small enemies
    "bit sniper", "dark follower", "pretender", "great pretender",
    "king pretender", "royal pretender", "poison pot", "wicked wick",
    "cannoned camel", "bunch o' balloons", "nimble bee", "stinging bee",
    "ratty rat", "ratty rat trio", "ring a ding", "piercing knight",
    "chipper chef", "burrfish", "gearbit", "red gearbit", "green gearbit",
    "blue gearbit", "sleepy snoozer", "dark wisp", "polliwog", "sly cat",
    "wily cat", "sergeant", "commander",
    # Raid bosses / event heartless
    "iron giant", "metal giant", "gear golem", "werewolf", "mean maiden",
    "jewel sorceress", "jewel princess", "adventurer", "greedy grouch",
    "enraged elk", "closehanded captain", "hocus pocus", "illuminator",
    "prison keeper", "volcanic lord", "blizzard lord", "storm rider",
    "grim reaper", "groundshaker", "savage vanguard", "fortress crab",
    "queen bee", "trident tail", "red trident tail", "green trident tail",
    "blue trident tail", "submarine carp", "enraged arachnid", "savage spider",
    "venomous spider", "scourge spider", "wicked spider", "malicious spider",
    "wretched witch", "assault dragon", "holiday sleigh", "thorned snake",
    "martial monkey", "weapon master", "mysterious sir", "ferry reaper",
    "loudmouth parade", "ribbitoad", "merry go rowdy", "titan", "shiva",
    "ramuh", "ifrit", "heartless tsum", "fiery globe",
    # Omega (ω) raid variants
    "darkside ω", "guard armor ω", "trickmaster ω", "fortress crab ω",
    "queen bee ω", "trident tail ω",
    # Additional χ / Union χ heartless (researched)
    "circus balloon", "circus crab", "crabby cake", "cranky cake",
    "cheery ape", "wild shaman", "apricot opera", "wily bandit",
    "swordsman", "armed warrior", "upright defender", "reversed defender",
    "pleasure dog", "bag o' coal", "bag o' coins", "bag o' gifts",
    "bag o' jewels", "dark score bag", "wicked watermelon",
    "large watermelon", "huge watermelon", "festive fireworks",
    "large fireworks", "huge fireworks", "round rice cake",
    "large rice cake", "bitter macaron", "mighty macaron",
    "colorful copter fleet", "jack o' lantern", "swaying spook",
    "wandering spook", "trick ghost-2", "high wizard",
]

KH3 = [
    # Olympus
    "flame core", "water core", "earth core", "popcat", "vitality popcat",
    "magic popcat", "focus popcat", "munny popcat", "bizzare archer",
    "rock troll", "satyr", "dark inferno", "mechanitaur",
    # Twilight Town
    "vermilion samba", "demon tide",
    # Toy Box
    "toy trooper", "pole cannon", "marionette", "king of toys",
    "jack in the box", "egg master", "crimson prankster", "stealth sneak",
    "sneak army", "angelic amber",
    # Kingdom of Corona
    "malachite bolero", "parasol beauty", "chief puff", "puffball",
    "chaos carriage", "grim guardianess",
    # Monstropolis
    "marine rumba", "gold beat", "pogo shovel", "demon tower",
    "sinister sweets", "spiteful sweets", "veil lizard", "lurk lizard",
    # Arendelle
    "helmed body", "winterhorn", "frost serpent", "sköll", "snowy crystal",
    # The Caribbean
    "vaporfly", "sea sprite", "spear lizard", "anchor raider",
    "raging vulture", "lightning angler", "shipwreck shark", "battleship",
    # San Fransokyo
    "tireblade", "darkubes", "catastrochorus", "metal troll",
    # Keyblade Graveyard / specials
    "fluttering", "flutterings", "lich",
    # Flans
    "cherry flan", "strawberry flan", "orange flan", "banana flan",
    "grape flan", "honeydew flan", "watermelon flan",
    # Gummi heartless (KH3)
    "flare shooter", "magnespace", "patafly", "sprinkler",
    "dazzling ball", "float lantern",
]

HEARTLESS_ORDER = (
    KH1 + COM + KH2 + DAYS + BBS + RECODED + KHX + KH3
)

NOBODY_ORDER = None  # alphabetical

# ──────────────────────────────────────────────────────────────────────────────
# Kingdom Hearts root character ordering (from GAME_ORDERINGS)
# ──────────────────────────────────────────────────────────────────────────────
CHARACTER_ORDER = [
    "sora", "riku", "kairi", "roxas", "namine", "rinoa", "donald", "goofy",
    "king mickey", "ansem", "xemnas",
]

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────
def slug_matches(stem, key):
    return key.lower() in stem.lower()


def sort_by_keys(files, keys):
    def key(fname):
        stem = Path(fname).stem
        for i, k in enumerate(keys):
            if slug_matches(stem, k):
                return (i, stem.lower())
        return (len(keys), stem.lower())
    return sorted(files, key=key)


def sort_heartless(files):
    keys = HEARTLESS_ORDER
    by_stem = {}
    for fname in files:
        stem = Path(fname).stem
        by_stem[stem] = fname
    ordered = []
    used = set()
    for k in keys:
        # match exact stem, else stem-with-suffix variants
        found = by_stem.get(k)
        if found is None:
            # allow '?'-like placeholder never matched
            continue
        ordered.append(found)
        used.add(found)
    # append any files not matched (alphabetical)
    rest = sorted((f for f in files if f not in used), key=lambda f: Path(f).stem.lower())
    return ordered + rest


def make_image_tile(bid, board_name, fname, category, rel_asset):
    stem = Path(fname).stem
    image = f"assets/Legends/{rel_asset}/{fname}" if rel_asset else f"assets/Legends/{fname}"
    return {
        "id": f"{bid}_{snake_case(stem)}",
        "type": "vocabulary",
        "label": stem,
        "category": category,
        "image": image,
        "emoji": "",
        "linkedBoardName": None,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": "",
    }


def make_link_tile(bid, board_name, child_name):
    child_id = board_id(child_name)
    return {
        "id": f"{bid}_{snake_case(child_name)}",
        "type": "board_link",
        "label": child_name,
        "category": board_name,
        "image": "",
        "emoji": "",
        "linkedBoardName": child_id,
        "isFullScreenImage": False,
        "bgColor": "#000000",
        "textColor": "#FFFFFF",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": "",
    }


def write_board(name, tier, parent_name, rel_asset, png_dir, tiles):
    bid = board_id(name)
    parent_bid = board_id(parent_name) if parent_name else None
    category = parent_name if parent_name else name
    columns = 6
    rows = max(1, (len(tiles) + columns - 1) // columns)
    board = {
        "id": bid,
        "name": name,
        "area": "Legends",
        "columns": columns,
        "backgroundColor": "transparent",
        "adjustableLayout": True,
        "isSubBoard": tier > 1,
        "isTertiaryBoard": tier >= 3,
        "isQuaternaryBoard": tier >= 4,
        "isQuinaryBoard": tier >= 5,
        "sortOrder": 0,
        "tier": tier,
        "parentBoardId": parent_bid,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {"rows": rows, "blankTilesAdded": 0},
        "tiles": tiles,
    }
    out = BOARDS_ROOT / rel_asset / f"{bid}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(board, f, ensure_ascii=False, indent=2)
    n_img = sum(1 for t in tiles if t['type'] == 'vocabulary')
    n_link = sum(1 for t in tiles if t['type'] == 'board_link')
    print(f"  {name:<20} tier={tier} img={n_img:>4} links={n_link} -> {rel_asset}/{bid}.json")


def main():
    kh_dir = ASSETS_ROOT
    heartless_dir = ASSETS_ROOT / "Heartless"
    nobodies_dir = ASSETS_ROOT / "Nobodies"

    kh_pngs = sorted(f.name for f in kh_dir.iterdir() if f.is_file() and f.suffix.lower() == '.png')
    h_pngs = sorted(f.name for f in heartless_dir.iterdir() if f.is_file() and f.suffix.lower() == '.png')
    n_pngs = sorted(f.name for f in nobodies_dir.iterdir() if f.is_file() and f.suffix.lower() == '.png')

    print(f"Kingdom Hearts PNGs: {len(kh_pngs)}")
    print(f"Heartless PNGs:      {len(h_pngs)}")
    print(f"Nobodies PNGs:       {len(n_pngs)}")

    # Kingdom Hearts root board
    kh_sorted = sort_by_keys(kh_pngs, CHARACTER_ORDER)
    kh_tiles = [make_image_tile(board_id("Kingdom Hearts"), "Kingdom Hearts", f,
                                "Computer Games", "Computer Games/Kingdom Hearts")
                for f in kh_sorted]
    kh_tiles.append(make_link_tile(board_id("Kingdom Hearts"), "Kingdom Hearts", "Heartless"))
    kh_tiles.append(make_link_tile(board_id("Kingdom Hearts"), "Kingdom Hearts", "Nobodies"))
    write_board("Kingdom Hearts", 2, "Computer Games", "", kh_dir, kh_tiles)

    # Heartless board
    h_sorted = sort_heartless(h_pngs)
    h_tiles = [make_image_tile(board_id("Heartless"), "Heartless", f,
                               "Kingdom Hearts", "Computer Games/Kingdom Hearts/Heartless")
               for f in h_sorted]
    # move the "heartless" logo image to the first tile
    h_idx = next((i for i, t in enumerate(h_tiles) if t['label'].lower() == 'heartless'), None)
    if h_idx is not None:
        h_tiles.insert(0, h_tiles.pop(h_idx))
    write_board("Heartless", 3, "Kingdom Hearts", "Heartless", heartless_dir, h_tiles)

    # Nobodies board (alphabetical), sibling of Heartless under Kingdom Hearts
    n_tiles = [make_image_tile(board_id("Nobodies"), "Nobodies", f,
                               "Kingdom Hearts", "Computer Games/Kingdom Hearts/Nobodies")
               for f in n_pngs]
    write_board("Nobodies", 3, "Kingdom Hearts", "Nobodies", nobodies_dir, n_tiles)

    # ---- verification ----
    missing = []
    for dirpath, _, filenames in os.walk(BOARDS_ROOT):
        for fn in filenames:
            if not fn.endswith('.json'):
                continue
            with open(os.path.join(dirpath, fn), encoding='utf-8') as f:
                b = json.load(f)
            for t in b.get('tiles', []):
                img = t.get('image') or ''
                if img and os.path.isfile(os.path.join(PROJECT_ROOT, img.replace('/', os.sep))):
                    continue
                if img:
                    missing.append((b['id'], t['id'], img))
    print(f"\nmissing images: {len(missing)}")
    for m in missing:
        print("  ", m)

    # check every heartless asset is covered
    assigned = {Path(f).stem for f in h_pngs}
    matched = {Path(f).stem for f in h_sorted}
    print(f"heartless assigned exactly once: {len(matched)}/{len(assigned)}")


if __name__ == '__main__':
    main()
