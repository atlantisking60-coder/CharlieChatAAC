import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';

class FavoritesService {
  static const _key = 'aac_favorites';
  final SharedPreferences _prefs;

  FavoritesService._(this._prefs);

  static Future<FavoritesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return FavoritesService._(prefs);
  }

  Set<String> get favorites =>
      _prefs.getStringList(_key)?.toSet() ?? <String>{};

  bool isFavorite(String id) => favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    final current = favorites;
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    final sorted = current.toList()..sort();
    await _prefs.setStringList(_key, sorted);
    await _recordSyncChange(sorted);
  }

  Future<void> _recordSyncChange(List<String> favoriteIds) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.favorites,
      entityId: 'default',
      operation: SyncOperation.upsert,
      payload: {'ids': favoriteIds},
    );
  }
}
