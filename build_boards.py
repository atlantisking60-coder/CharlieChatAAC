#!/usr/bin/env python3
"""
Build/update board JSON files for the Legends boards.
For each asset folder, create a board JSON with tiles referencing images from that folder.
Skip boards that already have >1 image tiles.
For Disney Stories, order characters by importance.
"""

import json
import os
import csv
import math

ASSETS_BASE = r"C:\Users\Craig\Downloads\Charlie Chat\assets\Legends"
BOARDS_BASE = r"C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\Legends"
CSV_PATH = r"C:\Users\Craig\Downloads\Charlie Chat\needs_work.csv"


def sanitize_id(text):
    result = text.lower().strip()
    result = result.replace(" (", "_")
    result = result.replace(")", "")
    result = result.replace(" ", "_")
    result = result.replace("-", "_")
    result = result.replace(".", "_")
    result = result.replace("'", "")
    result = result.replace(",", "")
    result = result.replace("/", "_")
    while "__" in result:
        result = result.replace("__", "_")
    if result.endswith("_"):
        result = result[:-1]
    return result


def exact_match(label, filename_no_ext):
    """Exact match (case-insensitive)."""
    return label.lower().strip() == filename_no_ext.lower().strip()


def prefix_match(label, filename_no_ext):
    """Check if label is a prefix of filename or vice versa (with word boundary)."""
    label_lower = label.lower().strip()
    filename_lower = filename_no_ext.lower().strip()
    if not label_lower or not filename_lower:
        return False
    # label is a prefix of filename (e.g., "evil queen" matches "evil queen (queen grimhilde)")
    if filename_lower.startswith(label_lower + " ") or filename_lower.startswith(label_lower + " ("):
        return True
    # filename is a prefix of label (e.g., "evil queen" as label for "evil queen.png" - but this is exact match)
    if label_lower.startswith(filename_lower + " "):
        return True
    # Check word-by-word partial match for specific patterns
    # e.g., "prince eric" matching "prince eric.png" (exact, should be handled)
    # e.g., "the huntsman" matching "the huntsman.png" (exact, should be handled)
    return False


def get_image_files(folder_path):
    """Get all image files in a folder (not subdirectories)."""
    images = []
    for f in os.listdir(folder_path):
        full_path = os.path.join(folder_path, f)
        if os.path.isfile(full_path):
            ext = os.path.splitext(f)[1].lower()
            if ext in (".png", ".jpg", ".jpeg", ".gif"):
                images.append(f)
    return images


def get_parent_board_id(asset_dir):
    parts = asset_dir.split("\\")
    if len(parts) >= 3:
        parent = parts[0] + "\\" + parts[1]
        if parent == "Characters\\Disney Stories":
            return "prebuilt_disney_stories"
        elif parent.startswith("Characters\\DC"):
            return "prebuilt_dc"
        elif parent.startswith("Characters\\Marvel"):
            return "prebuilt_marvel"
        elif parts[0] == "Characters" and parts[1] == "DnD":
            return "prebuilt_d_d"
        elif parts[0] == "Characters" and parts[1] == "X-Men":
            return "prebuilt_x_men"
    elif len(parts) == 2:
        return "prebuilt_characters"
    return None


def is_disney_story(asset_dir):
    return asset_dir.startswith("Characters\\Disney Stories\\")


# Disney Stories importance ordering for movies with 0 prebuilt tiles
DISNEY_IMPORTANCE_ORDER = {
    "1970 The Aristocats": [
        "duchess", "thomas o'malley", "marie", "toulouse", "berlioz",
        "edgar balthazar", "madame adelaide bonfamille", "lafayette",
        "napoleon", "roquefort", "frou-frou", "scat cat"
    ],
    "2001 Monsters, Inc": [
        "sully (james p. sullivan)", "mike wazowski", "boo", "mr. waternoose",
        "randall boggs", "roz", "celia mae", "george sanderson", "don carlton",
        "dean hardscrabble", "squishy", "fungus", "archie the scare pig", "art",
        "cda agent", "johnny worthington iii", "needleman", "professor knight",
        "terri and terry", "closet door", "the yeti"
    ],
}


def create_tile(board_id, label, image_filename, asset_rel_path):
    image_asset = f"assets/Legends/{asset_rel_path}/{image_filename}"
    tile_id = f"{board_id}_{sanitize_id(label)}"
    tile_id = tile_id[:80]
    return {
        "id": tile_id,
        "type": "vocabulary",
        "label": label,
        "category": "Custom",
        "imageAsset": image_asset,
        "emoji": "",
        "linkedBoardName": None,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": ""
    }


def create_blank_tile(board_id, index):
    return {
        "id": f"{board_id}_tile_{index}",
        "type": "blank",
        "label": "",
        "category": "Custom",
        "imageAsset": None,
        "emoji": "",
        "linkedBoardName": None,
        "isFullScreenImage": False,
        "bgColor": "transparent",
        "textColor": "#000000",
        "tileSize": 1,
        "colSpan": 1,
        "rowSpan": 1,
        "customVoice": ""
    }


