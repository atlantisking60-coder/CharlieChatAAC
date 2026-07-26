// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
final List<String> assetDirs = [
  '$projectRoot\\assets\\symbols',
  '$projectRoot\\assets\\images',
  '$projectRoot\\assets\\sign',
];
final String boardsDir = '$projectRoot\\lib\\data\\boards';

const Set<String> imageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.svg',
};

String normalize(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String baseLabel(String label) {
  return label.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim().toLowerCase();
}

String prebuiltId(String name) {
  final sanitized = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+$'), '');
  return 'prebuilt_$sanitized';
}

Map<String, List<String>> scanAssets() {
  final assetMap = <String, List<String>>{};
  for (final dir in assetDirs) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      final ext = '.${entity.path.split('.').last.toLowerCase()}';
      if (!imageExtensions.contains(ext)) continue;
      final relPath = entity.path.replaceFirst('$projectRoot\\', '').replaceAll('\\', '/');
      final nameNoExt = entity.path.split('\\').last.split('.').first;
      final key = normalize(nameNoExt);
      assetMap.putIfAbsent(key, () => []).add(relPath);
      // Also index without numeric suffix like "they (1)"
      final stripped = nameNoExt.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '').trim();
      if (stripped.toLowerCase() != nameNoExt.toLowerCase()) {
        final strippedKey = normalize(stripped);
        assetMap.putIfAbsent(strippedKey, () => []).add(relPath);
      }
    }
  }
  return assetMap;
}

// Special-case overrides for labels that don't match filenames directly.
final Map<String, String> specialMappings = {
  // Numbers
  'zero': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/0.png',
  'one': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/1.png',
  'two': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/2.png',
  'three': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/3.png',
  'four': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/4.png',
  'five': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/5.png',
  'six': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/6.png',
  'seven': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/7.png',
  'eight': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/8.png',
  'nine': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/9.png',
  'ten': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/10.png',
  'eleven': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/11.png',
  'twelve': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/12.png',
  'thirteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/13.png',
  'fourteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/14.png',
  'fifteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/15.png',
  'sixteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/16.png',
  'seventeen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/17.png',
  'eighteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/18.png',
  'nineteen': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/19.png',
  'twenty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/20.png',
  // Common Words -> Break & Lunchtime explicit mappings
  'calooequipment': 'assets/symbols/3. Lesson Vocab/Break & Lunchtime/caloo equipment.png',
  'hangingbars': 'assets/symbols/3. Lesson Vocab/Break & Lunchtime/hanging bars.png',
  'roundabout': 'assets/symbols/3. Lesson Vocab/Break & Lunchtime/roundabout.png',
  'swing': 'assets/symbols/3. Lesson Vocab/Break & Lunchtime/swing.png',
  // People duplicates
  'theyoneperson': 'assets/symbols/1. Main Boards/People/they (one person).png',
  'theymorethanoneperson': 'assets/symbols/1. Main Boards/People/they (more than one person).png',
  'you1': 'assets/symbols/1. Main Boards/People/you (1).png',
  'you2': 'assets/symbols/1. Main Boards/People/you (2).png',
};

List<String>? findCandidates(String label, Map<String, List<String>> assetMap) {
  final keys = <String>{
    normalize(label),
    normalize(baseLabel(label)),
    normalize(label.replaceAll(' ', '-')),
    normalize(label.replaceAll(' ', '_')),
  };
  final candidates = <String>[];
  for (final key in keys) {
    if (assetMap.containsKey(key)) {
      for (final path in assetMap[key]!) {
        if (!candidates.contains(path)) candidates.add(path);
      }
    }
  }
  if (candidates.isNotEmpty) return candidates;

  // Partial matching for single-word labels
  final labelNorm = normalize(label);
  final words = label
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]'))
      .where((w) => w.length > 2)
      .toList();
  for (final entry in assetMap.entries) {
    final key = entry.key;
    if (labelNorm.length > 3 && (key == labelNorm || labelNorm.contains(key) || key.contains(labelNorm))) {
      for (final path in entry.value) {
        if (!candidates.contains(path)) candidates.add(path);
      }
    } else if (words.isNotEmpty) {
      for (final word in words) {
        if (word.length > 3 && key.contains(word)) {
          for (final path in entry.value) {
            if (!candidates.contains(path)) candidates.add(path);
          }
          break;
        }
      }
    }
  }
  return candidates.isEmpty ? null : candidates;
}

