import base64
import json
import os
import re
import shutil
import sys
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# Project root is one level up from this script's directory
ROOT = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT / "lib" / "data" / "boards"
HIERARCHY_FILE = ROOT / "lib" / "data" / "runtime_hierarchy.json"
BUILD_WEB = ROOT / "build" / "web"
VERSIONS_DIR = ROOT / "Backups" / "Boards"
CUSTOM_SYMBOLS_DIR = ROOT / "assets" / "symbols" / "Custom"
BUILD_CUSTOM_SYMBOLS_DIR = BUILD_WEB / "assets" / "symbols" / "Custom"

CORS_ORIGINS = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:8787",
    "http://127.0.0.1:8787",
]


def _load_board_hierarchy():
    """Build a name -> (area, parent) map from the compiled Dart list plus the
    live runtime_hierarchy.json so new or moved boards get canonical paths."""
    hierarchy_path = ROOT / "lib" / "data" / "board_hierarchy.dart"
    pattern = re.compile(r"BoardHierarchyEntry\('([^']+)', '([^']+)'(?:, '([^']+)')?\)")
    result = {}
    try:
        if hierarchy_path.exists():
            for line in hierarchy_path.read_text(encoding="utf-8").splitlines():
                m = pattern.search(line)
                if m:
                    name, area, parent = m.group(1), m.group(2), m.group(3)
                    result[name] = (area, parent)
    except Exception as e:
        print(f"Could not load board hierarchy: {e}")
    # Merge live runtime hierarchy so the server can save newly-created boards.
    try:
        if HIERARCHY_FILE.exists():
            data = json.loads(HIERARCHY_FILE.read_text(encoding="utf-8"))
            for entry in data.get("entries", []):
                name = entry.get("name")
                area = entry.get("area")
                parent = entry.get("parentName")
                if name and area:
                    result[name] = (area, parent)
    except Exception as e:
        print(f"Could not load runtime hierarchy for canonical paths: {e}")
    return result


BOARD_HIERARCHY = _load_board_hierarchy()


def _canonical_board_path(area, name):
    """Build the canonical on-disk folder for a board from its hierarchy."""
    parts = []
    current = name
    for _ in range(20):
        if current is None or current not in BOARD_HIERARCHY:
            break
        entry_area, parent = BOARD_HIERARCHY[current]
        if entry_area != area:
            break
        parts.append(_folder_name(current))
        current = parent
    if not parts:
        return None
    parts.reverse()
    path = BOARDS_DIR / area
    for part in parts:
        path = path / part
    return path


def set_cors(handler, origin="*"):
    handler.send_header("Access-Control-Allow-Origin", origin)
    handler.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    handler.send_header("Access-Control-Allow-Headers", "Content-Type")


def _folder_name(name):
    return name.strip()


def _version_dir_for(target):
    """Directory where timestamped backups for a given board are kept."""
    rel = target.relative_to(BOARDS_DIR)
    return VERSIONS_DIR / rel.parent


