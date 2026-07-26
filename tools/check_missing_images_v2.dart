// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
final String boardsDir = '$projectRoot\\lib\\data\\boards';

void main() {
  final boardDir = Directory(boardsDir);
  final files = boardDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  final missingByBoard = <String, List<String>>{};
  var totalMissing = 0;
  var totalTiles = 0;
  for (final file in files) {
    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final boardName = (data['name'] as String?) ?? file.path.split('\\').last;
    final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
    final missing = <String>[];
    for (final tile in tiles) {
      final type = tile['type'] as String? ?? 'vocabulary';
      if (type == 'blank') continue;
      final label = (tile['label'] as String?) ?? '';
      if (label.isEmpty) continue;
      totalTiles++;
      final image = tile['image'] as String?;
      if (image == null || image.isEmpty) {
        missing.add(label);
        totalMissing++;
      } else if (image.startsWith('http://') || image.startsWith('https://')) {
        // External URL - valid image source for the app
      } else {
        final imageFile = File('$projectRoot/$image'.replaceAll('/', '\\'));
        if (!imageFile.existsSync()) {
          missing.add('$label (missing file: $image)');
          totalMissing++;
        }
      }
    }
    if (missing.isNotEmpty) {
      missingByBoard[boardName] = missing;
    }
  }

  final sb = StringBuffer();
  sb.writeln('Total tiles: $totalTiles');
  sb.writeln('Tiles missing images: $totalMissing');
  sb.writeln('');
  for (final entry in missingByBoard.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    sb.writeln('${entry.key}: ${entry.value.length} missing');
    for (final label in entry.value) {
      sb.writeln('  - $label');
    }
  }
  File('$projectRoot\\tools\\missing_images_report.txt').writeAsStringSync(sb.toString());
  print(sb.toString());
}
