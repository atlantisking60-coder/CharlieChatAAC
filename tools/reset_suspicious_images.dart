// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
final String boardsDir = '$projectRoot\\lib\\data\\boards';

void main() {
  final boardDir = Directory(boardsDir);
  final files = boardDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  var cleared = 0;
  for (final file in files) {
    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
    final boardName = (data['name'] as String?)?.toLowerCase() ?? '';
    var changed = false;
    for (final tile in tiles) {
      final image = tile['image'] as String?;
      if (image == null || image.isEmpty) continue;
      final lower = image.toLowerCase();
      final type = tile['type'] as String? ?? 'vocabulary';
      var suspicious = false;
      if (type != 'board_link') {
        // Sign letter screenshots on non-letter / non-sign boards
        if (lower.contains('16. letters') && !boardName.contains('alphabet') && !boardName.toLowerCase().contains('a-z of sign')) {
          suspicious = true;
        }
        // Alphabet letter images on non-alphabet boards
        if (lower.contains('/alphabet/') && !boardName.contains('alphabet') && !boardName.contains('phonics') && !boardName.toLowerCase().contains('a-z of sign')) {
          suspicious = true;
        }
        // Sign board screenshots on non-sign boards
        if (lower.contains('/sets/') && !boardName.contains('sign') && !boardName.contains('a-z')) {
          suspicious = true;
        }
        // Screenshots of completed boards are usually board-link icons, not tile images
        if (lower.contains('completed symbotalk board screenshots')) {
          suspicious = true;
        }
      }
      if (suspicious) {
        tile['image'] = null;
        changed = true;
        cleared++;
      }
    }
    if (changed) {
      file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
    }
  }
  print('Cleared $cleared suspicious image assignments.');
}