def _prune_versions(version_dir, keep=3):
    """Keep only the [keep] most recent backups in a directory."""
    if not version_dir.exists():
        return
    files = sorted(version_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    for old in files[keep:]:
        try:
            old.unlink()
        except Exception:
            pass


def _backup_board(target):
    """Copy the existing board to a timestamped backup, keeping the latest 3."""
    if not target.exists():
        return
    try:
        vdir = _version_dir_for(target)
        vdir.mkdir(parents=True, exist_ok=True)
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup = vdir / f"{target.stem}_{timestamp}.json"
        shutil.copy2(str(target), str(backup))
        _prune_versions(vdir)
    except Exception as e:
        print(f"Could not backup {target}: {e}")


def _board_path(board):
    """Compute the on-disk location for a board JSON."""
    area = (board.get("area") or "Common").strip()
    name = (board.get("name") or board.get("id", "untitled")).strip()
    board_id = (board.get("id") or "untitled").strip()
    # If the board already exists, overwrite it in place (prevents duplicate flat copies).
    existing = _find_board_file(area, board_id)
    if existing is not None:
        return existing
    # Use the compiled board hierarchy to put prebuilt/nested boards in the right place.
    canonical = _canonical_board_path(area, name)
    if canonical is not None:
        canonical.mkdir(parents=True, exist_ok=True)
        return canonical / f"{board_id}.json"
    # Unknown board: stash in a temp holding area so it doesn't clutter Common.
    temp_dir = BOARDS_DIR / "_temp" / (area or "Common")
    temp_dir.mkdir(parents=True, exist_ok=True)
    return temp_dir / f"{board_id}.json"


def _find_board_file(area, board_id):
    search_roots = [BOARDS_DIR / (area or "")]
    temp_root = BOARDS_DIR / "_temp" / (area or "Common")
    if temp_root.exists():
        search_roots.append(temp_root)
    matches = []
    for area_dir in search_roots:
        if not area_dir.exists():
            continue
        for root, _, files in os.walk(area_dir):
            for f in files:
                if f.lower() == f"{board_id}.json".lower():
                    matches.append(Path(root) / f)
    if not matches:
        return None
    # Prefer files inside a '(Montessori)' suffix folder, then the deepest path.
    matches.sort(
        key=lambda p: (
            any("(Montessori)" in part for part in p.parts),
            len(p.parts),
        ),
        reverse=True,
    )
    return matches[0]


class DevBoardHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # Quieter than default; print concise lines
        print(fmt % args)

    def _origin(self):
        return self.headers.get("Origin", "*")

    def _send_json(self, status, data):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        set_cors(self, self._origin())
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def _send_text(self, status, text, content_type="text/plain"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        set_cors(self, self._origin())
        self.end_headers()
        self.wfile.write(text.encode("utf-8"))

    def do_OPTIONS(self):
        self.send_response(204)
        set_cors(self, self._origin())
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # API: load a board JSON
        if path == "/loadBoard":
            board_id = query.get("id", [""])[0]
            area = query.get("area", [""])[0]
            if not board_id:
                return self._send_json(400, {"error": "Missing id"})
            f = _find_board_file(area, board_id)
            if f is None or not f.exists():
                return self._send_json(404, {"error": "Board not found"})
            try:
                with open(f, "r", encoding="utf-8") as fp:
                    return self._send_text(200, fp.read(), "application/json")
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # API: runtime hierarchy
        if path == "/runtimeHierarchy":
            if not HIERARCHY_FILE.exists():
                return self._send_json(404, {"error": "No runtime hierarchy"})
            try:
                with open(HIERARCHY_FILE, "r", encoding="utf-8") as fp:
                    return self._send_text(200, fp.read(), "application/json")
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # API: list all boards
        if path == "/listBoards":
            try:
                candidates = []
                keep_fields = {
                    "id", "name", "area", "parentBoardId", "linkedBoardId",
                    "rows", "columns", "adjustableLayout", "boxScale",
                    "tileHeight", "tileWidth", "backgroundColor",
                    "isSubBoard", "isTertiaryBoard", "isQuaternaryBoard", "isQuinaryBoard",
                    "sortOrder", "tier", "iconAssetPath", "tileIconAssetPath", "version",
                }
                if BOARDS_DIR.exists():
                    for root_dir, _, files in os.walk(BOARDS_DIR):
                        for f in files:
                            if f.lower().endswith(".json"):
                                fp = Path(root_dir) / f
                                try:
                                    b = json.loads(fp.read_text(encoding="utf-8"))
                                    # Keep only lightweight metadata; tiles are loaded on demand.
                                    stripped = {k: v for k, v in b.items() if k in keep_fields}
                                    stripped["tiles"] = []
                                    candidates.append((len(fp.parts), stripped))
                                except Exception:
                                    pass
                # Deduplicate by id, keeping the deepest (canonical) path for each board.
                candidates.sort(key=lambda x: x[0], reverse=True)
                seen = set()
                boards = []
                for _, b in candidates:
                    bid = (b.get("id") or "").lower()
                    if bid and bid not in seen:
                        seen.add(bid)
                        boards.append(b)
                return self._send_json(200, {"boards": boards})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # API: list versioned backups for a board
        if path == "/listVersions":
            board_id = query.get("id", [""])[0]
            area = query.get("area", [""])[0]
            try:
                f = _find_board_file(area, board_id)
                if f is None or not f.exists():
                    return self._send_json(404, {"error": "Board not found"})
                vdir = _version_dir_for(f)
                versions = []
                if vdir.exists():
                    for v in sorted(vdir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True):
                        versions.append({
                            "filename": v.name,
                            "saved": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(v.stat().st_mtime)),
                        })
                return self._send_json(200, {"versions": versions})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # API: restore a previous version of a board
        if path == "/restoreVersion":
            board_id = query.get("id", [""])[0]
            area = query.get("area", [""])[0]
            filename = query.get("filename", [""])[0]
            if not filename:
                return self._send_json(400, {"error": "Missing filename"})
            try:
                f = _find_board_file(area, board_id)
                if f is None or not f.exists():
                    return self._send_json(404, {"error": "Board not found"})
                vdir = _version_dir_for(f)
                backup = vdir / filename
                if not backup.exists():
                    return self._send_json(404, {"error": "Backup not found"})
                _backup_board(f)
                shutil.copy2(str(backup), str(f))
                return self._send_json(200, {"ok": True, "path": str(f)})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        # Fallback to static build files.
        # Flutter's web build writes asset paths with percent-encoding, so only
        # one URL decode is needed; repeated decoding would turn %20 into spaces.
        target = (path if path != "/" else "/index.html").lstrip("/")
        file_path = BUILD_WEB / target
        if not (file_path.exists() and file_path.is_file()) and "%" in target:
            target = urllib.parse.unquote(target)
            file_path = BUILD_WEB / target
        if file_path.exists() and file_path.is_file():
            content_type = "text/html"
            ext = file_path.suffix.lower()
            if ext in (".js",):
                content_type = "text/javascript"
            elif ext == ".css":
                content_type = "text/css"
            elif ext == ".json":
                content_type = "application/json"
            elif ext in (".png",):
                content_type = "image/png"
            elif ext in (".svg",):
                content_type = "image/svg+xml"
            elif ext in (".jpg", ".jpeg"):
                content_type = "image/jpeg"
            elif ext == ".gif":
                content_type = "image/gif"
            elif ext == ".webp":
                content_type = "image/webp"
            elif ext == ".wasm":
                content_type = "application/wasm"
            elif ext in (".ttf",):
                content_type = "font/ttf"
            elif ext in (".otf",):
                content_type = "font/otf"
            elif ext in (".woff",):
                content_type = "font/woff"
            elif ext in (".woff2",):
                content_type = "font/woff2"
            try:
                data = file_path.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", content_type)
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
                set_cors(self, self._origin())
                self.end_headers()
                self.wfile.write(data)
                return
            except Exception as e:
                return self._send_json(500, {"error": str(e)})
        return self._send_json(404, {"error": "Not found"})

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else b"{}"

        try:
            payload = json.loads(body.decode("utf-8"))
        except json.JSONDecodeError:
            return self._send_json(400, {"error": "Invalid JSON"})

        if path == "/saveBoard":
            board = payload
            target = _board_path(board)
            try:
                _backup_board(target)
                target.parent.mkdir(parents=True, exist_ok=True)
                with open(target, "w", encoding="utf-8") as fp:
                    json.dump(board, fp, indent=2, ensure_ascii=False)
                # Also keep a runtime hierarchy entry for this board if it isn't prebuilt
                _ensure_in_runtime_hierarchy(board)
                return self._send_json(200, {"ok": True, "path": str(target)})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        if path == "/saveHierarchy":
            entries = payload.get("entries", [])
            try:
                HIERARCHY_FILE.parent.mkdir(parents=True, exist_ok=True)
                with open(HIERARCHY_FILE, "w", encoding="utf-8") as fp:
                    json.dump({"entries": entries}, fp, indent=2, ensure_ascii=False)
                return self._send_json(200, {"ok": True, "path": str(HIERARCHY_FILE)})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        if path == "/deleteBoard":
            board_id = payload.get("id", "")
            area = payload.get("area", "")
            if not board_id:
                return self._send_json(400, {"error": "Missing id"})
            f = _find_board_file(area, board_id)
            if f is None or not f.exists():
                return self._send_json(404, {"error": "Board not found"})
            try:
                trash = f.parent / "_deleted"
                trash.mkdir(exist_ok=True)
                shutil.move(str(f), str(trash / f.name))
                return self._send_json(200, {"ok": True})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        if path == "/saveImage":
            try:
                filename = payload.get("filename", "")
                b64_data = payload.get("data", "")
                if not filename or not b64_data:
                    return self._send_json(400, {"error": "Missing filename or data"})
                raw = b64_data.split(",")[-1] if "," in b64_data else b64_data
                image_bytes = base64.b64decode(raw)
                CUSTOM_SYMBOLS_DIR.mkdir(parents=True, exist_ok=True)
                target = CUSTOM_SYMBOLS_DIR / filename
                target.write_bytes(image_bytes)
                if BUILD_WEB.exists():
                    BUILD_CUSTOM_SYMBOLS_DIR.mkdir(parents=True, exist_ok=True)
                    (BUILD_CUSTOM_SYMBOLS_DIR / filename).write_bytes(image_bytes)
                return self._send_json(200, {"ok": True, "path": f"assets/symbols/Custom/{filename}"})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        if path == "/deleteImage":
            try:
                filename = payload.get("filename", "")
                if not filename:
                    return self._send_json(400, {"error": "Missing filename"})
                target = CUSTOM_SYMBOLS_DIR / filename
                if target.exists():
                    target.unlink()
                build_target = BUILD_CUSTOM_SYMBOLS_DIR / filename
                if build_target.exists():
                    build_target.unlink()
                return self._send_json(200, {"ok": True})
            except Exception as e:
                return self._send_json(500, {"error": str(e)})

        return self._send_json(404, {"error": "Unknown endpoint"})


def _ensure_in_runtime_hierarchy(board):
    name = (board.get("name") or "").strip()
    area = (board.get("area") or "").strip()
    if not name or not area:
        return
    existing = {"entries": []}
    if HIERARCHY_FILE.exists():
        try:
            with open(HIERARCHY_FILE, "r", encoding="utf-8") as fp:
                existing = json.load(fp)
        except Exception:
            pass
    entries = existing.get("entries", [])
    names = {e.get("name", "").lower() for e in entries}
    if name.lower() in names:
        return
    entries.append({"name": name, "area": area})
    try:
        HIERARCHY_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(HIERARCHY_FILE, "w", encoding="utf-8") as fp:
            json.dump({"entries": entries}, fp, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"Could not update runtime hierarchy: {e}")


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8787
    if not BUILD_WEB.exists():
        print(f"Warning: {BUILD_WEB} not found. Run `flutter build web` first to serve the app.")
    ThreadingHTTPServer.allow_reuse_address = True
    server = ThreadingHTTPServer(("", port), DevBoardHandler)
    print(f"Charlie Chat dev server running on http://localhost:{port}")
    print(f"Board storage: {BOARDS_DIR}")
    print(f"Runtime hierarchy: {HIERARCHY_FILE}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
