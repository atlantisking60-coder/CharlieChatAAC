const fs = require('fs');
const path = require('path');

// Step 1: Parse hierarchy from Dart file
const hierContent = fs.readFileSync('C:/Users/Craig/Downloads/Charlie Chat/lib/data/board_hierarchy.dart', 'utf8');
const hierEntries = [];
// Use a regex that properly handles Dart string escapes
const regex = /BoardHierarchyEntry\('((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'(?:,\s*'((?:[^'\\]|\\.)*)')?\)/g;
let match;
while ((match = regex.exec(hierContent)) !== null) {
  // Unescape Dart strings: \' -> '
  const unescape = (s) => s.replace(/\\'/g, "'").replace(/\\\\/g, '\\');
  hierEntries.push({
    name: unescape(match[1]),
    area: unescape(match[2]),
    parentName: match[3] ? unescape(match[3]) : null
  });
}

// Step 2: Find all JSON files and extract 'name' field
function walkDir(d) {
  let r = [];
  try {
    const i = fs.readdirSync(d, {withFileTypes: true});
    for (const x of i) {
      const p = path.join(d, x.name);
      if (x.isDirectory()) r = r.concat(walkDir(p));
      else if (x.name.toLowerCase().endsWith('.json')) r.push(p);
    }
  } catch(e) {}
  return r;
}

const jsonFiles = walkDir('C:/Users/Craig/Downloads/Charlie Chat/lib/data/boards');
const jsonNames = new Set();
for (const f of jsonFiles) {
  try {
    const data = JSON.parse(fs.readFileSync(f, 'utf8'));
    if (data.name) {
      jsonNames.add(data.name.toLowerCase());
    }
  } catch(e) {}
}

// Step 3: Find virtual boards
const virtualBoards = [];
for (const entry of hierEntries) {
  if (!jsonNames.has(entry.name.toLowerCase())) {
    virtualBoards.push(entry);
  }
}

console.log('Total hierarchy entries: ' + hierEntries.length);
console.log('Unique JSON names: ' + jsonNames.size);
console.log('Virtual boards count: ' + virtualBoards.length);
console.log('');
console.log('=== VIRTUAL BOARDS ===');
virtualBoards.forEach((b, i) => {
  console.log((i+1) + '. Name: ' + JSON.stringify(b.name) + ' | Area: ' + b.area + ' | Parent: ' + (b.parentName || '(none)'));
});

// Check if symbols folder exists for each
console.log('');
console.log('=== CHECKING SYMBOL FOLDERS ===');
const symbolsRoot = 'C:/Users/Craig/Downloads/Charlie Chat/assets/symbols';
function dirExists(d) { try { fs.statSync(d); return true; } catch(e) { return false; } }

// Map area to symbols subfolder
const areaToFolder = {
  'Common': '1. Main Boards',
  'Subject Vocab': '4. Subjects',
  'Sign': '3. Lesson Vocab',
  'My School': '2. Baycroft Specific',
  'Personal': ''
};

virtualBoards.forEach((b, i) => {
  const areaFolder = areaToFolder[b.area] || b.area;
  // Try to find a matching folder under assets/symbols
  const possiblePaths = [
    path.join(symbolsRoot, areaFolder, b.name),
    path.join(symbolsRoot, b.name),
  ];
  let found = false;
  for (const p of possiblePaths) {
    if (dirExists(p)) {
      console.log((i+1) + '. ' + b.name + ' => FOUND: ' + p);
      found = true;
      break;
    }
  }
  if (!found) {
    console.log((i+1) + '. ' + b.name + ' => NO SYMBOL FOLDER');
  }
});