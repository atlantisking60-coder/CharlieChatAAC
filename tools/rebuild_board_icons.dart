// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'fix_board_assets_v2.dart' as fixer;

const Set<String> targetBoards = {'Actions', 'Jobs & Careers', 'Numbers'};

void main() {
  final assetMap = fixer.scanAssets();
  final totalImages = assetMap.values.fold<int>(0, (sum, list) => sum + list.length);
  print('Scanned $totalImages image assets across ${assetMap.length} keys.');

  final boardDir = Directory(fixer.boardsDir);
  final files = boardDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  for (final file in files) {
    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final boardName = (data['name'] as String?) ?? '';
    if (!targetBoards.contains(boardName)) continue;

    final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
    final labelCounts = <String, int>{};
    var changed = false;

    for (final tile in tiles) {
      final type = tile['type'] as String? ?? 'vocabulary';
      final label = (tile['label'] as String?) ?? '';
      if (type == 'blank' || label.isEmpty || type == 'board_link') continue;

      var searchLabel = label;
      if (searchLabel == '000)') searchLabel = '000';
      if (searchLabel == 'fog') searchLabel = 'foggy';

      String? chosen;
      final plainKey = fixer.normalize(searchLabel);
      final disambiguatedKey = '$plainKey${labelCounts[plainKey] ?? 0 + 1}';
      if (fixer.specialMappings.containsKey(disambiguatedKey)) {
        final mapped = fixer.specialMappings[disambiguatedKey]!;
        if (File('${fixer.projectRoot}/$mapped'.replaceAll('/', '\\')).existsSync()) {
          chosen = mapped;
        }
      }
      if (chosen == null && fixer.specialMappings.containsKey(plainKey)) {
        final mapped = fixer.specialMappings[plainKey]!;
        if (File('${fixer.projectRoot}/$mapped'.replaceAll('/', '\\')).existsSync()) {
          chosen = mapped;
        }
      }

      chosen ??= fixer.chooseImage(searchLabel, assetMap, boardName, labelCounts);

      if (chosen != null) {
        tile['image'] = chosen;
        changed = true;
        print('  ${file.path.split('\\').last}: "$label" -> $chosen');
      }
    }

    if (changed) {
      file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
      print('Saved ${file.path}');
    }
  }
}
