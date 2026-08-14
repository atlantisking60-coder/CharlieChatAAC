import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
dart_path = root / "lib" / "data" / "board_hierarchy.dart"
json_path = root / "lib" / "data" / "runtime_hierarchy.json"

# Matches BoardHierarchyEntry('name', 'area'[, 'parentName']),
# including names that contain escaped single quotes (e.g. Let\'s)
# or double-quoted names with literal apostrophes (e.g. "A Bug's Life").
single_re = re.compile(
    r'''BoardHierarchyEntry\(\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'(?:\s*,\s*'((?:\\'|[^'])*)')?\s*\)\s*,?'''
)
double_re = re.compile(
    r'''BoardHierarchyEntry\(\s*"([^"]*)"\s*,\s*'([^']*)'(?:\s*,\s*'([^']*)')?\s*\)\s*,?'''
)

compiled = []
seen = set()
for line in dart_path.read_text(encoding="utf-8").splitlines():
    m = single_re.search(line) or double_re.search(line)
    if not m:
        continue
    name = m.group(1).replace("\\'", "'")
    area = m.group(2).replace("\\'", "'")
    parent = m.group(3)
    if parent is not None:
        parent = parent.replace("\\'", "'")

    key = (name.lower(), area.lower())
    if key in seen:
        continue
    seen.add(key)

    entry = {"name": name, "area": area}
    if parent:
        entry["parentName"] = parent
    compiled.append(entry)

compiled_keys = {(e["name"].lower(), e["area"].lower()) for e in compiled}

extras = []  # Regenerate from compiled only; old/renamed/duplicate entries are dropped.

entries = compiled

json_path.parent.mkdir(parents=True, exist_ok=True)
with open(json_path, "w", encoding="utf-8") as f:
    json.dump({"entries": entries}, f, indent=2, ensure_ascii=False)

print(f"Wrote {len(entries)} entries to {json_path}")
print(f"  {len(compiled)} compiled from board_hierarchy.dart")
print(f"  {len(extras)} extra admin/user boards preserved")
