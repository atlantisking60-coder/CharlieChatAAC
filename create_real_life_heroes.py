#!/usr/bin/env python3
"""Create Real Life Heroes sub-boards with famous people lists."""

import json
import re
import shutil
from pathlib import Path
from math import ceil

PROJECT_ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = PROJECT_ROOT / "lib" / "data" / "boards" / "Legends" / "Real Life Heroes"
PARENT_JSON = BOARDS_DIR / "prebuilt_real_life_heroes.json"

SUB_BOARDS = [
    {
        "name": "Activism, Charity and Heroism",
        "icon": "assets/BOARDS/Legends/Real Life Heroes/Activism, Charity and Heroism.png",
        "people": [
            "Malala Yousafzai", "Greta Thunberg", "Martin Luther King Jr.",
            "Nelson Mandela", "Rosa Parks", "Harriet Tubman", "Mahatma Gandhi",
            "William Wilberforce", "Emmeline Pankhurst", "David Attenborough",
            "Jane Goodall", "Desmond Tutu", "Florence Nightingale", "Oskar Schindler",
            "Mother Teresa"
        ]
    },
    {
        "name": "Overcoming Challenges",
        "icon": "assets/BOARDS/Legends/Real Life Heroes/Overcoming Challenges.png",
        "people": [
            "Stephen Hawking", "Helen Keller", "Frida Kahlo", "Bethany Hamilton",
            "Nick Vujicic", "Terry Fox", "J.K. Rowling", "Ludwig van Beethoven",
            "Franklin D. Roosevelt", "Walt Disney", "Temple Grandin", "Jessica Cox",
            "Ellie Simmonds", "Christopher Reeve", "Stevie Wonder"
        ]
    },
    {
        "name": "Musical Practitioners",
        "icon": "assets/BOARDS/Subjects/Music Vocab.png",
        "people": [
            "Wolfgang Amadeus Mozart", "Ludwig van Beethoven", "Johann Sebastian Bach",
            "Elvis Presley", "The Beatles", "Beyonce", "Taylor Swift", "Ed Sheeran",
            "Adele", "Freddie Mercury", "David Bowie", "Aretha Franklin",
            "Michael Jackson", "Madonna", "Bob Marley"
        ]
    },
    {
        "name": "Famous Actors",
        "icon": "assets/BOARDS/Subjects/Performing Arts Vocab.png",
        "people": [
            "Leonardo DiCaprio", "Meryl Streep", "Tom Hanks", "Denzel Washington",
            "Judi Dench", "Morgan Freeman", "Emma Thompson", "Ian McKellen",
            "Daniel Day-Lewis", "Viola Davis", "Robert Downey Jr.", "Hugh Jackman",
            "Cate Blanchett", "Chadwick Boseman", "Audrey Hepburn"
        ]
    },
    {
        "name": "Popular Artists",
        "icon": "assets/BOARDS/Subjects/Art Vocab.png",
        "people": [
            "Vincent van Gogh", "Pablo Picasso", "Frida Kahlo", "Claude Monet",
            "Banksy", "Yayoi Kusama", "Leonardo da Vinci", "Georgia O'Keeffe",
            "Salvador Dali", "Henri Matisse", "Andy Warhol", "David Hockney",
            "Rembrandt", "Tracey Emin", "Jackson Pollock"
        ]
    },
    {
        "name": "Sporting Icons",
        "icon": "assets/BOARDS/Subjects/PE Vocab.png",
        "people": [
            "Muhammad Ali", "Usain Bolt", "Serena Williams", "Lionel Messi",
            "Cristiano Ronaldo", "Michael Jordan", "Simone Biles", "Lewis Hamilton",
            "Tom Daley", "Jessica Ennis-Hill", "David Beckham", "Ellie Simmonds",
            "Mo Farah", "Nadia Comaneci", "Michael Phelps"
        ]
    },
    {
        "name": "Scientific Pioneers",
        "icon": "assets/BOARDS/Subjects/Science Vocab.png",
        "people": [
            "Albert Einstein", "Marie Curie", "Isaac Newton", "Charles Darwin",
            "Stephen Hawking", "Rosalind Franklin", "Nikola Tesla", "Ada Lovelace",
            "Alexander Fleming", "Jane Goodall", "Galileo Galilei", "Rachel Carson",
            "Neil deGrasse Tyson", "Katherine Johnson", "Tim Berners-Lee"
        ]
    },
    {
        "name": "Financial Gurus",
        "icon": "assets/BOARDS/Legends/Real Life Heroes/Financial Gurus.png",
        "people": [
            "Warren Buffett", "Elon Musk", "Jeff Bezos", "Mark Zuckerberg",
            "Oprah Winfrey", "Richard Branson", "Sara Blakely", "Alan Sugar",
            "Deborah Meaden", "Peter Jones", "Adam Smith", "John Maynard Keynes",
            "Carl Icahn", "George Soros", "Mukesh Ambani"
        ]
    },
    {
        "name": "Intrepid Explorers",
        "icon": "assets/BOARDS/PEEP and Sustainability/Explorers.png",
        "people": [
            "Christopher Columbus", "Neil Armstrong", "Amelia Earhart", "Ernest Shackleton",
            "Marco Polo", "Ibn Battuta", "Sacagawea", "Roald Amundsen",
            "Edmund Hillary", "Tenzing Norgay", "David Livingstone", "Mary Kingsley",
            "Jacques Cousteau", "Tim Peake", "Ellen MacArthur"
        ]
    },
    {
        "name": "Celebrated Writers",
        "icon": "assets/BOARDS/English/Books.png",
        "people": [
            "William Shakespeare", "Jane Austen", "Charles Dickens", "J.K. Rowling",
            "Roald Dahl", "Michael Morpurgo", "Maya Angelou", "Dr. Seuss",
            "George Orwell", "Lewis Carroll", "J.R.R. Tolkien", "Agatha Christie",
            "Malorie Blackman", "David Walliams", "Beatrix Potter"
        ]
    },
    {
        "name": "Culinary Masters",
        "icon": "assets/BOARDS/Subjects/Cooking Vocab.png",
        "people": [
            "Gordon Ramsay", "Jamie Oliver", "Mary Berry", "Nigella Lawson",
            "Heston Blumenthal", "Julia Child", "Marco Pierre White", "Delia Smith",
            "Paul Hollywood", "Gino D'Acampo", "Raymond Blanc", "Massimo Bottura",
            "Dominique Ansel", "Marcus Wareing", "Prue Leith"
        ]
    },
    {
        "name": "Fashionable Designers",
        "icon": "assets/BOARDS/Clothes.png",
        "people": [
            "Coco Chanel", "Vivienne Westwood", "Alexander McQueen", "Giorgio Armani",
            "Stella McCartney", "Ralph Lauren", "Donatella Versace", "Christian Dior",
            "Yves Saint Laurent", "Karl Lagerfeld", "Victoria Beckham", "Jean-Paul Gaultier",
            "Mary Quant", "Tom Ford", "Diane von Furstenberg"
        ]
    },
    {
        "name": "Political Figures",
        "icon": "assets/BOARDS/Legends/Real Life Heroes/Political Figures.png",
        "people": [
            "Winston Churchill", "Margaret Thatcher", "Tony Blair", "Queen Elizabeth II",
            "King Charles III", "Barack Obama", "Nelson Mandela", "Mahatma Gandhi",
            "Angela Merkel", "Jacinda Ardern", "Volodymyr Zelenskyy",
            "Franklin D. Roosevelt", "Cleopatra", "Julius Caesar", "Abraham Lincoln"
        ]
    },
]


