import subprocess
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
SVG_DIR = PROJECT / "assets" / "Default Tab Icons"
RESVG = PROJECT / "node_modules" / ".bin" / "resvg-js-cli.cmd"

MISSING = [
    "grid_view",
    "abc",
    "checkroom",
    "paid",
    "church",
    "park",
    "sign_language",
    "auto_stories",
]

for name in MISSING:
    svg = SVG_DIR / f"{name} - tab icon.svg"
    png = SVG_DIR / f"{name} - tab icon.png"
    if not svg.exists():
        print(f"SVG not found: {svg}")
        continue
    # Remove the old 24x24 if we generated it without zoom
    if png.exists():
        png.unlink()
    subprocess.run([str(RESVG), "--fit-zoom", "4", str(svg), str(png)], check=True)
    print(f"Converted {svg.name} -> {png.name}")
