// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
final String textFile = r'$projectRoot\A-Z Of Sign.txt'.replaceAll('\$projectRoot', projectRoot);
final String imageDir = r'$projectRoot\assets\sign\00. A-Z of Sign'.replaceAll('\$projectRoot', projectRoot);
final String outputDir = r'$projectRoot\lib\data\boards\Sign'.replaceAll('\$projectRoot', projectRoot);

String prebuiltId(String name) {
  final sanitized = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+$'), '');
  return 'prebuilt_$sanitized';
}

String safeId(String label) => label
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String? findImage(String label) {
  final fileName = '$label.png';
  final file = File('$imageDir\\$fileName');
  if (file.existsSync()) {
    return 'assets/sign/00. A-Z of Sign/$fileName';
  }
  return null;
}

Map<String, dynamic> makeTile({
  required String id,
  required String type,
  required String label,
  String? image,
  String? linkedBoardName,
}) {
  return {
    'id': id,
    'type': type,
    'label': label,
    'image': image,
    'linkedBoardName': linkedBoardName,
  };
}

Map<String, dynamic> makeBoardJson({
  required String id,
  required String name,
  required String area,
  required int columns,
  required int rows,
  required List<Map<String, dynamic>> tiles,
}) {
  return {
    'id': id,
    'name': name,
    'area': area,
    'columns': columns,
    'defaultIconFolder': null,
    'layout': {
      'rows': rows,
      'blankTilesAdded': 0,
    },
    'tiles': tiles,
  };
}

void main() {
  final text = File(textFile).readAsStringSync();
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  print('Read ${lines.length} non-empty lines. First 5: ${lines.take(5).toList()}');

  final sections = <String, List<String>>{};
  String? currentLetter;
  final letterRegex = RegExp(r'^[A-Z]$');
  for (final line in lines) {
    if (letterRegex.hasMatch(line)) {
      currentLetter = line;
      sections.putIfAbsent(currentLetter, () => []);
      print('Found section: $currentLetter');
    } else if (currentLetter != null) {
      sections[currentLetter]!.add(line);
    }
  }
  print('Total sections: ${sections.length}');

  final parentTiles = <Map<String, dynamic>>[];
  final directory = Directory(outputDir);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  for (final letter in sections.keys.toList()..sort()) {
    final words = sections[letter]!;
    final boardName = '$letter (Sign)';
    final boardId = prebuiltId(boardName);
    final tiles = <Map<String, dynamic>>[];
    final seenLabels = <String, int>{};

    for (var i = 0; i < words.length; i++) {
      final label = words[i];
      final baseId = safeId(label);
      final count = seenLabels[baseId] ?? 0;
      seenLabels[baseId] = count + 1;
      final tileId = '${boardId}_t${i + 1}';
      final image = findImage(label);
      tiles.add(makeTile(
        id: tileId,
        type: 'vocabulary',
        label: label,
        image: image,
      ));
    }

    // Aim for roughly 6 columns and enough rows.
    const columns = 6;
    final rows = ((tiles.length + columns - 1) / columns).ceil().clamp(5, 20);

    final boardJson = makeBoardJson(
      id: boardId,
      name: boardName,
      area: 'Sign',
      columns: columns,
      rows: rows,
      tiles: tiles,
    );

    final outFile = File('$outputDir\\$boardId.json');
    outFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(boardJson));
    print('Wrote $outFile with ${tiles.length} tiles');

    parentTiles.add(makeTile(
      id: 'prebuilt_a_z_of_sign_link_${letter.toLowerCase()}',
      type: 'board_link',
      label: boardName,
      image: 'assets/symbols/1. Main Boards/Alphabet/${letter.toLowerCase()}.png',
      linkedBoardName: boardId,
    ));
  }

  // Parent board: A-Z Of Sign (kept file id for backwards compatibility)
  const parentColumns = 6;
  final parentRows = ((parentTiles.length + parentColumns - 1) / parentColumns).ceil();
  final parentJson = makeBoardJson(
    id: 'prebuilt_a_to_z_of_sign',
    name: 'A-Z Of Sign',
    area: 'Sign',
    columns: parentColumns,
    rows: parentRows,
    tiles: parentTiles,
  );

  final parentFile = File('$outputDir\\prebuilt_a_to_z_of_sign.json');
  parentFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(parentJson));
  print('Wrote $parentFile with ${parentTiles.length} links');
}