def slugify(text: str) -> str:
    s = text.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = s.strip("_")
    return s


def make_tile(board_id: str, label: str, index: int) -> dict:
    safe = slugify(label)
    return {
        "id": f"{board_id}_{safe}",
        "type": "vocabulary",
        "label": label,
        "category": "Custom",
        "imageAsset": "",
        "emoji": "",
        "isBoardLink": False,
        "linkedBoardId": "",
        "linkedBoardName": None,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": ""
    }


def make_board_json(sub: dict) -> dict:
    name = sub["name"]
    board_id = "prebuilt_" + slugify(name)
    icon = sub["icon"]
    people = sub["people"]
    columns = 8
    rows = ceil(len(people) / columns)
    tiles = [make_tile(board_id, p, i) for i, p in enumerate(people)]
    return {
        "id": board_id,
        "name": name,
        "area": "Legends",
        "columns": columns,
        "backgroundColor": "transparent",
        "adjustableLayout": True,
        "isSubBoard": True,
        "isTertiaryBoard": False,
        "isQuaternaryBoard": False,
        "isQuinaryBoard": False,
        "sortOrder": 0,
        "tier": 2,
        "iconAssetPath": icon,
        "tileIconAssetPath": icon,
        "version": 1,
        "boxScale": 1,
        "tileHeight": 100,
        "tileWidth": 100,
        "layout": {"rows": rows, "blankTilesAdded": 0},
        "tiles": tiles,
        "parentBoardId": "prebuilt_real_life_heroes"
    }


def main():
    BOARDS_DIR.mkdir(parents=True, exist_ok=True)

    # Update parent board JSON: point the four special tiles at the new icon location
    parent = json.load(open(PARENT_JSON, "r", encoding="utf-8-sig"))
    icon_overrides = {
        "Activism, Charity and Heroism": "assets/BOARDS/Legends/Real Life Heroes/Activism, Charity and Heroism.png",
        "Overcoming Challenges": "assets/BOARDS/Legends/Real Life Heroes/Overcoming Challenges.png",
        "Financial Gurus": "assets/BOARDS/Legends/Real Life Heroes/Financial Gurus.png",
        "Political Figures": "assets/BOARDS/Legends/Real Life Heroes/Political Figures.png",
    }
    for tile in parent.get("tiles", []):
        label = tile.get("label", "")
        if label in icon_overrides:
            tile["imageAsset"] = icon_overrides[label]
    json.dump(parent, open(PARENT_JSON, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(PARENT_JSON, "a", encoding="utf-8").write("\n")
    print(f"Updated parent: {PARENT_JSON.relative_to(PROJECT_ROOT)}")

    # Create sub-boards
    for sub in SUB_BOARDS:
        data = make_board_json(sub)
        folder_name = sub["name"]
        folder = BOARDS_DIR / folder_name
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"{data['id']}.json"
        json.dump(data, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        open(path, "a", encoding="utf-8").write("\n")
        print(f"Created: {path.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
