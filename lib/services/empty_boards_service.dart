import 'package:shared_preferences/shared_preferences.dart';

import '../data/board_index.dart';
import 'board_service.dart';

/// A board found to have 3 or fewer populated tiles during a scan.
class EmptyBoardEntry {
  final String id;
  final String name;
  final String area;
  final int tileCount;

  const EmptyBoardEntry({
    required this.id,
    required this.name,
    required this.area,
    required this.tileCount,
  });
}

/// Admin-only "to-do list" of boards that still need populating.
///
/// A scan of every known board is run the first time the list is requested
/// after an admin login (see [invalidate]); boards with 0-3 populated tiles
/// are surfaced. The result is then frozen for the rest of the session — a
/// board that gets filled in past 3 tiles deliberately stays on the list
/// until the app restarts (or the admin logs back in), so it can be visually
/// checked off rather than silently vanishing mid-session.
///
/// Boards that are intentionally small (e.g. a 2-tile board by design) can be
/// marked complete, which removes them immediately and keeps them excluded
/// from future scans until un-marked.
class EmptyBoardsService {
  EmptyBoardsService._();
  static final EmptyBoardsService instance = EmptyBoardsService._();

  static const _completedPrefsKey = 'admin_todo_completed_board_ids';
  static const int maxTilesForTodo = 3;

  SharedPreferences? _prefs;
  final Set<String> _completedIds = {};
  List<EmptyBoardEntry>? _cachedList;

  Future<void> _ensurePrefs() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _completedIds.addAll(_prefs!.getStringList(_completedPrefsKey) ?? const []);
  }

  /// Drops the frozen snapshot so the next [getList] call performs a fresh
  /// scan. Call this whenever an admin profile is (re)activated.
  void invalidate() {
    _cachedList = null;
  }

  bool get hasCachedList => _cachedList != null;

  Future<List<EmptyBoardEntry>> getList({bool forceRefresh = false}) async {
    await _ensurePrefs();
    if (_cachedList != null && !forceRefresh) return _cachedList!;

    final service = await BoardService.getInstance();

    final byId = <String, BoardIndexEntry>{};
    for (final entry in staticBoardIndex) {
      byId.putIfAbsent(entry.id, () => entry);
    }

    final candidateIds = byId.keys.where((id) => !_completedIds.contains(id)).toList();
    final results = <EmptyBoardEntry>[];

    // Fetch in small concurrent batches rather than all 900+ at once so we
    // don't flood the (possibly dev-server-backed) board loader.
    const batchSize = 20;
    for (var i = 0; i < candidateIds.length; i += batchSize) {
      final batch = candidateIds.skip(i).take(batchSize);
      final boards = await Future.wait(batch.map((id) => service.getBoard(id)));
      for (final board in boards) {
        if (board == null) continue;
        final tileCount = board.tiles
            .where((t) => t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty)
            .length;
        if (tileCount <= maxTilesForTodo) {
          final indexEntry = byId[board.id];
          results.add(EmptyBoardEntry(
            id: board.id,
            name: indexEntry?.name ?? board.name,
            area: indexEntry?.area ?? board.area,
            tileCount: tileCount,
          ));
        }
      }
    }

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cachedList = results;
    return results;
  }

  /// Marks a board as intentionally finished — removes it from the current
  /// list immediately and keeps it excluded from future scans.
  Future<void> markComplete(String boardId) async {
    await _ensurePrefs();
    if (_completedIds.add(boardId)) {
      await _prefs!.setStringList(_completedPrefsKey, _completedIds.toList());
    }
    _cachedList?.removeWhere((e) => e.id == boardId);
  }

  /// Un-marks a board, allowing it to reappear on the next scan if it still
  /// qualifies as sparse.
  Future<void> unmarkComplete(String boardId) async {
    await _ensurePrefs();
    if (_completedIds.remove(boardId)) {
      await _prefs!.setStringList(_completedPrefsKey, _completedIds.toList());
    }
  }
}
