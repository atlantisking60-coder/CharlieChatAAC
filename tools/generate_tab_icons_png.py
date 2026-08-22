import urllib.request
import urllib.error
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT / "assets" / "Default Tab Icons"
OUT_DIR.mkdir(parents=True, exist_ok=True)

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

URL_TEMPLATE = "https://material-icons.github.io/material-icons-png/png/black/{name}/baseline-4x.png"

missing = []
downloaded = []
for name in ICON_NAMES:
    url = URL_TEMPLATE.format(name=name)
    out = OUT_DIR / f"{name} - tab icon.png"
    try:
        with urllib.request.urlopen(url, timeout=20) as r:
            data = r.read()
        if not data.startswith(b"\x89PNG"):
            missing.append(name)
            continue
        out.write_bytes(data)
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

print(f"Downloaded {len(downloaded)} PNG(s) to {OUT_DIR}")
if missing:
    print(f"Missing icons: {', '.join(missing)}")
