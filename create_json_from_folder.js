const fs = require('fs');
const path = require('path');

const folderPath = process.argv[2];
if (!folderPath || !fs.existsSync(folderPath)) {
    console.log('Folder not found: ' + folderPath);
    process.exit(1);
}

if (!fs.statSync(folderPath).isDirectory()) {
    console.log('Not a folder: ' + folderPath);
    process.exit(1);
}

function fixName(name) {
    const apostropheMap = {
        'lets': "let's", 'dont': "don't", 'wont': "won't", 'cant': "can't",
        'didnt': "didn't", 'doesnt': "doesn't", 'isnt': "isn't", 'wasnt': "wasn't",
        'arent': "aren't", 'hasnt': "hasn't", 'havent': "haven't", 'wouldnt': "wouldn't",
        'shouldnt': "shouldn't", 'couldnt': "couldn't", 'thats': "that's", 'whats': "what's",
        'whos': "who's", 'theres': "there's", 'heres': "here's",
        'im': "i'm", 'ive': "i've", 'id': "i'd", 'ill': "i'll",
        'youre': "you're", 'youve': "you've", 'youd': "you'd", 'youll': "you'll",
        'hes': "he's", 'hed': "he'd", 'hell': "he'll",
        'shes': "she's", 'shed': "she'd", 'shell': "she'll",
        'were': "we're", 'weve': "we've", 'wed': "we'd", 'well': "we'll",
        'theyre': "they're", 'theyve': "they've", 'theyd': "they'd", 'theyll': "they'll",
    };
    let result = name.replace(/_/g, ' ');
    const words = result.split(' ');
    const fixedWords = words.map(w => apostropheMap[w.toLowerCase()] || w);
    result = fixedWords.join(' ');
    result = result.replace(/\b\w/g, c => c.toUpperCase());
    return result;
}

const files = fs.readdirSync(folderPath).filter(f => f.toLowerCase().endsWith('.png'));
if (files.length === 0) {
    console.log('No PNG files found in this folder.');
    process.exit(0);
}

const folderName = path.basename(folderPath);
const boardId = folderName.toLowerCase().replace(/[^a-z0-9& ]/g, '').replace(/ +/g, ' ').trim();
const boardName = fixName(folderName);

const tiles = files.map((file, i) => {
    const word = path.basename(file, '.png');
    const relPath = path.relative(
        'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards',
        path.join(folderPath, file)
    ).replace(/\\/g, '/');

    return {
        id: 'prebuilt_' + boardId + '_tile_' + (i + 1),
        type: 'image',
        label: word,
        category: boardName,
        image: relPath,
        emoji: '',
        linkedBoardName: null,
        isFullScreenImage: false,
        bgColor: 'transparent',
        textColor: '#000000',
        tileSize: 1,
        colSpan: 1,
        rowSpan: 1,
        customVoice: ''
    };
});

const cols = 5;
const rows = Math.ceil(tiles.length / cols);

const json = {
    id: 'prebuilt_' + boardId,
    name: boardName,
    area: 'Custom',
    columns: cols,
    backgroundColor: 'transparent',
    adjustableLayout: false,
    isSubBoard: false,
    isTertiaryBoard: false,
    isQuaternaryBoard: false,
    isQuinaryBoard: false,
    sortOrder: 0,
    tier: 1,
    boxScale: 1,
    tileHeight: 100,
    tileWidth: 100,
    layout: {
        rows: rows,
        blankTilesAdded: 0
    },
    tiles: tiles
};

const jsonPath = path.join(folderPath, 'prebuilt_' + boardId + '.json');
fs.writeFileSync(jsonPath, JSON.stringify(json, null, 2), 'utf8');
console.log('Created: prebuilt_' + boardId + '.json (' + tiles.length + ' tiles)');
