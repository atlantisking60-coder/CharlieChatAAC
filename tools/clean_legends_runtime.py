import json
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
DESIRED_ORDER = [
    "Legends",
    "Real Life Heroes",
    "Religion, Myth and History",
    "Books",
    "Cartoons and Puppets",
    "Computer Games",
    "Disney Stories",
    "Animations (Not Disney)",
    "Sci-Fi and Fantasy",
    "Superheroes",
]

def is_legends_top(e):
    if e.get("area") != "Legends":
        return False
    parent = e.get("parentName")
    return parent is None or parent == "Legends"

path = PROJECT / "lib" / "data" / "runtime_hierarchy.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

entries = data["entries"]
others = [e for e in entries if not is_legends_top(e)]
legends_tops = [e for e in entries if is_legends_top(e)]

# Rename old Not Disney Animations if present and make it a true top-level
for e in legends_tops:
    if e["name"] == "Not Disney Animations":
        e["name"] = "Animations (Not Disney)"
        if "parentName" in e:
            del e["parentName"]

# Build map
name_to_entry = {e["name"]: e for e in legends_tops}

new_tops = []
for name in DESIRED_ORDER:
    if name in name_to_entry:
        e = name_to_entry[name]
        # ensure no parentName for these top-level Legends tabs
        if "parentName" in e:
            del e["parentName"]
        new_tops.append(e)
    elif name == "Animations (Not Disney)" and "Not Disney Animations" in name_to_entry:
        e = name_to_entry["Not Disney Animations"]
        e["name"] = "Animations (Not Disney)"
        if "parentName" in e:
            del e["parentName"]
        new_tops.append(e)

# Rebuild: top-level desired first, then all others preserving their order
# Insert the top-level block at the position of the first original top-level
# to keep the file readable.
first_legends_top_idx = next((i for i, e in enumerate(entries) if is_legends_top(e)), None)
if first_legends_top_idx is None:
    # no legends top-level, prepend
    new_entries = new_tops + others
else:
    new_entries = others[:first_legends_top_idx] + new_tops + others[first_legends_top_idx:]

data["entries"] = new_entries
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("Cleaned runtime_hierarchy.json top-level Legends")
