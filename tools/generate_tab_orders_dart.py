import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_FILE = ROOT / "lib" / "data" / "tab_orders.json"
DART_FILE = ROOT / "lib" / "data" / "tab_orders_data.dart"


def dart_string(s: str) -> str:
    escaped = s.replace("\\", "\\\\").replace("'", "\\'")
    return "'" + escaped + "'"


def generate():
    data = json.loads(JSON_FILE.read_text(encoding="utf-8"))
    orders = data.get("orders", {})

    lines = []
    lines.append("/// Compiled fallback for tab (sub-board) ordering, generated from")
    lines.append("/// lib/data/tab_orders.json. This is the production-safe source of truth:")
    lines.append("///")
    lines.append("/// tab_orders.json is only used locally by tools/dev_server.py to keep the")
    lines.append("/// live-preview browser in sync while editing. It is never bundled as a")
    lines.append("/// Flutter asset, so a deployed build (or any session that never talked to")
    lines.append("/// the dev server) has no way to read it. [defaultTabOrders] is baked into")
    lines.append("/// the Dart source instead, so tab order is respected everywhere -- exactly")
    lines.append("/// like [boardHierarchy] in board_hierarchy.dart.")
    lines.append("///")
    lines.append("/// Regenerated automatically by tools/dev_server.py whenever an admin saves")
    lines.append("/// a tab order (POST /saveTabOrder). Do not hand-edit -- edit tab order via")
    lines.append("/// the app instead and let the dev server regenerate this file.")
    lines.append("const Map<String, List<String>> defaultTabOrders = {")
    for area, names in orders.items():
        names_str = ", ".join(dart_string(n) for n in names)
        lines.append(f"  {dart_string(area)}: [{names_str}],")
    lines.append("};")
    lines.append("")

    DART_FILE.write_text("\n".join(lines), encoding="utf-8")
    return len(orders)


if __name__ == "__main__":
    count = generate()
    print(f"Wrote {count} tab order entries to {DART_FILE}")
