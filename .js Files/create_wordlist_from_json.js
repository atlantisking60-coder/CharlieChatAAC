const fs = require('fs');
const path = require('path');

const jsonPath = process.argv[2];
if (!jsonPath || !fs.existsSync(jsonPath)) {
    console.log('File not found: ' + jsonPath);
    process.exit(1);
}

if (!jsonPath.endsWith('.json')) {
    console.log('Not a JSON file: ' + jsonPath);
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

const dir = path.dirname(jsonPath);
const base = path.basename(jsonPath, '.json');
const boardName = base.replace('prebuilt_', '');
const displayName = fixName(boardName);
const wordListPath = path.join(dir, displayName + ' - Word List.txt');

if (fs.existsSync(wordListPath)) {
    console.log('Word list already exists: ' + displayName + ' - Word List.txt');
    process.exit(0);
}

const content = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const words = (content.tiles || [])
    .map(t => t.label)
    .filter(l => l && l.trim());

if (words.length === 0) {
    console.log('No words found on this board.');
    process.exit(0);
}

const title = content.name || displayName;
const text = title + ' - Word List\n' +
             '='.repeat(title.length + 16) + '\n\n' +
             words.join('\n') + '\n';

fs.writeFileSync(wordListPath, text, 'utf8');
console.log('Created: ' + displayName + ' - Word List.txt (' + words.length + ' words)');
