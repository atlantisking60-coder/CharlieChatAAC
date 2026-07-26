const fs = require('fs');
const path = require('path');

function findJsonFiles(dir) {
    let results = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            results = results.concat(findJsonFiles(fullPath));
        } else if (entry.name.endsWith('.json') && entry.name.startsWith('prebuilt_')) {
            results.push(fullPath);
        }
    }
    return results;
}

const basePath = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards';
const files = findJsonFiles(basePath);

let created = 0;
let skipped = 0;
let errors = 0;

files.forEach(filePath => {
    try {
        const dir = path.dirname(filePath);
        const base = path.basename(filePath, '.json');
        const boardName = base.replace('prebuilt_', '');
        const wordListPath = path.join(dir, boardName + ' - Word List.txt');

        // Skip if already exists
        if (fs.existsSync(wordListPath)) {
            skipped++;
            return;
        }

        // Read JSON
        const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));

        // Extract words from tiles (labels with content)
        const words = (content.tiles || [])
            .map(t => t.label)
            .filter(l => l && l.trim());

        if (words.length === 0) {
            skipped++;
            return;
        }

        // Determine board display name
        const displayName = content.name || boardName;

        // Write word list
        const text = displayName + ' - Word List\n' +
                     '='.repeat(displayName.length + 16) + '\n\n' +
                     words.join('\n') + '\n';

        fs.writeFileSync(wordListPath, text, 'utf8');
        created++;
    } catch (e) {
        errors++;
        console.log('ERROR: ' + filePath + ' - ' + e.message);
    }
});

console.log('Done! Created: ' + created + ', Skipped: ' + skipped + ', Errors: ' + errors);