String? pickBestMatch(String label, List<String> candidates, {String? boardName}) {
  if (candidates.length == 1) return candidates.first;

  final base = baseLabel(label);
  final labelLower = label.toLowerCase();

  // Prefer exact filename matches
  final exact = <String>[];
  for (final c in candidates) {
    final filename = c.split('/').last.split('.').first.toLowerCase();
    if (filename == labelLower || filename == base) {
      exact.add(c);
    }
  }
  if (exact.isNotEmpty) {
    candidates = exact;
  }

  // Prefer files inside board-specific folders (heuristic)
  if (boardName != null && boardName.isNotEmpty) {
    final boardNorm = normalize(boardName);
    for (final c in candidates) {
      if (c.toLowerCase().contains(boardNorm)) return c;
    }
  }

  // Prefer first candidate (already somewhat ordered by scan)
  return candidates.first;
}

void processBoard(File file, Map<String, List<String>> assetMap) {
  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final boardName = data['name'] as String? ?? '';
  final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
  final labelCounts = <String, int>{};
  var changed = false;

  for (final tile in tiles) {
    final type = tile['type'] as String? ?? 'vocabulary';
    final label = (tile['label'] as String?) ?? '';
    final image = tile['image'] as String?;

    if (type == 'blank' || label.isEmpty) continue;

    // Board link styling
    if (type == 'board_link') {
      if (tile['bgColor'] != '#000000' || tile['textColor'] != '#FFFFFF') {
        tile['bgColor'] = '#000000';
        tile['textColor'] = '#FFFFFF';
        changed = true;
      }
    }

    // Full-screen styling
    final isFullScreen = (tile['isFullScreenImage'] as bool?) ?? false;
    if (isFullScreen) {
      if (tile['bgColor'] != '#FFCDD2' || tile['textColor'] != '#000000') {
        tile['bgColor'] = '#FFCDD2';
        tile['textColor'] = '#000000';
        changed = true;
      }
      continue;
    }

    // Skip if image already exists and file is present
    if (image != null && image.isNotEmpty) {
      final imageFile = File('$projectRoot/$image'.replaceAll('/', '\\'));
      if (imageFile.existsSync()) {
        continue;
      }
    }

    // Label corrections
    var searchLabel = label;
    if (searchLabel == '000)') searchLabel = '000';
    if (searchLabel == 'fog') searchLabel = 'foggy';

    // Special mappings
    final specialKey = normalize(searchLabel);
    final specialDisambiguatedKey = _disambiguatedKey(searchLabel, labelCounts);
    String? chosen;
    if (specialMappings.containsKey(specialDisambiguatedKey)) {
      final mapped = specialMappings[specialDisambiguatedKey]!;
      if (File('$projectRoot/$mapped'.replaceAll('/', '\\')).existsSync()) {
        chosen = mapped;
      }
    }
    if (chosen == null && specialMappings.containsKey(specialKey)) {
      final mapped = specialMappings[specialKey]!;
      if (File('$projectRoot/$mapped'.replaceAll('/', '\\')).existsSync()) {
        chosen = mapped;
      }
    }

    // Local asset search
    if (chosen == null) {
      final candidates = findCandidates(searchLabel, assetMap);
      if (candidates != null && candidates.isNotEmpty) {
        final disambiguated = _disambiguatedCandidates(searchLabel, candidates, labelCounts);
        chosen = pickBestMatch(searchLabel, disambiguated, boardName: boardName);
      }
    }

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

String _disambiguatedKey(String label, Map<String, int> labelCounts) {
  final base = normalize(label);
  final count = labelCounts[base] ?? 0;
  labelCounts[base] = count + 1;
  if (count == 0) return base;
  return '$base${count + 1}';
}

List<String> _disambiguatedCandidates(String label, List<String> candidates, Map<String, int> labelCounts) {
  final base = normalize(label);
  final count = labelCounts[base] ?? 0;
  labelCounts[base] = count + 1;
  if (count == 0) return candidates;

  // Prefer files with numeric/participial suffixes when this is a repeat occurrence
  final withSuffix = candidates.where((c) {
    final filename = c.split('/').last.split('.').first;
    return RegExp(r'\(\d+\)').hasMatch(filename) ||
        RegExp(r'\(one[^)]*\)|\(more[^)]*\)').hasMatch(filename);
  }).toList();
  return withSuffix.isNotEmpty ? withSuffix : candidates;
}

void main() {
  final assetMap = scanAssets();
  final totalImages = assetMap.values.fold<int>(0, (sum, list) => sum + list.length);
  print('Scanned $totalImages image assets across ${assetMap.length} keys.');

  final boardDir = Directory(boardsDir);
  final files = boardDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  print('Found ${files.length} board JSON files.');

  for (final file in files) {
    processBoard(file, assetMap);
  }
}
