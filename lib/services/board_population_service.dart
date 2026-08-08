class BoardPopulationService {
  const BoardPopulationService();

  List<String> suggestWords({
    required String title,
    required String context,
    required int maxCount,
  }) {
    final input = '$title $context'.toLowerCase();
    final suggestions = <String>[
      ..._wordsForInput(input),
      ..._coreWords,
    ];

    final seen = <String>{};
    final result = <String>[];
    for (final word in suggestions) {
      final cleaned = _cleanLabel(word);
      if (cleaned.isEmpty) continue;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) {
        result.add(cleaned);
      }
      if (result.length >= maxCount) break;
    }
    return result;
  }

  List<String> parseWordList(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map(_cleanLabel)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  List<String> _wordsForInput(String input) {
    final words = <String>[];
    for (final entry in _topicWords.entries) {
      if (input.contains(entry.key)) {
        words.addAll(entry.value);
      }
    }
    return words;
  }

  String _cleanLabel(String value) {
    return value.trim().toLowerCase();
  }
}

const _coreWords = <String>[
  'i',
  'you',
  'want',
  'need',
  'like',
  'do',
  'go',
  'more',
  'finished',
  'help',
  'yes',
  'no',
  'stop',
  'look',
  'listen',
  'where',
  'who',
  'what',
  'when',
  'why',
];

const _topicWords = <String, List<String>>{
  'animal': [
    'dog',
    'cat',
    'horse',
    'bird',
    'fish',
    'rabbit',
    'cow',
    'sheep',
  ],
  'colour': [
    'red',
    'blue',
    'green',
    'yellow',
    'black',
    'white',
    'orange',
    'purple',
  ],
  'color': [
    'red',
    'blue',
    'green',
    'yellow',
    'black',
    'white',
    'orange',
    'purple',
  ],
  'feeling': [
    'happy',
    'sad',
    'angry',
    'worried',
    'excited',
    'tired',
    'calm',
    'scared',
  ],
  'lesson': [
    'teacher',
    'learn',
    'question',
    'answer',
    'read',
    'write',
    'listen',
    'finished',
  ],
  'school': [
    'teacher',
    'friend',
    'class',
    'desk',
    'book',
    'pencil',
    'playground',
    'lunch',
  ],
  'weather': [
    'sunny',
    'rain',
    'cloudy',
    'windy',
    'cold',
    'hot',
    'snow',
    'storm',
  ],
};
