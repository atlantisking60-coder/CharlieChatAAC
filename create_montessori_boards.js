const fs = require('fs');
const path = require('path');

const WORDS_BASE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\symbols\\1. Main Boards\\Small Words';
const BOARDS_BASE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards\\Common\\Small Words\\Montessori';

function toSnakeCase(str) {
    return str.toLowerCase().replace(/[^a-z0-9& ]/g, '').replace(/ +/g, ' ').trim();
}

const TYPES = [
    'Abstract Noun', 'Adjective', 'Adverb', 'Article', 'Auxiliary Verb',
    'Collective Noun', 'Conjunction', 'Gerund', 'Interjection', 'Intransitive Verb',
    'Linking Verb', 'Noun', 'Participle', 'Preposition', 'Pronoun',
    'Proper Noun', 'Transitive Verb', 'Other'
];

TYPES.forEach(type => {
    // Read word list from text file
    const txtPath = path.join(WORDS_BASE, type + '.txt');
    if (!fs.existsSync(txtPath)) {
        console.log('Skipping ' + type + ' - no txt file');
        return;
    }
    const words = fs.readFileSync(txtPath, 'utf8').split('\n').filter(w => w.trim());

    const boardId = toSnakeCase(type);

    // Build tiles - one per word
    const tiles = words.map((word, i) => {
        const imagePath = 'assets/symbols/1. Main Boards/Small Words/' + type + '/' + word.toLowerCase() + '.png';
        return {
            id: 'prebuilt_' + boardId + '_tile_' + (i + 1),
            type: 'image',
            label: word,
            category: type,
            image: imagePath,
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
        name: type,
        area: 'Montessori Grammar',
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

    // Create folder
    const folderPath = path.join(BOARDS_BASE, type);
    fs.mkdirSync(folderPath, { recursive: true });

    // Write JSON
    const jsonPath = path.join(folderPath, 'prebuilt_' + boardId + '.json');
    fs.writeFileSync(jsonPath, JSON.stringify(json, null, 2), 'utf8');
    console.log(type + ' (' + tiles.length + ' tiles)');
});

console.log('Done!');
