import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
file_path = root / "lib" / "data" / "board_hierarchy.dart"
text = file_path.read_text(encoding="utf-8")

start_marker = "Future<void> loadRuntimeHierarchy() async {"
start = text.find(start_marker)
if start < 0:
    print("loadRuntimeHierarchy not found")
    raise SystemExit(1)

# Find the matching closing '}' that is on its own line after the function start.
brace_start = text.find("{", start)
brace_count = 0
end = brace_start
while end < len(text):
    ch = text[end]
    if ch == "{":
        brace_count += 1
    elif ch == "}":
        brace_count -= 1
        if brace_count == 0:
            break
    end += 1

if brace_count != 0:
    print("Could not find end of loadRuntimeHierarchy")
    raise SystemExit(1)

new_func = '''Future<void> loadRuntimeHierarchy() async {

  final merged = <BoardHierarchyEntry>[];

  // 1. Always start with the compiled-in prebuilt hierarchy (defines order).

  merged.addAll(boardHierarchy);

  // 2. Try the local dev server (live preview source of truth).

  try {

    final response = await http

        .get(Uri.parse('http://localhost:8787/runtimeHierarchy'))

        .timeout(const Duration(seconds: 2));

    if (response.statusCode == 200) {

      final data = json.decode(response.body) as Map<String, dynamic>;

      final list = (data['entries'] as List?) ?? [];

      final prebuiltNames = merged.map((e) => e.name.toLowerCase()).toSet();

      for (final e in list) {

        final entry = BoardHierarchyEntry.fromJson(e as Map<String, dynamic>);

        if (!prebuiltNames.contains(entry.name.toLowerCase())) {

          merged.add(entry);

        }

      }

    }

  } catch (_) {}

  // 3. Merge any locally persisted admin edits.

  try {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_runtimeHierarchyPrefsKey);

    if (raw != null && raw.isNotEmpty) {

      final list = json.decode(raw) as List;

      final prebuiltNames = merged.map((e) => e.name.toLowerCase()).toSet();

      for (final e in list) {

        final entry = BoardHierarchyEntry.fromJson(e as Map<String, dynamic>);

        if (!prebuiltNames.contains(entry.name.toLowerCase())) {

          merged.add(entry);

        }

      }

    }

  } catch (_) {}

  runtimeBoardHierarchy

    ..clear()

    ..addAll(merged);

}'''

new_text = text[:start] + new_func + text[end + 1:]
file_path.write_text(new_text, encoding="utf-8")
print("Patched loadRuntimeHierarchy")
