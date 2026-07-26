const fs = require('fs');
const path = require('path');

const BOARDS_BASE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\lib\\data\\boards';
const ASSETS_BASE = 'C:\\Users\\Craig\\Downloads\\Charlie Chat\\assets\\symbols';

// Convert underscores to spaces, handle common apostrophe cases
function fixName(name) {
    // Common words that should have apostrophes
    const apostropheMap = {
        'lets': "let's",
        'dont': "don't",
        'wont': "won't",
        'cant': "can't",
        'didnt': "didn't",
        'doesnt': "doesn't",
        'isnt': "isn't",
        'wasnt': "wasn't",
        'arent': "aren't",
        'hasnt': "hasn't",
        'havent': "haven't",
        'wouldnt': "wouldn't",
        'shouldnt': "shouldn't",
        'couldnt': "couldn't",
        'thats': "that's",
        'whats': "what's",
        'whos': "who's",
        'hes': "he's",
        'shes': "she's",
        'its': "it's",
        'weve': "we've",
        'theyve': "they've",
        'ive': "i've",
        'youve': "you've",
        'were': "we're",
        'theyre': "they're",
        'youre': "you're",
        'im': "i'm",
        'ive': "i've",
        'id': "i'd",
        'hed': "he'd",
        'shed': "she'd",
        'wed': "we'd",
        'theyd': "they'd",
        'youd': "you'd",
        'ill': "i'll",
        'hell': "he'll",
        'shell': "she'll",
        'well': "we'll",
        'theyll': "they'll",
        'youll': "you'll",
        'wholl': "who'll",
        'cant': "can't",
        'isnt': "isn't",
        'arent': "aren't",
        'wasnt': "wasn't",
        'werent': "weren't",
        'hasnt': "hasn't",
        'havent': "haven't",
        'hadnt': "hadn't",
        'doesnt': "doesn't",
        'dont': "don't",
        'didnt': "didn't",
        'wont': "won't",
        'wouldnt': "wouldn't",
        'shouldnt': "shouldn't",
        'couldnt': "couldn't",
        'mustnt': "mustn't",
        'neednt': "needn't",
        'lets': "let's",
        'thats': "that's",
        'whats': "what's",
        'theres': "there's",
        'heres': "here's",
        'whos': "who's",
        'hos': "ho's",
    };

    // Replace underscores with spaces
    let result = name.replace(/_/g, ' ');

    // Check for apostrophe opportunities
    const words = result.split(' ');
    const fixedWords = words.map(word => {
        const lower = word.toLowerCase();
        if (apostropheMap[lower]) {
            return apostropheMap[lower];
        }
        return word;
    });
    result = fixedWords.join(' ');

    // Title case
    result = result.replace(/\b\w/g, c => c.toUpperCase());

    return result;
}

// Fix word list filenames
function fixWordListFiles(dir) {
    let count = 0;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            count += fixWordListFiles(fullPath);
        } else if (entry.name.includes('_') && entry.name.includes('Word List')) {
            const newName = fixName(entry.name);
            if (newName !== entry.name) {
                const newPath = path.join(dir, newName);
                fs.renameSync(fullPath, newPath);
                count++;
            }
        }
    }
    return count;
}

// Fix JSON filenames
function fixJsonFiles(dir) {
    let count = 0;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            count += fixJsonFiles(fullPath);
        } else if (entry.name.includes('_') && entry.name.startsWith('prebuilt_') && entry.name.endsWith('.json')) {
            const newName = fixName(entry.name);
            if (newName !== entry.name) {
                const newPath = path.join(dir, newName);
                fs.renameSync(fullPath, newPath);
                count++;
            }
        }
    }
    return count;
}

// Fix JSON contents
function fixJsonContents(dir) {
    let count = 0;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            count += fixJsonContents(fullPath);
        } else if (entry.name.endsWith('.json') && entry.name.startsWith('prebuilt_')) {
            try {
                const content = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
                let modified = false;

                // Fix id
                if (content.id && content.id.includes('_')) {
                    content.id = fixName(content.id).toLowerCase().replace(/ /g, ' ');
                    modified = true;
                }

                // Fix name
                if (content.name && content.name.includes('_')) {
                    content.name = fixName(content.name);
                    modified = true;
                }

                // Fix tiles
                if (content.tiles) {
                    content.tiles.forEach(tile => {
                        if (tile.id && tile.id.includes('_')) {
                            // Keep tile ids lowercase with spaces
                            tile.id = fixName(tile.id).toLowerCase().replace(/ /g, ' ');
                            modified = true;
                        }
                        if (tile.label && tile.label.includes('_')) {
                            tile.label = fixName(tile.label);
                            modified = true;
                        }
                        if (tile.category && tile.category.includes('_')) {
                            tile.category = fixName(tile.category);
                            modified = true;
                        }
                    });
                }

                if (modified) {
                    fs.writeFileSync(fullPath, JSON.stringify(content, null, 2), 'utf8');
                    count++;
                }
            } catch(e) {}
        }
    }
    return count;
}

console.log('Fixing word list filenames...');
const wordListsFixed = fixWordListFiles(BOARDS_BASE);
console.log('  Fixed: ' + wordListsFixed);

console.log('Fixing JSON filenames...');
const jsonsFixed = fixJsonFiles(BOARDS_BASE);
console.log('  Fixed: ' + jsonsFixed);

console.log('Fixing JSON contents...');
const contentsFixed = fixJsonContents(BOARDS_BASE);
console.log('  Fixed: ' + contentsFixed);

console.log('Done!');
