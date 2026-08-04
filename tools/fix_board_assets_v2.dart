// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
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

// Board-name -> likely asset folder substrings (lowercase, using / separators).
final Map<String, List<String>> boardFolderHints = {
  'common words': ['1. main boards/common'],
  'feelings': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'sad': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'mad': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'scared': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'joyful': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'strong': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'calm': ['1. main boards/feelings and emotions', 'boards/feelings'],
  'shades of colours': ['1. main boards/colours'],
  'prepositions': ['1. main boards/prepositions'],
  'people': ['1. main boards/people', 'boards/people'],
  'school people': ['1. main boards/people', 'boards/people'],
  'animals': ['1. main boards/animals and habitats', 'boards/animals'],
  'mammals': ['1. main boards/animals and habitats/mammals'],
  'birds': ['1. main boards/animals and habitats/birds'],
  'reptiles': ['1. main boards/animals and habitats/reptiles'],
  'amphibians': ['1. main boards/animals and habitats/amphibians'],
  'insects': ['1. main boards/animals and habitats/insects'],
  'arachnids': ['1. main boards/animals and habitats/arachnids'],
  'invertebrates': ['1. main boards/animals and habitats/invertebrates'],
  'fish': ['1. main boards/animals and habitats/fish'],
  'habitats': ['1. main boards/animals and habitats/habitats'],
  'sealife': ['1. main boards/animals and habitats/sealife'],
  'nature vocabulary': ['1. main boards/animals and habitats/nature'],
  'body parts of animals': ['1. main boards/animals and habitats/body parts of animals'],
  'child animals': ['1. main boards/animals and habitats/child animals'],
  'groups of animals': ['1. main boards/animals and habitats/groups of animals'],
  'common actions': ['1. main boards/actions'],
  'movement': ['1. main boards/movement'],
  'buildings': ['1. main boards/places/buildings'],
  'rooms and home': ['1. main boards/places/rooms and home'],
  'furniture': ['1. main boards/places/furniture'],
  'local places': ['1. main boards/places'],
  'jobs and careers': ['1. main boards/careers'],
  'weather': ['1. main boards/weather'],
  'disasters': ['1. main boards/weather', 'boards/english'],
  'seasons': ['1. main boards/weather', 'boards/english'],
  'events and occasions': ['1. main boards/time/events and occasions'],
  'easter keywords': ['1. main boards/time/easter keywords'],
  'halloween keywords': ['1. main boards/time/halloween keywords'],
  'bonfire night keywords': ['1. main boards/time/bonfire night keywords'],
  'christmas keywords': ['1. main boards/time/christmas keywords'],
  'body parts': ['1. main boards/body parts'],
  'medical': ['1. main boards/body parts', 'boards/english'],
  'internal organs': ['1. main boards/body parts/internal organs'],
  'time': ['1. main boards/time'],
  'time (clocks)': ['1. main boards/time'],
  'months': ['1. main boards/time'],
  'class equipment': ['1. main boards/classroom equipment'],
  'thinking skills': ['2. baycroft specific/thinking skills'],
  'when things go wrong': ['2. baycroft specific'],
  'blank levels': ['2. baycroft specific/blank levels'],
  'lessons': ['assets/symbols/subjects'],
  'tutor timetables': ['1. main boards'],
  'people at school': ['2. baycroft specific'],
  'baycroft expects': ['2. baycroft specific/baycroft expects'],
  'actions': ['1. main boards/actions'],
  'phonics': ['1. main boards/phonics'],
  'phase 2 phonics': ['1. main boards/phonics'],
  'phase 3 phonics': ['1. main boards/phonics'],
  'phase 4 phonics': ['1. main boards/phonics'],
  'phase 5 phonics': ['1. main boards/phonics'],
  'phase 6 phonics': ['1. main boards/phonics'],
  'alphabet': ['1. main boards/alphabet'],
  'numbers': ['1. main boards/numbers', '3. lesson vocab/maths/basic/numbers'],
  'places': ['1. main boards/places'],
  'clothes': ['1. main boards/clothes'],
  'money': ['1. main boards', 'boards/money'],
  'interests': ['1. main boards/common interests'],
  'characters': ['1. main boards/people', 'boards/people'],
  'colours': ['1. main boards/colours'],
  'transport': ['1. main boards/vehicles'],
  'toys': ['1. main boards/toys'],
  'food and drink': ['1. main boards/cooking and food', '3. lesson vocab/cooking and food'],
  'home and household': ['1. main boards/places/rooms and home'],
  'school and instructions': ['1. main boards/people at school', 'boards/people at school'],
  'descriptions and attributes': ['1. main boards/adjectives', 'boards/english/adjectives'],
  'outside': ['1. main boards/places', 'boards/town'],
  'time and days': ['1. main boards/time', 'boards/time'],
  'questions': ['1. main boards/adverbs', 'boards/english/how'],
  'personal actions': ['1. main boards/actions'],
  'shared activities': ['1. main boards/people and places'],
  'leisure activities and interests': ['1. main boards/sports, activities and p.e'],
  'general objects': ['1. main boards/furniture'],
  'clothing and personal': ['1. main boards/clothes'],
  'personal possessions': ['1. main boards/toys'],
  'personal hygiene': ['1. main boards/body parts', 'boards/medical'],
  'gender and sexuality': ['1. main boards/people'],
  'sport': ['1. main boards/sports, activities and p.e'],
  'religion and customs': ['1. main boards/time/events and occasions'],
  'other countries': ['1. main boards/places'],
  'public notices': ['1. main boards'],
  'computer items': ['1. main boards/classroom equipment'],
  'grammatical elements': ['1. main boards/small words'],
  'quantity and measurement': ['1. main boards/numbers'],
  'a-z of sign': ['assets/sign'],
  'sign a-z': ['assets/sign'],
};

