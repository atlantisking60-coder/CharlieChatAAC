#!/usr/bin/env python3
"""Generate Legends board JSON files from the asset directory structure.

For each board in the Legends hierarchy:
1. Finds the corresponding asset directory under assets/Legends/
2. Lists all PNG files (non-recursively)
3. Sorts them by character importance
4. Writes a prebuilt_*.json file to lib/data/boards/Legends/ mirroring the
   asset tree
5. For parent boards, also generates board_link tiles for child boards
"""

import json
import os
import re
from pathlib import Path
from typing import Optional

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
ASSETS_ROOT = PROJECT_ROOT / "assets" / "Legends"
BOARDS_ROOT = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends"


# ──────────────────────────────────────────────────────────────────────────────
# Board ID generation — matches Dart _hierarchyBoardId (board_service.dart)
#  lowercase; space/hyphen → underscore; alnum/underscore → kept; else dropped
# ──────────────────────────────────────────────────────────────────────────────
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
    return re.sub(r'[^a-z0-9]+', '_', s.lower()).strip('_')


# ──────────────────────────────────────────────────────────────────────────────
# Hierarchy  (from board_hierarchy.dart lines 653–891)
# (name, area, parent_name_or_None)
# ──────────────────────────────────────────────────────────────────────────────
HIERARCHY = [
    ("Legends", "Legends", None),
    ("Books", "Legends", None),
    ("Cartoons and Puppets", "Legends", None),
    ("Looney Tunes", "Legends", "Cartoons and Puppets"),
    ("The House Of Mouse", "Legends", "Cartoons and Puppets"),
    ("The Muppets", "Legends", "Cartoons and Puppets"),
    ("Turtles", "Legends", "Cartoons and Puppets"),
    ("ReBoot", "Legends", "Cartoons and Puppets"),
    ("Ghostbusters", "Legends", "Cartoons and Puppets"),
    ("80s TV Shows", "Legends", "Cartoons and Puppets"),
    ("Animaniacs", "Legends", "Cartoons and Puppets"),
    ("The Simpsons", "Legends", "Cartoons and Puppets"),
    ("Computer Games", "Legends", None),
    ("Baldur's Gate 3", "Legends", "Computer Games"),
    ("Borderlands", "Legends", "Computer Games"),
    ("Cuphead", "Legends", "Computer Games"),
    ("Dragon Age", "Legends", "Computer Games"),
    ("Fable", "Legends", "Computer Games"),
    ("Final Fantasy", "Legends", "Computer Games"),
    ("FF10", "Legends", "Final Fantasy"),
    ("FF12", "Legends", "Final Fantasy"),
    ("FF13", "Legends", "Final Fantasy"),
    ("FF15", "Legends", "Final Fantasy"),
    ("FF16", "Legends", "Final Fantasy"),
    ("FF6", "Legends", "Final Fantasy"),
    ("FF7", "Legends", "Final Fantasy"),
    ("FF8", "Legends", "Final Fantasy"),
    ("FF9", "Legends", "Final Fantasy"),
    ("Hollow Knight", "Legends", "Computer Games"),
    ("Horizon", "Legends", "Computer Games"),
    ("Burning Shores", "Legends", "Horizon"),
    ("Forbidden West", "Legends", "Horizon"),
    ("Frozen Wilds", "Legends", "Horizon"),
    ("Logos", "Legends", "Horizon"),
    ("Zero Dawn", "Legends", "Horizon"),
    ("Kingdom Hearts", "Legends", "Computer Games"),
    ("Mario", "Legends", "Computer Games"),
    ("No Man's Sky", "Legends", "Computer Games"),
    ("Ori", "Legends", "Computer Games"),
    ("Palworld", "Legends", "Computer Games"),
    ("Pokemon", "Legends", "Computer Games"),
    ("Custom Eeveelutions", "Legends", "Pokemon"),
    ("Pokeballs and Important Items", "Legends", "Pokemon"),
    ("Pokemon - Gen 1 - Kanto (Fire Red, Leaf Green, Ocean Blue, Lightning Yellow)", "Legends", "Pokemon"),
    ("Pokemon - Gen 2 - Johto (Silver and Gold)", "Legends", "Pokemon"),
    ("Pokemon - Gen 3 - Hoenn (Ruby and Sapphire)", "Legends", "Pokemon"),
    ("Pokemon - Gen 4 - Sinnoh (Diamond and Pearl)", "Legends", "Pokemon"),
    ("Pokemon - Gen 5 - Unova (Black and White)", "Legends", "Pokemon"),
    ("Pokemon - Gen 6 - Kalos (X and Y)", "Legends", "Pokemon"),
    ("Pokemon - Gen 7 - Alola (Sun and Moon)", "Legends", "Pokemon"),
    ("Pokemon - Gen 8 - Galar (Sword and Shield)", "Legends", "Pokemon"),
    ("Pokemon - Gen 9 - Paldea (Scarlet and Violet)", "Legends", "Pokemon"),
    ("Pokemon Missed Evolutions", "Legends", "Pokemon"),
    ("Sonic", "Legends", "Computer Games"),
    ("Disney Stories", "Legends", None),
    ("1937 Snow White and The Seven Dwarfs", "Legends", "Disney Stories"),
    ("1940 Fantasia", "Legends", "Disney Stories"),
    ("1940 Pinocchio", "Legends", "Disney Stories"),
    ("1941 Dumbo", "Legends", "Disney Stories"),
    ("1942 Bambi", "Legends", "Disney Stories"),
    ("1950 Cinderella", "Legends", "Disney Stories"),
    ("1951 Alice In Wonderland", "Legends", "Disney Stories"),
    ("1953 Peter Pan", "Legends", "Disney Stories"),
    ("1955 Lady and The Tramp", "Legends", "Disney Stories"),
    ("1959 Sleeping Beauty", "Legends", "Disney Stories"),
    ("1961 101 Dalmatians", "Legends", "Disney Stories"),
    ("1963 The Sword In The Stone", "Legends", "Disney Stories"),
    ("1967 The Jungle Book", "Legends", "Disney Stories"),
    ("1970 The Aristocats", "Legends", "Disney Stories"),
    ("1973 Robin Hood", "Legends", "Disney Stories"),
    ("1977 The Rescuers", "Legends", "Disney Stories"),
    ("1977 Winnie The Pooh", "Legends", "Disney Stories"),
    ("1981 The Fox and The Hound", "Legends", "Disney Stories"),
    ("1985 The Black Cauldron", "Legends", "Disney Stories"),
    ("1986 The Great Mouse Detective", "Legends", "Disney Stories"),
    ("1988 Oliver and Company", "Legends", "Disney Stories"),
    ("1989 The Little Mermaid", "Legends", "Disney Stories"),
    ("1991 Beauty and The Beast", "Legends", "Disney Stories"),
    ("1992 Aladdin", "Legends", "Disney Stories"),
    ("1993 The Nightmare Before Christmas", "Legends", "Animations (Not Disney)"),
    ("1994 The Lion King", "Legends", "Disney Stories"),
    ("1995 Pocahontas", "Legends", "Disney Stories"),
    ("1995 Toy Story", "Legends", "Disney Stories"),
    ("1996 The Hunchback Of Notre Dame", "Legends", "Disney Stories"),
    ("1997 Hercules", "Legends", "Disney Stories"),
    ("1998 A Bug's Life", "Legends", "Disney Stories"),
    ("1998 Mulan", "Legends", "Disney Stories"),
    ("1999 Tarzan", "Legends", "Disney Stories"),
    ("2000 Dinosaur", "Legends", "Disney Stories"),
    ("2000 The Emperor's New Groove", "Legends", "Disney Stories"),
    ("2001 Atlantis - The Lost Empire", "Legends", "Disney Stories"),
    ("2001 Monsters, Inc", "Legends", "Disney Stories"),
    ("2002 Lilo and Stitch", "Legends", "Disney Stories"),
    ("2002 Treasure Planet", "Legends", "Disney Stories"),
    ("2003 Brother Bear", "Legends", "Disney Stories"),
    ("2003 Finding Nemo", "Legends", "Disney Stories"),
    ("2004 Home On The Range", "Legends", "Disney Stories"),
    ("2004 The Incredibles", "Legends", "Disney Stories"),
    ("2005 Chicken Little", "Legends", "Disney Stories"),
    ("2006 Cars", "Legends", "Disney Stories"),
    ("2007 Meet The Robinsons", "Legends", "Disney Stories"),
    ("2007 Ratatouille", "Legends", "Disney Stories"),
    ("2008 Bolt", "Legends", "Disney Stories"),
    ("2008 WALL-E", "Legends", "Disney Stories"),
    ("2009 The Princess and The Frog", "Legends", "Disney Stories"),
    ("2009 Up", "Legends", "Disney Stories"),
    ("2010 Tangled", "Legends", "Disney Stories"),
    ("2012 Brave", "Legends", "Disney Stories"),
    ("2012 Wreck-It Ralph", "Legends", "Disney Stories"),
    ("2013 Frozen", "Legends", "Disney Stories"),
    ("2014 Big Hero 6", "Legends", "Disney Stories"),
    ("2015 Inside Out", "Legends", "Disney Stories"),
    ("2015 The Good Dinosaur", "Legends", "Disney Stories"),
    ("2016 Moana", "Legends", "Disney Stories"),
    ("2016 Zootopia", "Legends", "Disney Stories"),
    ("2017 Coco", "Legends", "Disney Stories"),
    ("2020 Onward", "Legends", "Disney Stories"),
    ("2020 Soul", "Legends", "Disney Stories"),
    ("2021 Encanto", "Legends", "Disney Stories"),
    ("2021 Luca", "Legends", "Disney Stories"),
    ("2021 Raya and The Last Dragon", "Legends", "Disney Stories"),
    ("2022 Strange World", "Legends", "Disney Stories"),
    ("2022 Turning Red", "Legends", "Disney Stories"),
    ("2023 Elemental", "Legends", "Disney Stories"),
    ("2023 Wish", "Legends", "Disney Stories"),
    ("2025 Elio", "Legends", "Disney Stories"),
    ("Not Disney Animations", "Legends", None),
    ("An American Tail (1986)", "Legends", "Not Disney Animations"),
    ("The Land Before Time (1988)", "Legends", "Not Disney Animations"),
    ("All Dogs Go to Heaven (1989)", "Legends", "Not Disney Animations"),
    ("Real Life Heroes", "Legends", None),
    ("Religion, Myth and History", "Legends", None),
    ("Arabian and Middle Eastern Tales", "Legends", "Religion, Myth and History"),
    ("Arthurian Legend", "Legends", "Religion, Myth and History"),
    ("Asian Legends and Folklore", "Legends", "Religion, Myth and History"),
    ("Creatures and Races", "Legends", "Religion, Myth and History"),
    ("Fairy Tale Characters", "Legends", "Religion, Myth and History"),
    ("Famous Monsters and Horror Icons", "Legends", "Religion, Myth and History"),
    ("Gods, Titans, Heroes and Monsters", "Legends", "Religion, Myth and History"),
    ("Buddhism Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Christian Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Christian Angels and Demons", "Legends", "Christian Deities and People"),
    ("Angels", "Legends", "Christian Angels and Demons"),
    ("Demons", "Legends", "Christian Angels and Demons"),
    ("Egyptian Gods", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Family Trees", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Greek Gods", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Olympians", "Legends", "Greek Gods"),
    ("Titans", "Legends", "Greek Gods"),
    ("Heroes and Monsters (Greek and Roman)", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Hindu Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Islam Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Jewish Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Norse Gods", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Norse Heroes", "Legends", "Norse Gods"),
    ("Norse Locations", "Legends", "Norse Gods"),
    ("Norse Races", "Legends", "Norse Gods"),
    ("Norse Valkyries", "Legends", "Norse Gods"),
    ("Other Mythology", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Pagan Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Roman Gods", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Sikh Deities and People", "Legends", "Gods, Titans, Heroes and Monsters"),
    ("Legendary Heroes and Folk Heroes", "Legends", "Religion, Myth and History"),
    ("Literary and Gothic Characters", "Legends", "Religion, Myth and History"),
    ("Misc", "Legends", "Religion, Myth and History"),
    ("Robin Hood and English Folklore", "Legends", "Religion, Myth and History"),
    ("Sci-Fi and Fantasy", "Legends", None),
    ("Bleach", "Legends", "Sci-Fi and Fantasy"),
    ("DnD", "Legends", "Sci-Fi and Fantasy"),
    ("DnD Classes", "Legends", "DnD"),
    ("DnD Magic and Status", "Legends", "DnD"),
    ("DnD Races", "Legends", "DnD"),
    ("Doctor Who", "Legends", "Sci-Fi and Fantasy"),
    ("Farscape", "Legends", "Sci-Fi and Fantasy"),
    ("Gremlins", "Legends", "Sci-Fi and Fantasy"),
    ("Star Trek", "Legends", "Sci-Fi and Fantasy"),
    ("Deep Space 9", "Legends", "Star Trek"),
    ("Discovery", "Legends", "Star Trek"),
    ("Enterprise", "Legends", "Star Trek"),
    ("Known Races", "Legends", "Star Trek"),
    ("Lower Decks", "Legends", "Star Trek"),
    ("Picard", "Legends", "Star Trek"),
    ("Prodigy", "Legends", "Star Trek"),
    ("Starships", "Legends", "Star Trek"),
    ("Starfleet Academy", "Legends", "Star Trek"),
    ("Strange New Worlds", "Legends", "Star Trek"),
    ("The Animated Series", "Legends", "Star Trek"),
    ("The Next Generation", "Legends", "Star Trek"),
    ("The Original Series", "Legends", "Star Trek"),
    ("Voyager", "Legends", "Star Trek"),
    ("Star Wars", "Legends", "Sci-Fi and Fantasy"),
    ("The Expanse", "Legends", "Sci-Fi and Fantasy"),
    ("Blueprints", "Legends", "The Expanse"),
    ("The Lord Of The Rings", "Legends", "Sci-Fi and Fantasy"),
    ("The Hobbit", "Legends", "The Lord Of The Rings"),
    ("The Orville", "Legends", "Sci-Fi and Fantasy"),
    ("Wednesday", "Legends", "Sci-Fi and Fantasy"),
    ("Superheroes", "Legends", None),
    ("DC", "Legends", "Superheroes"),
    ("Aquaman", "Legends", "DC"),
    ("Bat Family", "Legends", "DC"),
    ("Doom Patrol", "Legends", "DC"),
    ("Green Arrow", "Legends", "DC"),
    ("Green Lantern", "Legends", "DC"),
    ("Justice League", "Legends", "DC"),
    ("Justice League Dark  Supernatural", "Legends", "DC"),
    ("Justice Society Of America (JSA)", "Legends", "DC"),
    ("Legends Of Tomorrow", "Legends", "DC"),
    ("New Gods, Apokolips and Cosmic Villains", "Legends", "DC"),
    ("Other Teams", "Legends", "DC"),
    ("Shazam", "Legends", "DC"),
    ("Super Family", "Legends", "DC"),
    ("Teen Titans", "Legends", "DC"),
    ("The Flash", "Legends", "DC"),
    ("Wonder Woman", "Legends", "DC"),
    ("Marvel", "Legends", "Superheroes"),
    ("Ant-Man", "Legends", "Marvel"),
    ("Black Panther", "Legends", "Marvel"),
    ("Black Widow and Hawkeye", "Legends", "Marvel"),
    ("Captain America", "Legends", "Marvel"),
    ("Deadpool", "Legends", "Marvel"),
    ("Doctor Strange", "Legends", "Marvel"),
    ("Eternals", "Legends", "Marvel"),
    ("Fantastic 4", "Legends", "Marvel"),
    ("Guardians Of The Galaxy", "Legends", "Marvel"),
    ("Hulk", "Legends", "Marvel"),
    ("Inhumans", "Legends", "Marvel"),
    ("Iron Man", "Legends", "Marvel"),
    ("Scarlet Witch", "Legends", "Marvel"),
    ("Spiderman", "Legends", "Marvel"),
    ("The Avengers", "Legends", "Marvel"),
    ("The Defenders and Street Level", "Legends", "Marvel"),
    ("Thor", "Legends", "Marvel"),
    ("Villains", "Legends", "Marvel"),
    ("X-Men", "Legends", "Superheroes"),
    ("Anti-Mutant Threats", "Legends", "X-Men"),
    ("Apocalypse and The Horsemen", "Legends", "X-Men"),
    ("Brotherhood of Mutants", "Legends", "X-Men"),
    ("Generation X", "Legends", "X-Men"),
    ("Hellfire Club", "Legends", "X-Men"),
    ("Major Villains", "Legends", "X-Men"),
    ("Marauders", "Legends", "X-Men"),
    ("Morlocks", "Legends", "X-Men"),
    ("New Mutants", "Legends", "X-Men"),
    ("Other", "Legends", "X-Men"),
    ("Weapon Program", "Legends", "X-Men"),
    ("X-Factor and Excalibur", "Legends", "X-Men"),
    ("X-Force", "Legends", "X-Men"),
    ("The X-Men", "Legends", "X-Men"),
    ("X-Men Later Additions", "Legends", "X-Men"),
    ("Xavier's Students", "Legends", "X-Men"),
]


# ──────────────────────────────────────────────────────────────────────────────
# Importance orderings — keyed by board NAME (not ID)
# Each list is an ordered list of keyword substrings. A file matches if ANY
# keyword is a substring of the filename stem (case-insensitive).
# The first matching keyword determines the position.
# ──────────────────────────────────────────────────────────────────────────────

DISNEY_ORDERINGS = {
    "The House Of Mouse": ["mickey", "minnie", "donald", "daisy", "goofy", "pluto", "pete", "chip", "dale", "huey", "dewey", "lewie", "scrooge", "launchpad"],
    "1937 Snow White and The Seven Dwarfs": [
        "snow white", "evil queen", "happy", "doc", "grumpy", "sleepy",
        "bashful", "sneezy", "dopey", "huntsman", "prince",
    ],
    "1940 Fantasia": [
        "mickey", "clarabelle", "donald", "chernabog", "leopold",
        "yen sid", "dance of the hours", "nutcracker",
    ],
    "1940 Pinocchio": [
        "pinocchio", "geppetto", "figaro", "cleo", "jiminy",
        "stromboli", "pleasure island", "coachman", "honest john",
    ],
    "1941 Dumbo": [
        "dumbo", "mrs jumbo", "timothy", "pink elephant", "casey jr",
        "stork", "ringmaster", "clown", "crow",
    ],
    "1942 Bambi": [
        "bambi", "mother", "thumper", "flower", "owl",
        "faline", "ronno", "man",
    ],
    "1950 Cinderella": [
        "cinderella", "fairy godmother", "prince", "anastasia",
        "drizella", "stepmother", "jaq", "gus",
    ],
    "1951 Alice In Wonderland": [
        "alice", "mad hatter", "white rabbit", "queen of hearts",
        "cheshire", "march hare", "caterpillar",
    ],
    "1953 Peter Pan": [
        "peter pan", "tinker", "wendy", "captain hook", "smee",
        "tiger lily", "nana", "lost boy", "crocodile",
    ],
    "1955 Lady and The Tramp": [
        "lady", "tramp", "trusty", "joe", "jellied",
    ],
    "1959 Sleeping Beauty": [
        "aurora", "maleficent", "phil", "flora", "fauna",
        "merriweather", "steffan", "king",
    ],
    "1961 101 Dalmatians": [
        "pongo", "perdita", "cruella", "puppy", "lucky",
        "penny", "patch", "pepper", "rover",
    ],
    "1963 The Sword In The Stone": [
        "arthur", "merlin", "madam mim", "archibald", "hazel",
    ],
    "1967 The Jungle Book": [
        "mowgli", "baloo", "bagheera", "akela",
        "shere khan", "kaa", "king louis", "rin",
    ],
    "1970 The Aristocats": [
        "duchess", "o'malley", "mariah", "berlioz", "toulouse",
        "figaro", "scat",
    ],
    "1973 Robin Hood": [
        "robin hood", "marian", "little john", "alan a. dale",
        "john", "sheriff", "prince",
    ],
    "1977 The Rescuers": [
        "bernadette", "bianca", "penny", "dolder", "snip", "snail",
    ],
    "1977 Winnie The Pooh": [
        "pooh", "piglet", "tigger", "eyore", "rabbit",
        "owl", "gopher", "pooh",
    ],
    "1981 The Fox and The Hound": [
        "tod", "copper", "vixey", "faline", "brock",
    ],
    "1985 The Black Cauldron": [
        "tain", "eilonwy", "gurgi", "fafnir", "horned king",
    ],
    "1986 The Great Mouse Detective": [
        "basil", "mary marple", "wiley", "dewdrop", "moriarty",
    ],
    "1988 Oliver and Company": [
        "oliver", "dodger", "fagin", "nancy", "tito",
    ],
    "1989 The Little Mermaid": [
        "ariel", "eric", "ursula", "sebastian", "flounder",
        "scuttle", "triton", "trixie",
    ],
    "1991 Beauty and The Beast": [
        "belle", "beast", "lumière", "lumiere", "cogsworth",
        "mrs. potts", "chip", "gaston", "le fou",
    ],
    "1992 Aladdin": [
        "aladdin", "jasmine", "jafar", "abu", "genie",
        "sultan", "iguana", "razoul",
    ],
    "1993 The Nightmare Before Christmas": [
        "jack skellington", "sally", "santa", "lock",
        "shark", "barrel", "mayor",
    ],
    "1994 The Lion King": [
        "simba", "nala", "mufasa", "scar",
        "timon", "pumbaa", "rafiki", "sarabi", "zazu", "ed",
    ],
    "1995 Pocahontas": [
        "pocahontas", "john smith", "kocoum", "ratcliffe",
        "powhatan", "merric", "florimel",
    ],
    "1995 Toy Story": [
        "woody", "buzz", "jessie", "rex", "slinky",
        "bo", "claw", "hamm", "potato",
    ],
    "1996 The Hunchback Of Notre Dame": [
        "quasimodo", "esmeralda", "clopin", "frollo", "phoebus",
    ],
    "1997 Hercules": [
        "hercules", "megara", "meg", "hades", "zeus",
        "hydra", "phil", "pegasus", "alcmene",
    ],
    "1998 A Bug's Life": [
        "flik", "helene", "attacus", "hopper", "princess",
    ],
    "1998 Mulan": [
        "mulan", "mushu", "shang", "xianni", "chi-fu",
    ],
    "1999 Tarzan": [
        "tarzan", "jane", "clayton", "kerchak", "kala",
        "terk", "tantor",
    ],
    "2000 Dinosaur": [
        "aladar", "nessa", "zini", "swoop", "baylene",
        "earl", "pter",
    ],
    "2000 The Emperor's New Groove": [
        "kuzco", "yzma", "pacha", "kuvas", "kip",
    ],
    "2001 Atlantis - The Lost Empire": [
        "milo", "kida", "rok", "mole", "vinny",
    ],
    "2001 Monsters, Inc": [
        "sulley", "mike", "boo", "cathy", "randall",
        "waternoose", "celia",
    ],
    "2002 Lilo and Stitch": [
        "lino", "stitch", "ning", "david", "jumba",
        "goro",
    ],
    "2002 Treasure Planet": [
        "jim hawkins", "long john", "billy", "breeze", "scroop",
    ],
    "2003 Brother Bear": [
        "kenai", "koda", "tukt", "denahi", "amarok",
    ],
    "2003 Finding Nemo": [
        "nemo", "marlin", "dory", "crush", "bruce",
        "squirt", "gill", "deb",
    ],
    "2004 Home On The Range": [
        "maggie", "grunnar", "penny", "eureka", "alfred",
    ],
    "2004 The Incredibles": [
        "mr. incredible", "elastigirl", "violet", "dash",
        "jack-jack", "frozone", "edg", "syler",
    ],
    "2005 Chicken Little": [
        "chicken little", "ace", "abby", "fuzzy", "bella",
    ],
    "2006 Cars": [
        "lightning", "mater", "sally", "luigi", "guido",
        "fillmore", "sarge", "flo", "ramone",
    ],
    "2007 Meet The Robinsons": [
        "lewis", "wilbur", "goob", "franny",
    ],
    "2007 Ratatouille": [
        "remy", "linguini", "colette", "anton", "skinner",
        "emile",
    ],
    "2008 Bolt": [
        "bolt", "penny", "rhino", "muster", "clawhauser",
    ],
    "2008 WALL-E": [
        "walle", "eve", "auto", "mo", "mopy",
    ],
    "2009 The Princess and The Frog": [
        "tiana", "naveen", "facilier", "charlotte", "lola",
    ],
    "2009 Up": [
        "carl", "russell", "kevin", "dug", "ellie",
        "charles",
    ],
    "2010 Tangled": [
        "rapunzel", "flynn", "gothel", "pascal", "maximus",
    ],
    "2012 Brave": [
        "merida", "eleanor", "murder", "witch", "ferris",
    ],
    "2012 Wreck-It Ralph": [
        "wreck", "ralph", "vanellope", "felix", "sergeant",
    ],
    "2013 Frozen": [
        "elsa", "anna", "olaf", "kristoff", "sven",
        "hans", "troll",
    ],
    "2014 Big Hero 6": [
        "hiro", "baymax", "go go", "wasabi",
        "honey", "fred", "yasai",
    ],
    "2015 Inside Out": [
        "joy", "sadness", "anger", "fear", "disgust",
        "bing bong",
    ],
    "2015 The Good Dinosaur": [
        "aron", "spot", "butch", "bush",
    ],
    "2016 Moana": [
        "moana", "maui", "grandma", "tefiti", "tamatoa",
    ],
    "2016 Zootopia": [
        "judy", "nick", "bellwether", "gazelle",
        "bogo", "mayor",
    ],
    "2017 Coco": [
        "miguel", "hector", "mama", "abel", "dante",
    ],
    "2020 Onward": [
        "ian", "barbarossa", "colt", "lauren",
    ],
    "2020 Soul": [
        "joe", "22", "jerry", "paul", "moonwind",
    ],
    "2021 Encanto": [
        "mirabel", "isabelle", "luisa", "dolores",
        "camil", "antonio", "abuela",
    ],
    "2021 Luca": [
        "luca", "alfredo", "giuliana", "massimo", "lori",
    ],
    "2021 Raya and The Last Dragon": [
        "raya", "sisu", "nok", "tuk",
    ],
    "2022 Strange World": [
        "searcher", "lore", "penny", "duke",
    ],
    "2022 Turning Red": [
        "mei", "paul", "grace", "roan", "mariah",
    ],
    "2023 Elemental": [
        "ember", "wade", "brock", "cathy",
    ],
    "2023 Wish": [
        "arielle", "val", "wish", "star",
    ],
    "2025 Elio": [
        "elio", "glim", "garbage",
    ],
}

SUPERHERO_ORDERINGS = {
    "Ant-Man": ["scott lang", "hope", "hank pym", "tjax", "ghost", "yellowjacket"],
    "Black Panther": ["tchalla", "shuri", "tchaka", "nakia", "okoye", "m'baku", "killmonger"],
    "Black Widow and Hawkeye": ["natasha", "clint", "yelena", "ronin"],
    "Captain America": ["steve rogers", "sam wilson", "bucky", "peggy", "ross", "sharon"],
    "Deadpool": ["deadpool", "wade", "weasel", "blindspot"],
    "Doctor Strange": ["strange", "wong", "mordo", "ancient one", "dormammu", "america"],
    "Eternals": ["thena", "sersi", "iwg", "kingo", "sprite", "phastos", "gilgamesh", "makkari"],
    "Fantastic 4": ["reed", "sue", "john", "ben", "doom"],
    "Guardians Of The Galaxy": ["quinlan", "gamora", "drax", "rocket", "groot", "mantis", "yondu"],
    "Hulk": ["bruce banner", "hulk", "betty", "thaddeus", "rickson"],
    "Inhumans": ["black bolt", "medusa", "karnilla", "maxim", "gorgon", "lockjaw"],
    "Iron Man": ["tony", "pepper", "james", "obadiah", "happy", "jarvis"],
    "Scarlet Witch": ["wanda", "vision", "agatha", "wiccan", "speed"],
    "Spiderman": [
        "peter parker", "mary jane", "gwen", "mysterio", "green goblin",
        "doc ock", "octavius", "sandman", "electro", "venom", "carnage",
        "kingpin", "kraven", "vulture", "shocker",
    ],
    "The Avengers": ["iron man", "captain america", "thor", "hulk", "black widow", "hawkeye"],
    "The Defenders and Street Level": ["daredevil", "jessica jones", "luke cage", "iron fist", "frank"],
    "Thor": ["thor", "loki", "odin", "frigga", "heimdall", "sif"],
    "Villains": ["green goblin", "doc ock", "venom", "sandman", "electro", "mysterio", "magneto", "joker", "harley", "lex luthor", "darkseid"],
    "Aquaman": ["arthur", "mera", "ocean master", "black manta", "aqualad", "vulko"],
    "Bat Family": ["bruce wayne", "dick grayson", "barbara", "tim drake", "stephanie", "damian", "nightwing", "batgirl", "oracle"],
    "Doom Patrol": ["cliff", "rachel", "larry", "jane", "mikey", "chief"],
    "Green Arrow": ["oliver", "felicity", "diggle", "laurel", "thea", "roy"],
    "Green Lantern": ["hal jordan", "john stewart", "guy gardner", "kyle rayner", "carol"],
    "Justice League": ["superman", "batman", "wonder woman", "flash", "green lantern", "aquaman", "cyborg", "martian manhunter"],
    "Justice League Dark  Supernatural": ["constantine", "zatanna", "swamp", "the question", "deadman"],
    "Justice Society Of America (JSA)": ["alan scott", "jay garrick", "hourman", "the atom", "hawkman", "doctor fate"],
    "Legends Of Tomorrow": ["sara", "ray", "kendra", "nate", "amaya", "zari"],
    "New Gods, Apokolips and Cosmic Villains": ["darkseid", "desaad", "steppenwolf", "miranda", "barda", "highfather"],
    "Other Teams": ["booster gold", "rip hunter", "blue beetle", "peacemaker", "vigilante"],
    "Shazam": ["shazam", "bill", "darla", "ezekiel", "mary"],
    "Super Family": ["superman", "lois", "jimmy", "lex luthor", "supergirl", "superboy"],
    "Teen Titans": ["dick", "rachel", "gar", "donna", "kori", "beast boy", "kid flash", "raven", "starfire"],
    "The Flash": ["barry", "iris", "joe", "cecil", "nora", "zoom", "reverse"],
    "Wonder Woman": ["diana", "steve", "hippolyta", "ariel"],
    "X-Men": ["xavier", "wolverine", "cyclops", "jean grey", "storm", "beast", "iceman", "nightcrawler", "colossus", "jubilee", "gambit"],
    "Anti-Mutant Threats": ["sentinel", "master", "purifier", "stryker", "weapon x"],
    "Apocalypse and The Horsemen": ["apocalypse", "archangel", "caliban", "mummira", "scarlet witch"],
    "Brotherhood of Mutants": ["magneto", "mystique", "toad", "pyro", "sabretooth", "blob", "quicksilver"],
    "Generation X": ["emma frost", "sebastian shaw", "holloway", "chamber"],
    "Hellfire Club": ["sebastian shaw", "emma frost", "lady deathstrike"],
    "Major Villains": ["magneto", "mystique", "sabretooth", "apocalypse", "lady deathstrike", "juggernaut"],
    "Marauders": ["sabretooth", "wolverine", "pyro", "arctic"],
    "Morlocks": ["tunnel", "caliban"],
    "New Mutants": ["daniel", "karma", "shatterstar", "mirage", "sunspot"],
    "Other": ["nightcrawler", "mystique"],
    "Weapon Program": ["wolverine", "silver samurai", "deathstrike", "x-23"],
    "X-Factor and Excalibur": ["hulkling", "wiccan", "speed", "lockheed", "nightcrawler", "colossus"],
    "X-Force": ["deadpool", "domino", "shatterstar", "cable", "wolverine"],
    "X-Men Later Additions": ["armor", "x-23", "proteus"],
    "Xavier's Students": ["xavier", "jean", "scott", "storm", "beast", "iceman", "wolverine"],
}

STAR_TREK_ORDERINGS = {
    "Deep Space 9": ["sisko", "kira", "dax", "bashir", "ock", "rom", "nerys", "quark", "garak", "dukat", "weyoun"],
    "Discovery": ["michael", "saru", "tiffin", "ash", "stella", "paul"],
    "Enterprise": ["archer", "trip", "tiffany", "phlox", "malcolm", "tpol", "hoshi", "reed"],
    "Known Races": ["klingon", "romulan", "dominion", "borg", "ferengi", "cardassian", "vulcan", "trill"],
    "Lower Decks": ["boimler", "mariner", "tendi", "rita"],
    "Picard": ["picard", "data", "beverly", "worf", "geordi", "soong"],
    "Prodigy": ["dal", "grob", "monq", "zeta"],
    "Starships": ["enterprise", "voyager", "defiant", "millennium falcon"],
    "Starfleet Academy": ["starfleet academy", "tilly", "anisha"],
    "Strange New Worlds": ["pike", "number one", "spock", "chapel", "m'benga"],
    "The Animated Series": ["kirk", "spock", "mccoy", "uhura", "scotty", "sulu"],
    "The Next Generation": ["picard", "riker", "data", "worf", "geordi", "troi", "beverly"],
    "The Original Series": ["kirk", "spock", "mccoy", "uhura", "scotty", "sulu"],
    "Voyager": ["janeway", "chakotay", "tuvok", "b'elanna", "tom", "seven", "doc"],
    "Star Trek": ["logo", "kirk", "spock", "star trek"],
}

STAR_WARS_ORDERINGS = {
    "Star Wars": [
        "luke skywalker", "leia organa", "han solo", "darth vader", "lando",
        "chewbacca", "r2", "c-3po", "yoda", "ob1", "boba fett", "stormtrooper",
        "darth maul", "count dooku", "grievous", "palpatine", "jar jar",
        "qui-gon", "anakin", "padmé", "rey", "finn", "poe", "kylo ren",
    ],
}

GAME_ORDERINGS = {
    "Mario": ["mario", "luigi", "peach", "daisy", "bowser", "bowser jr", "wario", "waluigi", "yoshi", "donkey kong", "diddy", "rosa", "toad"],
    "Kingdom Hearts": ["sora", "riku", "kairi", "roxas", "namine", "rinoa", "donald", "goofy", "king mickey", "ansem", "xemnas"],
    "Hollow Knight": ["knight", "hornet", "zote", "cornifer", "quirrel", "grimm", "dung", "lost kin"],
    "Cuphead": ["cuphead", "mugman", "charlie", "king dice", "devil", "cagney"],
    "Sonic": ["sonic", "tails", "knuckles", "shadow", "dr eggman", "silver", "rouge", "amy"],
    "No Man's Sky": ["atlas", "traveler", "exocraft", "multi-tool", "starship"],
    "Dragon Age": ["rook", "inquisitor", "solas", "morrigan", "varric", "alistair", "leliana", "cassandra", "dorian", "cullen", "flemeth", "loghain", "hawke", "elgar'nan", "ghilan'nain", "mythal"],
    "Ori": ["ori", "seir", "kuro", "gumo"],
    "Borderlands": ["brick", "mordecai", "lilith", "roland", "claptrap", "tannis", "moxxi"],
    "Fable": ["hero", "reaver", "theresa", "reaper", "jack"],
    "Baldur's Gate 3": ["gale", "shadowheart", "astarian", "laezel", "wyll", "karlach", "emperor"],
    "Final Fantasy": ["chocobo", "tonberry", "cactuar", "ff"],
    "FF7": ["cloud", "tifa", "barret", "aerith", "red xiii", "yuffie", "vincent", "cait sith", "sephiroth"],
    "FF8": ["squall", "rinoa", "quan", "zell", "selphie", "irvine", "laguna", "seifer", "edea"],
    "FF9": ["zidane", "garnet", "vivi", "freya", "quina", "ama", "eidolon", "kuja"],
    "FF10": ["tidus", "yuna", "aulia", "wakka", "lulu", "kimahri", "sora", "yevon"],
    "FF12": ["ashe", "basch", "vann", "fran", "balthier", "penelo", "vaan"],
    "FF13": ["lightning", "snow", "serah", "sazh", "vanille", "fang"],
    "FF15": ["noctis", "gladio", "ignis", "prompto", "lunafreya", "aranea"],
    "FF16": ["clive", "joshua", "jill", "dion", "barnabas", "ultima"],
    "FF6": ["terra", "locke", "celes", "edgar", "sabin", "setzer", "cyan", "relm", "strago"],
    "Computer Games": ["logo", "mario", "sonic", "zelda", "cloud", "master chief", "spyro", "ratchet"],
    "Palworld": ["pal", "lamball", "chikipi", "jetdragon", "frostallion"],
    "Horizon": ["logo", "aloy", "elisabet", "sovereign", "stormbird", "thunderjaw"],
    "Zero Dawn": ["aloy", "elisabet", "sovereign", "stormbird", "thunderjaw"],
}

MYTH_ORDERINGS = {
    "Greek Gods": ["zeus", "hera", "poseidon", "demeter", "hades", "hestia", "hermes", "aphrodite", "ares", "hephaestus"],
    "Olympians": ["zeus", "hera", "poseidon", "demeter", "hades", "hestia", "hermes", "aphrodite", "ares", "hephaestus"],
    "Titans": ["cronus", "rhea", "oceanus", "hyperion", "iapetus", "theia", "themis"],
    "Heroes and Monsters (Greek and Roman)": ["heracles", "perseus", "theseus", "odysseus", "achilles", "hector", "medusa", "minotaur"],
    "Egyptian Gods": ["ra", "osiris", "isle", "anubis", "horus", "set", "bastet", "thoth"],
    "Roman Gods": ["jupiter", "mars", "venus", "mercury", "neptune", "minerva"],
    "Norse Gods": ["odin", "thor", "loki", "frigg", "freyja", "heimdall", "tyr", "bragi"],
    "Norse Heroes": ["sigurd", "beowulf", "ragnar", "helgi"],
    "Norse Locations": ["asgard", "midgard", "helheim", "niflheim"],
    "Norse Races": ["aesir", "vanir", "jotunn", "draugr", "alf", "dwarf"],
    "Norse Valkyries": ["brünhild", "sigrún", "örðla", "gunnr"],
    "Hindu Deities and People": ["shiva", "vishnu", "brahma", "ganesha", "durga", "krishna", "rama", "hanuman", "indra"],
    "Buddhism Deities and People": ["buddha", "bodhisattva", "sakyamuni", "avalokiteshvara", "maitreya"],
    "Christian Deities and People": ["god", "jesus", "mary", "mary", "apostle", "mary magdalene", "john", "paul", "peter"],
    "Angels": ["michael", "gabriel", "raphael", "uriel", "sariel", "anafiel", "remiel", "barachiel", "jophiel", "zadkiel"],
    "Demons": ["satan", "beelzebub", "baphomet", "asmodeus", "baal", "moloch", "lilith"],
    "Other Mythology": ["artemis", "hecate", "selene", "nymph", "satyr", "faun", "gorgon"],
    "Family Trees": ["zeus", "poseidon", "hades", "cronus", "rhea", "hermes"],
    "Legendary Heroes and Folk Heroes": ["king arthur", "merlin", "lancelot", "robin hood", "beowulf", "el cid"],
    "Asian Legends and Folklore": ["monkey king", "wukong", "chang'e", "nezha", "dragon", "koi"],
    "Arabian and Middle Eastern Tales": ["ali baba", "aladdin", "sinbad", "jasmine", "genie"],
    "Creatures and Races": ["unicorn", "phoenix", "griffin", "dragon", "centaur", "satyr", "mermaid", "minotaur", "cyclops", "harpy", "sphinx", "werewolf"],
    "Famous Monsters and Horror Icons": ["frankenstein", "dracula", "mummy", "wolf man", "king kong", "godzilla", "phantom"],
    "Arthurian Legend": ["king arthur", "merlin", "lancelot", "guinevere", "mordred", "excalibur", "gawain"],
    "Literary and Gothic Characters": ["dracula", "frankenstein", "holmes", "watson", "dorian", "gatsby", "heathcliff", "holden"],
}

LORE_ORDERINGS = {
    "Bleach": ["ichigo", "rukia", "orihime", "uryu", "sado", "renji", "byakuya", "toshiro", "aizen", "urahara", "yoruichi", "yamamoto", "kenpachi", "ulquiorra", "grimmjow", "gin", "zangetsu", "kon"],
    "The Lord Of The Rings": ["frodo", "sam", "gandalf", "aragorn", "legolas", "gimli", "boromir", "galadriel", "gollum", "sauron", "saruman", "bilbo"],
    "The Hobbit": ["bilbo", "thorin", "gandalf", "smaug", "bard", "beorn", "radagast", "tauriel", "thranduil", "azog", "bolg"],
    "The Orville": ["ed mercer", "kelly", "gordon", "isaac"],
    "Doctor Who": ["the doctor", "companion", "dalek", "cyberman", "master"],
    "Farscape": ["john", "aeryn", "d'argo", "zhaan", "rincewind", "chi"],
    "Wednesday": ["wednesday", "morticia", "gomez", "thing", "pugsley", "enid"],
    "The Expanse": ["holden", "naomi", "alex", "amos", "miller", "naomi"],
    "Blueprints": ["blueprint", "diagram", "schematic"],
}

ALL_ORDERINGS = {}
for d in [DISNEY_ORDERINGS, SUPERHERO_ORDERINGS, STAR_TREK_ORDERINGS, STAR_WARS_ORDERINGS, GAME_ORDERINGS, MYTH_ORDERINGS, LORE_ORDERINGS]:
    ALL_ORDERINGS.update(d)


# ── Title character hints for boards without explicit orderings ─────────────
TITLE_HINTS = {
    "Books": [
        "harry potter", "hobbit", "lord of the rings", "odyssey",
        "ulysses", "moby", "sherlock", "dracula", "frankenstein",
        "dantes", "oliver", "david", "tom sawyer", "wizard",
        "gatsby", "pride", "jane eyre", "anne", "war and peace",
        "les miserables", "catcher", "hunger", "little prince",
        "three musketeers", "dorian", "wuthering",
    ],
    "Cartoons and Puppets": ["bugs bunny", "mickey", "kermit", "gloopy"],
    "Turtles": ["leonardo", "donatello", "raphael", "michelangelo", "splinter", "shredder"],
    "ReBoot": ["bob", "dot matrix", "enzo", "megabyte", "hexadecimal", "phong"],
    "Ghostbusters": ["venkman", "stantz", "spengler", "zeddemore", "slimer", "stay-puft", "gozer"],
    "80s TV Shows": ["inspector gadget", "danger mouse", "duckula", "treguard"],
    "Animaniacs": ["yakko", "wakko", "dot", "pinky", "brain", "slappy", "skippy"],
    "The Simpsons": ["homer", "marge", "bart", "lisa", "maggie", "ned flanders", "milhouse", "krusty", "moe", "barney", "apu", "burns", "smithers", "sideshow bob", "ralph wiggum"],
    "An American Tail (1986)": ["fievel", "tanya", "mama", "papa", "tiger"],
    "The Land Before Time (1988)": ["littlefoot", "cera", "ducky", "petrie", "spike", "sharptooth"],
    "All Dogs Go to Heaven (1989)": ["charlie", "itchy", "anne-marie", "carface", "king gator"],
    "Gremlins": ["gizmo", "stripe", "mogwai", "gremlin"],
    "Real Life Heroes": [
        "apollo", "marie curie", "tesla", "da vinci", "napoleon",
        "cleopatra", "caesar", "abraham lincoln", "winston churchill",
        "leonardo", "shannon",
    ],
    "Religion, Myth and History": [
        "christ", "buddha", "mohammed", "moses", "king arthur",
    ],
    "Fairy Tale Characters": [
        "red riding", "little red", "three little pigs", "goldilocks",
        "jack", "cinderella", "hansel", "snow white", "rapunzel",
        "sleeping beauty",
    ],
    "Famous Monsters and Horror Icons": [
        "frankenstein", "dracula", "mummy", "wolf", "king kong",
        "godzilla", "phantom",
    ],
    "Legendary Heroes and Folk Heroes": [
        "king arthur", "merlin", "lancelot", "robin hood", "beowulf",
    ],
    "Literary and Gothic Characters": [
        "dracula", "frankenstein", "holmes", "watson", "dorian",
        "gatsby", "heathcliff", "holden",
    ],
    "Misc": ["misc"],
    "Robin Hood and English Folklore": ["robin hood", "little john", "marian", "sheriff"],
    "Sci-Fi and Fantasy": ["logo", "star trek", "star wars", "lord of the rings"],
    "DnD": ["dragon", "dungeon", "dice", "d20"],
    "DnD Classes": ["fighter", "wizard", "cleric", "rogue", "barbarian", "paladin", "ranger"],
    "DnD Magic and Status": ["potion", "scroll", "spell", "magic", "status"],
    "DnD Races": ["human", "elf", "dwarf", "halfling", "half-orc", "dragonborn", "gnome", "tiefling"],
    "Star Trek": ["kirk", "spock", "logo", "star trek"],
    "The Expanse": ["holden", "naomi", "alex", "amos", "miller"],
    "The Lord Of The Rings": ["frodo", "sam", "gandalf", "aragorn", "legolas", "gimli", "boromir", "galadriel", "gollum"],
    "The Hobbit": ["bilbo", "thorin", "smaug", "gandalf", "gollum"],
    "The Orville": ["ed mercer", "kelly", "gordon", "isaac"],
    "Wednesday": ["wednesday", "morticia", "gomez", "thing"],
    "Superheroes": ["superhero", "logo"],
    "DC": ["logo", "superman", "batman", "wonder woman", "flash", "green lantern", "aquaman"],
    "Marvel": ["logo", "iron man", "captain america", "thor", "hulk", "black widow", "spiderman"],
    "X-Men": ["logo", "xavier", "wolverine", "cyclops", "jean grey", "storm", "beast", "iceman", "nightcrawler", "colossus"],
    "The X-Men": ["logo", "xavier", "wolverine", "cyclops", "jean", "storm", "beast", "iceman", "nightcrawler", "colossus", "gambit", "jubilee"],
    "New Gods, Apokolips and Cosmic Villains": ["darkseid", "desaad", "steppenwolf", "highfather", "miranda"],
    "Other Teams": ["booster gold", "blue beetle", "peacemaker"],
    "Shazam": ["shazam", "bill", "darla", "ezekiel", "mary"],
    "Super Family": ["superman", "lois", "jimmy", "lex luthor", "supergirl"],
    "Teen Titans": ["robin", "raven", "beast boy", "starfire", "cyborg"],
    "The Flash": ["flash", "reverse", "zoom", "iris"],
    "Wonder Woman": ["wonder woman", "diana", "steve", "hippolyta"],
    "Aquaman": ["aquaman", "arthur", "mera", "black manta"],
    "Bat Family": ["batman", "bruce wayne", "dick grayson", "nightwing", "barbara"],
    "Doom Patrol": ["cliff", "rachel", "larry", "jane", "mikey"],
    "Green Arrow": ["oliver", "felicity", "diggle", "laurel"],
    "Green Lantern": ["hal jordan", "john stewart", "guy gardner", "kyle rayner"],
    "Justice League": ["superman", "batman", "wonder woman", "flash", "green lantern", "aquaman"],
    "Justice League Dark  Supernatural": ["constantine", "zatanna", "swamp"],
    "Justice Society Of America (JSA)": ["alan scott", "jay garrick", "hourman", "hawkman", "doctor fate"],
    "Legends Of Tomorrow": ["sara", "ray", "kendra", "nate", "amaya", "zari"],
    "Cartoons and Puppets": ["bugs bunny", "mickey mouse", "kermit", "gloopy", "pepe"],
    "Cuphead": ["cuphead", "mugman", "charlie", "king dice", "devil"],
    "Baldur's Gate 3": ["gale", "shadowheart", "astarian", "laezel", "wyll", "karlach"],
    "Borderlands": ["brick", "mordecai", "lilith", "roland", "claptrap"],
    "Fable": ["hero", "reaver", "theresa", "reaper"],
    "Hollow Knight": ["knight", "hornet", "zote", "cornifer", "quirrel"],
    "Horizon": ["aloy", "elisabet", "sovereign", "stormbird"],
    "Kingdom Hearts": ["sora", "riku", "kairi", "roxas", "namine", "donald", "goofy"],
    "Mario": ["mario", "luigi", "peach", "bowser", "wario", "yoshi"],
    "No Man's Sky": ["atlas", "traveler", "multi-tool"],
    "Ori": ["ori", "seir", "kuro", "gumo"],
    "Palworld": ["pal", "lamball", "chikipi", "jetdragon"],
    "Custom Eeveelutions": ["vaporeon", "jolteon", "flareon", "espeon", "umbreon", "leafeon", "glaceon", "sylveon"],
    "Pokeballs and Important Items": ["pokeball", "great ball", "ultra ball", "master ball", "potion"],
    "Pokemon": ["pikachu", "logo", "pokeball", "pikachu"],
    "Pokemon Missed Evolutions": ["pikachu", "eevee", "tyrogue"],
    "Sonic": ["sonic", "tails", "knuckles", "shadow", "dr eggman"],
    "Computer Games": ["logo", "mario", "sonic", "zelda", "cloud", "master chief"],
    "Logos": ["logo"],
    "Burning Shores": ["aloy", "sovereign", "horizon", "burner"],
    "Frozen Wilds": ["aloy", "horizon", "frozen", "beast"],
    "Forbidden West": ["aloy", "sovereign", "horizon", "far Zenith"],
    "Fable": ["hero", "reaver", "theresa"],
}

# ──────────────────────────────────────────────────────────────────────────────
# Board metadata helpers
# ──────────────────────────────────────────────────────────────────────────────
_NAME_MAP: dict[str, tuple[str, str, Optional[str]]] = {}
for _e in HIERARCHY:
    _NAME_MAP.setdefault(_e[0], _e)  # First occurrence wins (matches Dart)

_CHILDREN: dict[str, list[str]] = {}
for _n, _a, _p in HIERARCHY:
    _CHILDREN.setdefault(_p or "_ROOT_", []).append(_n)

# Boards whose asset/output folders don't match their hierarchy name path.
_PATH_OVERRIDES: dict[str, str] = {
    "The X-Men": "Superheroes/X-Men/X-Men",
}


def calculate_tier(name: str) -> int:
    if name == "Legends":
        return 1
    tier = 1
    parent = _NAME_MAP.get(name, ("", "", None))[2]
    visited = set()
    while parent is not None and parent not in visited:
        visited.add(parent)
        tier += 1
        parent = _NAME_MAP.get(parent, ("", "", None))[2]
    return tier


def get_parent_name(name: str) -> Optional[str]:
    entry = _NAME_MAP.get(name)
    if entry is None:
        return None
    return entry[2]


def get_children(name: str) -> list[str]:
    return sorted(_CHILDREN.get(name, []))


def get_ancestor_chain(name: str) -> list[str]:
    """Get list of ancestor names from immediate parent to tier-1 parent."""
    ancestors = []
    parent = get_parent_name(name)
    visited = set()
    while parent is not None and parent not in visited:
        visited.add(parent)
        ancestors.insert(0, parent)
        parent = get_parent_name(parent)
    return ancestors


# ──────────────────────────────────────────────────────────────────────────────
# File sorting
# ──────────────────────────────────────────────────────────────────────────────
def is_pokemon_gen(bid: str, name: str) -> bool:
    return "Gen" in name or "Pokemon" in name.lower() and "gen" in bid.lower()


def sort_pokemon(files: list[str]) -> list[str]:
    def key(f):
        stem = Path(f).stem
        m = re.match(r'(\d+)', stem)
        return (float(m.group(1)) if m else float('inf'), stem.lower())
    return sorted(files, key=key)


def sort_by_keywords(files: list[str], ordering: list[str]) -> list[str]:
    """Sort files by keyword matching. First match wins."""
    def get_idx(fname: str) -> tuple[int, str]:
        stem = Path(fname).stem.lower()
        for i, kw in enumerate(ordering):
            if kw.lower() in stem:
                return (i, stem)
        return (len(ordering), stem)
    return sorted(files, key=get_idx)


def sort_heuristic(files: list[str], title_hints: list[str]) -> list[str]:
    """Logo first, title character second, then alphabetical."""
    def key(fname: str) -> tuple[int, str]:
        stem = Path(fname).stem.lower()
        if "logo" in stem:
            return (0, stem)
        for i, h in enumerate(title_hints):
            if h.lower() in stem:
                return (1, stem)
        return (2, stem)
    return sorted(files, key=key)


def sort_files(board_name: str, files: list[str]) -> list[str]:
    bid = board_id(board_name)

    # Pokemon: sort by Pokedex number
    if board_name.startswith("Pokemon") or bid.startswith("prebuilt_pokemon") or bid == "prebuilt_custom_eevee_lutions" or bid == "prebuilt_pokeballs_and_important_items":
        if any(re.match(r'\d+', Path(f).stem) for f in files):
            return sort_pokemon(files)

    # Explicit ordering
    if board_name in ALL_ORDERINGS:
        return sort_by_keywords(files, ALL_ORDERINGS[board_name])

    # Heuristic
    hints = TITLE_HINTS.get(board_name, [])
    return sort_heuristic(files, hints)


# ──────────────────────────────────────────────────────────────────────────────
# Path helpers
# ──────────────────────────────────────────────────────────────────────────────
def get_relative_asset_path(name: str) -> str:
    """Path from assets/Legends/ to the board's folder."""
    if name == "Legends":
        return ""
    if name in _PATH_OVERRIDES:
        return _PATH_OVERRIDES[name]
    ancestors = get_ancestor_chain(name)
    parts = ancestors + [name]
    return "/".join(parts)


def get_json_output_path(name: str) -> Path:
    bid = board_id(name)
    if name == "Legends":
        return BOARDS_ROOT / f"{bid}.json"
    if name in _PATH_OVERRIDES:
        parts = [str(BOARDS_ROOT)] + _PATH_OVERRIDES[name].split("/") + [f"{bid}.json"]
        return Path("/".join(parts))
    ancestors = get_ancestor_chain(name)
    parts = [str(BOARDS_ROOT)] + ancestors + [name, f"{bid}.json"]
    return Path("/".join(parts))


def get_asset_dir(name: str) -> Path:
    rel = get_relative_asset_path(name)
    if not rel:
        return ASSETS_ROOT
    return ASSETS_ROOT / rel


# ──────────────────────────────────────────────────────────────────────────────
# Tile generation
# ──────────────────────────────────────────────────────────────────────────────
def make_image_tile(board_id_str, board_name, fname, category, rel_asset):
    stem = Path(fname).stem
    label = stem

    # Clean up label: "casey jr. circus train" -> "casey jr. circus train"
    # Just strip leading/trailing whitespace
    label = label.strip()

    # Image path: assets/Legends/<rel_asset>/<fname>
    image = f"assets/Legends/{rel_asset}/{fname}" if rel_asset else f"assets/Legends/{fname}"

    return {
        "id": f"{board_id_str}_{snake_case(stem)}",
        "type": "vocabulary",
        "label": label,
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


def make_link_tile(board_id_str, board_name, child_name):
    child_id = board_id(child_name)
    child_snake = snake_case(child_name)

    return {
        "id": f"{board_id_str}_{child_snake}",
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


# ──────────────────────────────────────────────────────────────────────────────
# Board JSON generation
# ──────────────────────────────────────────────────────────────────────────────
def generate_board_json(name: str) -> dict:
    bid = board_id(name)
    tier = calculate_tier(name)
    parent_name = get_parent_name(name)
    parent_bid = board_id(parent_name) if parent_name else None

    is_subboard = tier > 1
    is_tertiary = tier >= 3
    is_quaternary = tier >= 4
    is_quinary = tier >= 5

    category = parent_name if parent_name else name

    # Find asset directory
    asset_dir = get_asset_dir(name)
    image_files = []
    if asset_dir.exists():
        image_files = sorted(
            [f.name for f in asset_dir.iterdir() if f.is_file() and f.suffix.lower() == ".png"]
        )

    # Sort by importance
    image_files = sort_files(name, image_files)

    # Build tiles
    rel_asset = get_relative_asset_path(name)
    tiles = []

    for fname in image_files:
        tiles.append(make_image_tile(bid, name, fname, category, rel_asset if name != "Legends" else ""))

    # Add link tiles for children
    children = get_children(name)
    for child in children:
        tiles.append(make_link_tile(bid, name, child))

    columns = 6
    rows = max(1, (len(tiles) + columns - 1) // columns)

    result = {
        "id": bid,
        "name": name,
        "area": "Legends",
        "columns": columns,
        "backgroundColor": "transparent",
        "adjustableLayout": True,
        "isSubBoard": is_subboard,
        "isTertiaryBoard": is_tertiary,
        "isQuaternaryBoard": is_quaternary,
        "isQuinaryBoard": is_quinary,
        "sortOrder": 0,
        "tier": tier,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {
            "rows": rows,
            "blankTilesAdded": 0,
        },
        "tiles": tiles,
    }

    if parent_bid:
        result["parentBoardId"] = parent_bid

    return result


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
def main():
    os.makedirs(BOARDS_ROOT, exist_ok=True)

    total = sum(1 for _, a, _ in HIERARCHY if a == "Legends")
    success = 0
    skipped = 0

    for name, area, parent in HIERARCHY:
        if area != "Legends":
            continue

        bid = board_id(name)
        output_path = get_json_output_path(name)

        # Fast-skip: check JSON existence first
        if output_path.exists():
            print(f"  SKIP (exists): {name}")
            success += 1
            continue

        children = get_children(name)

        asset_dir = get_asset_dir(name)
        has_images = False
        if asset_dir.exists():
            image_count = sum(1 for f in asset_dir.iterdir() if f.is_file() and f.suffix.lower() == ".png")
            has_images = image_count > 0

        has_children = len(children) > 0

        if not has_images and not has_children:
            skipped += 1
            continue

        print(f"  Generating: {name}...", flush=True)
        json_data = generate_board_json(name)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)

        image_count = len(json_data["tiles"]) - len(children)
        link_count = len(children)
        status = f"OK ({image_count} imgs + {link_count} links = {len(json_data['tiles'])} tiles)"
        print(f"  {status}: {name}")
        success += 1

    print(f"\n{'='*60}")
    print(f"Generated: {success} / {total} board JSONs (skipped {skipped})")


if __name__ == "__main__":
    main()
