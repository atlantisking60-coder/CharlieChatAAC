const fs = require('fs');
const path = require('path');

const ASSETS_ROOT = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\symbols';
const BOARDS_ROOT = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards';
const LESSON_VOCAB_PREFIX = '3. Lesson Vocab';

function titleCase(str) {
    return str.replace(/\b\w/g, c => c.toUpperCase());
}

function toSnakeCase(str) {
    return str.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
}

function findLeafFolders(dir) {
    const results = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    const pngFiles = entries.filter(e => e.isFile() && e.name.toLowerCase().endsWith('.png'));
    const subdirs = entries.filter(e => e.isDirectory());

    if (pngFiles.length > 0 && subdirs.length === 0) {
        results.push({ folderPath: dir, pngFiles });
    }

    subdirs.forEach(subdir => {
        results.push(...findLeafFolders(path.join(dir, subdir.name)));
    });

    return results;
}

// Start processing
const startPath = path.join(ASSETS_ROOT, LESSON_VOCAB_PREFIX);
console.log(`Scanning: ${startPath}`);
console.log(`Output:   ${BOARDS_ROOT}`);
console.log('');

const leafFolders = findLeafFolders(startPath);

leafFolders.forEach(({ folderPath, pngFiles }) => {
    // Get the path relative to the lesson vocab root
    const relToRoot = path.relative(startPath, folderPath);
    // e.g. "Art\7" or "Art\8"

    const segments = relToRoot.split(path.sep);
    // e.g. ["Art", "7"]

    const folderName = path.basename(folderPath);
    // e.g. "7"

    const boardName = titleCase(folderName);
    const boardId = toSnakeCase(folderName);

    // Build output folder path using Title Case of each segment
    const outputSegments = segments.map(s => titleCase(s));
    const boardFolderPath = path.join(BOARDS_ROOT, ...outputSegments);
    fs.mkdirSync(boardFolderPath, { recursive: true });

    const tiles = pngFiles.map((png, i) => {
        const tileName = path.basename(png.name, '.png');
        // Image path relative to project root: assets/symbols/3. Lesson Vocab/Art/7/file.png
        const imagePath = ['assets', 'symbols', LESSON_VOCAB_PREFIX, ...segments, png.name].join('/');

        return {
            id: `prebuilt_${boardId}_tile_${i + 1}`,
            type: 'image',
            label: tileName,
            category: boardName,
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
        id: `prebuilt_${boardId}`,
        name: boardName,
        area: 'Subject Vocab',
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

    const jsonFileName = `prebuilt_${boardId}.json`;
    const jsonPath = path.join(boardFolderPath, jsonFileName);
    fs.writeFileSync(jsonPath, JSON.stringify(json, null, 2), 'utf8');

    const displayPath = outputSegments.join('\\');
    console.log(`${displayPath} (${tiles.length} tiles)`);
});

console.log('');
console.log(`Done! Processed ${leafFolders.length} boards.`);