// Special-case overrides for labels that don't have a direct filename match.
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
  'thirty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/30.png',
  'forty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/40.png',
  'fifty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/50.png',
  'sixty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/60.png',
  'seventy': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/70.png',
  'eighty': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/80.png',
  'ninety': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/90.png',
  'hundred': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/hundred.png',
  'thousand': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/thousand.png',
  'million': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/million.png',
  'billion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/billion.png',
  'trillion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/trillion.png',
  'quarillion': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/quadrillion.png',
  'and': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/and.png',
  // Colours
  'black': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
  'grey': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
  'white': 'assets/symbols/1. Main Boards/Colours/colourless.png',
  'silver': 'assets/symbols/1. Main Boards/Colours/Shades Of Grey.png',
  'brown': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
  'primarycolours': 'assets/symbols/1. Main Boards/Colours/primary colours.png',
  'red': 'assets/symbols/1. Main Boards/Colours/Shades Of Red.png',
  'orange': 'assets/symbols/1. Main Boards/Colours/Shades Of Orange.png',
  'yellow': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
  'green': 'assets/symbols/1. Main Boards/Colours/Shades Of Green.png',
  'darkgreen': 'assets/symbols/1. Main Boards/Colours/Shades Of Green.png',
  'secondarycolours': 'assets/symbols/1. Main Boards/Colours/secondary colours.png',
  'blue': 'assets/symbols/1. Main Boards/Colours/Shades Of Blue.png',
  'darkblue': 'assets/symbols/1. Main Boards/Colours/Shades Of Blue.png',
  'purple': 'assets/symbols/1. Main Boards/Colours/Shades Of Purple.png',
  'violet': 'assets/symbols/1. Main Boards/Colours/Shades Of Purple.png',
  'pink': 'assets/symbols/1. Main Boards/Colours/Shades Of Pink.png',
  'tertiarycolours': 'assets/symbols/1. Main Boards/Colours/tertiary colours.png',
  'maroon': 'assets/symbols/1. Main Boards/Colours/Shades Of Red.png',
  'coffee': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
  'ocher': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
  'mustard': 'assets/symbols/1. Main Boards/Colours/Shades Of Yellow.png',
  'colourwheel': 'assets/symbols/1. Main Boards/Colours/colour wheel.png',
  'beige': 'assets/symbols/1. Main Boards/Colours/Shades Of Brown.png',
  'rainbow': 'assets/symbols/1. Main Boards/Colours/rainbow.png',
  'complimentarycolours': 'assets/symbols/1. Main Boards/Colours/complimentary colours.png',
  // Other known missing labels
  'claw': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/claw.png',
  'beakbill': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/beak.png',
  'pricklesspinesquills': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/spines.png',
  'antler': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/antler.png',
  'pincer': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/pincer.png',
  'hump': 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/hump.png',
  'kid': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/kid (goat).png',
  'hatchling': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/hatchling.png',
  'nestling': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/nestling.png',
  'eaglet': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/eaglet.png',
  'owlet': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/owlet.png',
  'cria': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/cria.png',
  'sick': 'assets/symbols/1. Main Boards/Body Parts/sick.png',
  'presentorgift': 'assets/symbols/1. Main Boards/Time/Events and Occasions/Christmas/present.png',
  'santaclaus': 'assets/symbols/1. Main Boards/Time/Events and Occasions/Christmas/santa.png',
  'yuletidechocolatelog': 'assets/symbols/1. Main Boards/Time/Events and Occasions/Christmas/yule log.png',
  'coloursofchristmas': 'assets/symbols/1. Main Boards/Time/Events and Occasions/Christmas/colours of christmas.png',
  'birdofprey': 'assets/symbols/1. Main Boards/Animals and Habitats/Birds/bird of prey.png',
  'kestrel': 'assets/symbols/1. Main Boards/Animals and Habitats/Birds/kestrel.png',
  'parakeetparrotmacaw': 'assets/symbols/1. Main Boards/Animals and Habitats/Birds/parakeet.png',
  'icerink': 'assets/symbols/1. Main Boards/Places/Buildings/ice rink.png',
  'mallorshoppingcentre': 'assets/symbols/1. Main Boards/Places/Buildings/mall or shopping centre.png',
  'storeorshop': 'assets/symbols/1. Main Boards/Places/Buildings/store or shop.png',
  'calfmoose': 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/calf (moose).png',
  'leavorexit': 'assets/symbols/1. Main Boards/Actions/leave or exit.png',
  'mixstir': 'assets/symbols/1. Main Boards/Actions/mix and stir.png',
  '000': 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers/0.png',
  'fog': 'assets/symbols/1. Main Boards/Weather/foggy.png',
  'rooms': 'assets/symbols/1. Main Boards/Places/Rooms and Home/rooms.png',
  'roomshome': 'assets/symbols/1. Main Boards/Places/Rooms and Home/rooms.png',
  'mr': 'assets/symbols/1. Main Boards/People/Mr.png',
  'mrs': 'assets/symbols/1. Main Boards/People/Mrs.png',
  // Common Words -> Break and Lunchtime explicit mappings
  'calooequipment': 'assets/symbols/3. Lesson Vocab/Break and Lunchtime/caloo equipment.png',
  'hangingbars': 'assets/symbols/3. Lesson Vocab/Break and Lunchtime/hanging bars.png',
  'roundabout': 'assets/symbols/3. Lesson Vocab/Break and Lunchtime/roundabout.png',
  'swing': 'assets/symbols/3. Lesson Vocab/Break and Lunchtime/swing.png',
  // People duplicates
  'theyoneperson': 'assets/symbols/1. Main Boards/People/they (one person).png',
  'theymorethanoneperson': 'assets/symbols/1. Main Boards/People/they (more than one person).png',
  'you1': 'assets/symbols/1. Main Boards/People/you (1).png',
  'you2': 'assets/symbols/1. Main Boards/People/you (2).png',
};

