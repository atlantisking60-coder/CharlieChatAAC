import base64
import hashlib
import json
import os
import re
import shutil
import sys
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# Project root is one level up from this script's directory
ROOT = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT / "lib" / "data" / "boards"
HIERARCHY_FILE = ROOT / "lib" / "data" / "runtime_hierarchy.json"
TAB_ORDERS_FILE = ROOT / "lib" / "data" / "tab_orders.json"
BUILD_WEB = ROOT / "build" / "web"
VERSIONS_DIR = ROOT / "Backups" / "Boards"
ASSETS_DIR = ROOT / "assets"
CUSTOM_SYMBOLS_DIR = ASSETS_DIR / "symbols" / "Custom"
BUILD_CUSTOM_SYMBOLS_DIR = BUILD_WEB / "assets" / "symbols" / "Custom"

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}

# content hash -> asset-relative path, built lazily on first upload.
_ASSET_HASH_INDEX = None

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



def _build_asset_hash_index():
    """Map every bundled image's content hash to its asset-relative path."""
    index = {}
    if not ASSETS_DIR.exists():
        return index
    for root, _, files in os.walk(ASSETS_DIR):
        root_path = Path(root)
        if "_replaced" in root_path.parts:
            continue
        for name in files:
            if Path(name).suffix.lower() not in IMAGE_EXTS:
                continue
            fp = root_path / name
            try:
                digest = hashlib.sha256(fp.read_bytes()).hexdigest()
            except Exception:
                continue
            rel = "assets/" + fp.relative_to(ASSETS_DIR).as_posix()
            # Prefer the shortest (most canonical) path and never a Custom copy.
            current = index.get(digest)
            if current is None or (
                current.startswith("assets/symbols/Custom/")
                and not rel.startswith("assets/symbols/Custom/")
            ):
                index[digest] = rel
    return index


def _find_identical_asset(image_bytes):
    """Return the asset path of a byte-identical existing image, or None."""
    global _ASSET_HASH_INDEX
    if _ASSET_HASH_INDEX is None:
        _ASSET_HASH_INDEX = _build_asset_hash_index()
        print(f"Indexed {len(_ASSET_HASH_INDEX)} unique asset images for reuse matching.")
    return _ASSET_HASH_INDEX.get(hashlib.sha256(image_bytes).hexdigest())


def _register_asset_hash(image_bytes, rel_path):
    global _ASSET_HASH_INDEX
    if _ASSET_HASH_INDEX is None:
        return
    _ASSET_HASH_INDEX.setdefault(hashlib.sha256(image_bytes).hexdigest(), rel_path)


def _asset_dir_for_board(area, name, board_id):
    """Asset folder mirroring the board's own folder under lib/data/boards.

    Falls back to assets/symbols/Custom when the board cannot be located.
    """
    board_file = None
    if board_id:
        board_file = _find_board_file(area or "", board_id)
    if board_file is None and area and name:
        canonical = _canonical_board_path(area, name)
        if canonical is not None:
            board_file = canonical / "placeholder.json"
    if board_file is None:
        return CUSTOM_SYMBOLS_DIR
    try:
        rel = board_file.parent.relative_to(BOARDS_DIR)
    except ValueError:
        return CUSTOM_SYMBOLS_DIR
    if "_temp" in rel.parts or "_deleted" in rel.parts:
        return CUSTOM_SYMBOLS_DIR
    return _resolve_existing_asset_dir(rel)


def _normalise_folder(name):
    """Loose comparison key so '1. January' matches the existing '1 January'."""
    return re.sub(r"[^a-z0-9]+", "", name.lower())


def _resolve_existing_asset_dir(rel):
    """Walk the mirrored path, reusing existing asset folders where the names
    only differ by punctuation, so we never create near-duplicate folders."""
    current = ASSETS_DIR
    for part in rel.parts:
        exact = current / part
        if exact.is_dir():
            current = exact
            continue
        match = None
        if current.is_dir():
            key = _normalise_folder(part)
            for child in current.iterdir():
                if child.is_dir() and _normalise_folder(child.name) == key:
                    match = child
                    break
        current = match if match is not None else exact
    return current


def _canonical_board_path(area, name):
    """Build the canonical on-disk folder for a board from its hierarchy."""
    parts = []
    seen = set()
    current = name
    for _ in range(20):
        if current is None or current not in BOARD_HIERARCHY:
            break
        if current in seen:
            # Cycle in the hierarchy data (shouldn't happen, but has before
            # from stale in-memory data) — stop instead of nesting forever.
            print(f"WARNING: cycle detected in BOARD_HIERARCHY at '{current}', "
                  f"stopping canonical path resolution for '{name}'")
            break
        seen.add(current)
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


def _scan_board_files():
    """Walk lib/data/boards once and index every board JSON by its lowercased id.

    Walking per request made startup take minutes once the app began asking for
    several hundred boards, so the whole tree is indexed in a single pass and
    invalidated only when a board file is added, moved or deleted.
    """
    index = {}
    if not BOARDS_DIR.exists():
        return index
    for root, _, files in os.walk(BOARDS_DIR):
        root_path = Path(root)
        for f in files:
            if not f.lower().endswith(".json"):
                continue
            index.setdefault(f[:-5].lower(), []).append(root_path / f)
    # Prefer '(Montessori)' folders, then the deepest path, matching the old order.
    for matches in index.values():
        matches.sort(
            key=lambda p: (
                any("(Montessori)" in part for part in p.parts),
                len(p.parts),
            ),
            reverse=True,
        )
    return index


