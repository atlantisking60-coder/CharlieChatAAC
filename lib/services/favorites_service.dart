import 'dart:async' show unawaited;
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';

class FavoritesService {
  // Use profile-specific keys for favorites so each profile has its own stash.
  // The profileId is injected at init time; keys are namespaced as
  // aac_favorites_<id> and aac_favourite_boards_<id>.
  final SharedPreferences _prefs;
  final String _profileId;

// Profile-specific keys for this service instance.
  String get _key => 'aac_favorites_$_profileId';
  String get _boardKey => 'aac_favourite_boards_$_profileId';

  FavoritesService._(this._prefs, this._profileId);

  static Future<FavoritesService> init({String profileId = 'default'}) async {
    final prefs = await SharedPreferences.getInstance();
    // Renamed Baycroft board: old ids now point at baycroft_people_at_baycroft.
    await _migrateBaycroftBoardFavourites(prefs, profileId);
    return FavoritesService._(prefs, profileId);
  }

  static Future<void> _migrateGlobalFavourites(SharedPreferences prefs, String profileId) async {
    // Migrate from old profile-specific keys to global keys
    final oldProfileKey = 'aac_favorites_$profileId';
    final oldProfileBoardKey = 'aac_favourite_boards_$profileId';
    
    final profileFavs = prefs.getStringList(oldProfileKey);
    if (profileFavs != null && profileFavs.isNotEmpty) {
      final existing = prefs.getStringList('aac_favorites_$profileId');
      final merged = {...?existing, ...profileFavs}.toList()..sort();
      await prefs.setStringList('aac_favorites_$profileId', merged);
      await prefs.remove(oldProfileKey);
    }
    
    final profileBoards = prefs.getStringList(oldProfileBoardKey);
    if (profileBoards != null && profileBoards.isNotEmpty) {
      final existing = prefs.getStringList('aac_favourite_boards_$profileId');
      final merged = {...?existing, ...profileBoards}.toList()..sort();
      await prefs.setStringList('aac_favourite_boards_$profileId', merged);
      await prefs.remove(oldProfileBoardKey);
    }
  }

  static Future<void> _migrateBaycroftBoardFavourites(SharedPreferences prefs, String profileId) async {
    // Remap old baycroft board ids within the profile-specific favourites list.
    final currentFavs = prefs.getStringList('aac_favorites_$profileId');
    if (currentFavs == null || currentFavs.isEmpty) return;
    const replacements = {
      'baycroft_people_at_school': 'baycroft_people_at_baycroft',
      'prebuilt_people_at_school': 'baycroft_people_at_baycroft',
      'prebuilt_people_at_baycroft': 'baycroft_people_at_baycroft',
      'prebuilt_my_school_main': 'baycroft_my_school_main',
      'prebuilt_baycroft_expects': 'baycroft_expects',
      'prebuilt_blank_levels': 'baycroft_blank_levels',
      'prebuilt_class_equipment': 'baycroft_class_equipment',
      'prebuilt_food_options': 'baycroft_food_options',
      'prebuilt_my_school_lessons': 'baycroft_my_school_lessons',
      'prebuilt_other_useful_stuff': 'baycroft_other_useful_stuff',
      'prebuilt_school_events': 'baycroft_school_events',
      'prebuilt_thinking_skills': 'baycroft_thinking_skills',
      'prebuilt_when_things_go_wrong': 'baycroft_when_things_go_wrong',
    };
    final remapped = currentFavs.map((b) => replacements[b] ?? b).toSet().toList()..sort();
    if (remapped.length != currentFavs.length ||
        remapped.any((b) => !currentFavs.contains(b))) {
      await prefs.setStringList('aac_favorites_$profileId', remapped);
    }
  }

  String get profileId => _profileId;

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
    // Record sync change in background to avoid blocking the UI
    unawaited(_recordSyncChange(sorted));
  }

  Set<String> get favoriteBoards =>
      _prefs.getStringList(_boardKey)?.toSet() ?? <String>{};

  bool isFavoriteBoard(String id) => favoriteBoards.contains(id);

  Future<void> toggleFavoriteBoard(String id) async {
    final current = favoriteBoards;
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    final sorted = current.toList()..sort();
    await _prefs.setStringList(_boardKey, sorted);
    // Record sync change in background to avoid blocking the UI
    unawaited(_recordBoardSyncChange(sorted));
  }

  Future<void> _recordSyncChange(List<String> favoriteIds) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.favorites,
      entityId: _profileId,
      operation: SyncOperation.upsert,
      payload: {'ids': favoriteIds},
    );
  }

  Future<void> _recordBoardSyncChange(List<String> favoriteBoardIds) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.favorites,
      entityId: '${_profileId}_boards',
      operation: SyncOperation.upsert,
      payload: {'ids': favoriteBoardIds},
    );
  }
}