Map<String, List<String>> scanAssets() {
  final assetMap = <String, List<String>>{};
  final rootDir = Directory('$projectRoot\\assets');
  if (!rootDir.existsSync()) return assetMap;
  for (final entity in rootDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final ext = '.${entity.path.split('.').last.toLowerCase()}';
    if (!imageExtensions.contains(ext)) continue;
    final relPath = entity.path.replaceFirst('$projectRoot\\', '').replaceAll('\\', '/');
    final nameNoExt = entity.path.split('\\').last.split('.').first;
    final key = normalize(nameNoExt);
    assetMap.putIfAbsent(key, () => []).add(relPath);
    final stripped = nameNoExt.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '').trim();
    if (stripped.toLowerCase() != nameNoExt.toLowerCase()) {
      final strippedKey = normalize(stripped);
      assetMap.putIfAbsent(strippedKey, () => []).add(relPath);
    }
  }
  return assetMap;
}

List<String>? directMatches(String label, Map<String, List<String>> assetMap) {
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
  return candidates.isEmpty ? null : candidates;
}

List<String>? partialMatches(String label, Map<String, List<String>> assetMap) {
  final labelNorm = normalize(label);
  final words = label
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]'))
      .where((w) => w.length > 2)
      .toList();
  final candidates = <String>[];
  for (final entry in assetMap.entries) {
    final key = entry.key;
    var matched = false;
    if (labelNorm.length > 3 && (labelNorm.contains(key) || key.contains(labelNorm))) {
      matched = true;
    } else if (words.isNotEmpty) {
      for (final word in words) {
        if (word.length > 3 && key.contains(word)) {
          matched = true;
          break;
        }
      }
    }
    if (matched) {
      for (final path in entry.value) {
        if (!candidates.contains(path)) candidates.add(path);
      }
    }
  }
  return candidates.isEmpty ? null : candidates;
}