_BOARD_FILE_INDEX = None
_BOARD_INDEX_LOCK = threading.Lock()
_BOARD_LIST_CACHE = None

LIST_KEEP_FIELDS = {
    "id", "name", "area", "parentBoardId", "linkedBoardId",
    "rows", "columns", "adjustableLayout", "boxScale",
    "tileHeight", "tileWidth", "backgroundColor",
    "isSubBoard", "isTertiaryBoard", "isQuaternaryBoard", "isQuinaryBoard",
    "sortOrder", "tier", "iconAssetPath", "tileIconAssetPath", "version",
}


def _invalidate_board_index():
    global _BOARD_FILE_INDEX, _BOARD_LIST_CACHE
    with _BOARD_INDEX_LOCK:
        _BOARD_FILE_INDEX = None
        _BOARD_LIST_CACHE = None


def _list_boards_cached():
    """Lightweight metadata for every board, parsed once and cached.

    Re-parsing every JSON on each request made the parent-board picker take
    tens of seconds (and time out, appearing to find no boards at all).
    """
    global _BOARD_LIST_CACHE
    with _BOARD_INDEX_LOCK:
        if _BOARD_LIST_CACHE is not None:
            return _BOARD_LIST_CACHE
    index = _find_board_index()
    boards = []
    seen = set()
    for board_id, matches in index.items():
        if board_id in seen:
            continue
        try:
            b = json.loads(matches[0].read_text(encoding="utf-8"))
        except Exception:
            continue
        stripped = {k: v for k, v in b.items() if k in LIST_KEEP_FIELDS}
        stripped["tiles"] = []
        if stripped.get("id"):
            seen.add(board_id)
            boards.append(stripped)
    with _BOARD_INDEX_LOCK:
        _BOARD_LIST_CACHE = boards
    return boards


def _find_board_index():
    global _BOARD_FILE_INDEX
    with _BOARD_INDEX_LOCK:
        if _BOARD_FILE_INDEX is None:
            _BOARD_FILE_INDEX = _scan_board_files()
            print(f"Indexed {len(_BOARD_FILE_INDEX)} board files.")
        return _BOARD_FILE_INDEX


def _find_board_file(area, board_id):
    if not board_id:
        return None
    matches = _find_board_index().get(board_id.lower())
    if not matches:
        return None
    # Prefer a match inside the requested area, else fall back to the best match.
    if area:
        area_prefix = (BOARDS_DIR / area).parts
        for m in matches:
            if m.parts[: len(area_prefix)] == area_prefix:
                return m
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
                return self._send_json(200, {"boards": _list_boards_cached()})
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

        # API: load tab orders
        if path == "/tabOrders":
            try:
                if not TAB_ORDERS_FILE.exists():
                    return self._send_json(200, {"orders": {}})
                try:
                    with open(TAB_ORDERS_FILE, "r", encoding="utf-8") as fp:
                        return self._send_text(200, fp.read(), "application/json")
                except Exception as e:
                    return self._send_json(500, {"error": str(e)})
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
                is_new = not target.exists()
                _backup_board(target)
                target.parent.mkdir(parents=True, exist_ok=True)
                with open(target, "w", encoding="utf-8") as fp:
                    json.dump(board, fp, indent=2, ensure_ascii=False)
                if is_new:
                    _invalidate_board_index()
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

        if path == "/saveTabOrder":
            area = payload.get("area", "")
            names = payload.get("names", [])
            try:
                data = {"orders": {}}
                if TAB_ORDERS_FILE.exists():
                    try:
                        with open(TAB_ORDERS_FILE, "r", encoding="utf-8") as fp:
                            data = json.load(fp)
                    except Exception:
                        pass
                data.setdefault("orders", {})[area] = names
                TAB_ORDERS_FILE.parent.mkdir(parents=True, exist_ok=True)
                with open(TAB_ORDERS_FILE, "w", encoding="utf-8") as fp:
                    json.dump(data, fp, indent=2, ensure_ascii=False)
                return self._send_json(200, {"ok": True, "path": str(TAB_ORDERS_FILE)})
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
                _invalidate_board_index()
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

                # 1. Reuse an existing asset with byte-identical content.
                existing = _find_identical_asset(image_bytes)
                if existing is not None:
                    print(f"saveImage: reusing existing asset {existing}")
                    return self._send_json(200, {"ok": True, "path": existing, "reused": True})

                # 2. Otherwise store it in the asset folder mirroring the board.
                target_dir = _asset_dir_for_board(
                    payload.get("area"), payload.get("name"), payload.get("boardId")
                )
                target_dir.mkdir(parents=True, exist_ok=True)
                target = target_dir / filename
                target.write_bytes(image_bytes)
                rel = "assets/" + target.relative_to(ASSETS_DIR).as_posix()

                # Mirror into build/web so the running preview can load it now.
                if BUILD_WEB.exists():
                    build_target = BUILD_WEB / rel
                    build_target.parent.mkdir(parents=True, exist_ok=True)
                    build_target.write_bytes(image_bytes)

                _register_asset_hash(image_bytes, rel)
                print(f"saveImage: stored new asset {rel}")
                return self._send_json(200, {"ok": True, "path": rel, "reused": False})
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
