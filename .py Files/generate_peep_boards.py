import json
import os
import re
import sys

BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ASSET_ROOT = os.path.join(BASE, 'assets', 'Subject Vocab', 'PEEP')
OUT_ROOT = os.path.join(BASE, 'lib', 'data', 'boards', 'Subject Vocab', 'PEEP')
AREA = 'Subject Vocab'

# Folder names whose subdirectories should merge into a single board
# (sub-folder images are collected recursively; no sub-boards are created).
FLATTEN = {'Flags'}


def board_id(name):
    # Matches app's _hierarchyBoardId: lowercase, runs of non-alnum -> '_',
    # trim trailing underscores. (board_service.dart:66)
    return 'prebuilt_' + re.sub(r'[^a-z0-9]+', '_', name.lower()).rstrip('_')


def tile_slug(rel):
    out = []
    prev = ''
    for ch in rel:
        if ch.isupper() and prev and (prev.isupper() or prev.islower()):
            out.append('_')
        out.append(ch)
        prev = ch
    s = ''.join(out).lower()
    s = re.sub(r'[^a-z0-9]+', '_', s)
    s = re.sub(r'_+', '_', s).strip('_')
    return s


def rel_path(path, root):
    return os.path.relpath(path, root).replace('\\', '/')


def load_existing(relpath):
    p = os.path.join(OUT_ROOT, relpath)
    if not os.path.isfile(p):
        return {}
    try:
        with open(p, encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}


def preserve(existing, key, default):
    v = existing.get(key, default)
    return v


def build_boards():
    tree = {}  # relpath ('' = root) -> board dict

    for dirpath, dirnames, filenames in os.walk(ASSET_ROOT):
        dirnames.sort()
        rel = rel_path(dirpath, ASSET_ROOT)
        rel = '' if rel == '.' else rel

        segments = rel.split('/') if rel else []
        # Skip directories that are children of a flattened board folder.
        if segments and any(seg in FLATTEN for seg in segments[:-1]):
            continue

        name = os.path.basename(dirpath) if rel else 'PEEP'
        bid = board_id(name)
        is_flattened = bool(segments) and segments[-1] in FLATTEN

        if is_flattened:
            pngs = sorted(
                os.path.relpath(os.path.join(dp, f), dirpath).replace('\\', '/')
                for dp, _, fns in os.walk(dirpath)
                for f in fns if f.lower().endswith('.png'))
            subdirs = []
        else:
            pngs = sorted(f for f in filenames if f.lower().endswith('.png'))
            subdirs = sorted(dirnames)

        depth = 0 if rel == '' else rel.count('/') + 1
        parent_id = ''
        if rel:
            parent_rel = os.path.dirname(rel) if '/' in rel else ''
            parent_name = 'PEEP' if parent_rel == '' else os.path.basename(parent_rel)
            parent_id = board_id(parent_name)

        json_rel = os.path.join(rel, bid + '.json') if rel else bid + '.json'
        existing = load_existing(json_rel)

        # Tier flags: root=1, depth1=2, depth2=3, ...
        tier = 1 + depth
        is_sub = depth > 0
        is_tert = tier >= 3
        is_quart = tier >= 4
        is_quin = tier >= 5

        vocab_tiles = []
        for relpng in pngs:
            asset_rel = os.path.join(rel, relpng).replace('\\', '/') if rel else relpng
            stem = os.path.splitext(os.path.basename(relpng))[0]
            full_rel = 'PEEP/' + asset_rel if rel else 'PEEP/' + relpng
            slug = tile_slug(full_rel)
            vocab_tiles.append({
                'id': 'prebuilt_' + slug,
                'type': 'vocabulary',
                'label': stem,
                'category': 'Assets',
                'imageAsset': 'assets/Subject Vocab/' + full_rel,
                'emoji': '',
                'isBoardLink': False,
                'linkedBoardId': '',
                'linkedBoardName': None,
                'isFullScreenImage': False,
                'bgColor': 'transparent',
                'textColor': '#000000',
                'tileSize': 1,
                'colSpan': 1,
                'rowSpan': 1,
                'customVoice': '',
            })

        link_tiles = []
        for d in subdirs:
            child_rel = os.path.join(rel, d).replace('\\', '/') if rel else d
            child_id = board_id(d)
            child_asset_dir = os.path.join(dirpath, d)
            first_png = None
            cpngs = sorted(
                f for f in os.listdir(child_asset_dir)
                if f.lower().endswith('.png'))
            if cpngs:
                first_png = 'assets/Subject Vocab/PEEP/' + child_rel + '/' + cpngs[0]
            else:
                # maybe first png deeper
                for sub, _, cfiles in os.walk(child_asset_dir):
                    cfiles.sort()
                    found = [f for f in cfiles if f.lower().endswith('.png')]
                    if found:
                        sub_rel = rel_path(sub, ASSET_ROOT).replace('\\', '/')
                        first_png = 'assets/Subject Vocab/PEEP/' + sub_rel + '/' + found[0]
                        break
            if first_png is None:
                first_png = ''
            parent_slug = bid[len('prebuilt_'):]
            child_slug = child_id[len('prebuilt_'):]
            link_tiles.append({
                'id': 'prebuilt_' + parent_slug + '_' + child_slug,
                'type': 'board_link',
                'label': d,
                'category': 'Assets',
                'imageAsset': first_png,
                'emoji': '',
                'isBoardLink': True,
                'linkedBoardId': child_id,
                'linkedBoardName': child_id,
                'isFullScreenImage': False,
                'bgColor': '#000000',
                'textColor': '#FFFFFF',
                'tileSize': 1,
                'colSpan': 1,
                'rowSpan': 1,
                'customVoice': '',
            })

        tiles = link_tiles + vocab_tiles

        board = {
            'id': bid,
            'name': name,
            'area': AREA,
            'tier': preserve(existing, 'tier', tier),
            'parentBoardId': preserve(existing, 'parentBoardId', parent_id),
            'isSubBoard': preserve(existing, 'isSubBoard', is_sub),
            'isTertiaryBoard': preserve(existing, 'isTertiaryBoard', is_tert),
            'isQuaternaryBoard': preserve(existing, 'isQuaternaryBoard', is_quart),
            'isQuinaryBoard': preserve(existing, 'isQuinaryBoard', is_quin),
            'sortOrder': preserve(existing, 'sortOrder', 0),
            'columns': preserve(existing, 'columns', 6),
            'adjustableLayout': preserve(existing, 'adjustableLayout', False),
            'backgroundColor': preserve(existing, 'backgroundColor', 'transparent'),
            'boxScale': preserve(existing, 'boxScale', 1),
            'tileWidth': preserve(existing, 'tileWidth', 100),
            'tileHeight': preserve(existing, 'tileHeight', 100),
            'version': preserve(existing, 'version', 0),
            'layout': preserve(existing, 'layout', {'rows': 8, 'blankTilesAdded': 0}),
            'tiles': tiles,
        }
        tree[rel] = board

    return tree


