const fs = require('fs');
const path = require('path');

const ASSETS_ROOT = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\sign';
const BOARDS_ROOT = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards\\Sign';

function toBoardId(str) {
    return str.toLowerCase().replace(/[^a-z0-9& ]/g, '').replace(/ +/g, ' ').trim();
}

// Folders to process: 01 through 34
const foldersToProcess = [];
const allFolders = fs.readdirSync(ASSETS_ROOT);
for (let i = 1; i <= 34; i++) {
    const prefix = String(i).padStart(2, '0') + '. ';
    const match = allFolders.find(f => f.startsWith(prefix));
    if (match) {
        foldersToProcess.push({ prefix: i, folderName: match });
    }
}

console.log('Processing ' + foldersToProcess.length + ' folders from ' + ASSETS_ROOT);
console.log('Output: ' + BOARDS_ROOT);
console.log('');

foldersToProcess.forEach(function(item) {
    var folderName = item.folderName;
    // Strip the "XX. " prefix to get the board name
    var boardName = folderName.replace(/^\d+\.\s*/, '');
    var boardId = toBoardId(boardName);

    var sourcePath = path.join(ASSETS_ROOT, folderName);
    var entries = fs.readdirSync(sourcePath, { withFileTypes: true });
    var pngFiles = entries.filter(function(e) {
        return e.isFile() && e.name.toLowerCase().endsWith('.png');
    });

    if (pngFiles.length === 0) {
        console.log(folderName + ' - no PNGs found, skipping');
        return;
    }

    // Use existing folder path (Title Case, no numbers)
    var boardFolderPath = path.join(BOARDS_ROOT, boardName);

    // Create if it doesn't exist
    if (!fs.existsSync(boardFolderPath)) {
        fs.mkdirSync(boardFolderPath, { recursive: true });
    }

    // Delete old JSON files in this folder
    var existingFiles = fs.readdirSync(boardFolderPath);
    existingFiles.forEach(function(f) {
        if (f.endsWith('.json')) {
            fs.unlinkSync(path.join(boardFolderPath, f));
        }
    });

    var tiles = pngFiles.map(function(png, i) {
        var tileName = path.basename(png.name, '.png');
        // Image path: assets/sign/XX. FolderName/file.png
        var imagePath = 'assets/sign/' + folderName + '/' + png.name;

        return {
            id: 'prebuilt_' + boardId + '_tile_' + (i + 1),
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

    var cols = 5;
    var rows = Math.ceil(tiles.length / cols);

    var json = {
        id: 'prebuilt_' + boardId,
        name: boardName,
        area: 'Sign',
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

    var jsonFileName = 'prebuilt_' + boardId + '.json';
    var jsonPath = path.join(boardFolderPath, jsonFileName);
    fs.writeFileSync(jsonPath, JSON.stringify(json, null, 2), 'utf8');

    // Verify
    var verify = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    console.log(folderName + ' -> ' + boardName + ' (' + verify.tiles.length + ' tiles, file: ' + jsonFileName + ')');
});

console.log('');
console.log('Done!');