String? pickBestMatch(String label, List<String> candidates, String boardName) {
  if (candidates.length == 1) return candidates.first;

  final boardNorm = normalize(boardName);
  final hints = boardFolderHints[boardName.toLowerCase()] ?? [];

  // Prefer exact filename match first
  final labelLower = label.toLowerCase();
  final base = baseLabel(label);
  final exact = <String>[];
  for (final c in candidates) {
    final filename = c.split('/').last.split('.').first.toLowerCase();
    if (filename == labelLower || filename == base) {
      exact.add(c);
    }
  }
  if (exact.length == 1) return exact.first;
  final exactPool = exact.isNotEmpty ? exact : candidates;

  // Prefer board-specific folders
  for (final hint in hints) {
    for (final c in exactPool) {
      if (c.toLowerCase().contains(hint)) return c;
    }
  }

  // Prefer assets/symbols paths over sign letter screenshots for non-sign boards
  final isSignBoard = boardNorm.contains('sign') || boardNorm.contains('a-z');
  final symbolCandidates = exactPool.where((c) => c.toLowerCase().startsWith('assets/symbols/')).toList();
  final signCandidates = exactPool.where((c) => c.toLowerCase().startsWith('assets/sign/')).toList();
  if (!isSignBoard && symbolCandidates.isNotEmpty) {
    return symbolCandidates.first;
  }
  if (isSignBoard && signCandidates.isNotEmpty) {
    return signCandidates.first;
  }

  // Avoid sign letter screenshots as a last resort unless board is alphabet/letters
  final nonLetter = exactPool.where((c) {
    final lower = c.toLowerCase();
    return !lower.contains('16. letters') && !lower.contains('/alphabet/');
  }).toList();
  if (nonLetter.isNotEmpty) return nonLetter.first;

  return exactPool.first;
}

String? chooseImage(
  String label,
  Map<String, List<String>> assetMap,
  String boardName,
  Map<String, int> labelCounts,
) {
  // Direct matches only. Partial matching is disabled because it produced
  // too many false positives (e.g., "claw" matching the alphabet letter "a").
  var candidates = directMatches(label, assetMap);
  if (candidates == null || candidates.isEmpty) return null;

  final base = normalize(label);
  final count = labelCounts[base] ?? 0;
  labelCounts[base] = count + 1;

  // For duplicates, prefer suffixed files
  if (count > 0) {
    final suffixed = candidates.where((c) {
      final filename = c.split('/').last.split('.').first;
      return RegExp(r'\(\d+\)').hasMatch(filename) ||
          RegExp(r'\(one[^)]*\)|\(more[^)]*\)').hasMatch(filename);
    }).toList();
    if (suffixed.isNotEmpty) {
      candidates = suffixed;
    }
  }

  final best = pickBestMatch(label, candidates, boardName);
  if (best == null) return null;

  // For second/third duplicates, try to pick a different suffixed candidate if possible
  if (count > 0) {
    final others = candidates.where((c) => c != best && (c.contains('(') || c.contains(')'))).toList();
    if (others.isNotEmpty) {
      return pickBestMatch(label, others, boardName) ?? best;
    }
  }
  return best;
}

void processBoard(File file, Map<String, List<String>> assetMap) {
  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final boardName = (data['name'] as String?) ?? '';
  final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
  final labelCounts = <String, int>{};
  var changed = false;

  for (final tile in tiles) {
    final type = tile['type'] as String? ?? 'vocabulary';
    final label = (tile['label'] as String?) ?? '';

    if (type == 'blank' || label.isEmpty) continue;

    // Board link styling
    if (type == 'board_link') {
      if (tile['bgColor'] != '#000000' || tile['textColor'] != '#FFFFFF') {
        tile['bgColor'] = '#000000';
        tile['textColor'] = '#FFFFFF';
        changed = true;
      }
      continue; // don't try to find images for board links
    }

    // Full-screen styling
    final isFullScreen = (tile['isFullScreenImage'] as bool?) ?? false;
    if (isFullScreen) {
      if (tile['bgColor'] != '#FFCDD2' || tile['textColor'] != '#000000') {
        tile['bgColor'] = '#FFCDD2';
        tile['textColor'] = '#000000';
        changed = true;
      }
    }

    // Skip if image already exists and file is present
    final image = tile['image'] as String?;
    if (image != null && image.isNotEmpty) {
      final imageFile = File('$projectRoot/$image'.replaceAll('/', '\\'));
      if (imageFile.existsSync()) {
        continue;
      }
    }

    var searchLabel = label;
    if (searchLabel == '000)') searchLabel = '000';
    if (searchLabel == 'fog') searchLabel = 'foggy';

    // Special mappings: try both plain and disambiguated keys
    String? chosen;
    final plainKey = normalize(searchLabel);
    final disambiguatedKey = '$plainKey${labelCounts[plainKey] ?? 0 + 1}';
    if (specialMappings.containsKey(disambiguatedKey)) {
      final mapped = specialMappings[disambiguatedKey]!;
      if (File('$projectRoot/$mapped'.replaceAll('/', '\\')).existsSync()) {
        chosen = mapped;
      }
    }
    if (chosen == null && specialMappings.containsKey(plainKey)) {
      final mapped = specialMappings[plainKey]!;
      if (File('$projectRoot/$mapped'.replaceAll('/', '\\')).existsSync()) {
        chosen = mapped;
      }
    }

    chosen ??= chooseImage(searchLabel, assetMap, boardName, labelCounts);

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
