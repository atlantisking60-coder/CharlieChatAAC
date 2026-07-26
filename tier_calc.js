const fs = require('fs');
const path = require('path');

const hierContent = fs.readFileSync('C:/Users/Craig/Downloads/Charlie Chat/lib/data/board_hierarchy.dart', 'utf8');
const allEntries = [];
const regex = /BoardHierarchyEntry\('((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'(?:,\s*'((?:[^'\\]|\\.)*)')?\)/g;
let match;
while ((match = regex.exec(hierContent)) !== null) {
  const unescape = (s) => s.replace(/\\'/g, "'").replace(/\\\\/g, '\\');
  allEntries.push({
    name: unescape(match[1]),
    area: unescape(match[2]),
    parentName: match[3] ? unescape(match[3]) : null
  });
}

function getTier(name) {
  let tier = 1;
  let current = name;
  const seen = new Set();
  while (current) {
    if (seen.has(current.toLowerCase())) break;
    seen.add(current.toLowerCase());
    const entry = allEntries.find(e => e.name.toLowerCase() === current.toLowerCase());
    if (!entry || !entry.parentName) return tier;
    tier++;
    current = entry.parentName;
  }
  return tier;
}

const virtualNames = [
  "2001 Monsters, Inc.", "Horror Icons", "Breaktime", "E.P.I.C.",
  "P.D.", "P.E.", "P.E.E.P.", "S.T.E.M.", "T.F.L. / I.T.", "Tutor Time",
  "A-Z Of Sign",
  "A (Sign)", "B (Sign)", "C (Sign)", "D (Sign)", "E (Sign)",
  "F (Sign)", "G (Sign)", "H (Sign)", "I (Sign)", "J (Sign)",
  "K (Sign)", "L (Sign)", "M (Sign)", "N (Sign)", "O (Sign)",
  "P (Sign)", "Q (Sign)", "R (Sign)", "S (Sign)", "T (Sign)",
  "U (Sign)", "V (Sign)", "W (Sign)", "X (Sign)", "Y (Sign)",
  "Z (Sign)"
];

// Also trace the full parent chain for each
virtualNames.forEach(name => {
  const chain = [name];
  let current = name;
  const seen = new Set();
  while (current) {
    if (seen.has(current.toLowerCase())) break;
    seen.add(current.toLowerCase());
    const entry = allEntries.find(e => e.name.toLowerCase() === current.toLowerCase());
    if (!entry || !entry.parentName) break;
    chain.push(entry.parentName);
    current = entry.parentName;
  }
  console.log(name + ' | Tier ' + getTier(name) + ' | Chain: ' + chain.join(' -> '));
});