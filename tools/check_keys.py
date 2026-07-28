import json, sys
from pathlib import Path
p = Path(__file__).resolve().parent.parent / sys.argv[1]
with open(p) as f:
    d = json.load(f)
print(list(d.keys()))
