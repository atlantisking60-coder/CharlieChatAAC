import 'dart:convert';
import 'dart:io';

void main() {
  final boardPath = r'C:\Users\Craig\Downloads\Charlie Chat\lib\data\boards\My School\prebuilt_lessons.json';
  final file = File(boardPath);
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final tiles = (data['tiles'] as List).cast<Map<String, dynamic>>();

  // Remove blank tiles
  final vocabTiles = tiles.where((t) => t['type'] != 'blank').toList();

  // Add new tiles if missing
  final newLabels = {
    'Health & Social Care': r'assets/symbols/Subjects/Health & Social Care.png',
    'Public Services': r'assets/symbols/Subjects/Public Services.png',
    'Design Technology': r'assets/symbols/Subjects/Design Technology.png',
  };
  final existingLabels = vocabTiles.map((t) => t['label'] as String?).toSet();
  for (final entry in newLabels.entries) {
    if (!existingLabels.contains(entry.key)) {
      vocabTiles.add({
        'id': 'prebuilt_lessons_t${vocabTiles.length + 1}',
        'type': 'vocabulary',
        'label': entry.key,
        'image': entry.value,
        'linkedBoardName': null,
      });
    }
  }

  // Image overrides
  final imageOverrides = {
    'PEEP': r'assets/symbols/Subjects/PEEP.png',
    'construction engineering': r'assets/symbols/Subjects/Construction.png',
    'P.E': r'assets/symbols/Subjects/P.E.png',
    'performing arts': r'assets/symbols/Subjects/Performing Arts.png',
    'resistant materials': r'assets/symbols/Subjects/Resistant Materials.png',
    'textiles': r'assets/symbols/Subjects/Textiles.png',
    'religion & worldviews': r'assets/symbols/Subjects/Religion & Worldviews.png',
    'sustainability': r'assets/symbols/Subjects/Sustainability.png',
    'cooking': r'assets/symbols/Subjects/Cooking.png',
    'horticulture': r'assets/symbols/Subjects/Horticulture.png',
    'retail': r'assets/symbols/Subjects/Retail.png',
    'photography': r'assets/symbols/Subjects/Photography.png',
    'living life skills': r'assets/symbols/Subjects/Living Life Skills.png',
    'prepare for adulthood': r'assets/symbols/Subjects/Prepare For Adulthood.png',
    'hair & beauty': r'assets/symbols/Subjects/Hair & Beauty.png',
    'information technology': r'assets/symbols/Subjects/I.T.png',
    'T.F.L': r'assets/symbols/Subjects/TFL.png',
    'english': r'assets/symbols/Subjects/English.png',
    'maths': r'assets/symbols/Subjects/Maths.png',
    'science': r'assets/symbols/Subjects/Science.png',
    'art': r'assets/symbols/Subjects/Art.png',
    'music': r'assets/symbols/Subjects/Music.png',
    'breaktime': r'assets/symbols/Subjects/Breaktime.png',
    'lunchtime': r'assets/symbols/Subjects/Lunchtime.png',
    'tutor time': r'assets/symbols/Subjects/Tutor Time.png',
    'personal development': r'assets/symbols/Subjects/P.D.png',
    'geography': r'assets/symbols/Subjects/Science.png',
    'history': r'assets/symbols/Subjects/PEEP.png',
    'languages': r'assets/symbols/Subjects/English.png',
    'EPIC': r'assets/symbols/Subjects/EPIC.png',
  };
  for (final t in vocabTiles) {
    final label = t['label'] as String?;
    if (label != null && imageOverrides.containsKey(label)) {
      t['image'] = imageOverrides[label];
    }
  }

  // Sort alphabetically by label
  vocabTiles.sort((a, b) => (a['label'] as String).toLowerCase().compareTo((b['label'] as String).toLowerCase()));

  // Reassign ids
  for (var i = 0; i < vocabTiles.length; i++) {
    vocabTiles[i]['id'] = 'prebuilt_lessons_t${i + 1}';
  }

  // Add blanks to fill grid
  final columns = data['columns'] as int;
  final layout = data['layout'] as Map<String, dynamic>;
  final rows = (layout['rows'] as num).toInt();
  final totalSlots = columns * rows;
  final neededBlanks = totalSlots - vocabTiles.length;

  final finalTiles = List<Map<String, dynamic>>.from(vocabTiles);
  for (var i = 0; i < neededBlanks; i++) {
    finalTiles.add({
      'id': 'prebuilt_lessons_blank_$i',
      'type': 'blank',
      'label': null,
      'image': null,
      'linkedBoardName': null,
    });
  }

  data['tiles'] = finalTiles;
  file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
}