def get_or_create_template(asset_dir, board_json_name, board_json_path):
    """Get the template JSON (preference: asset prebuilt > board JSON)."""
    asset_path = os.path.join(ASSETS_BASE, asset_dir)
    prebuilt_filename = None

    # Try asset prebuilt JSON first (preferred - always clean)
    if os.path.exists(asset_path):
        for f in os.listdir(asset_path):
            if f.startswith("prebuilt_") and f.endswith(".json"):
                prebuilt_filename = f
                with open(os.path.join(asset_path, f), "r", encoding="utf-8") as fh:
                    try:
                        return json.load(fh), "asset_prebuilt", prebuilt_filename
                    except:
                        pass

    # Try board JSON (no asset prebuilt available)
    if board_json_name:
        board_file = os.path.join(board_json_path, board_json_name)
        if os.path.exists(board_file):
            with open(board_file, "r", encoding="utf-8") as f:
                try:
                    template = json.load(f)
                    # Clear imageAsset from all tiles to start fresh
                    if "tiles" in template:
                        for tile in template["tiles"]:
                            tile["imageAsset"] = None
                    return template, "board_cleared", board_json_name
                except:
                    pass

    return None, None, None


def match_tiles_to_images(tiles, images, asset_rel_path, board_id):
    """Match template tiles to image files using exact and prefix matching.
    Returns (updated_tiles, matched_images_set).
    """
    matched_images = set()
    updated_tiles = []

    # Phase 1: Exact matches
    for tile in tiles:
        tile_copy = json.loads(json.dumps(tile))
        label = tile_copy.get("label", "").strip()
        if label:
            for img in images:
                if img in matched_images:
                    continue
                img_name = os.path.splitext(img)[0]
                if exact_match(label, img_name):
                    tile_copy["imageAsset"] = f"assets/Legends/{asset_rel_path}/{img}"
                    tile_copy["type"] = "vocabulary"
                    matched_images.add(img)
                    break
        if not tile_copy.get("imageAsset"):
            tile_copy["imageAsset"] = None
            if label:
                tile_copy["type"] = "vocabulary"
            else:
                tile_copy["type"] = "blank"
        updated_tiles.append(tile_copy)

    # Phase 2: Prefix matches for remaining tiles
    for i, tile in enumerate(updated_tiles):
        if tile.get("imageAsset"):
            continue
        label = tile.get("label", "").strip()
        if label:
            for img in images:
                if img in matched_images:
                    continue
                img_name = os.path.splitext(img)[0]
                if prefix_match(label, img_name):
                    tile["imageAsset"] = f"assets/Legends/{asset_rel_path}/{img}"
                    tile["type"] = "vocabulary"
                    matched_images.add(img)
                    break
            if not tile.get("imageAsset"):
                tile["imageAsset"] = None
                tile["type"] = "vocabulary" if label else "blank"

    return updated_tiles, matched_images


