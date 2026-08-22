import json
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
path = PROJECT / "lib" / "data" / "runtime_hierarchy.json"

DESIRED_GODS_ORDER = [
    "Family Trees",
    "Egyptian Gods",
    "Norse Gods",
    "Greek Gods",
    "Roman Gods",
    "Heroes and Monsters (Greek and Roman)",
    "Other Mythology",
    "Christian Deities and People",
    "Jewish Deities and People",
    "Hindu Deities and People",
    "Islam Deities and People",
    "Buddhism Deities and People",
    "Sikh Deities and People",
    "Pagan Deities and People",
]

TO_REMOVE = [
    "Christian Angels and Demons",
    "Christian Angels Demons",
    "Angels",
    "Demons",
    "Roman Unique Gods",
]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

entries = data["entries"]

# Filter out unwanted entries
new_entries = []
for e in entries:
    name = e.get("name", "")
    area = e.get("area", "")
    parent = e.get("parentName")
    # Remove the specific unwanted names in the Legends area
    if area == "Legends" and name in TO_REMOVE:
        continue
    # Remove any child of Gods, Titans, Heroes and Monsters that is not in desired list
    if area == "Legends" and parent == "Gods, Titans, Heroes and Monsters" and name not in DESIRED_GODS_ORDER:
        continue
    new_entries.append(e)

data["entries"] = new_entries

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Cleaned Gods, Titans, Heroes and Monsters runtime hierarchy")
