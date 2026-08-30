import re, sys
from collections import Counter
src = open('lib/data/board_index.dart', encoding='utf-8').read()
entries = re.findall(r"BoardIndexEntry\(\s*id: '([^']+)',\s*name: '([^']+)',\s*area: '([^']+)'(?:,\s*parentBoardId: ([^,]+))?,?\s*isSubBoard: (\w+),\s*isTertiaryBoard: (\w+),\s*sortOrder: (\d+),\s*tier: (\d+)", src)
c = Counter()
byArea = Counter()
for e in entries:
    area = e[2]
    tier = int(e[7])
    byArea[area] += 1
    if area == 'Subject Vocab':
        c[tier] += 1
print('Subject Vocab by tier:', dict(sorted(c.items())))
print('area totals:', dict(sorted(byArea.items())))
print('total parsed entries:', len(entries))