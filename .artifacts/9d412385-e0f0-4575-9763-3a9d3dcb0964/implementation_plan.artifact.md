# Expand and Reorder Disney Story Boards

The user wants to expand the "Disney Stories" board to include a comprehensive list of Disney and Pixar movies, ordered chronologically by release year. This involves creating 47 new board files and updating the parent board and hierarchy.

## User Review Required

> [!IMPORTANT]
> This change adds 47 new boards. Each new board will initially contain a single blank tile. The parent "Disney Stories" board will now contain 73 board links, requiring its layout to be expanded to 15 rows.

## Proposed Changes

### [Board Data]

I will update existing boards and create new ones in `lib/data/boards/Common/People/Characters/Disney Stories/`. All boards will have their `sortOrder` updated to match the new 10-increment sequence (10 to 730).

#### Existing Boards to Update:
- Snow White & The Seven Dwarfs (1937) -> sortOrder: 10
- Pinocchio (1940) -> sortOrder: 20
- Fantasia (1940) -> sortOrder: 30
- Dumbo (1941) -> sortOrder: 40
- Bambi (1942) -> sortOrder: 50
- Cinderella (1950) -> sortOrder: 60
- Alice In Wonderland (1951) -> sortOrder: 70
- Peter Pan (1953) -> sortOrder: 80
- Lady & The Tramp (1955) -> sortOrder: 90
- Sleeping Beauty (1959) -> sortOrder: 100
- 101 Dalmatians (1961) -> sortOrder: 110
- The Sword In The Stone (1963) -> sortOrder: 120
- The Jungle Book (1967) -> sortOrder: 130
- Robin Hood (1973) -> sortOrder: 150
- Winnie The Pooh (1977) -> sortOrder: 160
- The Rescuers (1977) -> sortOrder: 170
- The Little Mermaid (1989) -> sortOrder: 220
- Beauty & The Beast (1991) -> sortOrder: 240
- Aladdin (1992) -> sortOrder: 250
- The Nightmare Before Christmas (1993) -> sortOrder: 260
- The Lion King (1994) -> sortOrder: 270
- Pocahontas (1995) -> sortOrder: 290
- The Hunchback Of Notre Dame (1996) -> sortOrder: 300
- Hercules (1997) -> sortOrder: 310
- Mulan (1998) -> sortOrder: 330
- Tarzan (1999) -> sortOrder: 340

#### New Boards to Create (in correct sort order):
- The Aristocats (1970) (140)
- The Fox & The Hound (1981) (180)
- The Black Cauldron (1985) (190)
- The Great Mouse Detective (1986) (200)
- Oliver & Company (1988) (210)
- The Rescuers Down Under (1990) (230)
- Toy Story (1995) (280)
- A Bug's Life (1998) (320)
- Dinosaur (2000) (350)
- The Emperor's New Groove (2000) (360)
- Monsters, Inc. (2001) (370)
- Atlantis - The Lost Empire (2001) (380)
- Lilo & Stitch (2002) (390)
- Treasure Planet (2002) (400)
- Finding Nemo (2003) (410)
- Brother Bear (2003) (420)
- The Incredibles (2004) (430)
- Home On The Range (2004) (440)
- Chicken Little (2005) (450)
- Cars (2006) (460)
- Ratatouille (2007) (470)
- Meet The Robinsons (2007) (480)
- WALL-E (2008) (490)
- Bolt (2008) (50)
- Up (2009) (510)
- The Princess & The Frog (2009) (520)
- Tangled (2010) (530)
- Brave (2012) (540)
- Wreck-It Ralph (2012) (550)
- Frozen (2013) (560)
- Big Hero 6 (2014) (570)
- Inside Out (2015) (580)
- The Good Dinosaur (2015) (590)
- Zootopia (2016) (600)
- Moana (2016) (610)
- Coco (2017) (620)
- Onward (2020) (630)
- Soul (2020) (640)
- Raya & The Last Dragon (2021) (650)
- Encanto (2021) (660)
- Luca (2021) (670)
- Turning Red (2022) (680)
- Lightyear (2022) (690)
- Strange World (2022) (700)
- Elemental (2023) (710)
- Wish (2023) (720)
- Elio (2025) (730)

### [Parent Board]

#### [MODIFY] [prebuilt_disney_stories.json](file:///C:/Users/Craig/Downloads/Charlie%20Chat/lib/data/boards/Common/People/Characters/Disney%20Stories/prebuilt_disney_stories.json)
- Increase `rows` to 15.
- Update the `tiles` list to include board links for all 73 movies in the specified chronological order.

### [Hierarchy]

#### [MODIFY] [board_hierarchy.dart](file:///C:/Users/Craig/Downloads/Charlie%20Chat/lib/data/board_hierarchy.dart)
- Update the `boardHierarchy` constant to include all 73 boards in chronological order.

## Verification Plan

### Manual Verification
- Open the app and navigate to `People / Characters / Disney Stories`.
- Verify all 73 sub-board tabs are present and ordered correctly by year.
- Verify that clicking on new tabs opens the (initially empty) board.
