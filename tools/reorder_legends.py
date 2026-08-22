import json
import re
import sys
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
OLD_ANIMATION = "Not Disney Animations"


def reorder_runtime_hierarchy():
    path = PROJECT / "lib" / "data" / "runtime_hierarchy.json"
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    entries = data["entries"]

    # Find all Legends entries and split them into top-level blocks.
    legends_blocks = []
    other = []
    current_top = None
    current_children = []
    pending = []

    def flush_pending():
        nonlocal current_top, current_children, pending
        if pending:
            # The first pending entry is the top-level block, rest are already a block
            pass

    # Collect legends blocks and other entries in order, preserving non-Legends placement
    blocks = []
    for e in entries:
        if e.get("area") == "Legends":
            if e.get("parentName") is None:
                # top-level: start a new block
                current_children = [e]
                blocks.append(("legend_top", current_children))
            else:
                # child: add to the most recent legends block if present
                if current_children is not None:
                    current_children.append(e)
                else:
                    # orphan child, append as its own block
                    blocks.append(("legend_child", [e]))
        else:
            blocks.append(("other", [e]))

    # Map top-level names to their blocks (first child is the top-level entry)
    name_to_block = {}
    for kind, block in blocks:
        if kind == "legend_top":
            name = block[0]["name"]
            if name == OLD_ANIMATION:
                name = "Animations (Not Disney)"
                block[0]["name"] = name
                block[0]["parentName"] = None
            name_to_block[name] = (kind, block)

    # Gather non-top-level/non-Legends blocks and remaining legends blocks
    other_blocks = [b for b in blocks if b[0] != "legend_top"]

    # Build new block list: desired top-level blocks in order, then everything else
    new_blocks = []
    for name in DESIRED_ORDER:
        if name in name_to_block:
            new_blocks.append(name_to_block[name])
            # mark consumed

    # Add all other blocks, skipping consumed top-level blocks
    consumed_names = set(DESIRED_ORDER)
    for kind, block in other_blocks:
        if kind == "legend_top" and block[0]["name"] in consumed_names:
            continue
        new_blocks.append((kind, block))

    # Flatten
    new_entries = []
    for _, block in new_blocks:
        new_entries.extend(block)

    data["entries"] = new_entries
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def reorder_board_hierarchy():
    path = PROJECT / "lib" / "data" / "board_hierarchy.dart"
    text = path.read_text(encoding="utf-8")

    # Regex to match a full BoardHierarchyEntry line
    entry_re = re.compile(r"^\s*BoardHierarchyEntry\(\s*'([^']*)'\s*,\s*'([^']*)'(?:\s*,\s*'([^']*)')?\s*\),?$", re.MULTILINE)

    # Find all lines
    all_lines = text.splitlines()

    # Identify which all_lines are entry lines and their parsed values
    entries = []  # (line_no, raw, name, area, parent)
    for i, line in enumerate(all_lines):
        m = entry_re.match(line)
        if m:
            name, area, parent = m.group(1), m.group(2), m.group(3)
            entries.append({
                "index": i,
                "raw": line,
                "name": name,
                "area": area,
                "parent": parent,
            })

    # Build blocks for Legends top-level
    # A block starts at a top-level Legends entry and includes consecutive subsequent entries that are in the same area and are not top-level.
    # We'll define the block boundary by the *next* top-level any-area or end.
    # For safety, we group children as all consecutive non-top-level Legends lines after a top-level Legends line.
    legend_blocks = []  # list of (top_index, [indices])
    other_indices = []  # set of all line indices that belong to other entries or already handled

    # First pass: mark each entry as top-level Legends, child Legends, or other
    def is_top_level_legends(e):
        return e["area"] == "Legends" and e["parent"] is None

    # We need to extract top-level blocks. We scan entry lines.
    i = 0
    while i < len(entries):
        e = entries[i]
        if is_top_level_legends(e):
            block = [i]
            i += 1
            while i < len(entries):
                nxt = entries[i]
                if nxt["area"] == "Legends" and nxt["parent"] is not None:
                    block.append(i)
                    i += 1
                else:
                    break
            legend_blocks.append(block)
        else:
            i += 1

    # Map top-level name to block
    name_to_block = {}
    for block in legend_blocks:
        top = entries[block[0]]
        name = top["name"]
        if name == OLD_ANIMATION:
            name = "Animations (Not Disney)"
            top["name"] = name
            top["parent"] = None
        name_to_block[name] = block

    # Need to insert/reorder the top-level lines. Simplest: take the first top-level raw line and reorder them at the very start of the Legends section.
    # We'll create new raw top-level lines for desired order, placing them as a contiguous block starting at the original first Legends top-level line.
    # The children will be left where they are (still part of their original blocks further down); this keeps the file valid.

    # But if we leave children at original locations, the top-level blocks won't be contiguous. That's fine for index-based ordering.
    # We'll move only the top-level entry line for each desired board.
    # First, get the original top-level raw lines and remove them from their current spots.
    new_top_raws = []
    for name in DESIRED_ORDER:
        if name in name_to_block:
            top_index = name_to_block[name][0]
            new_top_raws.append(entries[top_index]["raw"])
        else:
            # Insert a new top-level line for the missing one (Animations)
            new_top_raws.append("  BoardHierarchyEntry('Animations (Not Disney)', 'Legends'),")

    # Replace the top-level entry lines: we'll build a new list of lines.
    # Determine the contiguous span of top-level Legends lines? They are not contiguous.
    # We'll just remove all top-level Legends entry lines from their original positions and insert the new sequence at the position of the first top-level Legends line.

    first_legend_line = None
    for block in legend_blocks:
        line_idx = entries[block[0]]["index"]
        if first_legend_line is None or line_idx < first_legend_line:
            first_legend_line = line_idx

    removed_set = set()
    for block in legend_blocks:
        removed_set.add(entries[block[0]]["index"])

    new_lines = []
    inserted = False
    for idx, line in enumerate(all_lines):
        if idx == first_legend_line and not inserted:
            # Insert the new top-level block
            for raw in new_top_raws:
                new_lines.append(raw)
            inserted = True
        if idx in removed_set:
            # skip the old top-level line
            continue
        new_lines.append(line)

    # Also need to handle the old "Not Disney Animations" if it exists as a child or top-level elsewhere.
    # If it was a top-level in the file, its line is now replaced by the new top-level raw. Good.
    # If it was a child elsewhere, it will remain as a child (not top-level). That's fine.

    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    reorder_runtime_hierarchy()
    reorder_board_hierarchy()
    print("Done")
