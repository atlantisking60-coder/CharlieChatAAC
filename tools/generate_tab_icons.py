import json
import urllib.request
import urllib.error
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT / "assets" / "Default Tab Icons"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Material fallback icons used in _getBoardIconData (lib/main.dart)
ICON_NAMES = [
    "grid_view",
    "pets",
    "people",
    "access_time",
    "abc",
    "restaurant",
    "directions_bus",
    "place",
    "home",
    "school",
    "favorite",
    "palette",
    "format_list_numbered",
    "sports",
    "checkroom",
    "paid",
    "wb_sunny",
    "music_note",
    "brush",
    "church",
    "computer",
    "park",
    "toys",
    "help",
    "directions_run",
    "movie",
    "sign_language",
    "auto_stories",
    "person",
    "dashboard",
    "edit",
    "reorder",
]

URL_TEMPLATE = "https://raw.githubusercontent.com/marella/material-design-icons/main/svg/filled/{name}.svg"

missing = []
downloaded = []
for name in ICON_NAMES:
    url = URL_TEMPLATE.format(name=name)
    out = OUT_DIR / f"{name}.svg"
    try:
        with urllib.request.urlopen(url, timeout=20) as r:
            data = r.read().decode("utf-8")
        if not data.strip().startswith("<svg"):
            missing.append(name)
            continue
        out.write_text(data, encoding="utf-8")
        downloaded.append(name)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            missing.append(name)
        else:
            print(f"Error downloading {name}: {e}")
            missing.append(name)
    except Exception as e:
        print(f"Error downloading {name}: {e}")
        missing.append(name)

print(f"Downloaded {len(downloaded)} SVG(s) to {OUT_DIR}")
if missing:
    print(f"Missing icons: {', '.join(missing)}")