def main():
    tree = build_boards()
    for rel in sorted(tree, key=lambda r: (r.count('/'), r)):
        b = tree[rel]
        json_rel = os.path.join(rel, b['id'] + '.json') if rel else b['id'] + '.json'
        out_path = os.path.join(OUT_ROOT, json_rel)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(b, f, ensure_ascii=False, indent=2)
        links = sum(1 for t in b['tiles'] if t.get('type') == 'board_link')
        vocab = sum(1 for t in b['tiles'] if t.get('type') == 'vocabulary')
        print('{:3d} links {:3d} vocab  {:45s} -> {}'.format(
            links, vocab, b['name'], json_rel))

    # ---- verification pass ----
    print('\n=== VERIFICATION ===')
    missing = []
    total_vocab = 0
    total_pngs = 0
    for dirpath, _, filenames in os.walk(ASSET_ROOT):
        total_pngs += sum(1 for f in filenames if f.lower().endswith('.png'))
    for dirpath, _, filenames in os.walk(OUT_ROOT):
        for fn in filenames:
            if not fn.endswith('.json'):
                continue
            p = os.path.join(dirpath, fn)
            with open(p, encoding='utf-8') as f:
                b = json.load(f)
            for t in b.get('tiles', []):
                img = t.get('imageAsset') or ''
                if img and not img.startswith('blob:'):
                    total_vocab += 1 if not t.get('isBoardLink') else 0
                    ap = os.path.join(BASE, img.replace('/', os.sep))
                    if not os.path.isfile(ap):
                        missing.append((b['id'], t['id'], img))
    print('asset PNGs total:      ', total_pngs)
    print('vocab tiles in JSONs:  ', total_vocab)
    print('missing image paths:   ', len(missing))
    for m in missing[:20]:
        print('  ', m)
    if missing:
        sys.exit(1)


if __name__ == '__main__':
    main()