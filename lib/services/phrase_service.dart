import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';

class PhraseHistoryService {
  static const _historyKey = 'aac_phrase_history';
  static const _maxHistory = 12;
  final SharedPreferences _prefs;

  PhraseHistoryService._(this._prefs);

  static Future<PhraseHistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PhraseHistoryService._(prefs);
  }

  List<String> get history {
    final saved = _prefs.getStringList(_historyKey) ?? <String>[];
    return saved.reversed.toList();
  }

  Future<void> addPhrase(String phrase) async {
    final current = _prefs.getStringList(_historyKey) ?? <String>[];
    current.remove(phrase);
    current.add(phrase);
    while (current.length > _maxHistory) {
      current.removeAt(0);
    }
    await _prefs.setStringList(_historyKey, current);
    await _recordSyncChange(SyncOperation.upsert);
  }

  Future<void> removePhrase(String phrase) async {
    final current = _prefs.getStringList(_historyKey) ?? <String>[];
    current.removeWhere((item) => item == phrase);
    await _prefs.setStringList(_historyKey, current);
    await _recordSyncChange(SyncOperation.upsert);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
    await _recordSyncChange(SyncOperation.clear);
  }

  Future<void> _recordSyncChange(SyncOperation operation) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.phraseHistory,
      entityId: 'default',
      operation: operation,
      payload: {'history': _prefs.getStringList(_historyKey) ?? <String>[]},
    );
  }
}
