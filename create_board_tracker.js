const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

// ── Hierarchy from board_hierarchy.dart ──
const boardHierarchy = [
  { name: 'Common Words', area: 'Common' },
  { name: 'Small Words', area: 'Common' },
  { name: 'Numbers', area: 'Common' },
  { name: 'Letters', area: 'Common' },
  { name: 'Phonics', area: 'Common', parentName: 'Letters' },
  { name: 'Phase 2 Phonics', area: 'Common', parentName: 'Phonics' },
  { name: 'Phase 3 Phonics', area: 'Common', parentName: 'Phonics' },
  { name: 'Phase 4 Phonics', area: 'Common', parentName: 'Phonics' },
  { name: 'Phase 5 Phonics', area: 'Common', parentName: 'Phonics' },
  { name: 'Phase 6 Phonics', area: 'Common', parentName: 'Phonics' },
  { name: 'Feelings', area: 'Common' },
  { name: 'Sad', area: 'Common', parentName: 'Feelings' },
  { name: 'Mad', area: 'Common', parentName: 'Feelings' },
  { name: 'Scared', area: 'Common', parentName: 'Feelings' },
  { name: 'Joyful', area: 'Common', parentName: 'Feelings' },
  { name: 'Strong', area: 'Common', parentName: 'Feelings' },
  { name: 'Calm', area: 'Common', parentName: 'Feelings' },
  { name: 'Colours', area: 'Common' },
  { name: 'Shades Of Colours', area: 'Common', parentName: 'Colours' },
  { name: 'Prepositions', area: 'Common' },
  { name: 'People', area: 'Common' },
  { name: 'Characters', area: 'Common', parentName: 'People' },
  { name: 'School People', area: 'Common', parentName: 'People' },
  { name: 'Gods, Titans, Heroes & Monsters', area: 'Common', parentName: 'Characters' },
  { name: 'Heroes & Monsters (Greek & Roman)', area: 'Common', parentName: 'Characters' },
  { name: 'Fairy Tale Characters', area: 'Common', parentName: 'Characters' },
  { name: 'Disney Stories', area: 'Common', parentName: 'Characters' },
  { name: 'D&D', area: 'Common', parentName: 'Characters' },
  { name: 'Arthurian Legend', area: 'Common', parentName: 'Characters' },
  { name: 'Arabian & Middle Eastern Tales', area: 'Common', parentName: 'Characters' },
  { name: 'Asian Legends & Folklore', area: 'Common', parentName: 'Characters' },
  { name: 'Horror Icons', area: 'Common', parentName: 'Characters' },
  { name: 'Legendary Heroes & Folk Heroes', area: 'Common', parentName: 'Characters' },
  { name: 'Literary & Gothic Characters', area: 'Common', parentName: 'Characters' },
  { name: 'Marvel', area: 'Common', parentName: 'Characters' },
  { name: 'X-Men', area: 'Common', parentName: 'Characters' },
  { name: 'DC', area: 'Common', parentName: 'Characters' },
  { name: 'The Muppets', area: 'Common', parentName: 'Characters' },
  { name: 'Star Wars', area: 'Common', parentName: 'Characters' },
  { name: 'Star Trek', area: 'Common', parentName: 'Characters' },
  { name: 'The Lord Of The Rings', area: 'Common', parentName: 'Characters' },
  { name: 'Computer Games', area: 'Common', parentName: 'Characters' },
  { name: '1937 Snow White & The Seven Dwarfs', area: 'Common', parentName: 'Disney Stories' },
  { name: '1940 Pinocchio', area: 'Common', parentName: 'Disney Stories' },
  { name: '1940 Fantasia', area: 'Common', parentName: 'Disney Stories' },
  { name: '1941 Dumbo', area: 'Common', parentName: 'Disney Stories' },
  { name: '1942 Bambi', area: 'Common', parentName: 'Disney Stories' },
  { name: '1950 Cinderella', area: 'Common', parentName: 'Disney Stories' },
  { name: '1951 Alice In Wonderland', area: 'Common', parentName: 'Disney Stories' },
  { name: '1953 Peter Pan', area: 'Common', parentName: 'Disney Stories' },
  { name: '1955 Lady & The Tramp', area: 'Common', parentName: 'Disney Stories' },
  { name: '1959 Sleeping Beauty', area: 'Common', parentName: 'Disney Stories' },
  { name: '1961 101 Dalmatians', area: 'Common', parentName: 'Disney Stories' },
  { name: '1963 The Sword In The Stone', area: 'Common', parentName: 'Disney Stories' },
  { name: '1967 The Jungle Book', area: 'Common', parentName: 'Disney Stories' },
  { name: '1970 The Aristocats', area: 'Common', parentName: 'Disney Stories' },
  { name: '1973 Robin Hood', area: 'Common', parentName: 'Disney Stories' },
  { name: '1977 Winnie The Pooh', area: 'Common', parentName: 'Disney Stories' },
  { name: '1977 The Rescuers', area: 'Common', parentName: 'Disney Stories' },
  { name: '1981 The Fox & The Hound', area: 'Common', parentName: 'Disney Stories' },
  { name: '1985 The Black Cauldron', area: 'Common', parentName: 'Disney Stories' },
  { name: '1986 The Great Mouse Detective', area: 'Common', parentName: 'Disney Stories' },
  { name: '1988 Oliver & Company', area: 'Common', parentName: 'Disney Stories' },
  { name: '1989 The Little Mermaid', area: 'Common', parentName: 'Disney Stories' },
  { name: '1991 Beauty & The Beast', area: 'Common', parentName: 'Disney Stories' },
  { name: '1992 Aladdin', area: 'Common', parentName: 'Disney Stories' },
  { name: '1993 The Nightmare Before Christmas', area: 'Common', parentName: 'Disney Stories' },
  { name: '1994 The Lion King', area: 'Common', parentName: 'Disney Stories' },
  { name: '1995 Pocahontas', area: 'Common', parentName: 'Disney Stories' },
  { name: '1995 Toy Story', area: 'Common', parentName: 'Disney Stories' },
  { name: '1996 The Hunchback Of Notre Dame', area: 'Common', parentName: 'Disney Stories' },
  { name: '1997 Hercules', area: 'Common', parentName: 'Disney Stories' },
  { name: '1998 Mulan', area: 'Common', parentName: 'Disney Stories' },
  { name: '1998 A Bug\'s Life', area: 'Common', parentName: 'Disney Stories' },
  { name: '1999 Tarzan', area: 'Common', parentName: 'Disney Stories' },
  { name: '2000 Dinosaur', area: 'Common', parentName: 'Disney Stories' },
  { name: '2000 The Emperor\'s New Groove', area: 'Common', parentName: 'Disney Stories' },
  { name: '2001 Atlantis - The Lost Empire', area: 'Common', parentName: 'Disney Stories' },
  { name: '2001 Monsters, Inc.', area: 'Common', parentName: 'Disney Stories' },
  { name: '2002 Lilo & Stitch', area: 'Common', parentName: 'Disney Stories' },
  { name: '2002 Treasure Planet', area: 'Common', parentName: 'Disney Stories' },
  { name: '2003 Brother Bear', area: 'Common', parentName: 'Disney Stories' },
  { name: '2003 Finding Nemo', area: 'Common', parentName: 'Disney Stories' },
  { name: '2004 Home On The Range', area: 'Common', parentName: 'Disney Stories' },
  { name: '2004 The Incredibles', area: 'Common', parentName: 'Disney Stories' },
  { name: '2005 Chicken Little', area: 'Common', parentName: 'Disney Stories' },
  { name: '2006 Cars', area: 'Common', parentName: 'Disney Stories' },
  { name: '2007 Meet The Robinsons', area: 'Common', parentName: 'Disney Stories' },
  { name: '2007 Ratatouille', area: 'Common', parentName: 'Disney Stories' },
  { name: '2008 Bolt', area: 'Common', parentName: 'Disney Stories' },
  { name: '2008 WALL-E', area: 'Common', parentName: 'Disney Stories' },
  { name: '2009 The Princess & The Frog', area: 'Common', parentName: 'Disney Stories' },
  { name: '2009 Up', area: 'Common', parentName: 'Disney Stories' },
  { name: '2010 Tangled', area: 'Common', parentName: 'Disney Stories' },
  { name: '2012 Wreck-It Ralph', area: 'Common', parentName: 'Disney Stories' },
  { name: '2012 Brave', area: 'Common', parentName: 'Disney Stories' },
  { name: '2013 Frozen', area: 'Common', parentName: 'Disney Stories' },
  { name: '2014 Big Hero 6', area: 'Common', parentName: 'Disney Stories' },
  { name: '2015 Inside Out', area: 'Common', parentName: 'Disney Stories' },
  { name: '2015 The Good Dinosaur', area: 'Common', parentName: 'Disney Stories' },
  { name: '2016 Zootopia', area: 'Common', parentName: 'Disney Stories' },
  { name: '2016 Moana', area: 'Common', parentName: 'Disney Stories' },
  { name: '2017 Coco', area: 'Common', parentName: 'Disney Stories' },
  { name: '2020 Onward', area: 'Common', parentName: 'Disney Stories' },
  { name: '2020 Soul', area: 'Common', parentName: 'Disney Stories' },
  { name: '2021 Raya & The Last Dragon', area: 'Common', parentName: 'Disney Stories' },
  { name: '2021 Encanto', area: 'Common', parentName: 'Disney Stories' },
  { name: '2021 Luca', area: 'Common', parentName: 'Disney Stories' },
  { name: '2022 Turning Red', area: 'Common', parentName: 'Disney Stories' },
  { name: '2022 Strange World', area: 'Common', parentName: 'Disney Stories' },
  { name: '2023 Wish', area: 'Common', parentName: 'Disney Stories' },
  { name: '2023 Elemental', area: 'Common', parentName: 'Disney Stories' },
  { name: '2025 Elio', area: 'Common', parentName: 'Disney Stories' },
  { name: 'Animals', area: 'Common' },
  { name: 'Mammals', area: 'Common', parentName: 'Animals' },
  { name: 'Birds', area: 'Common', parentName: 'Animals' },
  { name: 'Reptiles', area: 'Common', parentName: 'Animals' },
  { name: 'Dinosaurs', area: 'Common', parentName: 'Reptiles' },
  { name: 'Amphibians', area: 'Common', parentName: 'Animals' },
  { name: 'Insects', area: 'Common', parentName: 'Animals' },
  { name: 'Arachnids', area: 'Common', parentName: 'Animals' },
  { name: 'Invertebrates', area: 'Common', parentName: 'Animals' },
  { name: 'Fish', area: 'Common', parentName: 'Animals' },
  { name: 'Sealife', area: 'Common', parentName: 'Animals' },
  { name: 'Nature Vocabulary', area: 'Common', parentName: 'Animals' },
  { name: 'Body Parts Of Animals', area: 'Common', parentName: 'Animals' },
  { name: 'Child Animals', area: 'Common', parentName: 'Animals' },
  { name: 'Groups Of Animals', area: 'Common', parentName: 'Animals' },
  { name: 'Movement', area: 'Common', parentName: 'Actions' },
  { name: 'Places', area: 'Common' },
  { name: 'Buildings', area: 'Common', parentName: 'Places' },
  { name: 'Rooms & Home', area: 'Common', parentName: 'Places' },
  { name: 'Furniture', area: 'Common', parentName: 'Places' },
  { name: 'Habitats', area: 'Common', parentName: 'Places' },
  { name: 'Local Places', area: 'Common', parentName: 'Places' },
  { name: 'Jobs & Careers', area: 'Common' },
  { name: 'Weather', area: 'Common' },
  { name: 'Seasons', area: 'Common', parentName: 'Weather' },
  { name: 'Body Parts', area: 'Common' },
  { name: 'Medical', area: 'Common', parentName: 'Body Parts' },
  { name: 'Internal Organs', area: 'Common', parentName: 'Body Parts' },
  { name: 'Time', area: 'Common' },
  { name: 'Time (Clocks)', area: 'Common', parentName: 'Time' },
  { name: 'Months', area: 'Common', parentName: 'Time' },
  { name: 'Events & Occasions', area: 'Common', parentName: 'Time' },
  { name: 'Passover Keywords', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Easter Keywords', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Halloween Keywords', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Bonfire Night Keywords', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Christmas Keywords', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Special Days', area: 'Common', parentName: 'Events & Occasions' },
  { name: 'Clothes', area: 'Common' },
  { name: 'Transport', area: 'Common' },
  { name: 'Money', area: 'Common' },
  { name: 'Toys', area: 'Common' },
  { name: 'World Map', area: 'Common' },
  { name: 'My School Main', area: 'My School' },
  { name: 'Baycroft Expects', area: 'My School' },
  { name: 'Thinking Skills', area: 'My School' },
  { name: 'When Things Go Wrong', area: 'My School' },
  { name: 'Blank Levels', area: 'My School' },
  { name: 'My School Lessons', area: 'My School' },
  { name: 'Class Equipment', area: 'My School' },
  { name: 'People At School', area: 'My School' },
  { name: 'Subject Vocabulary', area: 'Subject Vocab' },
  { name: 'Lessons', area: 'Subject Vocab' },
  { name: 'Better Words (Thesaurus)', area: 'My School' },
  { name: 'Sentence Creator', area: 'Subject Vocab' },
  { name: 'Small Words (Subject)', area: 'Subject Vocab' },
  { name: 'Letters (Subject)', area: 'Subject Vocab' },
  { name: 'Numbers (Subject)', area: 'Subject Vocab' },
  { name: 'Breaktime', area: 'Subject Vocab' },
  { name: 'Lunchtime', area: 'Subject Vocab' },
  { name: 'Tutor Time', area: 'Subject Vocab' },
  { name: 'English', area: 'Subject Vocab' },
  { name: 'Maths', area: 'Subject Vocab' },
  { name: 'Science', area: 'Subject Vocab' },
  { name: 'T.F.L. / I.T.', area: 'Subject Vocab' },
  { name: 'P.D.', area: 'Subject Vocab' },
  { name: 'P.E.E.P.', area: 'Subject Vocab' },
  { name: 'E.P.I.C.', area: 'Subject Vocab' },
  { name: 'P.E.', area: 'Subject Vocab' },
  { name: 'Art', area: 'Subject Vocab' },
  { name: 'Performing Arts', area: 'Subject Vocab' },
  { name: 'Sustainability', area: 'Subject Vocab' },
  { name: 'Cooking', area: 'Subject Vocab' },
  { name: 'Resistant Materials', area: 'Subject Vocab' },
  { name: 'Textiles', area: 'Subject Vocab' },
  { name: 'Religion & Worldviews', area: 'Subject Vocab' },
  { name: 'Music', area: 'Subject Vocab' },
  { name: 'Horticulture', area: 'Subject Vocab' },
  { name: 'Retail', area: 'Subject Vocab' },
  { name: 'Photography', area: 'Subject Vocab' },
  { name: 'Construction', area: 'Subject Vocab' },
  { name: 'Engineering', area: 'Subject Vocab' },
  { name: 'Design Technology', area: 'Subject Vocab' },
  { name: 'Hair & Beauty', area: 'Subject Vocab' },
  { name: 'Health & Social Care', area: 'Subject Vocab' },
  { name: 'Public Services', area: 'Subject Vocab' },
  { name: 'S.T.E.M.', area: 'Subject Vocab' },
  { name: 'Option A', area: 'Subject Vocab' },
  { name: 'Option B', area: 'Subject Vocab' },
  { name: 'Option C', area: 'Subject Vocab' },
  { name: 'Tech Rotation', area: 'Subject Vocab' },
  { name: 'Sign Main', area: 'Sign' },
  { name: 'A-Z Of Sign', area: 'Sign' },
  { name: 'A (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'B (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'C (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'D (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'E (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'F (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'G (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'H (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'I (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'J (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'K (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'L (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'M (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'N (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'O (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'P (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'Q (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'R (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'S (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'T (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'U (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'V (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'W (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'X (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'Y (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
  { name: 'Z (Sign)', area: 'Sign', parentName: 'A-Z Of Sign' },
];

// ── Helper functions ──
function findEntry(name) {
  return boardHierarchy.find(e => e.name.toLowerCase() === name.toLowerCase());
}

function hierarchyTier(name) {
  let tier = 1;
  let current = name;
  while (current) {
    const entry = findEntry(current);
    if (!entry || !entry.parentName) return tier;
    tier++;
    current = entry.parentName;
  }
  return tier;
}

function hierarchyPath(name) {
  const parts = [];
  let current = name;
  while (current) {
    parts.unshift(current);
    const entry = findEntry(current);
    current = entry ? entry.parentName : null;
  }
  return parts.join(' > ');
}

function hierarchyParent(name) {
  const entry = findEntry(name);
  return entry ? entry.parentName || null : null;
}

// ── Scan all JSON files ──
const boardsDir = path.join(__dirname, 'lib', 'data', 'boards');

function findJsonFiles(dir) {
  let results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(findJsonFiles(fullPath));
    } else if (entry.name.toLowerCase().endsWith('.json')) {
      results.push(fullPath);
    }
  }
  return results;
}

const jsonFiles = findJsonFiles(boardsDir);
console.log(`Found ${jsonFiles.length} JSON board files`);

// ── Parse boards ──
const boards = [];
for (const filePath of jsonFiles) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(raw);

    const relPath = path.relative(boardsDir, filePath).replace(/\\/g, '/');
    const folderPath = path.dirname(relPath);
    const area = data.area || relPath.split('/')[0];

    // Count tile types
    const tiles = data.tiles || [];
    const vocabTiles = tiles.filter(t => t.type === 'vocabulary').length;
    const boardLinkTiles = tiles.filter(t => t.type === 'board_link').length;
    const blankTiles = tiles.filter(t => t.type === 'blank').length;
    const imageTiles = tiles.filter(t => t.type === 'image' || t.type === 'image_viewer').length;
    const totalTiles = tiles.length;

    // Check if any images exist on disk
    let hasImages = false;
    for (const tile of tiles) {
      if (tile.image && tile.image.startsWith('assets/')) {
        const imgPath = path.join(__dirname, tile.image);
        if (fs.existsSync(imgPath)) {
          hasImages = true;
          break;
        }
      }
    }

    const boardName = data.name || path.basename(filePath, path.extname(filePath));
    const tier = data.tier || hierarchyTier(boardName);
    const parentBoard = data.parentBoardId || hierarchyParent(boardName);
    const boardPath = hierarchyPath(boardName);
    const isSubBoard = data.isSubBoard || !!parentBoard;

    boards.push({
      boardName,
      area,
      tier,
      isSubBoard,
      parentBoard: parentBoard || '',
      boardPath: data.tier ? boardPath : `${area} > ${relPath.replace(/\/Prebuilt .*\.json$/i, '').replace(/\//g, ' > ')}`,
      folderPath: folderPath === '.' ? '' : folderPath,
      jsonFile: path.basename(filePath),
      columns: data.columns || 5,
      totalTiles,
      vocabTiles,
      boardLinkTiles,
      blankTiles,
      imageTiles,
      hasImages,
      adjustableLayout: data.adjustableLayout || false,
      backgroundColor: data.backgroundColor || 'transparent',
      sortOrder: data.sortOrder || 0,
    });
  } catch (e) {
    console.error(`Error parsing ${filePath}: ${e.message}`);
  }
}

// Sort by area, then tier, then name
boards.sort((a, b) => {
  const areaOrder = { 'Common': 1, 'My School': 2, 'Subject Vocab': 3, 'Sign': 4, 'Personal': 5 };
  const areaDiff = (areaOrder[a.area] || 99) - (areaOrder[b.area] || 99);
  if (areaDiff !== 0) return areaDiff;
  if (a.tier !== b.tier) return a.tier - b.tier;
  return a.boardName.localeCompare(b.boardName);
});

console.log(`Parsed ${boards.length} boards`);

// ── Create Excel workbook ──
const workbook = new ExcelJS.Workbook();
workbook.creator = 'Charlie Chat Board Tracker';
workbook.created = new Date();

const ws = workbook.addWorksheet('Board Tracker', {
  views: [{ state: 'frozen', xSplit: 0, ySplit: 1 }],
});

// ── Define columns ──
ws.columns = [
  { header: '#', key: 'num', width: 5 },
  { header: 'Board Name', key: 'boardName', width: 35 },
  { header: 'Area', key: 'area', width: 15 },
  { header: 'Tier', key: 'tier', width: 7 },
  { header: 'Tier Label', key: 'tierLabel', width: 14 },
  { header: 'Parent Board', key: 'parentBoard', width: 30 },
  { header: 'Built Board', key: 'built', width: 13 },
  { header: 'Pictures Persist On Reload', key: 'picsPersist', width: 26 },
  { header: 'Order Persists On Reload', key: 'orderPersist', width: 25 },
  { header: 'Hierarchy Correct & Persists', key: 'hierarchyCorrect', width: 28 },
  { header: 'Board 100% Correct', key: 'boardCorrect', width: 20 },
  { header: 'Notes / Issues', key: 'notes', width: 35 },
  { header: 'Board Path (Hierarchy)', key: 'boardPath', width: 50 },
  { header: 'Folder Path', key: 'folderPath', width: 40 },
  { header: 'JSON File', key: 'jsonFile', width: 35 },
  { header: 'Columns', key: 'columns', width: 9 },
  { header: 'Total Tiles', key: 'totalTiles', width: 11 },
  { header: 'Vocab Tiles', key: 'vocabTiles', width: 11 },
  { header: 'Board Links', key: 'boardLinkTiles', width: 11 },
  { header: 'Blank Tiles', key: 'blankTiles', width: 11 },
  { header: 'Image Tiles', key: 'imageTiles', width: 11 },
  { header: 'Has Images On Disk', key: 'hasImages', width: 18 },
  { header: 'Is Sub Board', key: 'isSubBoard', width: 13 },
  { header: 'Adjustable Layout', key: 'adjustableLayout', width: 17 },
  { header: 'Sort Order', key: 'sortOrder', width: 11 },
];

// ── Styling ──
const headerRow = ws.getRow(1);
headerRow.height = 30;
headerRow.eachCell((cell) => {
  cell.font = { bold: true, size: 11, color: { argb: 'FFFFFFFF' } };
  cell.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF2E5090' },
  };
  cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
  cell.border = {
    bottom: { style: 'medium', color: { argb: 'FF000000' } },
  };
});

// ── Area colours ──
const areaColors = {
  'Common':      'FFE8F0FE',
  'My School':   'FFFCE8CD',
  'Subject Vocab': 'FFE6F4EA',
  'Sign':        'FFF3E8FD',
  'Personal':    'FFFFF3E0',
};

const tierLabels = {
  1: 'Main',
  2: 'Sub',
  3: 'Tertiary',
  4: 'Quaternary',
  5: 'Quinary',
};

// ── Add data rows ──
boards.forEach((b, i) => {
  const row = ws.addRow({
    num: i + 1,
    boardName: b.boardName,
    area: b.area,
    tier: b.tier,
    tierLabel: tierLabels[b.tier] || `Tier ${b.tier}`,
    parentBoard: b.parentBoard,
    built: '',
    picsPersist: '',
    orderPersist: '',
    hierarchyCorrect: '',
    boardCorrect: '',
    notes: '',
    boardPath: b.boardPath,
    folderPath: b.folderPath,
    jsonFile: b.jsonFile,
    columns: b.columns,
    totalTiles: b.totalTiles,
    vocabTiles: b.vocabTiles,
    boardLinkTiles: b.boardLinkTiles,
    blankTiles: b.blankTiles,
    imageTiles: b.imageTiles,
    hasImages: b.hasImages ? 'Yes' : 'No',
    isSubBoard: b.isSubBoard ? 'Yes' : 'No',
    adjustableLayout: b.adjustableLayout ? 'Yes' : 'No',
    sortOrder: b.sortOrder,
  });

  // Area background colour
  const bgColor = areaColors[b.area] || 'FFFFFFFF';
  row.eachCell({ includeEmpty: true }, (cell, colNumber) => {
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: bgColor },
    };
    cell.alignment = { vertical: 'middle', wrapText: true };
    cell.border = {
      bottom: { style: 'thin', color: { argb: 'FFD0D0D0' } },
    };

    // Centre-align certain columns
    if ([1, 3, 4, 5, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25].includes(colNumber)) {
      cell.alignment = { vertical: 'middle', horizontal: 'center' };
    }
  });

  // Indent sub-boards
  if (b.tier > 1) {
    const nameCell = row.getCell(2);
    nameCell.value = '  '.repeat(b.tier - 1) + b.boardName;
  }

  // Highlight blank boards (all tiles blank)
  if (b.totalTiles > 0 && b.blankTiles === b.totalTiles) {
    row.getCell(2).font = { italic: true, color: { argb: 'FF888888' } };
  }
});

// ── Add data validation for checkbox columns ──
const lastRow = ws.lastRow.number;
for (let r = 2; r <= lastRow; r++) {
  // Built Board (G)
  ws.getCell(r, 7).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Yes,No,In Progress"'],
  };
  // Pictures Persist (H)
  ws.getCell(r, 8).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Yes,No,In Progress"'],
  };
  // Order Persist (I)
  ws.getCell(r, 9).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Yes,No,In Progress"'],
  };
  // Hierarchy Correct (J)
  ws.getCell(r, 10).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Yes,No,In Progress"'],
  };
  // Board 100% Correct (K)
  ws.getCell(r, 11).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Yes,No,In Progress"'],
  };
}

// ── Summary sheet ──
const summary = workbook.addWorksheet('Summary');

summary.columns = [
  { header: 'Metric', key: 'metric', width: 35 },
  { header: 'Value', key: 'value', width: 15 },
];

const summaryHeader = summary.getRow(1);
summaryHeader.height = 25;
summaryHeader.eachCell((cell) => {
  cell.font = { bold: true, size: 11, color: { argb: 'FFFFFFFF' } };
  cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2E5090' } };
  cell.alignment = { vertical: 'middle', horizontal: 'center' };
});

const summaryData = [
  ['Total Boards', boards.length],
  [''],
  ['--- BY AREA ---', ''],
  ...Object.entries(areaColors).map(([area]) => {
    const count = boards.filter(b => b.area === area).length;
    return [area, count];
  }),
  [''],
  ['--- BY TIER ---', ''],
  ...[1,2,3,4,5].map(t => {
    const count = boards.filter(b => b.tier === t).length;
    return [`Tier ${t} (${tierLabels[t]})`, count];
  }),
  [''],
  ['--- TILE STATS ---', ''],
  ['Total Vocab Tiles', boards.reduce((s, b) => s + b.vocabTiles, 0)],
  ['Total Board Link Tiles', boards.reduce((s, b) => s + b.boardLinkTiles, 0)],
  ['Total Blank Tiles', boards.reduce((s, b) => s + b.blankTiles, 0)],
  ['Total Image Tiles', boards.reduce((s, b) => s + b.imageTiles, 0)],
  ['Boards With Images On Disk', boards.filter(b => b.hasImages).length],
  ['Boards Without Images', boards.filter(b => !b.hasImages).length],
  [''],
  ['--- AREA COLOURS ---', ''],
  ...Object.entries(areaColors).map(([area, color]) => [area, color]),
];

summaryData.forEach(([metric, value]) => {
  summary.addRow({ metric, value });
});

// ── Save ──
const outputPath = path.join(__dirname, 'Board Tracker.xlsx');
workbook.xlsx.writeFile(outputPath).then(() => {
  console.log(`\nSpreadsheet saved to: ${outputPath}`);
  console.log(`Total boards: ${boards.length}`);
  console.log(`Boards by area:`);
  Object.keys(areaColors).forEach(area => {
    console.log(`  ${area}: ${boards.filter(b => b.area === area).length}`);
  });
  console.log(`Boards by tier:`);
  [1,2,3,4,5].forEach(t => {
    console.log(`  Tier ${t} (${tierLabels[t]}): ${boards.filter(b => b.tier === t).length}`);
  });
}).catch(err => {
  console.error('Error writing file:', err);
});
