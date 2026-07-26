const fs = require('fs');
const path = require('path');

// Recursively search for any folder matching a virtual board name under assets/symbols
function findFolder(dir, targetName) {
  const target = targetName.toLowerCase();
  let results = [];
  try {
    const items = fs.readdirSync(dir, {withFileTypes: true});
    for (const item of items) {
      if (item.isDirectory()) {
        if (item.name.toLowerCase() === target) {
          results.push(path.join(dir, item.name));
        }
        results = results.concat(findFolder(path.join(dir, item.name), targetName));
      }
    }
  } catch(e) {}
  return results;
}

const symbolsRoot = 'C:/Users/Craig/Downloads/Charlie Chat/assets/symbols';
// Also check BOARDS subfolder
const boardsRoot = 'C:/Users/Craig/Downloads/Charlie Chat/assets/symbols/BOARDS';

const virtualBoards = [
  {name: "2001 Monsters, Inc.", area: "Common", parentName: "Disney Stories"},
  {name: "Horror Icons", area: "Common", parentName: "Characters"},
  {name: "Breaktime", area: "Subject Vocab", parentName: null},
  {name: "E.P.I.C.", area: "Subject Vocab", parentName: null},
  {name: "P.D.", area: "Subject Vocab", parentName: null},
  {name: "P.E.", area: "Subject Vocab", parentName: null},
  {name: "P.E.E.P.", area: "Subject Vocab", parentName: null},
  {name: "S.T.E.M.", area: "Subject Vocab", parentName: null},
  {name: "T.F.L. / I.T.", area: "Subject Vocab", parentName: null},
  {name: "Tutor Time", area: "Subject Vocab", parentName: null},
  {name: "A-Z Of Sign", area: "Sign", parentName: null},
  {name: "A (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "B (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "C (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "D (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "E (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "F (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "G (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "H (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "I (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "J (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "K (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "L (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "M (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "N (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "O (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "P (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "Q (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "R (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "S (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "T (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "U (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "V (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "W (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "X (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "Y (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
  {name: "Z (Sign)", area: "Sign", parentName: "A-Z Of Sign"},
];

// Compute tiers
function getTier(boardName, entries) {
  let tier = 1;
  let current = boardName;
  const seen = new Set();
  while (current) {
    if (seen.has(current.toLowerCase())) break;
    seen.add(current.toLowerCase());
    const entry = entries.find(e => e.name.toLowerCase() === current.toLowerCase());
    if (!entry || !entry.parentName) return tier;
    tier++;
    current = entry.parentName;
  }
  return tier;
}

virtualBoards.forEach((b, i) => {
  const tier = getTier(b.name, virtualBoards);
  let found = findFolder(symbolsRoot, b.name);
  // Also try without special chars
  if (found.length === 0) {
    const simplified = b.name.replace(/[^a-zA-Z0-9 ]/g, '').trim();
    found = findFolder(symbolsRoot, simplified);
  }
  console.log((i+1) + '. ' + b.name + ' | Area: ' + b.area + ' | Parent: ' + (b.parentName || '(none)') + ' | Tier: ' + tier + ' | Symbols: ' + (found.length > 0 ? found.join(', ') : 'NONE'));
});