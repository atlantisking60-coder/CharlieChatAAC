import 'dart:convert';
import 'dart:io';

void main() {
  final path = r'lib/data/boards/Sign/A-Z Of Sign/prebuilt_a-z_of_sign.json';
  final file = File(path);
  final jsonString = file.readAsStringSync();
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();

  final regex = RegExp(r'^prebuilt_a-z_of_sign_([a-z])_sign$');
  for (final tile in tiles) {
    final id = tile['id'] as String? ?? '';
    final match = regex.firstMatch(id);
    if (match != null) {
      final letter = match.group(1)!;
      tile['type'] = 'board_link';
      tile['linkedBoardName'] = 'prebuilt_${letter}_sign';
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(data)}\n');
  // ignore: avoid_print
  print('Updated ${tiles.length} A-Z of Sign tiles');
}
