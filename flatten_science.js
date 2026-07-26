const fs = require('fs');
const path = require('path');

const BOARDS_SCIENCE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards\\Subject Vocab\\Science';
const ASSETS_SCIENCE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\symbols\\3. Lesson Vocab\\Science';

function moveSubfoldersUp(parentDir) {
    const years = ['Year 7', 'Year 8', 'Year 9'];
    let moved = 0;

    years.forEach(year => {
        const yearPath = path.join(parentDir, year);
        if (!fs.existsSync(yearPath) || !fs.statSync(yearPath).isDirectory()) return;

        const entries = fs.readdirSync(yearPath, { withFileTypes: true });
        entries.forEach(entry => {
            const src = path.join(yearPath, entry.name);
            const dest = path.join(parentDir, entry.name);

            if (fs.existsSync(dest)) {
                console.log('  SKIP (exists): ' + entry.name);
                return;
            }

            fs.renameSync(src, dest);
            console.log('  MOVED: ' + year + '/' + entry.name + ' -> ' + entry.name);
            moved++;
        });

        // Remove empty year folder
        if (fs.readdirSync(yearPath).length === 0) {
            fs.rmdirSync(yearPath);
            console.log('  Removed empty: ' + year + '/');
        }
    });

    return moved;
}

// Fix typo in my path
const assetsPath = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\symbols\\3. Lesson Vocab\\Science';

console.log('Moving boards...');
const boardsMoved = moveSubfoldersUp(BOARDS_SCIENCE);
console.log('  Moved: ' + boardsMoved);

console.log('\\nMoving assets...');
const assetsMoved = moveSubfoldersUp(assetsPath);
console.log('  Moved: ' + assetsMoved);

// Now update JSON image paths
console.log('\\nUpdating JSON image paths...');
function updateJsonPaths(dir) {
    let count = 0;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            count += updateJsonPaths(fullPath);
        } else if (entry.name.endsWith('.json') && entry.name.startsWith('prebuilt_')) {
            try {
                let content = fs.readFileSync(fullPath, 'utf8');
                let modified = false;

                // Fix paths that still reference Year 7/8/9
                const yearPattern = /assets\/symbols\/3\. Lesson Vocab\/Science\/Year [789]\//g;
                if (yearPattern.test(content)) {
                    content = content.replace(yearPattern, 'assets/symbols/3. Lesson Vocab/Science/');
                    modified = true;
                }

                if (modified) {
                    fs.writeFileSync(fullPath, content, 'utf8');
                    count++;
                }
            } catch(e) {}
        }
    }
    return count;
}

const jsonsUpdated = updateJsonPaths(BOARDS_SCIENCE);
console.log('  Updated: ' + jsonsUpdated);

console.log('\\nDone!');
