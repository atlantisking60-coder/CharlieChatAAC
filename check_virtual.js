const fs = require('fs');
const path = require('path');

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

const jf = walkDir('C:/Users/Craig/Downloads/Charlie Chat/lib/data/boards');
const nm = {};
for (const f of jf) {
  try {
    const d = JSON.parse(fs.readFileSync(f, 'utf8'));
    if (d.name) {
      const k = d.name.toLowerCase();
      if (!nm[k]) nm[k] = [];
      nm[k].push(path.basename(f));
    }
  } catch(e) {}
}

// Check specific names
const checks = [
  'breaktime', 'e.p.i.c.', 'p.d.', 'p.e.', 'p.e.e.p.',
  's.t.e.m.', "t.f.l. / i.t.", 'tutor time', 'horror icons',
  'a-z of sign', 'a (sign)', "z hinduism", 'd&d',
  'famous monsters & horror icons', 'monsters inc',
  "earth's layers", "let's get together",
  "1998 a bug's life", "2000 the emperor's new groove", "2001 monsters, inc."
];
console.log('=== SPECIFIC CHECKS ===');
checks.forEach(c => {
  const k = c.toLowerCase();
  console.log('CHECK "' + c + '": ' + (nm[k] ? JSON.stringify(nm[k]) : 'NOT_FOUND'));
});

console.log('\n=== ALL JSON NAME KEYS (sorted) ===');
Object.keys(nm).sort().forEach(k => console.log(k));