def process_folder(asset_dir, board_json_name, board_json_path):
    asset_path = os.path.join(ASSETS_BASE, asset_dir)
    images = get_image_files(asset_path)

    if not images:
        print(f"  SKIP: No images in {asset_dir}")
        return False, "no_images"

    asset_rel_path = asset_dir.replace("\\", "/")

    template, template_source, prebuilt_filename = get_or_create_template(asset_dir, board_json_name, board_json_path)

    # Extract board properties from template
    if template:
        board_id = template.get("id", "")
        board_name = template.get("name", "")
        columns = template.get("columns", 5)
        parent_id = template.get("parentBoardId")
        tier = template.get("tier", 2)
        is_sub = template.get("isSubBoard", True)
        is_tertiary = template.get("isTertiaryBoard", False)
        is_quaternary = template.get("isQuaternaryBoard", False)
        is_quinary = template.get("isQuinaryBoard", False)
        sort_order = template.get("sortOrder", 0)
        bg_color = template.get("backgroundColor", "transparent")
        adjustable = template.get("adjustableLayout", True)
        box_scale = template.get("boxScale", 1)
        tile_height = template.get("tileHeight", 100)
        tile_width = template.get("tileWidth", 100)
        layout = template.get("layout", {})
    else:
        folder_name = os.path.basename(asset_path.rstrip("\\"))
        board_id = "prebuilt_" + sanitize_id(folder_name)
        board_name = folder_name
        columns = 5
        parent_id = get_parent_board_id(asset_dir)
        tier = 3 if asset_dir.count("\\") >= 2 else 2
        is_sub = tier >= 2
        is_tertiary = asset_dir.count("\\") >= 2
        is_quaternary = False
        is_quinary = False
        sort_order = 0
        bg_color = "transparent"
        adjustable = True
        box_scale = 1
        tile_height = 100
        tile_width = 100
        layout = {"rows": 0, "blankTilesAdded": 0}

    if not board_id:
        board_id = "prebuilt_" + sanitize_id(board_name)
    if not board_name:
        board_name = os.path.basename(asset_path.rstrip("\\"))

    if not parent_id:
        parent_id = get_parent_board_id(asset_dir)

    # Get template tiles
    template_tiles = template.get("tiles", []) if template else []

    # Check if template tiles match images
    template_matches = 0
    for tile in template_tiles:
        label = tile.get("label", "").strip()
        if label:
            for img in images:
                img_name = os.path.splitext(img)[0]
                if exact_match(label, img_name) or prefix_match(label, img_name):
                    template_matches += 1
                    break

    tiles = []
    matched_images = set()

    use_importance_order = False
    importance_order = []
    if is_disney_story(asset_dir):
        folder_name = os.path.basename(asset_path.rstrip("\\"))
        if folder_name in DISNEY_IMPORTANCE_ORDER:
            use_importance_order = True
            importance_order = DISNEY_IMPORTANCE_ORDER[folder_name]

    if template_tiles and template_matches > 0:
        # Use template tiles with matching
        tiles, matched_images = match_tiles_to_images(
            template_tiles, images, asset_rel_path, board_id
        )

        # Add unmatched images as new tiles
        for img in images:
            if img not in matched_images:
                img_name = os.path.splitext(img)[0]
                tile = create_tile(board_id, img_name, img, asset_rel_path)
                tiles.append(tile)
    else:
        # Create tiles from image filenames
        ordered_images = images
        if use_importance_order:
            ordered_images = []
            used = set()
            for imp_label in importance_order:
                for img in images:
                    img_name = os.path.splitext(img)[0].lower().strip()
                    if img_name == imp_label.lower().strip():
                        ordered_images.append(img)
                        used.add(img)
                        break
            # Add any remaining images at the end (alphabetical)
            for img in sorted(images):
                if img not in used:
                    ordered_images.append(img)
            images = ordered_images

        for img in images:
            img_name = os.path.splitext(img)[0]
            tile = create_tile(board_id, img_name, img, asset_rel_path)
            tiles.append(tile)

    # Calculate layout
    total_tiles = len(tiles)
    rows_needed = math.ceil(total_tiles / columns) if total_tiles > 0 else 1
    total_cells = rows_needed * columns

    # Use existing layout rows if it's larger
    if layout and layout.get("rows"):
        layout_rows = layout["rows"]
        if layout_rows >= rows_needed:
            total_cells = layout_rows * columns
            rows_needed = layout_rows

    # Fill with blank tiles if needed
    blank_idx = 1
    while len(tiles) < total_cells:
        tiles.append(create_blank_tile(board_id, len(tiles) + 1))

    blank_tiles_added = len(tiles) - sum(1 for t in tiles if t.get("imageAsset"))

    # Build final JSON
    board = {
        "id": board_id,
        "name": board_name,
        "area": "Legends",
        "columns": columns,
        "backgroundColor": bg_color,
        "adjustableLayout": adjustable,
        "isSubBoard": is_sub,
        "isTertiaryBoard": is_tertiary,
        "isQuaternaryBoard": is_quaternary,
        "isQuinaryBoard": is_quinary,
        "sortOrder": sort_order,
        "tier": tier,
        "boxScale": box_scale,
        "tileHeight": tile_height,
        "tileWidth": tile_width,
        "layout": {
            "rows": rows_needed,
            "blankTilesAdded": 0
        },
        "tiles": tiles,
    }

    if parent_id:
        board["parentBoardId"] = parent_id

    # Determine output filename
    if board_json_name:
        out_name = board_json_name
    elif prebuilt_filename:
        out_name = prebuilt_filename
    else:
        out_name = "prebuilt_" + sanitize_id(board_name) + ".json"

    os.makedirs(board_json_path, exist_ok=True)
    output_path = os.path.join(board_json_path, out_name)

    image_count = sum(1 for t in tiles if t.get("imageAsset"))
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(board, f, indent=2, ensure_ascii=False)

    print(f"  Wrote: {out_name} - {len(tiles)} tiles, {image_count} images")
    return True, f"tiles={len(tiles)}, images={image_count}"


def main():
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Processing {len(rows)} folders...\n")

    processed = 0
    skipped = 0
    results = []

    for row in rows:
        asset_dir = row["AssetDir"]
        board_json_name = (row.get("BoardJsonName", "") or "").strip()
        board_path = row["BoardPath"]
        board_image_count_str = row.get("BoardImageCount", "") or ""

        try:
            board_image_count = int(board_image_count_str) if board_image_count_str else 0
        except:
            board_image_count = 0

        if board_image_count > 1:
            print(f"SKIP (already populated: {board_image_count} images): {asset_dir}")
            skipped += 1
            continue

        print(f"Processing: {asset_dir} ({row['ImageCount']} asset images)")

        success, msg = process_folder(asset_dir, board_json_name, board_path)
        if success:
            processed += 1
            results.append({"folder": asset_dir, "status": "processed", "detail": msg})
        else:
            skipped += 1
            results.append({"folder": asset_dir, "status": "skipped", "detail": msg})

    print(f"\n\nDone! Processed: {processed}, Skipped: {skipped}")

    with open(r"C:\Users\Craig\Downloads\Charlie Chat\build_results.csv", "w", encoding="utf-8") as f:
        f.write("folder,status,detail\n")
        for r in results:
            f.write(f"{r['folder']},{r['status']},{r['detail']}\n")


if __name__ == "__main__":
    main()
