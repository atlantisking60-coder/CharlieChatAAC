import 'dart:async' show Completer, unawaited;
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/board_hierarchy.dart';
import '../models/symbol_tile.dart';
import 'external_symbol_service.dart';
import 'symbol_metadata_service.dart';
import 'sync_service.dart';

part 'generate_boards_json.dart';

/// DATA STORAGE ENGINE
/// This service handles how boards are saved and loaded. 
/// It automatically detects if it's on Web (Browser Storage) 
/// or Native (Real File System).


const int defaultBoardColumns = 5;
const int defaultBoardRows = 6;
const String defaultBoardColor = 'transparent';
const String lightGreenBoardColor = '#90EE90';
const String darkBlueBoardColor = '#1E3A8A';

/// Prebuilt board names — derived from the single-source hierarchy.
/// This list is kept for backward compatibility with code that references
/// [prebuiltBoardNames] directly. The authoritative source of truth is
/// [runtimeBoardHierarchy] — the compiled const merged with any admin edits
/// persisted in SharedPreferences.  User-created entries are per-user and
/// not included here — they are tracked separately in the user's hierarchy doc.
List<String> get prebuiltBoardNames {
  final names = runtimeBoardHierarchy.map((e) => e.name).toList();
  final seen = <String>{};
  return names.where((n) => seen.add(n)).toList();
}

const Set<String> lightGreenPrebuiltBoards = {
  // Previously contained My School / Subject Vocab boards; now all areas use the default background.
};

const Set<String> darkBluePrebuiltBoards = {
  // All boards now use transparent background
};

const Set<String> _retiredBoardIds = {
  'prebuilt_new_board',
  'prebuilt_adjectives',
  'prebuilt_rooms_home',
  'prebuilt_events_occasions',
  'prebuilt_habitats_science',
};

String prebuiltBoardId(String name) {
  if (name.toLowerCase() == 'a-z of sign' || name.toLowerCase() == 'a-z of sign') {
    return 'prebuilt_a-z_of_sign';
  }
  return 'prebuilt_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';
}

class Board {
  String id;
  String name;
  String area;
  String? parentBoardId;
  String? linkedBoardId;
  int rows;
  int columns;
  bool adjustableLayout;
  double boxScale;
  double tileHeight;
  double tileWidth;
  String backgroundColor;
  List<SymbolTile> tiles;
  bool isSubBoard;
  bool isTertiaryBoard;
  bool isQuaternaryBoard;
  bool isQuinaryBoard;
  int sortOrder;
  int tier; // Tier 1 (Main) to 5 (Quinary)
  String? iconAssetPath;
  int version;

  Board({
    required this.id,
    required this.name,
    this.area = 'Common',
    this.parentBoardId,
    this.linkedBoardId,
    required this.rows,
    required this.columns,
    required this.tiles,
    this.adjustableLayout = false,
    this.boxScale = 1.0,
    this.tileHeight = 100.0,
    this.tileWidth = 100.0,
    this.backgroundColor = defaultBoardColor,
    this.isSubBoard = false,
    this.isTertiaryBoard = false,
    this.isQuaternaryBoard = false,
    this.isQuinaryBoard = false,
    this.sortOrder = 0,
    this.tier = 1,
    this.iconAssetPath,
    this.version = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'area': area,
        'parentBoardId': parentBoardId,
        'linkedBoardId': linkedBoardId,
        'rows': rows,
        'columns': columns,
        'adjustableLayout': adjustableLayout,
        'boxScale': boxScale,
        'tileHeight': tileHeight,
        'tileWidth': tileWidth,
        'backgroundColor': backgroundColor,
        'tiles': tiles.map((t) => t.toMap()).toList(),
        'isSubBoard': isSubBoard,
        'isTertiaryBoard': isTertiaryBoard,
        'isQuaternaryBoard': isQuaternaryBoard,
        'isQuinaryBoard': isQuinaryBoard,
        'sortOrder': sortOrder,
        'tier': tier,
        'iconAssetPath': iconAssetPath,
        'version': version,
      };

  factory Board.fromMap(Map<String, dynamic> m, {bool includeTiles = true}) => Board(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Board',
        area: m['area'] ?? 'Common',
        parentBoardId: m['parentBoardId'] as String?,
        linkedBoardId: m['linkedBoardId'] as String?,
        rows: m['rows'] ?? defaultBoardRows,
        columns: m['columns'] ?? defaultBoardColumns,
        adjustableLayout: m['adjustableLayout'] ?? false,
        boxScale:
            (m['boxScale'] is num) ? (m['boxScale'] as num).toDouble() : 1.0,
        tileHeight:
            (m['tileHeight'] is num) ? (m['tileHeight'] as num).toDouble() : 100.0,
        tileWidth:
            (m['tileWidth'] is num) ? (m['tileWidth'] as num).toDouble() : 100.0,
        backgroundColor: m['backgroundColor'] ?? defaultBoardColor,
        tiles: includeTiles
            ? ((m['tiles'] as List<dynamic>?)
                    ?.map((e) => SymbolTile.fromMap(Map<String, dynamic>.from(e)))
                    .toList() ??
                [])
            : [],
        isSubBoard: m['isSubBoard'] ?? false,
        isTertiaryBoard: m['isTertiaryBoard'] ?? false,
        isQuaternaryBoard: m['isQuaternaryBoard'] ?? false,
        isQuinaryBoard: m['isQuinaryBoard'] ?? false,
        sortOrder: m['sortOrder'] ?? 0,
        tier: m['tier'] ?? ((m['isQuinaryBoard'] ?? false) ? 5 : ((m['isQuaternaryBoard'] ?? false) ? 4 : ((m['isTertiaryBoard'] ?? false) ? 3 : ((m['isSubBoard'] ?? false) ? 2 : 1)))), 
        iconAssetPath: m['iconAssetPath'] as String?,
        version: (m['version'] as num?)?.toInt() ?? 0,
      );
}

class BoardService {
  static BoardService? _instance;
  static BoardService? get current => _instance;
  Directory? _dataDir;
  SharedPreferences? _prefs;
  late SharedPreferences _deletionPrefs;
  final Set<String> _deletedBoardIds = {};
  String? _projectRoot;
  String? _rawProfileId;
  String? _currentProfileId;
  bool _isAdmin = false;

  BoardService._();

  static Future<BoardService> getInstance({String? projectRoot}) async {
    if (_instance != null) {
      if (projectRoot != null) _instance!._projectRoot = projectRoot;
      return _instance!;
    }
    final s = BoardService._();
    if (projectRoot != null) s._projectRoot = projectRoot;
    await s._init();
    _instance = s;
    return s;
  }

  bool _hasSyncedDevBoards = false;

  void setCurrentProfileId(String profileId) {
    // Store the raw (original) profile ID for board ID prefixing.
    _rawProfileId = profileId;

    // Both 'admin' and 'default' profiles share the 'default' board database.
    if (profileId == 'admin' || profileId == 'default' || profileId.toLowerCase() == 'default') {
      _currentProfileId = 'default';
    } else {
      _currentProfileId = profileId;
    }
    _isAdmin = profileId == 'admin';
    
    // Trigger dev sync for this profile if not already done
    if (kIsWeb && Uri.base.host == 'localhost' && !_hasSyncedDevBoards) {
      _hasSyncedDevBoards = true;
      _syncDevBoards();
    }
  }

  /// Returns the raw profile ID before the admin/default mapping.
  /// Used for board ID prefixing (e.g. 'admin', 'craig', 'default').
  String get rawProfileId => _rawProfileId ?? 'default';

  /// Returns the mapped profile ID (admin→default, others unchanged).
  String get currentProfileId => _currentProfileId ?? 'default';

  /// Returns true if the current profile is the admin profile.
  bool get isAdmin => _isAdmin;

  /// If set, this board will be loaded before other prebuilt boards during startup.
  String? _priorityBoardId;

  /// Mark a board as the user's chosen priority so it loads first.
  void setPriorityBoardId(String id) => _priorityBoardId = id;

  Future<void> _syncDevBoards() async {
    // On web, the dev server is accessed on-demand by _loadBoard/_loadBoardFromAssets.
    // Bulk-syncing all boards here overwhelms localStorage and is unnecessary.
    if (kIsWeb) return;
    try {
      final uri = Uri.parse('http://localhost:8787/listBoards');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> allBoards = json.decode(response.body);
        for (final b in allBoards) {
          final board = _boardFromJson(b as Map<String, dynamic>);
          if (_deletedBoardIds.contains(board.id)) continue;
          // Always refresh boards from dev server to ensure latest images
          await _writeBoard(board, mirrorToDisk: false, cacheInWebStorage: !board.id.startsWith('prebuilt_'));
        }
        debugPrint('Dev Sync: Updated $_currentProfileId profile with ${allBoards.length} boards from disk.');
      }
    } catch (e) {
      debugPrint('Dev Sync Error: $e');
    }
  }

  String _getBoardKey(String boardId) {
    return 'board_${_currentProfileId ?? 'default'}_$boardId';
  }

  String _getSortOrderKey(String boardId) {
    return 'board_sortorder_${_currentProfileId ?? 'default'}_$boardId';
  }

  Future<void> _saveSortOrder(Board board) async {
    if (_prefs == null) return;
    await _prefs!.setInt(_getSortOrderKey(board.id), board.sortOrder);
  }

  String _getTabOrderKey(String area) {
    return 'board_taborder_${_currentProfileId ?? 'default'}_$area';
  }

  List<String>? getTabOrder(String area) {
    if (_prefs == null) return null;
    final raw = _prefs!.getString(_getTabOrderKey(area));
    if (raw == null || raw.isEmpty) return null;
    try {
      return (json.decode(raw) as List).cast<String>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTabOrder(String area, List<String> names) async {
    if (_prefs == null) return;
    await _prefs!.setString(_getTabOrderKey(area), json.encode(names));
  }

  Future<void> clearTabOrder(String area) async {
    if (_prefs == null) return;
    await _prefs!.remove(_getTabOrderKey(area));
  }

  /// STORAGE INITIALIZATION
/// On Web: Uses SharedPreferences (Browser storage).
/// On Native: Uses getApplicationDocumentsDirectory (Local folder).

  Future<void> _init() async {
    if (!kIsWeb && _projectRoot == null) {
      var candidateRoot = Directory.current;
      while (true) {
        final localBoards = Directory(
          p.join(candidateRoot.path, 'lib', 'data', 'boards'),
        );
        if (await localBoards.exists()) {
          _projectRoot = candidateRoot.path;
          break;
        }
        final parent = candidateRoot.parent;
        if (p.equals(parent.path, candidateRoot.path)) break;
        candidateRoot = parent;
      }
    }
    _deletionPrefs = await SharedPreferences.getInstance();
    _deletedBoardIds.addAll(
      _deletionPrefs.getStringList('deleted_board_ids_v2') ?? const [],
    );
    // Recover any prebuilt boards that were auto-deleted by the duplicate-name
    // bug. Only genuinely retired prebuilt IDs should stay deleted.
    final recovered = _deletedBoardIds
        .where((id) => id.startsWith('prebuilt_') && !_retiredBoardIds.contains(id))
        .toSet();
    if (recovered.isNotEmpty) {
      _deletedBoardIds.removeAll(recovered);
      await _deletionPrefs.setStringList(
        'deleted_board_ids_v2',
        _deletedBoardIds.toList(),
      );
    }
    if (kIsWeb) {
      _prefs = _deletionPrefs;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _dataDir = Directory('${dir.path}/boards');
      if (!await _dataDir!.exists()) {
        await _dataDir!.create(recursive: true);
      }
    }

    // Deleted-boards list is persistent. Never clear it on startup — doing
    // so caused deleted boards to reappear from assets on every launch.
    // The old _initializeEmptyBoardLibrary reset is no longer needed.

    // Load hierarchy: runtime (static + admin edits) + user entries.
    // Runs on ALL platforms so web and native present identically.
    {
      await loadRuntimeHierarchy();
      final userId = _currentProfileId ?? 'default';
      await loadUserCustomHierarchyEntries(userId);
      await ensureEmptyUserHierarchy(userId);
    }

    // Retire any boards that should never be loaded before we populate from assets.
    await retireSpecifiedBoards();

    await _initializeEmptyBoardLibrary();
    await _clearAccidentallyPopulatedPhonicsBoards();

    // Ensure prebuilt boards are loaded from JSON assets into storage.
    // Runs on ALL platforms so web and native present identically.
    await _ensurePrebuiltBoards();
    await _ensureProjectBoardsFromAssets();
    await fixSignBoards();
    await fixStaleBoardLinks();
    await _removeDuplicateNameBoards();
  }

  /// Remove any boards that share a name with another board, keeping the one
  /// with the most tiles (or the prebuilt one if tile counts are equal).
  Future<void> _removeDuplicateNameBoards() async {
    try {
      final boards = await listBoards();
      final byName = <String, List<Board>>{};
      for (final b in boards) {
        byName.putIfAbsent(b.name.toLowerCase(), () => []).add(b);
      }
      for (final entry in byName.entries) {
        if (entry.value.length <= 1) continue;
        // Keep the board with the most tiles; prefer prebuilt IDs on ties
        entry.value.sort((a, b) {
          final tileCmp = b.tiles.length.compareTo(a.tiles.length);
          if (tileCmp != 0) return tileCmp;
          final aPrebuilt = a.id.startsWith('prebuilt_') ? 1 : 0;
          final bPrebuilt = b.id.startsWith('prebuilt_') ? 1 : 0;
          return bPrebuilt.compareTo(aPrebuilt);
        });
        for (final dup in entry.value.skip(1)) {
          if (dup.id.startsWith('prebuilt_')) {
            debugPrint('Skipping prebuilt duplicate "${dup.name}" (id: ${dup.id})');
            continue;
          }
          debugPrint('Removing duplicate board "${dup.name}" (id: ${dup.id})');
          await deleteBoard(dup.id);
        }
      }
    } catch (_) {}
  }

  Future<void> _clearAccidentallyPopulatedPhonicsBoards() async {
    return; // Disabled — phonics boards now intentionally populated with correct images
  }

  Future<void> _initializeEmptyBoardLibrary() async {
    return; // Disabled — boards are now intentionally populated
  }

  Future<void> retireSpecifiedBoards() async {
    for (final id in _retiredBoardIds) {
      // Mark as deleted first so later loading steps skip it even if it doesn't exist in storage yet.
      await _markBoardDeleted(id);
      if (await loadBoard(id) != null) await deleteBoard(id);
    }
  }

  Future<void> _markBoardDeleted(String id) async {
    if (_deletedBoardIds.add(id)) {
      await _deletionPrefs.setStringList(
        'deleted_board_ids_v2',
        _deletedBoardIds.toList(),
      );
    }
  }

  Future<void> _clearBoardDeletion(String id) async {
    if (_deletedBoardIds.remove(id)) {
      await _deletionPrefs.setStringList(
        'deleted_board_ids_v2',
        _deletedBoardIds.toList(),
      );
    }
  }

  /// Ensures all '[Letter] (Sign)' boards are correctly assigned to the Sign area
  /// and marked as sub-boards of 'A-Z Of Sign'.
  Future<void> fixSignBoards() async {
    final boards = await listBoards();
    final signParentId = prebuiltBoardId('A-Z Of Sign');
    for (final board in boards) {
      if (board.name.contains('(Sign)')) {
        var changed = false;
        if (board.area != 'Sign') {
          board.area = 'Sign';
          changed = true;
        }
        // All '[letter] (Sign)' are sub-boards, except the A-Z main index itself
        if (board.name != 'A-Z Of Sign' && board.name != 'A to Z Of Sign' && board.name.contains('(Sign)')) {
          if (!board.isSubBoard) {
            board.isSubBoard = true;
            changed = true;
          }
          if (board.parentBoardId != signParentId) {
            board.parentBoardId = signParentId;
            changed = true;
          }
          if (board.tier != 2) {
            board.tier = 2;
            changed = true;
          }
        }
        if (changed) {
          await _writeBoard(board);
        }
      }
    }
  }

  /// Undo the old light-green background that was applied to My School / Sign /
  /// Subject Vocab boards. Any board still stored with that colour is reset to
  /// the default transparent background.
  Future<void> resetGreenBoardBackgrounds() async {
    final boards = await listBoards();
    for (final board in boards) {
      if (board.backgroundColor.toLowerCase() == lightGreenBoardColor.toLowerCase()) {
        board.backgroundColor = defaultBoardColor;
        await _writeBoard(board);
      }
    }
  }

  /// Fix any board-link tiles that still point to the deleted 'Common' board.
  /// Redirect them to a board whose name matches the tile label.
  Future<void> fixStaleBoardLinks() async {
    final oldCommonId = prebuiltBoardId('Common');
    final boards = await listBoards();
    for (final board in boards) {
      var changed = false;
      for (final tile in board.tiles) {
        if (tile.isBoardLink && tile.linkedBoardId == oldCommonId) {
          // Try to find a board matching the tile label
          final targetName = tile.label;
          var targetId = prebuiltBoardId(targetName);
          // If no exact prebuilt board, see if any board name matches the label
          for (final b in boards) {
            if (b.name.toLowerCase() == targetName.toLowerCase()) {
              targetId = b.id;
              break;
            }
          }
          tile.linkedBoardId = targetId;
          changed = true;
        }
      }
      if (changed) {
        await _writeBoard(board);
      }
    }
  }

  /// Create empty subboards for any board-link tiles that point to a missing board.
  Future<void> _ensureMissingSubboards() async {
    final boards = await listBoards();
    final existingIds = boards.map((b) => b.id).toSet();
    final created = <String>[];
    for (final board in boards) {
      for (final tile in board.tiles) {
        if (!tile.isBoardLink) continue;
        final targetId = tile.linkedBoardId;
        if (targetId.isEmpty ||
            existingIds.contains(targetId) ||
            _deletedBoardIds.contains(targetId)) {
          continue;
        }
        final targetName = tile.label.isNotEmpty ? tile.label : _nameFromBoardId(targetId);
        final newBoard = Board(
          id: targetId,
          name: targetName,
          rows: defaultBoardRows,
          columns: defaultBoardColumns,
          adjustableLayout: true,
          backgroundColor: defaultBoardColor,
          tiles: List.generate(
            defaultBoardRows * defaultBoardColumns,
            (index) => SymbolTile(
              id: 'tile_$index',
              label: '',
              category: targetName,
              imageAsset: '',
              bgColor: 'transparent',
              textColor: '#000000',
            ),
          ),
          isSubBoard: true,
        );
        await _writeBoard(newBoard);
        existingIds.add(targetId);
        created.add(targetName);
      }
    }
    if (created.isNotEmpty) {
      debugPrint('Created missing subboards: ${created.join(', ')}');
    }
  }

  String _nameFromBoardId(String id) {
    if (id.startsWith('prebuilt_')) {
      id = id.substring('prebuilt_'.length);
    }
    return id.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  // Legacy Small Words migration removed to avoid touching non-existent boards.

/// DEVELOPER SYNC SETTING
/// This allows the Desktop app to talk directly to your 
/// source code folder.

  void setProjectRoot(String? path) {
    if (path != null && path.isNotEmpty) {
      _projectRoot = path;
    }
  }

/// PREBUILT LOADER
/// This runs on the very first launch. It checks if the basic 
/// boards (Letters, Numbers, etc.) exist, and if not, creates 
/// them from the local asset folders.

  /// Whether [name] is one of the grammar sub-boards nested under Small Words.
  bool _isSmallWordsSub(String name) {
    return runtimeBoardHierarchy.any(
      (e) => e.name == name && e.parentName == 'Small Words',
    );
  }

  Future<void> _ensurePrebuiltBoards() async {
    // If a priority board has been chosen, load it first so the user sees it
    // while the rest of the prebuilt boards load in the background.
    String? priorityName;
    if (_priorityBoardId != null) {
      for (final n in prebuiltBoardNames) {
        if (prebuiltBoardId(n) == _priorityBoardId) {
          priorityName = n;
          break;
        }
      }
    }
    final orderedNames = priorityName != null
        ? [priorityName, ...prebuiltBoardNames.where((n) => n != priorityName)]
        : prebuiltBoardNames.toList();

    // Small Words grammar sub-boards are loaded last.
    final rest = orderedNames.skip(1).toList();
    rest.sort((a, b) {
      final aSub = _isSmallWordsSub(a);
      final bSub = _isSmallWordsSub(b);
      if (aSub == bSub) return 0;
      return aSub ? 1 : -1;
    });
    final sortedNames = [orderedNames.first, ...rest];

    final Future<void> Function(String) loadOne = (name) async {
      final id = prebuiltBoardId(name);
      if (_deletedBoardIds.contains(id)) return;
      final key = _getBoardKey(id);
      
      bool exists = false;
      bool hasImages = true;
      if (kIsWeb) {
        final raw = _prefs!.getString(key);
        exists = raw != null;
        if (exists) {
          try {
            final m = json.decode(raw) as Map<String, dynamic>;
            final tiles = m['tiles'] as List<dynamic>? ?? [];
            final tilesWithImages = tiles.where((t) {
              final img = t['image'] as String? ?? t['imageAsset'] as String? ?? '';
              return img.isNotEmpty && img.startsWith('assets/');
            }).length;
            hasImages = tilesWithImages > tiles.length * 0.5;
          } catch (_) {}
        }
      } else {
        final f = File('${_dataDir!.path}/$key.json');
        exists = await f.exists();
        if (exists) {
          try {
            final raw = await f.readAsString();
            final m = json.decode(raw) as Map<String, dynamic>;
            final tiles = m['tiles'] as List<dynamic>? ?? [];
            // Check not just that paths start with assets/, but that files exist on disk
            final ratio = _imageFileExistenceRatio(tiles);
            hasImages = ratio > 0.5;
          } catch (_) {}
        }
      }

      // In native dev mode (projectRoot set), always reload from disk JSON
      // so edits to JSON files take effect on next launch without manual cache clearing.
      File? diskJsonFile;
      if (!kIsWeb && _projectRoot != null) {
        diskJsonFile = await _findProjectJsonFile(id);
      }
      final hasDiskJson = diskJsonFile != null;
      
      // If board exists AND has images AND no disk JSON override, skip reload
      // EXCEPTION: Always ensure 'Disney Stories' board is checked (to allow population)
      if (exists && hasImages && !hasDiskJson && name != 'Disney Stories') return;

      // Board is missing, has no images, or disk JSON is newer — reload from source
      if (exists && !hasImages) {
        debugPrint('Board "$name" exists but has missing images — reloading from source');
      } else if (hasDiskJson) {
        debugPrint('Board "$name" reloading from on-disk JSON (dev mode)');
      }

      // 1. Try to load from canonical lib/data/boards/[Area] JSON source (Dev Mode)
      // On Web, we fetch from the local dev server.
      if (kIsWeb && Uri.base.host == 'localhost') {
        try {
          final area = _areaForBoardName(name);
          final uri = Uri.parse('http://localhost:8787/loadBoard?id=$id&area=$area');
          final response = await http.get(uri).timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
             final board = _boardFromJson(json.decode(response.body) as Map<String, dynamic>);
             await _writeBoard(board, mirrorToDisk: false, cacheInWebStorage: false);
             _boardCache[board.id] = board;
             return;
          }
        } catch (_) {}
      }

      // On native dev mode, always prefer the on-disk JSON over cached storage
      if (diskJsonFile != null) {
        try {
          final raw = await diskJsonFile.readAsString();
          final board = _boardFromJson(json.decode(raw) as Map<String, dynamic>);
          // We load from disk, but we DON'T mirror it back to disk (it's already there)
          await _writeBoard(board, mirrorToDisk: false);
          _boardCache[board.id] = board;
          return;
        } catch (e) {
          debugPrint('Error loading board $name from JSON: $e');
        }
      }

      // 2. Try to load from App Assets (Production Mode)
      final assetBoard = await _loadBoardFromAssets(id, name);
      if (assetBoard != null) {
        await _writeBoard(assetBoard, mirrorToDisk: false, cacheInWebStorage: false);
        _boardCache[assetBoard.id] = assetBoard;
        return;
      }

      // All refresh sources failed but board already exists in storage.
      // EXCEPTION: Re-populate Disney Stories if it has fewer than 71 movies
      if (exists) {
          if (name == 'Disney Stories') {
              final stored = await loadBoard(id);
              if (stored != null && (stored.tiles.where((t) => t.isBoardLink).length < 71 || stored.tiles.isEmpty)) {
                  // Fall through to population logic
              } else {
                  return;
              }
          } else {
              return;
          }
      }

      final backgroundColor = darkBluePrebuiltBoards.contains(name)
          ? darkBlueBoardColor
          : lightGreenPrebuiltBoards.contains(name)
              ? lightGreenBoardColor
              : defaultBoardColor;
      
/// POPULATING CORE BOARDS
/// This logic looks at the boards you asked to be pre-filled
/// and generates the tile list using paths in your assets folder.

      List<SymbolTile> initialTiles = _generateMainBoardTiles(name);
      if (false) { // auto-populate disabled
      if (name == 'Letters' || name == 'Letters (Subject)') {
        initialTiles = _generateAlphabetTiles();
      } else if (name == 'Numbers' || name == 'Numbers (Subject)') {
        initialTiles = _generateNumberTiles();
      } else if (name == 'Small Words (Subject)') {
          final assetBoard = await _loadBoardFromAssets('prebuilt_small_words', 'Small Words');
          if (assetBoard != null) {
              initialTiles = assetBoard.tiles;
          }
      } else if (name == 'Subject Vocabulary') {
          initialTiles = _generateSubjectVocabularyTiles();
      } else if (name == 'Colours') {
        initialTiles = _generateColourTiles();
      } else if (name == 'Common Words') {
        initialTiles = _generateCommonWordsTiles();
      } else if (name == 'Feelings') {
        initialTiles = _generateFeelingsTiles();
      } else if (name == 'Sad') {
        initialTiles = _generateSadTiles();
      } else if (name == 'Mad') {
        initialTiles = _generateMadTiles();
      } else if (name == 'Scared') {
        initialTiles = _generateScaredTiles();
      } else if (name == 'Joyful') {
        initialTiles = _generateJoyfulTiles();
      } else if (name == 'Strong') {
        initialTiles = _generateStrongTiles();
      } else if (name == 'Calm') {
        initialTiles = _generateCalmTiles();
      } else if (name == 'Shades Of Colours') {
        initialTiles = _generateShadesOfColoursTiles();
      } else if (name == 'Prepositions') {
        initialTiles = _generatePrepositionsTiles();
      } else if (name == 'People') {
        initialTiles = _generatePeopleTiles();
      } else if (name == 'School People') {
        initialTiles = _generateSchoolPeopleTiles();
      } else if (name == 'Animals') {
        initialTiles = _generateAnimalsTiles();
      } else if (name == 'Mammals') {
        initialTiles = _generateMammalsTiles();
      } else if (name == 'Birds') {
        initialTiles = _generateBirdsTiles();
      } else if (name == 'Reptiles') {
        initialTiles = _generateReptilesTiles();
      } else if (name == 'Amphibians') {
        initialTiles = _generateAmphibiansTiles();
      } else if (name == 'Insects') {
        initialTiles = _generateInsectsTiles();
      } else if (name == 'Arachnids') {
        initialTiles = _generateArachnidsTiles();
      } else if (name == 'Invertebrates') {
        initialTiles = _generateInvertebratesTiles();
      } else if (name == 'Fish') {
        initialTiles = _generateFishTiles();
      } else if (name == 'Habitats') {
        initialTiles = _generateHabitatsTiles();
      } else if (name == 'Sealife') {
        initialTiles = _generateSealifeTiles();
      } else if (name == 'Nature Vocabulary') {
        initialTiles = _generateNatureVocabularyTiles();
      } else if (name == 'Body Parts of Animals') {
        initialTiles = _generateBodyPartsOfAnimalsTiles();
      } else if (name == 'Child Animals') {
        initialTiles = _generateChildAnimalsTiles();
      } else if (name == 'Groups of Animals') {
        initialTiles = _generateGroupsOfAnimalsTiles();
      } else if (name == 'Common Actions') {
        initialTiles = _generateCommonActionsTiles();
      } else if (name == 'Movement') {
        initialTiles = _generateMovementTiles();
      } else if (name == 'Buildings') {
        initialTiles = _generateBuildingsTiles();
      } else if (name == 'Rooms and Home') {
        initialTiles = _generateRoomsAndHomeTiles();
      } else if (name == 'Furniture') {
        initialTiles = _generateFurnitureTiles();
      } else if (name == 'Local Places') {
        initialTiles = _generateLocalPlacesTiles();
      } else if (name == 'Jobs and Careers') {
        initialTiles = _generateJobsAndCareersTiles();
      } else if (name == 'Weather') {
        initialTiles = _generateWeatherTiles();
      } else if (name == 'Disasters') {
        initialTiles = _generateDisastersTiles();
      } else if (name == 'Seasons') {
        initialTiles = _generateSeasonsTiles();
      } else if (name == 'Events and Occasions') {
        initialTiles = _generateEventsAndOccasionsTiles();
      } else if (name == 'Body Parts') {
        initialTiles = _generateBodyPartsTiles();
      } else if (name == 'Medical') {
        initialTiles = _generateMedicalTiles();
      } else if (name == 'Internal Organs') {
        initialTiles = _generateInternalOrgansTiles();
      } else if (name == 'Time (Clocks)') {
        initialTiles = _generateTimeClocksTiles();
      } else if (name == 'Months') {
        initialTiles = _generateMonthsTiles();
      } else if (name == 'Class Equipment') {
        initialTiles = _generateClassEquipmentTiles();
      } else if (name == 'Thinking Skills') {
        initialTiles = _generateThinkingSkillsTiles();
      } else if (name == 'When Things Go Wrong') {
        initialTiles = _generateWhenThingsGoWrongTiles();
      } else if (name == 'Lessons') {
        initialTiles = _generateLessonsTiles();
      } else if (name == 'Tutor Timetables') {
        initialTiles = _generateTutorTimetablesTiles();
      } else if (name == 'People At School') {
        initialTiles = _generatePeopleAtSchoolTiles();
      } else if (name == 'Baycroft Expects') {
        initialTiles = _generateBaycroftExpectsTiles();
      } else if (name == 'Actions') {
        initialTiles = _generateActionsTiles();
      } else if (name == 'Disney Stories') {
        initialTiles = _generateDisneyStoriesTiles();
      } else if (name == 'Phonics') {
        initialTiles = _generatePhonicsTiles();
      } else if (name == 'Phase 2 Phonics') {
        initialTiles = _generatePhase2PhonicsTiles();
      }
      } // end auto-populate disabled

      // Determine if this is a sub-board or tertiary board from the hierarchy
      final isTertiaryBoard = hierarchyTier(name) >= 3;
      final isSubBoard = hierarchyIsSubBoard(name);

      // Determine column count based on board name (from Excel COLUMNS field)
      int columns = defaultBoardColumns;
      if (name == 'Prepositions') {
        columns = 7;
      } else if (name == 'Shades Of Colours') {
        columns = 3;
      } else if (name == 'Sad' || name == 'Mad' || name == 'Scared' || name == 'Joyful' ||
                 name == 'Strong' || name == 'Calm') {
        columns = 4;
      } else if (name == 'Letters' || name == 'Numbers') {
        columns = 5;
      } else if (name == 'Common Words' || name == 'Feelings' || name == 'Colours') {
        columns = 6;
      }

      int rows = defaultBoardRows;
      if (name == 'Common Words') {
        rows = 8;
      } else if (name == 'Feelings') {
        rows = 7;
      } else if (name == 'Prepositions') {
        rows = 9;
      }

      // Turn OFF adjustable layout for specified boards (fixed grid)
      final fixedLayoutBoards = {
        'Feelings', 'Prepositions', 'Colours', 'Shades Of Colours',
        'Letters', 'Numbers',
        'Sad', 'Mad', 'Scared', 'Joyful', 'Strong', 'Calm',
      };
      final useFixedLayout = fixedLayoutBoards.contains(name);
      
      // Determine parent ID from the hierarchy (authoritative).
      String? parentId = hierarchyParentId(name);

      final board = Board(
        id: id,
        name: name,
        area: _areaForBoardName(name),
        rows: rows,
        columns: columns,
        parentBoardId: parentId,
        adjustableLayout: !useFixedLayout && initialTiles.isNotEmpty,
        backgroundColor: backgroundColor,
        iconAssetPath: 'assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png',
        tiles: initialTiles.isNotEmpty ? initialTiles : List.generate(
          rows * columns,
          (index) => SymbolTile(
            id: 'tile_$index',
            label: '',
            category: name,
            imageAsset: '',
            bgColor: 'transparent',
            textColor: '#000000',
          ),
        ),
        isSubBoard: isSubBoard,
        isTertiaryBoard: isTertiaryBoard,
      );
      await _writeBoard(board, mirrorToDisk: false);
    };

    // Load the priority board first so the user can start using the app.
    // Remaining boards are loaded on demand when the user selects their tab.
    if (sortedNames.isNotEmpty) {
      await loadOne(sortedNames.first);
    }

    // MIGRATE: Consolidate 'A-Z Of Sign' and 'A to Z Of Sign'
    final oldSignIds = ['prebuilt_a_to_z_of_sign', 'prebuilt_a_z_of_sign'];
    final canonicalSignId = prebuiltBoardId('A-Z Of Sign');
    for (final oldId in oldSignIds) {
        if (oldId == canonicalSignId) continue;
        final oldKey = _getBoardKey(oldId);
        if (kIsWeb) {
            final raw = _prefs!.getString(oldKey);
            if (raw != null) {
                try {
                    final m = json.decode(raw) as Map<String, dynamic>;
                    m['id'] = canonicalSignId;
                    m['name'] = 'A-Z Of Sign';
                    await _prefs!.setString(_getBoardKey(canonicalSignId), json.encode(m));
                    await _prefs!.remove(oldKey);
                } catch (_) {}
            }
        } else {
            final oldFile = File('${_dataDir!.path}/$oldKey.json');
            if (await oldFile.exists()) {
                try {
                    final m = json.decode(await oldFile.readAsString()) as Map<String, dynamic>;
                    m['id'] = canonicalSignId;
                    m['name'] = 'A-Z Of Sign';
                    await File('${_dataDir!.path}/${_getBoardKey(canonicalSignId)}.json')
                        .writeAsString(json.encode(m));
                    await oldFile.delete();
                } catch (_) {}
            }
        }
    }

    // Migrate the old 'Common' board to 'Common Words' (rename instead of delete)
    final oldCommonId = prebuiltBoardId('Common');
    final newCommonId = prebuiltBoardId('Common Words');
    final oldCommonKey = _getBoardKey(oldCommonId);
    final newCommonKey = _getBoardKey(newCommonId);
    if (kIsWeb) {
      final oldRaw = _prefs!.getString(oldCommonKey);
      final newExists = _prefs!.containsKey(newCommonKey);
      if (oldRaw != null && !newExists) {
        // Rename: parse, update id/name, write to new key, remove old
        try {
          final m = json.decode(oldRaw) as Map<String, dynamic>;
          m['id'] = newCommonId;
          m['name'] = 'Common Words';
          await _prefs!.setString(newCommonKey, json.encode(m));
        } catch (_) {}
      }
      await _prefs!.remove(oldCommonKey);
    } else {
      final oldCommonFile = File('${_dataDir!.path}/$oldCommonKey.json');
      final newCommonFile = File('${_dataDir!.path}/$newCommonKey.json');
      if (await oldCommonFile.exists() && !await newCommonFile.exists()) {
        try {
          final m = json.decode(await oldCommonFile.readAsString()) as Map<String, dynamic>;
          m['id'] = newCommonId;
          m['name'] = 'Common Words';
          await newCommonFile.writeAsString(JsonEncoder.withIndent('  ').convert(m));
        } catch (_) {}
      }
      if (await oldCommonFile.exists()) {
        await oldCommonFile.delete();
      }
    }
    // Also migrate from project source if in developer mode
    if (!kIsWeb && _projectRoot != null) {
      final projectOldCommonFile = File('$_projectRoot/assets/boards/$oldCommonId.json');
      if (await projectOldCommonFile.exists()) {
        try {
          final m = json.decode(await projectOldCommonFile.readAsString()) as Map<String, dynamic>;
          m['id'] = newCommonId;
          m['name'] = 'Common Words';
          final jsonFile = await _findProjectJsonFile(newCommonId);
          if (jsonFile != null) {
            await jsonFile.writeAsString(JsonEncoder.withIndent('  ').convert(m));
          }
        } catch (_) {}
        await projectOldCommonFile.delete();
      }
    }
  }

  List<SymbolTile> _generateAlphabetTiles() {
    final tiles = 'abcdefghijklmnopqrstuvwxyz'.split('').map((char) => SymbolTile(
      id: 'letter_$char',
      label: char.toUpperCase(),
      category: 'Alphabet',
      imageAsset: 'assets/symbols/1. Main Boards/Alphabet/$char.png',
    )).toList();
    // Extra words from Excel
    final phrases = [
      ["it's fun to stay at the", "assets/symbols/1. Main Boards/Alphabet/it's fun to stay at the.png"],
      ['you can take me hot to go', 'assets/symbols/1. Main Boards/Alphabet/you can take me hot to go.png'],
      ['find out what it means to me', 'assets/symbols/1. Main Boards/Alphabet/find out what it means to me.png'],
    ];
    for (final p in phrases) {
      tiles.add(SymbolTile(
        id: 'letter_phrase_${p[0].replaceAll(RegExp(r"[^a-z0-9]"), "_")}',
        label: p[0],
        category: 'Alphabet',
        imageAsset: p[1],
      ));
    }
    // Phonics subboard link at end (black bg, white text)
    tiles.add(SymbolTile(
      id: 'letter_phonics_link',
      label: 'Phonics',
      category: 'Alphabet',
      imageAsset: 'assets/symbols/BOARDS/Letters.png',
      isBoardLink: true,
      linkedBoardId: prebuiltBoardId('Phonics'),
      bgColor: '#000000',
      textColor: '#FFFFFF',
    ));
    // Fill to 35 tiles
    while (tiles.length < 35) {
      tiles.add(SymbolTile(
        id: 'letter_empty_${tiles.length}',
        label: '',
        category: 'Alphabet',
        imageAsset: '',
      ));
    }
    return tiles;
  }

  List<SymbolTile> _generateNumberTiles() {
    final tiles = <SymbolTile>[];
    final base = 'assets/symbols/3. Lesson Vocab/Maths/Basic/Numbers';
    final mathBase = 'assets/symbols/3. Lesson Vocab/Maths/Basic';

    // 1. Operations
    for (final op in [
      ['plus', 'https://static.arasaac.org/pictograms/3220/3220_300.png'],
      ['subtract', '$mathBase/subtract.png'],
      ['multiply', '$mathBase/multiply.png'],
      ['divide', '$mathBase/divide (visual).png'],
      ['equals', '$mathBase/equals.png'],
    ]) {
      tiles.add(SymbolTile(id: 'num_op_${op[0]}', label: op[0], category: 'Numbers', imageAsset: op[1]));
    }

    // 2. Spelled-out words (zero to nineteen)
    final words1 = ['zero','one','two','three','four','five','six','seven','eight','nine','ten',
      'eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen'];
    for (final w in words1) {
      tiles.add(SymbolTile(id: 'num_word_$w', label: w, category: 'Numbers',
        imageAsset: 'assets/symbols/1. Main Boards/Time/$w.png'));
    }

    // 3. Tens (twenty to ninety)
    final words2 = ['twenty','thirty','forty','fifty','sixty','seventy','eighty','ninety'];
    for (final w in words2) {
      tiles.add(SymbolTile(id: 'num_word_$w', label: w, category: 'Numbers',
        imageAsset: 'assets/symbols/1. Main Boards/Time/$w.png'));
    }

    // 4. Large (hundred to quadrillion)
    final words3 = ['hundred','thousand','million','billion','trillion','quadrillion','and'];
    for (final w in words3) {
      tiles.add(SymbolTile(id: 'num_word_$w', label: w, category: 'Numbers',
        imageAsset: 'assets/symbols/1. Main Boards/Time/$w.png'));
    }

    // 5. Place-value word pictures
    for (final pv in [
      ['one (1)', '$mathBase/one.png'],
      ['ten (10)', '$mathBase/ten.png'],
      ['hundred (100)', '$mathBase/hundred.png'],
      ['thousand (1,000)', '$mathBase/thousand.png'],
    ]) {
      tiles.add(SymbolTile(id: 'num_pv_${pv[0].replaceAll(RegExp(r"[^a-z0-9]"),"_")}',
        label: pv[0], category: 'Numbers', imageAsset: pv[1]));
    }
    
    tiles.add(SymbolTile(id: 'num_blank_1', label: '', category: 'Numbers', imageAsset: '', bgColor: 'transparent'));

    // 6. Digits 0-10
    for (final d in ['0','1','2','3','4','5','6','7','8','9','10']) {
      tiles.add(SymbolTile(id: 'num_digit_$d', label: d, category: 'Numbers',
        imageAsset: '$base/$d.png'));
    }

    // 7. Place value labels
    for (final pv in [
      ['ones', '$mathBase/ones.png'],
      ['tens', '$mathBase/tens.png'],
      ['hundreds', '$mathBase/hundreds.png'],
      ['thousands', '$mathBase/thousands.png'],
    ]) {
      tiles.add(SymbolTile(id: 'num_label_${pv[0]}', label: pv[0], category: 'Numbers', imageAsset: pv[1]));
    }

    tiles.add(SymbolTile(id: 'num_blank_2', label: '', category: 'Numbers', imageAsset: '', bgColor: 'transparent'));

    // 8. Clock/time words
    for (final t in ["o'clock", 'quarter past', 'half past', 'quarter to']) {
      tiles.add(SymbolTile(
        id: 'num_time_${t.replaceAll(RegExp(r"[^a-z0-9]"), "_")}',
        label: t, category: 'Numbers',
        imageAsset: 'assets/symbols/3. Lesson Vocab/Maths/Time/$t.png',
      ));
    }

    // Fill to 65
    while (tiles.length < 65) {
      tiles.add(SymbolTile(
        id: 'num_empty_${tiles.length}',
        label: '',
        category: 'Numbers',
        imageAsset: '',
      ));
    }

    return tiles;
  }

  List<SymbolTile> _generateColourTiles() {
    final colours = [
      'black', 'grey', 'white', 'silver', 'brown', 'primary colours',
      'red', 'orange', 'yellow', 'green', 'dark green', 'secondary colours',
      'blue', 'dark blue', 'purple', 'violet', 'pink', 'tertiary colours',
      'magenta', 'mauve', 'lilac', 'maroon', 'mahogany', 'complimentary colours',
      'coffee', 'tan', 'ochre', 'mustard', 'peach', 'colour wheel',
      'beige', 'olive', 'lime', 'chartreuse', 'lavender', 'rainbow',
      'cyan', 'turquoise', 'teal', 'azure', 'sapphire'
    ];
    
    final tiles = colours.map((c) => SymbolTile(
      id: 'colour_${c.replaceAll(' ', '_').replaceAll('\'', '')}',
      label: c,
      category: 'Colours',
      imageAsset: 'assets/symbols/1. Main Boards/Colours/${c.toLowerCase()}.png',
    )).toList();
    
    // Add Shades of Colours board link as the final tile
    tiles.add(SymbolTile(
      id: 'colour_shades_link',
      label: 'Shades of Colours',
      category: 'Colours',
      imageAsset: 'assets/symbols/1. Main Boards/Colours/Shades Of Colours.png',
      isBoardLink: true,
      linkedBoardId: prebuiltBoardId('Shades of Colours'),
    ));
    
    return tiles;
  }

  // Legacy Common Words generator removed to avoid duplicate and non-existent asset paths.

  List<SymbolTile> _generateFeelingsTiles() {
    final tiles = <SymbolTile>[];
    
    // First row: folder icon links to sub-boards — images from BOARDS/Feelings folder
    final feelingsBoards = ['Sad', 'Mad', 'Scared', 'Joyful', 'Strong', 'Calm'];
    for (final boardName in feelingsBoards) {
      tiles.add(SymbolTile(
        id: 'feelings_link_${boardName.toLowerCase()}',
        label: boardName,
        category: 'Feelings',
        imageAsset: 'assets/symbols/BOARDS/Feelings/$boardName.png',
        isBoardLink: true,
        linkedBoardId: prebuiltBoardId(boardName),
        bgColor: '#000000',
        textColor: '#FFFFFF',
      ));
    }
    
    // Following rows: words
    final feelingsWords = [
      'happy', 'sad', 'angry', 'ill', 'pain', 'tired',
      'embarrassed', 'bored', 'calm', 'scared', 'confused', 'worried',
      'ashamed', 'guilty', 'anxious', 'frustrated', 'like', 'love',
      'shy', 'curious', 'proud', 'jealous', 'trust', 'lonely',
      'disappointed', 'dizzy', 'hot', 'cold', 'hungry', 'thirsty',
      'uncomfortable'
    ];
    
    for (final word in feelingsWords) {
      tiles.add(SymbolTile(
        id: 'feeling_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Feelings',
        imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$word.png',
      ));
    }
    
    // Three empty tiles
    for (int i = 0; i < 3; i++) {
      tiles.add(SymbolTile(
        id: 'feeling_empty_$i',
        label: '',
        category: 'Feelings',
        imageAsset: '',
        bgColor: 'transparent',
        textColor: '#000000',
      ));
    }
    
    // Feelings Wheel and Putchik's Wheel Of Emotions - full screen images
    tiles.add(SymbolTile(
      id: 'feelings_wheel',
      label: 'Feelings Wheel',
      category: 'Feelings',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/baycroft\'s wheel of emotions.png',
      isFullScreenImage: true,
    ));
    
    tiles.add(SymbolTile(
      id: 'putchik_wheel',
      label: 'Putchik\'s Wheel Of Emotions',
      category: 'Feelings',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/putchik\'s wheel of emotions.png',
      isFullScreenImage: true,
    ));
    
    return tiles;
  }

  List<SymbolTile> _generateSadTiles() {
    final sadWords = [
      'tired', 'bored', 'lonely', 'depressed',
      'ashamed', 'guilty', 'sleepy', 'uncaring',
      'desolate', 'hopeless', 'stupid', 'miserable'
    ];
    return sadWords.map((w) => SymbolTile(
      id: 'sad_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Sad',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateMadTiles() {
    final madWords = [
      'hurt', 'hostile', 'angry', 'selfish',
      'hateful', 'critical', 'defensive', 'sarcastic',
      'frustrated', 'jealous', 'annoyed', 'doubtful'
    ];
    return madWords.map((w) => SymbolTile(
      id: 'mad_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Mad',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateScaredTiles() {
    final scaredWords = [
      'rejected', 'nervous', 'confused', 'helpless',
      'insecure', 'anxious', 'discouraged', 'worried',
      'baffled', 'vulnerable', 'embarrassed', 'overwhelmed',
      'horrified', 'terrified', 'petrified', 'panicked'
    ];
    return scaredWords.map((w) => SymbolTile(
      id: 'scared_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Scared',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateJoyfulTiles() {
    final joyfulWords = [
      'excited', 'optimistic', 'happy', 'cheerful',
      'creative', 'energetic', 'daring', 'hopeful',
      'delighted', 'amused', 'passionate', 'enthusiastic'
    ];
    return joyfulWords.map((w) => SymbolTile(
      id: 'joyful_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Joyful',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateStrongTiles() {
    final strongWords = [
      'motivated', 'valuable', 'confident', 'worthy',
      'successful', 'fulfilled', 'inspired', 'appreciated',
      'faithful', 'respected', 'proud', 'assured'
    ];
    return strongWords.map((w) => SymbolTile(
      id: 'strong_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Strong',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateCalmTiles() {
    final calmWords = [
      'serene', 'grounded', 'peaceful', 'present',
      'relaxed', 'safe', 'caring', 'content',
      'loving', 'focused', 'comfortable', 'trusting'
    ];
    return calmWords.map((w) => SymbolTile(
      id: 'calm_${w.replaceAll(' ', '_')}',
      label: w,
      category: 'Calm',
      imageAsset: 'assets/symbols/1. Main Boards/Feelings and Emotions/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateShadesOfColoursTiles() {
    final shades = [
      'Shades Of Red', 'Shades Of Orange', 'Shades Of Yellow', 'Shades Of Green',
      'Shades Of Blue', 'Shades Of Purple', 'Shades Of Pink', 'Shades Of Brown', 'Shades Of Grey'
    ];
    return shades.map((s) => SymbolTile(
      id: 'shades_${s.replaceAll(' ', '_').toLowerCase()}',
      label: s.toLowerCase(),
      category: 'Shades',
      imageAsset: 'assets/symbols/1. Main Boards/Colours/$s.png',
      isBoardLink: true,
      linkedBoardId: '',
    )).toList();
  }

  List<SymbolTile> _generatePrepositionsTiles() {
    final tiles = <SymbolTile>[];
    
    // Word tiles
    final prepositions = [
      'get', 'put', 'at', 'above', 'over', 'into', 'out of',
      'high', 'up', 'between', 'on', 'off', 'among', 'around',
      'centre', 'start', 'next to', 'in', 'beside', 'near', 'finish',
      'low', 'down', 'behind', 'under', 'in front', 'before', 'after',
      'background', 'middle', 'foreground', 'below', 'large', 'medium', 'small',
      'this', 'that', 'inside', 'outside', 'here', 'there', 'somewhere',
      'different', 'same', 'along', 'across', 'toward', 'away', 'through',
      'left', 'middle', 'right', 'short', 'long', 'close', 'far',
      'a few', 'a lot', 'opposite', 'another', 'tall'
    ];
    
    int i = 0;
    for (final word in prepositions) {
      String imagePath = 'assets/symbols/1. Main Boards/Prepositions/${word.replaceAll(' ', ' ')}.png';
      // Handle special cases for file names that differ from the word
      if (word == 'out of') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/out.png';
      } else if (word == 'next to') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/next to.png';
      } else if (word == 'in front') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/in front.png';
      } else if (word == 'somewhere') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/somewhere else.png';
      } else if (word == 'large') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/big.png';
      } else if (word == 'small') {
        imagePath = 'assets/symbols/1. Main Boards/Prepositions/little.png';
      } else if (word == 'middle') {
        if (i == 29) {
          imagePath = 'assets/symbols/1. Main Boards/Prepositions/middle ground.png';
        } else {
          imagePath = 'assets/symbols/1. Main Boards/Prepositions/middle.png';
        }
      }
      
      tiles.add(SymbolTile(
        id: 'prep_${word.replaceAll(' ', '_')}_$i',
        label: word,
        category: 'Prepositions',
        imageAsset: imagePath,
      ));
      i++;
    }
    
    // Folder link to Adjectives board
    tiles.add(SymbolTile(
      id: 'prep_link_adjectives',
      label: 'Adjectives',
      category: 'Prepositions',
      imageAsset: 'assets/symbols/BOARDS/English/Adjectives.png',
      isBoardLink: true,
      linkedBoardId: prebuiltBoardId('Adjectives'),
      bgColor: '#FF0000',
      textColor: '#FFFFFF',
    ));

    // Folder link to Other Adjectives board
    tiles.add(SymbolTile(
      id: 'prep_link_other_adjectives',
      label: 'Other Adjectives',
      category: 'Prepositions',
      imageAsset: 'assets/symbols/BOARDS/English/Adjectives.png',
      isBoardLink: true,
      linkedBoardId: prebuiltBoardId('Other Adjectives'),
      bgColor: '#FF0000',
      textColor: '#FFFFFF',
    ));
    
    return tiles;
  }

  List<SymbolTile> _generatePeopleTiles() {
    final tiles = <SymbolTile>[];
    
    // Word tiles
    final people = [
      'I', 'he', 'she', 'they', 'they', 'person',
      'me', 'you', 'you', 'we', 'us', 'man',
      'grandmother', 'grandfather', 'friend', 'classmate', 'someone else',
      'woman', 'mother', 'father', 'aunt', 'uncle', 'carer', 'boy',
      'sister', 'brother', 'cousin', 'family friend', 'stranger', 'girl',
      'baby', 'toddler', 'teenager', 'adult', 'middle aged', 'old aged',
      'called', '', 'School People', 'Characters', 'Jobs and Careers'
    ];
    
    for (final word in people) {
      if (word.isEmpty) {
        tiles.add(SymbolTile(
          id: 'people_empty',
          label: '',
          category: 'People',
          imageAsset: '',
        ));
      } else if (word == 'School People' || word == 'Characters' || word == 'Jobs and Careers') {
        // Board links with black background and white text
        String boardName = word;
        String imagePath = 'assets/symbols/BOARDS/English/$boardName.png';
        if (word == 'School People') {
          imagePath = 'assets/symbols/BOARDS/People At School.png';
        }
        
        tiles.add(SymbolTile(
          id: 'people_link_${word.replaceAll(' ', '_').toLowerCase()}',
          label: _toTitleCase(word),
          category: 'People',
          imageAsset: imagePath,
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(boardName),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/People/$word.png';
        tiles.add(SymbolTile(
          id: 'people_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'People',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateSchoolPeopleTiles() {
    final tiles = <SymbolTile>[];
    
    final schoolPeople = [
      'teacher', 'teaching assistant', 'yellow lanyard',
      'tutor team', 'duty staff', 'head teacher',
      'office staff', 'first aid staff', 'dinner hall',
      'drivers and escorts', 'speech and language', 'friends'
    ];
    
    for (final word in schoolPeople) {
      String imagePath = 'assets/symbols/1. Main Boards/People At School/$word.png';
      tiles.add(SymbolTile(
        id: 'school_people_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'School People',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateAnimalsTiles() {
    final tiles = <SymbolTile>[];
    
    // Board links with black background and white text
    final boardLinks = [
      ('MAMMALS', 'Mammals'),
      ('BIRDS', 'Birds'),
      ('REPTILES', 'Reptiles'),
      ('AMPHIBIANS', 'Amphibians'),
      ('INSECTS', 'Insects'),
      ('ARACHNIDS', 'Arachnids'),
      ('INVERTEBRATES', 'Invertebrates'),
      ('FISH', 'Fish'),
      ('HABITATS', 'Habitats'),
      ('SEALIFE', 'Sealife'),
      ('NATURE VOCABULARY', 'Nature Vocabulary'),
      ('BODY PARTS - ANIMALS', 'Body Parts of Animals'),
      ('CHILD ANIMALS', 'Child Animals'),
      ('GROUPS OF ANIMALS', 'Groups of Animals'),
    ];
    
    for (final (label, boardName) in boardLinks) {
      tiles.add(SymbolTile(
        id: 'animals_link_${boardName.toLowerCase().replaceAll(' ', '_')}',
        label: label,
        category: 'Animals',
        imageAsset: 'assets/symbols/BOARDS/English/$boardName.png',
        isBoardLink: true,
        linkedBoardId: prebuiltBoardId(boardName),
        bgColor: 'transparent',
        textColor: '#000000',
      ));
    }
    
    // Individual animal type words
    final animalTypes = [
      'mammal', 'bird', 'reptile', 'amphibian', 'insect', 'arachnid',
      'invertebrate', 'fish', 'habitat', 'sealife'
    ];
    
    for (final word in animalTypes) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/$word.png';
      tiles.add(SymbolTile(
        id: 'animal_type_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Animals',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateMammalsTiles() {
    final tiles = <SymbolTile>[];
    
    final mammals = [
      'anteater', 'antelope', 'armadillo', 'bandicoot', 'bat', 'bear', 'beaver', 'camel', 'cat', 'chimpanzee', 'chipmunk', 'cow', 'deer', 'dog', 'donkey', 'echidna', 'elephant', 'fox', 'giraffe', 'goat', 'gorilla', 'guinea pig', 'hamster', 'hedgehog', 'hippopotamus', 'horse', 'human', 'kangaroo', 'koala', 'leopard', 'lion', 'llama', 'meerkat', 'mole', 'monkey', 'moose', 'mouse', 'panda', 'pig', 'platypus', 'porcupine', 'possum', 'rabbit', 'raccoon', 'rat', 'red panda', 'reindeer', 'rhinoceros', 'sheep', 'skunk', 'sloth', 'squirrel', 'tasmanian devil', 'tiger', 'wallaby', 'wolf', 'wombat', 'zebra'
    ];
    
    for (final word in mammals) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Mammals/$word.png';
      tiles.add(SymbolTile(
        id: 'mammal_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Mammals',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateBirdsTiles() {
    final tiles = <SymbolTile>[];
    
    final birds = [
      'bird', 'bird of prey', 'blackbird', 'budgie', 'buzzard', 'cassowary', 'chicken', 'cockatoo', 'cormorant', 'crow', 'dodo', 'dove', 'duck', 'eagle', 'egret', 'emu', 'falcon', 'finch', 'flamingo', 'goose', 'hawk', 'heron', 'hornbill', 'jay', 'kestrel', 'kingfisher', 'kiwi', 'lark', 'mallard', 'osprey', 'ostrich', 'owl', 'parakeet', 'parrot - macaw', 'parrot', 'peacock', 'pelican', 'penguin', 'pigeon', 'quail', 'raven', 'robin', 'rooster', 'seagull', 'sparrow', 'starling', 'swallow', 'swan', 'thrush', 'toucan', 'turkey', 'vulture', 'wren'
    ];
    
    for (final word in birds) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Birds/$word.png';
      tiles.add(SymbolTile(
        id: 'bird_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Birds',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateReptilesTiles() {
    final tiles = <SymbolTile>[];
    
    final reptiles = [
      'alligator', 'anaconda', 'bearded dragon', 'caiman', 'chameleon', 'cobra', 'crocodile', 'gecko', 'gharial', 'iguana', 'komodo dragon', 'lizard', 'python', 'rattlesnake', 'snake', 'tortoise', 'tortoise - hard shell', 'turtle', 'viper'
    ];
    
    for (final word in reptiles) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Reptiles/$word.png';
      tiles.add(SymbolTile(
        id: 'reptile_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Reptiles',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateAmphibiansTiles() {
    final tiles = <SymbolTile>[];
    
    final amphibians = [
      'axolotl', 'eel', 'frog', 'frogspawn', 'newt', 'poison dart frog', 'salamander', 'toad', 'tree frog'
    ];
    
    for (final word in amphibians) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Amphibians/$word.png';
      tiles.add(SymbolTile(
        id: 'amphibian_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Amphibians',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateInsectsTiles() {
    final tiles = <SymbolTile>[];
    
    final insects = [
      'ant', 'aphid', 'bee', 'beetle', 'beetle - ground', 'butterfly', 'caterpillar', 'centipede', 'cockroach', 'cricket', 'dragonfly', 'earthworm', 'earwig', 'flea', 'fly', 'gnat', 'grasshopper', 'ladybird', 'locust', 'millipede', 'mosquito', 'moth', 'praying mantis', 'silverfish', 'slug', 'snail', 'stick insect', 'termite', 'wasp', 'egg - insect', 'larva', 'pupa'
    ];
    
    for (final word in insects) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Insects/$word.png';
      tiles.add(SymbolTile(
        id: 'insect_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Insects',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateArachnidsTiles() {
    final tiles = <SymbolTile>[];
    
    final arachnids = ['mite', 'scorpion', 'spider', 'tick'];
    
    for (final word in arachnids) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Arachnids/$word.png';
      tiles.add(SymbolTile(
        id: 'arachnid_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Arachnids',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateInvertebratesTiles() {
    final tiles = <SymbolTile>[];

    final categoryWords = {
      'arthropods', 'cnidarians', 'molluscs', 'annelids', 'echinoderms',
      'poriferans', 'platyhelminthes', 'nematodes', 'rotifers', 'bryozoans'
    };
    final sealifeWords = {
      'cnidarians', 'coral', 'hydra', 'jellyfish', 'sea anemone',
      'molluscs', 'echinoderms', 'brittle star', 'sand dollar', 'sea cucumber',
      'sea urchin', 'starfish', 'poriferans', 'sea sponge', 'rotifers', 'bryozoans'
    };

    final invertebrates = [
      'arthropods', 'Arachnids', 'Insects', 'myriapods', 'centipede', 'millipede',
      'crustaceans', 'barnacle', 'crab', 'crayfish', 'lobster', 'prawn', 'shrimp',
      'cnidarians', 'coral', 'hydra', 'jellyfish', 'sea anemone',
      'molluscs', 'slug', 'snail',
      'annelids', 'earthworm', 'leech',
      'echinoderms', 'brittle star', 'sand dollar', 'sea cucumber', 'sea urchin', 'starfish',
      'poriferans', 'sea sponge',
      'platyhelminthes', 'nematodes', 'rotifers', 'bryozoans'
    ];

    for (final word in invertebrates) {
      if (word == 'Arachnids' || word == 'Insects') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'invertebrate_link_${word.toLowerCase()}',
          label: word,
          category: 'Invertebrates',
          imageAsset: 'assets/symbols/BOARDS/Animals/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: '#000000',
          textColor: '#FFFFFF',
        ));
      } else {
        final folder = sealifeWords.contains(word) ? 'Sealife' : 'Invertebrates';
        String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/$folder/$word.png';
        final isCategory = categoryWords.contains(word);
        tiles.add(SymbolTile(
          id: 'invertebrate_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Invertebrates',
          imageAsset: imagePath,
          bgColor: isCategory ? '#ADD8E6' : 'transparent',
          textColor: '#000000',
        ));
      }
    }

    return tiles;
  }

  List<SymbolTile> _generateFishTiles() {
    final tiles = <SymbolTile>[];
    
    final fish = [
      'fish', 'angelfish', 'anglerfish', 'archerfish', 'barracuda', 'betta', 'blobfish', 'blue tang', 'catfish', 'clownfish', 'cod', 'flying fish', 'goby', 'goldfish', 'guppy', 'herring', 'loach', 'mackerel', 'marlin', 'mudskipper', 'pufferfish', 'sardine', 'salmon', 'sturgeon', 'swordfish', 'tetra', 'tuna', 'trout'
    ];
    
    for (final word in fish) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Fish/$word.png';
      tiles.add(SymbolTile(
        id: 'fish_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Fish',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateHabitatsTiles() {
    final tiles = <SymbolTile>[];
    
    final habitats = [
      'habitat', 'alpine', 'antarctic', 'aquatic', 'arctic', 'burrows',
      'cave', 'coastal', 'coral reef', 'desert', 'estuary', 'farm',
      'farmland', 'forest', 'freshwater', 'glacier', 'grassland', 'ice caps',
      'jungle', 'lake', 'mangrove', 'marsh', 'mountain', 'ocean',
      'polar', 'pond', 'rainforest', 'river', 'savannah', 'sea',
      'soil', 'steppe', 'stream', 'swamp', 'tide pool', 'tundra',
      'underground', 'urban', 'volcanic regions', 'wetland', 'island', 'Habitats (Science)'
    ];
    
    for (final word in habitats) {
      if (word == 'Habitats (Science)') {
        // Board link with black background and white text
        tiles.add(SymbolTile(
          id: 'habitat_link_science',
          label: 'Habitats (Science)',
          category: 'Habitats',
          imageAsset: 'assets/symbols/BOARDS/English/Habitats (Science).png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId('Habitats (Science)'),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Habitats/$word.png';
        tiles.add(SymbolTile(
          id: 'habitat_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Habitats',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateSealifeTiles() {
    final tiles = <SymbolTile>[];
    
    final sealife = [
      'barnacle', 'brittle star', 'clam', 'coral', 'cuttlefish', 'dolphin',
      'eel', 'eel', 'great white shark', 'hammerhead shark', 'humpback whale', 'hydra',
      'jellyfish', 'kelp', 'krill', 'manta ray', 'mollusc', 'mussel',
      'nautilus', 'octopus', 'orca', 'otter', 'oyster', 'phytoplankton',
      'plankton', 'sand dollar', 'sea anemone', 'sea cucumber', 'sea lion', 'sea sponge',
      'sea urchin', 'seahorse', 'seal', 'seaweed', 'shark', 'squid',
      'starfish', 'tadpole', 'walrus', 'whale shark', 'whale'
    ];
    
    for (final word in sealife) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Sealife/$word.png';
      tiles.add(SymbolTile(
        id: 'sealife_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Sealife',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateNatureVocabularyTiles() {
    final tiles = <SymbolTile>[];
    
    final natureVocab = [
      'tree', 'flower', 'soil', 'sky',
      'carnivore', 'herbivore', 'omnivore', 'piscivore', 'scavenger',
      'matutinal', 'diurnal', 'vespertine', 'crepuscular', 'nocturnal',
      'hibernate', 'migrate', 'breed', 'food chain', 'camouflage',
      'wild', 'tame', 'pet', 'predator', 'prey'
    ];
    
    for (final word in natureVocab) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Nature Vocabulary/$word.png';
      tiles.add(SymbolTile(
        id: 'nature_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Nature Vocabulary',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateBodyPartsOfAnimalsTiles() {
    final tiles = <SymbolTile>[];
    
    final bodyParts = [
      'paw', 'fur', 'whiskers', 'tail', 'claw',
      'feather', 'beak', 'wing', 'fin', 'gills',
      'scales', 'shell', 'pouch', 'tongue', 'prickles',
      'fang', 'horn', 'mane', 'trunk', 'tusk',
      'snout', 'feeler', 'proboscis', 'flipper', 'blubber',
      'tentacles', 'udder', 'hoof', 'trotter'
    ];
    
    for (final word in bodyParts) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Animal Body Parts/$word.png';
      tiles.add(SymbolTile(
        id: 'animal_body_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Body Parts of Animals',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateChildAnimalsTiles() {
    final tiles = <SymbolTile>[];
    
    final childAnimals = [
      'calf (cow)', 'calf (elephant)', 'calf (moose, camel, giraffe)', 'calf (sealife)',
      'chick', 'cub', 'cygnet', 'duckling',
      'gosling', 'fawn', 'foal', 'fry',
      'hoglet', 'joey', 'kid', 'kitten',
      'lamb', 'piglet', 'porcupette', 'pup'
    ];
    
    for (final word in childAnimals) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Child Animals/$word.png';
      tiles.add(SymbolTile(
        id: 'child_animal_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Child Animals',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateGroupsOfAnimalsTiles() {
    final tiles = <SymbolTile>[];
    
    final groups = [
      'army of frogs', 'array of hedgehogs', 'bale of turtles', 'band of gorillas', 'bed of clams', 'bevy of swans', 'boil of toads', 'brood of hens', 'business of ferrets', 'cast of crabs', 'cauldron of bats', 'cloud of gnats', 'clowder of cats', 'clutch of chicks', 'colony of ants', 'company of parrots', 'congregation of alligators', 'convocation of eagles', 'crash of hippos', 'dazzle of zebras', 'flight of birds', 'float of crocodiles', 'flock of sheep', 'gaggle of geese', 'herd of cattle', 'horde of hamsters', 'huddle of penguins', 'intrusion of cockroaches', 'kettle of hawks', 'labor of moles', 'leap of leopards', 'litter of puppies', 'lounge of lizards', 'mischief of mice', 'mob of kangaroos', 'murder of crows', 'nursery of raccoons', 'ostentation of peacocks', 'pack of dogs', 'paddle of ducks', 'parliament of owls', 'pod of dolphins', 'prickle of porcupines', 'pride of lions', 'quiver of cobras', 'raft of otters', 'rafter of turkeys', 'school of fish', 'siege of herons', 'skulk of foxes', 'slaughter of wolves', 'sleuth of bears', 'slither of snakes', 'sounder of swine', 'stench of skunks', 'streak of tigers', 'string of ponies', 'swarm of bees', 'team of horses', 'tower of giraffes', 'tribe of goats', 'troop of lemurs', 'warren of rabbits'
    ];
    
    for (final word in groups) {
      String imagePath = 'assets/symbols/1. Main Boards/Animals and Habitats/Groups of Animals/$word.png';
      tiles.add(SymbolTile(
        id: 'group_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Groups of Animals',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateCommonActionsTiles() {
    final tiles = <SymbolTile>[];
    
    final actions = [
      'ask', 'do', 'dress', 'drink', 'eat',
      'go', 'stop', 'play', 'sleep', 'talk',
      'listen', 'enter', 'leave or exit', 'throw away', 'throw',
      'mix', 'mix and stir', 'cook', 'blow nose', 'ride', 'Movement'
    ];
    
    for (final word in actions) {
      if (word == 'Movement') {
        // Board link with black background and white text
        tiles.add(SymbolTile(
          id: 'actions_link_movement',
          label: 'Movement',
          category: 'Common Actions',
          imageAsset: 'assets/symbols/BOARDS/English/Movement.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId('Movement'),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Actions/$word.png';
        tiles.add(SymbolTile(
          id: 'action_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Common Actions',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateMovementTiles() {
    final tiles = <SymbolTile>[];

    final movements = [
      'crawl', 'dive', 'float', 'fly',
      'gallop', 'glide', 'hop', 'hover',
      'jog', 'jump', 'leap', 'plod',
      'pounce', 'roll', 'run', 'scuttle',
      'slither', 'sneak', 'stomp', 'stretch',
      'swim', 'waddle', 'wait', 'walk'
    ];

    final imageFor = {
      'float': 'assets/Subject Vocab/Science/Material Properties/float.png',
      'glide': 'assets/Subject Vocab/Better Words (Thesaurus)/Actions Verbs Thesaurus/Fly/glide.png',
      'hover': 'assets/Subject Vocab/Better Words (Thesaurus)/Actions Verbs Thesaurus/Fly/hover.png',
      'jog': 'assets/Subject Vocab/Better Words (Thesaurus)/Actions Verbs Thesaurus/Move/jog.png',
      'sneak': 'assets/Common/Actions/Movement/sneak or creep.png',
      'stretch': 'assets/Subject Vocab/Science/Material Properties/stretch.png',
    };

    for (final word in movements) {
      final imagePath = imageFor[word] ?? 'assets/Common/Actions/Movement/$word.png';
      tiles.add(SymbolTile(
        id: 'movement_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Movement',
        imageAsset: imagePath,
      ));
    }

    return tiles;
  }

  List<SymbolTile> _generateBuildingsTiles() {
    final tiles = <SymbolTile>[];
    
    final buildings = [
      'Buildings', 'Rooms and Home', 'Furniture', 'Habitats', 'Local Places',
      'airport', 'bank', 'cafe', 'church', 'cinema', 'clinic',
      'coffee shop', 'college', 'community centre', 'court', 'dentist', 'fire station',
      'gp surgery', 'hospital', 'hotel', 'ice rink', 'library', 'mall or shopping centre',
      'mosque', 'museum', 'office', 'optician', 'petrol station', 'pharmacy',
      'police station', 'post office', 'prison', 'restaurant', 'school', 'stadium',
      'store or shop', 'synagogue', 'temple', 'theatre', 'university', 'vet'
    ];
    
    for (final word in buildings) {
      if (word == 'Buildings' || word == 'Rooms and Home' || word == 'Furniture' || word == 'Habitats' || word == 'Local Places') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'buildings_link_${word.replaceAll(' ', '_').toLowerCase()}',
          label: _toTitleCase(word),
          category: 'Buildings',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Places/Buildings/$word.png';
        tiles.add(SymbolTile(
          id: 'building_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Buildings',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateRoomsAndHomeTiles() {
    final tiles = <SymbolTile>[];
    
    final rooms = [
      'Buildings', 'Rooms and Home', 'Furniture', 'Habitats', 'Local Places',
      'home', 'office', 'attic', 'shower room', 'guest room',
      'bedroom', 'study', 'stairs', 'bathroom', '(home) gym',
      'kitchen', 'dining room', 'hallway', 'toilet', 'laundry',
      'garden', 'conservatory', 'cellar', 'living room', 'garage',
      'classroom'
    ];
    
    for (final word in rooms) {
      if (word == 'Buildings' || word == 'Rooms and Home' || word == 'Furniture' || word == 'Habitats' || word == 'Local Places') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'rooms_link_${word.replaceAll(' ', '_').toLowerCase()}',
          label: _toTitleCase(word),
          category: 'Rooms and Home',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Places/Rooms and Home/$word.png';
        tiles.add(SymbolTile(
          id: 'room_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Rooms and Home',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateFurnitureTiles() {
    final tiles = <SymbolTile>[];
    
    final furniture = [
      'Buildings', 'Rooms and Home', 'Furniture', 'Habitats', 'Local Places',
      'armchair', 'barbeque', 'bath', 'bean bag', 'bed', 'bedside table',
      'book', 'bookshelf', 'bunk bed', 'chair', 'chest of drawers', 'chest, trunk',
      'coat rack', 'coffee table', 'cot', 'cupboard', 'dining table', 'dishwasher',
      'dryer', 'fire pit', 'floor', 'freezer', 'fridge', 'gazebo',
      'hammock', 'high chair', 'lamp', 'lights', 'oven', 'patio',
      'picnic table', 'picture', 'plant', 'recliner', 'shelf', 'shoe rack',
      'shower', 'sink', 'sofa', 'storage cube', 'swing', 'table',
      'tv', 'wardrobe', 'washing machine'
    ];
    
    for (final word in furniture) {
      if (word == 'Buildings' || word == 'Rooms and Home' || word == 'Furniture' || word == 'Habitats' || word == 'Local Places') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'furniture_link_${word.replaceAll(' ', '_').toLowerCase()}',
          label: _toTitleCase(word),
          category: 'Furniture',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Places/Furniture/$word.png';
        tiles.add(SymbolTile(
          id: 'furniture_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Furniture',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateLocalPlacesTiles() {
    final tiles = <SymbolTile>[];
    
    final localPlaces = [
      'beach', 'building site', 'bus stop', 'garden centre', 'ice rink (outside)',
      'nature park', 'pitch', 'play park', 'skate park', 'soft play',
      'swimming pool', 'tennis court', 'water park', 'zoo'
    ];
    
    for (final word in localPlaces) {
      String imagePath = 'assets/symbols/1. Main Boards/Places/Local Places/$word.png';
      tiles.add(SymbolTile(
        id: 'local_place_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Local Places',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateJobsAndCareersTiles() {
    final tiles = <SymbolTile>[];
    
    final jobs = [
      'accountant', 'actor', 'animator', 'artist', 'astronaut', 'author', 'baker', 'barber', 'bartender', 'blacksmith', 'builder', 'bus driver', 'butcher', 'captain', 'carpenter', 'chef', 'comedian', 'construction worker', 'dancer', 'dentist', 'doctor', 'electrician', 'emergency manager', 'engineer', 'farmer', 'fireperson', 'fisherperson', 'fitness instructor', 'freight broker', 'gardener', 'hairdresser', 'hotel worker', 'inspector', 'IT technician', 'journalist', 'judge', 'kitchen porter', 'lawyer', 'librarian', 'lifeguard', 'lollipop person', 'marine biologist', 'mechanic', 'milkperson', 'musician', 'nanny', 'newscaster', 'nurse', 'optician', 'painter', 'pharmacist', 'photographer', 'pilot', 'plumber', 'police officer', 'postperson', 'quality controller', 'retail sales assistant', 'ringmaster', 'runner', 'sailor', 'scientist', 'secretary', 'security guard', 'singer', 'software developer', 'soldier', 'tailor', 'teacher', 'tour guide', 'train guard', 'travel agent', 'TV presenter', 'urban planner', 'vet', 'waiter', 'waste manager', 'web designer', 'welder', 'X-ray technician', 'yoga instructor', 'zookeeper'
    ];
    
    for (final word in jobs) {
      String imagePath = 'assets/symbols/1. Main Boards/Jobs and Careers/$word.png';
      tiles.add(SymbolTile(
        id: 'job_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Jobs and Careers',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateWeatherTiles() {
    final tiles = <SymbolTile>[];
    
    final weather = [
      'Disasters', 'weather', 'hot', 'cold',
      'sun', 'sunny', 'rain', 'rainy',
      'wind', 'windy', 'cloud', 'cloudy',
      'fog', 'foggy', 'snow', 'snowy',
      'storm', 'thunder and lightning', 'sleet', 'hail',
      'Seasons', '', '', 'rainbow'
    ];
    
    for (final word in weather) {
      if (word.isEmpty) {
        tiles.add(SymbolTile(
          id: 'weather_empty',
          label: '',
          category: 'Weather',
          imageAsset: '',
        ));
      } else if (word == 'Disasters' || word == 'Seasons') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'weather_link_${word.toLowerCase()}',
          label: word,
          category: 'Weather',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Weather/$word.png';
        tiles.add(SymbolTile(
          id: 'weather_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Weather',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateDisastersTiles() {
    final tiles = <SymbolTile>[];
    
    final disasters = [
      'earthquake', 'flood', 'hurricane', 'tornado', 'tsunami', 'volcano', 'wildfire', 'drought', 'avalanche', 'blizzard', 'landslide', 'cyclone'
    ];
    
    for (final word in disasters) {
      String imagePath = 'assets/symbols/1. Main Boards/Weather/Disasters/$word.png';
      tiles.add(SymbolTile(
        id: 'disaster_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Disasters',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateSeasonsTiles() {
    final tiles = <SymbolTile>[];
    
    final seasons = [
      'winter', '', '', '',
      'spring', '', '', '',
      'summer', '', '', '',
      'autumn', '', '', ''
    ];
    
    for (int i = 0; i < seasons.length; i++) {
      final word = seasons[i];
      if (word.isEmpty) {
        tiles.add(SymbolTile(
          id: 'season_empty_$i',
          label: '',
          category: 'Seasons',
          imageAsset: '',
        ));
      } else {
        tiles.add(SymbolTile(
          id: 'season_$word',
          label: word,
          category: 'Seasons',
          imageAsset: 'assets/symbols/1. Main Boards/Weather/Seasons/$word.png',
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateEventsAndOccasionsTiles() {
    final tiles = <SymbolTile>[];
    
    final events = [
      'new years', 'chinese new years', 'valentine\'s day', 'st. patrick\'s day', 'holi, festival of light',
      'world book day', 'mother\'s day', 'easter', 'earth day', 'pride',
      'solstice', 'father\'s day', 'independence day', 'diwali', 'halloween',
      'day of the dead', 'bonfire night', 'thanksgiving', 'Hanukkah', 'christmas',
      'Easter Keywords', 'Halloween Keywords', 'Bonfire Night Keywords', 'Christmas Keywords'
    ];
    
    for (final word in events) {
      if (word == 'Easter Keywords' || word == 'Halloween Keywords' || word == 'Bonfire Night Keywords' || word == 'Christmas Keywords') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'events_link_${word.replaceAll(' ', '_').toLowerCase()}',
          label: _toTitleCase(word),
          category: 'Events and Occasions',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Time/Events and Occasions/$word.png';
        tiles.add(SymbolTile(
          id: 'event_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Events and Occasions',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateBodyPartsTiles() {
    final tiles = <SymbolTile>[];
    
    final bodyParts = [
      'hair', 'head', 'forehead', 'eye', 'eyebrow', 'eyelash',
      'ear', 'nose', 'mouth', 'teeth', 'tongue', 'chin',
      'neck', 'shoulder', 'chest', 'belly', 'back', 'arm',
      'elbow', 'wrist', 'hand', 'knuckles', 'finger', 'fingernail',
      'waist', 'hip', 'private area', 'bottom', 'leg', 'knee',
      'ankle', 'foot', 'toes', 'toenails', '', 'burp', 'fart', 'sick', 'period', 'Medical', 'Internal Organs'
    ];
    
    for (final word in bodyParts) {
      if (word.isEmpty) {
        tiles.add(SymbolTile(
          id: 'body_empty',
          label: '',
          category: 'Body Parts',
          imageAsset: '',
        ));
      } else if (word == 'Medical' || word == 'Internal Organs') {
        // Board links with black background and white text
        tiles.add(SymbolTile(
          id: 'body_link_${word.toLowerCase()}',
          label: word,
          category: 'Body Parts',
          imageAsset: 'assets/symbols/BOARDS/English/$word.png',
          isBoardLink: true,
          linkedBoardId: prebuiltBoardId(word),
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Body Parts/$word.png';
        tiles.add(SymbolTile(
          id: 'body_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Body Parts',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateMedicalTiles() {
    final tiles = <SymbolTile>[];
    
    final medical = [
      'gp surgery', 'hospital', 'dentist', 'optician',
      'doctor', 'nurse', 'dentist', 'optician',
      'reflex test', 'surgery', 'hearing test', 'eye test'
    ];
    
    for (final word in medical) {
      String imagePath = 'assets/symbols/1. Main Boards/Body Parts/Medical/$word.png';
      tiles.add(SymbolTile(
        id: 'medical_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Medical',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateInternalOrgansTiles() {
    final tiles = <SymbolTile>[];
    
    final organs = [
      'organs', 'muscle', 'nerves', 'skeleton', 'bone',
      'skull', 'mandible (jaw)', 'brain', 'clavicle (collar bone)', 'esophagus',
      'spine, spinal cord', 'ribs', 'heart', 'lungs', 'diaphragm',
      'liver', 'stomach', 'intestines', 'kidneys', 'pelvis',
      'humerus', 'radius', 'ulna', 'oxygen', 'carbon dioxide',
      'femur', 'patella (knee)', 'tibia', 'fibia', 'tissue',
      'veins', 'blood vessels', 'blood cells', 'arteries'
    ];
    
    for (final word in organs) {
      String imagePath = 'assets/symbols/1. Main Boards/Body Parts/Internal Organs/$word.png';
      tiles.add(SymbolTile(
        id: 'organ_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Internal Organs',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateTimeClocksTiles() {
    final tiles = <SymbolTile>[];
    
    final timeClocks = [
      'yesterday', 'today', 'tomorrow', 'monday',
      'duration', 'before', 'now', 'after', 'soon', 'later', 'tuesday',
      'timeline', 'past', 'present', 'future', 'noon', 'midnight', 'wednesday',
      'clock', 'sundial', 'watch', 'timer', 'stopwatch', 'nighttime', 'thursday',
      'dawn', 'morning', 'daytime', 'afternoon', 'evening', 'dusk', 'friday',
      'day', 'week', 'weekend', 'month', 'year', 'calendar', 'saturday',
      'life', 'birthday', 'party', 'decade', 'century', 'millennium', 'sunday',
      'cycle', 'seconds', 'minutes', 'hours', 'never', 'forever', 'leap year'
    ];
    
    for (final word in timeClocks) {
      String imagePath = 'assets/symbols/1. Main Boards/Time/Time (Clocks)/$word.png';
      tiles.add(SymbolTile(
        id: 'time_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Time (Clocks)',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateMonthsTiles() {
    final tiles = <SymbolTile>[];
    
    final months = [
      'winter', 'december', 'january', 'february',
      'spring', 'march', 'april', 'may',
      'summer', 'june', 'july', 'august',
      'autumn', 'september', 'october', 'november'
    ];
    
    for (int i = 0; i < months.length; i++) {
      final word = months[i];
      if (word == 'winter' || word == 'spring' || word == 'summer' || word == 'autumn') {
        tiles.add(SymbolTile(
          id: 'month_$word',
          label: word,
          category: 'Months',
          imageAsset: 'assets/symbols/1. Main Boards/Time/Months/$word.png',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Time/Months/$word.png';
        tiles.add(SymbolTile(
          id: 'month_$word',
          label: word,
          category: 'Months',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateClassEquipmentTiles() {
    final tiles = <SymbolTile>[];
    
    final equipment = [
      'pencil', 'pen', 'highlighter', 'felt-tip', 'colouring pencil', 'colouring pen',
      'text book', 'plain paper', 'lined paper', 'squared paper', 'graph paper', 'tracing paper',
      'interactive board', 'whiteboard', 'rubber / eraser', 'sharpener', 'calculator', '',
      'ruler', 'measuring tape', 'set square', 'protractor', 'compass', '',
      'counter', 'dice', 'spinner', 'paper scissors', 'glue stick', '',
      'chair', 'table', 'tray', 'clipboard'
    ];
    
    for (final word in equipment) {
      if (word.isEmpty) {
        tiles.add(SymbolTile(
          id: 'class_empty',
          label: '',
          category: 'Class Equipment',
          imageAsset: '',
        ));
      } else {
        String imagePath = 'assets/symbols/1. Main Boards/Class Equipment/$word.png';
        tiles.add(SymbolTile(
          id: 'class_${word.replaceAll(' ', '_')}',
          label: word,
          category: 'Class Equipment',
          imageAsset: imagePath,
        ));
      }
    }
    
    return tiles;
  }

  List<SymbolTile> _generateThinkingSkillsTiles() {
    final tiles = <SymbolTile>[];
    
    final skills = [
      'synthesising', 'making connections', 'questioning', 'determining importance',
      'visualising', 'inferring', 'predicting', 'summarising'
    ];
    
    for (final word in skills) {
      String imagePath = 'assets/symbols/2. Baycroft Specific/Thinking Skills and Blank Levels/$word.png';
      tiles.add(SymbolTile(
        id: 'thinking_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Thinking Skills',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateWhenThingsGoWrongTiles() {
    final tiles = <SymbolTile>[];
    
    final issues = [
      'conflict', 'rude', 'mean', 'bullying'
    ];
    
    for (final word in issues) {
      String imagePath = 'assets/symbols/2. Baycroft Specific/Baycroft Expects and Words For When Things Go Wrong/$word.png';
      tiles.add(SymbolTile(
        id: 'wrong_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'When Things Go Wrong',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateLessonsTiles() {
    final tiles = <SymbolTile>[];

    final lessons = [
      'breaktime', 'lunchtime', 'tutor time', 'english', 'maths', 'science',
      'T.F.L', 'personal development', 'peep', 'epic', 'p.e.', 'art',
      'performing arts', 'sustainability', 'cooking', 'resistant materials',
      'textiles', 'religion and worldviews', 'music', 'horticulture', 'retail',
      'photography', 'information technology', 'construction', 'engineering',
      'living life skills', 'prepare for adulthood'
    ];
    
    for (final word in lessons) {
      // Lessons symbols are now consolidated in the Subjects folder.
      final fileName = _toTitleCase(word);
      String imagePath = 'assets/symbols/Subjects/$fileName.png';

      tiles.add(SymbolTile(
        id: 'lesson_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Lessons',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  List<SymbolTile> _generateTutorTimetablesTiles() {
    final tiles = <SymbolTile>[];
    
    final timetableItems = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday',
      'period 1', 'period 2', 'period 3', 'period 4', 'period 5',
      'break', 'lunch', 'home time'
    ];
    
    for (final word in timetableItems) {
      String imagePath = 'assets/symbols/2. Baycroft Specific/Timetables/$word.png';
      tiles.add(SymbolTile(
        id: 'timetable_${word.replaceAll(' ', '_')}',
        label: word,
        category: 'Tutor Timetables',
        imageAsset: imagePath,
      ));
    }
    
    return tiles;
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}').join(' ');
  }

/// LISTER
/// Returns all available boards. If Developer Mode is on, 
/// it lists files from your project folder instead of app storage.

  List<Board> _withoutDeletedBoards(Iterable<Board> boards) {
    return boards.where((board) => !_deletedBoardIds.contains(board.id)).toList();
  }

  Future<List<Board>> listBoards({String? area, bool includeTiles = true}) async {
    if (!kIsWeb && _projectRoot != null) {
      final root = Directory(p.join(_projectRoot!, 'lib', 'data', 'boards'));
      if (await root.exists()) {
        final boardsById = <String, Board>{};
        final modifiedById = <String, DateTime>{};
        await for (final entity in root.list(recursive: true)) {
          if (entity is! File || p.extension(entity.path).toLowerCase() != '.json') continue;
          try {
            final modified = await entity.lastModified();
            final board = _boardFromJson(
              json.decode(await entity.readAsString()) as Map<String, dynamic>,
              includeTiles: includeTiles,
            );
            final previousModified = modifiedById[board.id];
            if (previousModified == null || modified.isAfter(previousModified)) {
              boardsById[board.id] = board;
              modifiedById[board.id] = modified;
            }
          } catch (e) {
            debugPrint('listBoards: failed to load ${entity.path}: $e');
          }
        }
        if (boardsById.isNotEmpty) {
          return _areaFilter(_sortBoards(_withoutDeletedBoards(boardsById.values)), area);
        }
      }
      // Fallback to old assets/boards path for backward compatibility
      final projectBoardsDir = Directory('$_projectRoot/assets/boards');
      if (await projectBoardsDir.exists()) {
        final files = projectBoardsDir.listSync().whereType<File>().toList();
        final boards = <Board>[];
        for (var f in files) {
          try {
            final m = json.decode(await f.readAsString()) as Map<String, dynamic>;
            boards.add(Board.fromMap(m, includeTiles: includeTiles));
          } catch (e) {
            debugPrint('listBoards: failed to load fallback ${f.path}: $e');
          }
        }
        if (boards.isNotEmpty) return _areaFilter(_sortBoards(boards), area);
      }
    }

    final currentPrefix = _getBoardKey('');
    const defaultPrefix = 'board_default_';
    if (kIsWeb) {
      final keys = _prefs!.getKeys();
      final boardsById = <String, Board>{};
      for (final prefix in [defaultPrefix, currentPrefix]) {
        for (final key in keys.where((key) => key.startsWith(prefix))) {
          try {
            final m = json.decode(_prefs!.getString(key)!) as Map<String, dynamic>;
            final board = Board.fromMap(m, includeTiles: includeTiles);
            // Cached prebuilt boards can have stale hierarchy metadata (tier,
            // area, parent). Trust the compiled/runtime hierarchy instead.
            if (board.id.startsWith('prebuilt_')) {
              final areaFromHierarchy = _areaForBoardName(board.name);
              if (areaFromHierarchy != null) board.area = areaFromHierarchy;
              final tier = hierarchyTier(board.name);
              board.tier = tier;
              board.isSubBoard = tier > 1;
              board.isTertiaryBoard = tier > 2;
              board.isQuaternaryBoard = tier > 3;
              board.isQuinaryBoard = tier > 4;
              final parentId = hierarchyParentId(board.name);
              board.parentBoardId = parentId ?? '';
            }
            boardsById[board.id] = board;
          } catch (e) {
            debugPrint('listBoards: failed to decode web key $key: $e');
          }
        }
      }

      // Inject prebuilt boards missing from storage as lightweight placeholders.
      // The full JSON is only loaded when the user selects the board's tab.
      for (final name in prebuiltBoardNames) {
        if (area != null && _areaForBoardName(name) != area) continue;
        final id = prebuiltBoardId(name);
        if (!boardsById.containsKey(id) && !_deletedBoardIds.contains(id)) {
          final tier = hierarchyTier(name);
          final parentName = hierarchyParent(name);
          final parentId = (parentName != null && parentName.isNotEmpty)
              ? prebuiltBoardId(parentName)
              : null;
          final index = runtimeBoardHierarchy
              .indexWhere((e) => e.name.toLowerCase() == name.toLowerCase());
          final sortOrder = index >= 0 ? index : 0;
          boardsById[id] = Board(
            id: id,
            name: name,
            area: _areaForBoardName(name),
            parentBoardId: parentId,
            rows: defaultBoardRows,
            columns: defaultBoardColumns,
            tiles: const [],
            isSubBoard: tier > 1,
            isTertiaryBoard: tier > 2,
            isQuaternaryBoard: tier > 3,
            isQuinaryBoard: tier > 4,
            tier: tier,
            sortOrder: sortOrder,
          );
        }
      }
      
      return _areaFilter(_sortBoards(_withoutDeletedBoards(boardsById.values)), area);
    } else {
      final boardsById = <String, Board>{};
      for (final prefix in [defaultPrefix, currentPrefix]) {
        final files = _dataDir!
            .listSync()
            .whereType<File>()
            .where((file) => p.basename(file.path).startsWith(prefix));
        for (final file in files) {
          try {
            final content = await file.readAsString();
            final m = json.decode(content) as Map<String, dynamic>;
            final board = Board.fromMap(m, includeTiles: includeTiles);
            boardsById[board.id] = board;
          } catch (e) {
            debugPrint('listBoards: failed to load native file ${file.path}: $e');
          }
        }
      }
      return _areaFilter(_sortBoards(_withoutDeletedBoards(boardsById.values)), area);
    }
  }

  List<Board> _sortBoards(List<Board> boards) {
    boards.sort((a, b) {
      final aIndex = prebuiltBoardNames.indexOf(a.name);
      final bIndex = prebuiltBoardNames.indexOf(b.name);
      final aPrebuilt = aIndex >= 0;
      final bPrebuilt = bIndex >= 0;

      // Prebuilt boards are always ordered by the compiled hierarchy.
      // This ignores stale / auto-generated sortOrder values and ensures
      // the landing board for each area is always first.
      if (aPrebuilt && bPrebuilt) {
        return aIndex.compareTo(bIndex);
      }
      if (aPrebuilt) return -1;
      if (bPrebuilt) return 1;

      // For any remaining boards, fall back to sortOrder then name.
      if (a.sortOrder != 0 && b.sortOrder != 0) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      if (a.sortOrder != 0) return -1;
      if (b.sortOrder != 0) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return boards;
  }

  List<Board> _areaFilter(List<Board> boards, String? area) {
    if (area == null) return boards;
    return boards.where((b) => b.area == area).toList();
  }

  Future<Board?> loadBoard(String id) async {
    if (kIsWeb && _deletedBoardIds.contains(id)) return null;
    if (!kIsWeb && _projectRoot != null) {
      final jsonFile = await _findProjectJsonFile(id);
      if (jsonFile != null) {
        try {
          return _boardFromJson(json.decode(await jsonFile.readAsString()) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error loading board $id from JSON: $e');
        }
      }
      // Fallback to old assets/boards path for backward compatibility
      final f = File('$_projectRoot/assets/boards/$id.json');
      if (await f.exists()) {
        return Board.fromMap(json.decode(await f.readAsString()));
      }
    }

    final key = _getBoardKey(id);
    if (kIsWeb) {
      // For prebuilt boards the JSON file is the source of truth; ignore any
      // stale or empty cached copy in localStorage.
      if (id.startsWith('prebuilt_')) {
        final asset = await _loadBoardFromAssets(id, _nameFromBoardId(id));
        if (asset != null) return asset;
      }
      final raw = _prefs!.getString(key);
      if (raw == null) return null;
      return _boardFromJson(json.decode(raw) as Map<String, dynamic>);
    } else {
      final f = File('${_dataDir!.path}/$key.json');
      if (!await f.exists()) return null;
      final m = json.decode(await f.readAsString()) as Map<String, dynamic>;
      return _boardFromJson(m);
    }
  }

  // In-memory board cache. Keyed by board id.
  final Map<String, Board> _boardCache = {};

  /// Clear a specific board from the in-memory cache.
  void clearBoardCache(String id) => _boardCache.remove(id);

  /// Clear all cached boards.
  void clearAllBoardCache() => _boardCache.clear();

  /// Returns a board from the cache, or loads it from storage if not present.
  /// This is the preferred call for lazy board loading.
  Future<Board?> getBoard(String id) async {
    final cached = _boardCache[id];
    if (cached != null) return cached;
    final board = await loadBoard(id);
    if (board != null) _boardCache[id] = board;
    return board;
  }

  /// Persist just the board's sortOrder without re-writing the full board JSON.
  Future<void> saveSortOrder(Board board) async {
    await _saveSortOrder(board);
  }

  final Map<String, Completer<void>> _saveInProgress = {};

  Future<void> saveBoard(Board board, {bool recordSync = true}) async {
    // Save Guard: Prevent concurrent saves of the same board to avoid race conditions and redundant IO
    if (_saveInProgress.containsKey(board.id)) {
      debugPrint('Save already in progress for board ${board.id}, waiting...');
      return _saveInProgress[board.id]!.future;
    }

    final completer = Completer<void>();
    _saveInProgress[board.id] = completer;

    try {
      await _clearBoardDeletion(board.id);
      await _writeBoard(board,
          cacheInWebStorage: true,
          mirrorToDisk: true);
      _boardCache[board.id] = board;
      await _saveSortOrder(board);

      // Register new board in the appropriate hierarchy.
      // Runs on ALL platforms so web and native present identically.
      // Root-level utility boards like Favorites are excluded.
      if (board.id == 'prebuilt_favorites') {
        // Favorites lives at root, not in any area hierarchy.
      } else if (!board.id.startsWith('link_') && !isInBoardHierarchy(board.name)) {
        String? parentName;
        if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
          final parent = await loadBoard(board.parentBoardId!);
          parentName = parent?.name;
        }
        final entry = BoardHierarchyEntry(board.name, board.area, parentName);
        final userId = _currentProfileId ?? 'default';

        if (_isAdmin) {
          // Admin edits go directly into the static/compiled hierarchy —
          // persisted to prefs AND mirrored to the dev server which writes
          // the change back to board_hierarchy.dart on disk.
          await addToRuntimeHierarchy(entry);
          _mirrorHierarchyToDevServer();
          debugPrint('BoardHierarchy [admin]: added "${board.name}" under area '
              '"${board.area}"${parentName != null ? ', parent "$parentName"' : ''}');
        } else {
          // User-created boards go in the per-user hierarchy —
          // only visible to this user.
          await addUserHierarchyEntry(userId, entry);
          debugPrint('BoardHierarchy [$userId]: added "${board.name}" under area '
              '"${board.area}"${parentName != null ? ', parent "$parentName"' : ''}');
        }
      }

      if (recordSync) {
        try {
          final sync = await SyncService.init().timeout(const Duration(seconds: 2));
          await sync.recordChange(
            entityType: SyncEntityType.board,
            entityId: board.id,
            operation: SyncOperation.upsert,
            payload: board.toMap(),
          ).timeout(const Duration(seconds: 2));
          // Automatically push the pending queue after a board save.
          await sync.pushAllPending().timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('Sync failed (ignoring): $e');
        }
      }

      // Auto-sync tile labels to image search tags.
      _syncTileLabelsToImageTags(board);
    } catch (e) {
      debugPrint('Error saving board ${board.id}: $e');
      rethrow;
    } finally {
      _saveInProgress.remove(board.id);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Promote a user-created board to a prebuilt (admin only).
  /// It receives a `prebuilt_` id, is removed from its old local key, and
  /// re-saved so it is loaded from source on the next run.
  Future<void> publishAsPrebuilt(Board board) async {
    final oldId = board.id;
    if (board.id.startsWith('prebuilt_')) {
      // Already prebuilt; just re-save to mirror to disk.
      await saveBoard(board);
      return;
    }
    board.id = prebuiltBoardId(board.name);
    await deleteBoard(oldId);
    await saveBoard(board);
  }

  /// Push every local board (including user ones) to the project as prebuilt
  /// boards. Intended for the offline sync / admin "push to project" action.
  Future<void> pushAllToProject() async {
    final all = await listBoards();
    for (final board in all) {
      try {
        final key = _getBoardKey(board.id);
        if (board.id.startsWith('prebuilt_')) {
          // Only push the local (edited) copy to the project, never the source.
          final hasLocal = kIsWeb
              ? (_prefs?.containsKey(key) ?? false)
              : (await File('${_dataDir!.path}/$key.json').exists());
          if (hasLocal) {
            final local = await loadBoard(board.id);
            if (local != null) {
              await _writeBoard(local, mirrorToDisk: true, cacheInWebStorage: true);
            }
          }
        } else {
          await publishAsPrebuilt(board);
        }
      } catch (e) {
        debugPrint('pushAllToProject failed for ${board.id}: $e');
      }
    }
    _mirrorHierarchyToDevServer();
  }

  /// Scans every tile on [board].  For each tile whose label (lowercased)
  /// does not match the image filename (lowercased, no extension), the
  /// tile's label is added as a search tag for that image in
  /// [SymbolMetadataService].  Runs fire-and-forget so it never blocks
  /// the save path.
  void _syncTileLabelsToImageTags(Board board) async {
    try {
      final meta = await SymbolMetadataService.init();
      final updates = <String, List<String>>{};
      for (final tile in board.tiles) {
        if (tile.isBoardLink || tile.imageAsset.isEmpty || tile.label.isEmpty) continue;
        final imageFilename = p.basenameWithoutExtension(tile.imageAsset).toLowerCase();
        final tileLabel = tile.label.toLowerCase();
        if (imageFilename == tileLabel) continue;
        final assetId = tile.imageAsset;
        updates.putIfAbsent(assetId, () => []).add(tileLabel);
      }
      await meta.batchAddTags(updates);
    } catch (e) {
      debugPrint('Error syncing tile labels to image tags: $e');
    }
  }

  /// Restores all default prebuilt boards by clearing their deletion
  /// tombstones and re-running the generation pipeline.  User-created
  /// boards are left untouched.
  Future<void> restoreDefaultBoards() async {
    _deletedBoardIds.removeWhere((id) => id.startsWith('prebuilt_'));
    await _deletionPrefs.setStringList(
      'deleted_board_ids_v2',
      _deletedBoardIds.toList(),
    );
    await _ensurePrebuiltBoards();
    await _ensureProjectBoardsFromAssets();
    await _ensureMissingSubboards();
  }

/// WRITER
/// Saves a board's JSON data. 
/// It writes to the project root (if set), and then to 
/// the primary storage (Web or Native).
/// If admin profile is active, also saves to default profile.

  Future<void> _freeLocalStorageSpace() async {
    if (!kIsWeb || _prefs == null) return;
    // The symbol metadata cache can be rebuilt in memory; free its persisted copy.
    await _prefs!.remove('aac_symbol_metadata_v1');
  }

  Future<void> _writeBoard(Board board, {bool mirrorToDisk = true, bool cacheInWebStorage = true}) async {
    _normalizePersistentIds(board);
    final boardJson = _boardToJson(board);

    if (!kIsWeb && _projectRoot != null && mirrorToDisk) {
      final existingFile = await _findProjectJsonFile(board.id);
      final jsonFile = await _projectJsonFileForBoard(board);
      await jsonFile.writeAsString(JsonEncoder.withIndent('  ').convert(boardJson));

      if (existingFile != null &&
          p.normalize(existingFile.path) != p.normalize(jsonFile.path)) {
        await existingFile.delete();
      }

      await _writeWordList(board, jsonFile.parent);
    }

    // In web builds, also try to mirror the save to a local dev server
    if (kIsWeb && mirrorToDisk) {
      await _mirrorSaveToDevServer(boardJson);
    }

    final key = _getBoardKey(board.id);
    if (kIsWeb) {
      final encoded = json.encode(board.toMap());
      if (cacheInWebStorage) {
        try {
          await _prefs!.setString(key, encoded);
        } catch (e) {
          if (e.toString().contains('QuotaExceededError')) {
            debugPrint('localStorage quota exceeded while saving board ${board.id}. Freeing caches and skipping.');
            await _freeLocalStorageSpace();
            // Skip the localStorage cache for this board; it can be re-loaded from source.
            return;
          } else {
            rethrow;
          }
        }

        if (_isAdmin) {
          // OPTIMIZATION: Instead of scanning ALL keys with _prefs!.getKeys(),
          // we construct the specific keys for known profiles.
          try {
            final profilesRaw = _prefs!.getString('aac_user_profiles');
            if (profilesRaw != null && profilesRaw.isNotEmpty) {
              final List<dynamic> profiles = json.decode(profilesRaw);
              for (final p in profiles) {
                final id = p['id'] as String?;
                if (id == null || id == 'default' || id == 'admin') continue;
                final profileKey = 'board_${id}_${board.id}';
                try {
                  await _prefs!.setString(profileKey, encoded);
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('Error propagating admin board edit to profiles: $e');
          }
        }
      }
    } else {
      final encoded = json.encode(board.toMap());
      final f = File('${_dataDir!.path}/$key.json');
      await f.writeAsString(encoded);

      if (_isAdmin) {
        // Update all profile files for this board
        final boardSuffix = '_${board.id}.json';
        final files = _dataDir!.listSync().whereType<File>();
        for (final file in files) {
          if (p.basename(file.path).startsWith('board_') &&
              p.basename(file.path).endsWith(boardSuffix)) {
            await file.writeAsString(encoded);
          }
        }
      }
    }
  }

  Future<void> _writeWordList(Board board, Directory targetDir) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sanitisedName = board.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final fileName = '$sanitisedName - Word List - $dateStr.txt';
    final words = board.tiles
        .where((t) => t.label.trim().isNotEmpty)
        .map((t) => t.label.trim())
        .toList();
    final content = '${board.name}\n${'=' * board.name.length}\n\n${words.join('\n')}\n';
    final file = File(p.join(targetDir.path, fileName));
    await file.writeAsString(content);
  }

  /// POST the board JSON to a small local dev server so edits made in the web
  /// preview are written straight back to the project source files. If the
  /// server is not running this fails silently and the board still lives in
  /// browser storage.
  Future<void> _mirrorSaveToDevServer(Map<String, dynamic> boardJson) async {
    try {
      final uri = Uri.parse('http://localhost:8787/saveBoard');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(boardJson),
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) {
        debugPrint('Dev save server returned ${response.statusCode}');
      }
    } catch (e) {
      // Server not running; ignore.
    }
  }

  /// List the last three versioned backups of a board from the dev server.
  Future<List<Map<String, dynamic>>> listVersions(String boardId, {String area = 'Common'}) async {
    if (!kIsWeb) return [];
    try {
      final uri = Uri.parse('http://localhost:8787/listVersions?id=$boardId&area=$area');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return (body['versions'] as List<dynamic>?)
                ?.map((v) => v as Map<String, dynamic>)
                .toList() ??
            [];
      }
    } catch (e) {
      debugPrint('listVersions error: $e');
    }
    return [];
  }

  /// Restore a specific versioned backup of a board.
  Future<bool> restoreVersion(String boardId, String filename, {String area = 'Common'}) async {
    if (!kIsWeb) return false;
    try {
      final encoded = Uri.encodeComponent(filename);
      final uri = Uri.parse('http://localhost:8787/restoreVersion?id=$boardId&area=$area&filename=$encoded');
      final response = await http.post(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('restoreVersion error: $e');
      return false;
    }
  }

  /// POST the full runtime hierarchy to the local dev server so it can write
  /// the entries back to board_hierarchy.dart.  Fails silently if the server
  /// is not running.
  void _mirrorHierarchyToDevServer() {
    try {
      final entries = runtimeBoardHierarchy.map((e) => e.toJson()).toList();
      final uri = Uri.parse('http://localhost:8787/saveHierarchy');
      http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'entries': entries}),
          )
          .timeout(const Duration(seconds: 5))
          .then((_) {
            debugPrint('Hierarchy mirrored to dev server successfully');
          }, onError: (e) {
            debugPrint('Failed to mirror hierarchy: $e');
          });
    } catch (e) {
      debugPrint('Error in _mirrorHierarchyToDevServer: $e');
    }
  }

  Future<void> deleteBoard(String id) async {
    // Load board metadata before hiding it behind its deletion tombstone so
    // the web mirror can compute the correct source-file area.
    String? boardName;
    String? boardArea;
    if (kIsWeb) {
      try {
        final board = await loadBoard(id);
        boardName = board?.name;
        boardArea = board?.area;
      } catch (_) {}
    }
    await _markBoardDeleted(id);

    // In web builds, also try to mirror the deletion to a local dev server so
    // deletions made in the web preview are reflected in the project files.
    if (kIsWeb) {
      unawaited(_mirrorDeleteToDevServer(id, boardName, boardArea));
    }

    final key = _getBoardKey(id);
    if (kIsWeb) {
      await _prefs!.remove(key);

      if (_isAdmin) {
        // OPTIMIZATION: Instead of scanning ALL keys, construct specific keys.
        try {
          final profilesRaw = _prefs!.getString('aac_user_profiles');
          if (profilesRaw != null && profilesRaw.isNotEmpty) {
            final List<dynamic> profiles = json.decode(profilesRaw);
            for (final p in profiles) {
              final pid = p['id'] as String?;
              if (pid == null || pid == 'default' || pid == 'admin') continue;
              final profileKey = 'board_${pid}_$id';
              await _prefs!.remove(profileKey);
            }
          }
        } catch (e) {
          debugPrint('Error propagating admin board delete to profiles: $e');
        }
      }
    } else {
      final f = File('${_dataDir!.path}/$key.json');
      if (await f.exists()) await f.delete();
      
      if (_isAdmin) {
        // Remove from all profiles
        final boardSuffix = '_$id.json';
        final files = _dataDir!.listSync().whereType<File>();
        for (final file in files) {
          if (p.basename(file.path).startsWith('board_') && p.basename(file.path).endsWith(boardSuffix)) {
            await file.delete();
          }
        }
      }
    }
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.board,
      entityId: id,
      operation: SyncOperation.delete,
    );
  }

  /// POST a board deletion to the local dev server so deletions made in the web
  /// preview are reflected in the project source files. If the server is not
  /// running this fails silently.
  Future<void> _mirrorDeleteToDevServer(String id, String? boardName, String? boardArea) async {
    try {
      final area = (boardArea != null && boardArea.isNotEmpty)
          ? boardArea
          : _areaForBoardName(boardName ?? _nameFromBoardId(id));
      final uri = Uri.parse('http://localhost:8787/deleteBoard');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'id': id, 'area': area}),
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) {
        debugPrint('Dev delete server returned ${response.statusCode}');
      }
    } catch (e) {
      // Server not running; ignore.
    }
  }

/// EXPORTER
/// Utility for Desktop to dump everything currently in 
/// the app's database into the project source code.

  Future<void> exportToProject(String projectRoot) async {
    final boards = await listBoards();
    for (var board in boards) {
      final area = board.area.isNotEmpty ? board.area : _areaForBoardName(board.name);
      Directory? parentDir;
      if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
        final parentFile = await _findProjectJsonFile(board.parentBoardId!);
        if (parentFile != null) parentDir = parentFile.parent;
      }
      final areaRoot = Directory(p.join(projectRoot, 'lib', 'data', 'boards', area));
      Directory boardDir;
      if (parentDir != null) {
        boardDir = Directory(p.join(parentDir.path, _boardFolderName(board.name)));
      } else if (board.tier > 1) {
        boardDir = areaRoot;
      } else {
        boardDir = Directory(p.join(areaRoot.path, _boardFolderName(board.name)));
      }
      if (!await boardDir.exists()) {
        await boardDir.create(recursive: true);
      }
      final f = File(p.join(boardDir.path, '${board.id}.json'));
      await f.writeAsString(JsonEncoder.withIndent('  ').convert(_boardToJson(board)));
    }
  }

  /// Compute the nested file path for a board under [root].
  /// Uses the same parent-chain logic as [_projectJsonFileForBoard].
  Future<File> boardJsonPathUnder(Board board, String root) async {
    final area = board.area.isNotEmpty ? board.area : _areaForBoardName(board.name);
    final areaRoot = Directory(p.join(root, 'lib', 'data', 'boards', area));
    String? parentRelativePath;
    if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
      final parentFile = await _findProjectJsonFile(board.parentBoardId!);
      if (parentFile != null && _projectRoot != null) {
        final boardsRoot = p.join(_projectRoot!, 'lib', 'data', 'boards');
        parentRelativePath = p.relative(parentFile.parent.path, from: boardsRoot);
      }
    }

    // On web, _findProjectJsonFile returns null. Fall back to looking up the
    // parent board from storage and computing the path recursively.
    if (parentRelativePath == null && board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
      final parentBoard = await loadBoard(board.parentBoardId!);
      if (parentBoard != null) {
        parentRelativePath = await boardRelativePath(parentBoard);
      }
    }

    Directory boardDir;
    if (parentRelativePath != null) {
      boardDir = Directory(p.join(root, 'lib', 'data', 'boards', parentRelativePath, _boardFolderName(board.name)));
    } else if (board.tier > 1) {
      boardDir = areaRoot;
    } else {
      boardDir = Directory(p.join(areaRoot.path, _boardFolderName(board.name)));
    }
    if (!await boardDir.exists()) {
      await boardDir.create(recursive: true);
    }
    return File(p.join(boardDir.path, '${board.id}.json'));
  }

  /// Return the relative path (from `lib/data/boards/`) for [board],
  /// e.g. `Common/Common Words` or `Common/Letters/Phonics/Phase 3 Phonics`.
  /// Works on all platforms including web (uses storage, not filesystem).
  Future<String> boardRelativePath(Board board) async {
    if (board.id == 'prebuilt_favorites') return '';
    final area = board.area.isNotEmpty ? board.area : _areaForBoardName(board.name);
    if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
      Board? parentBoard = _boardCache[board.parentBoardId!];
      if (parentBoard == null) {
        parentBoard = await loadBoard(board.parentBoardId!);
      }
      if (parentBoard != null) {
        final parentPath = await boardRelativePath(parentBoard);
        return '$parentPath/${_boardFolderName(board.name)}';
      }
      final parentName = _hierarchyNameForId(board.parentBoardId!);
      if (parentName != null) {
        final parentPath = _hierarchyRelativePath(parentName);
        return '$parentPath/${_boardFolderName(board.name)}';
      }
    }
    if (board.tier > 1) return area;
    return '$area/${_boardFolderName(board.name)}';
  }

  String? _hierarchyNameForId(String id) {
    for (final e in runtimeBoardHierarchy) {
      if (prebuiltBoardId(e.name) == id) return e.name;
    }
    return null;
  }

  String _hierarchyRelativePath(String name) {
    final parent = hierarchyParent(name);
    if (parent == null) {
      return '${hierarchyArea(name)}/${_boardFolderName(name)}';
    }
    return '${_hierarchyRelativePath(parent)}/${_boardFolderName(name)}';
  }

  Future<void> clearAllBoardTiles() async {
    final boards = await listBoards();
    for (var board in boards) {
      if (board.tiles.isNotEmpty) {
        board.tiles.clear();
        await saveBoard(board);
      }
    }
  }

  Future<void> mergeAssets(String oldPath, String newPath) async {
    // Standardize paths
    final oldP = oldPath.replaceAll('\\', '/');
    final newP = newPath.replaceAll('\\', '/');
    
    if (oldP == newP) return;

    await _updateAssetInAllBoards(oldP, newP);

    // 4. Delete the old asset file
    if (!kIsWeb && !oldP.startsWith('assets/') && !oldP.startsWith('http')) {
      final oldFile = File(oldP);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
    
    // Also notify dev server if on web
    if (kIsWeb) {
      try {
        final uri = Uri.parse('http://localhost:8787/deleteImage');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'path': oldP}),
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  Future<void> deleteAssetGlobally(String path) async {
    final p = path.replaceAll('\\', '/');
    await _updateAssetInAllBoards(p, '');

    if (!kIsWeb && !p.startsWith('assets/') && !p.startsWith('http')) {
      final file = File(p);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (kIsWeb) {
      try {
        final uri = Uri.parse('http://localhost:8787/deleteImage');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'path': p}),
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  Future<void> _updateAssetInAllBoards(String oldPath, String newPath) async {
    // 1. Identify all boards across ALL profiles
    List<String> boardKeys = [];
    if (kIsWeb) {
      boardKeys = _prefs!.getKeys().where((k) => k.startsWith('board_')).toList();
    } else {
      boardKeys = _dataDir!.listSync().whereType<File>()
          .map((f) => p.basenameWithoutExtension(f.path))
          .where((name) => name.startsWith('board_'))
          .toList();
    }

    // 2. Update boards in storage
    for (final key in boardKeys) {
      try {
        String? raw;
        if (kIsWeb) {
          raw = _prefs!.getString(key);
        } else {
          raw = await File('${_dataDir!.path}/$key.json').readAsString();
        }

        if (raw == null) continue;
        final m = json.decode(raw) as Map<String, dynamic>;
        final b = Board.fromMap(m);
        
        bool changed = false;
        for (int i = 0; i < b.tiles.length; i++) {
          if (b.tiles[i].imageAsset.replaceAll('\\', '/') == oldPath) {
            b.tiles[i] = b.tiles[i].copyWith(imageAsset: newPath);
            changed = true;
          }
        }

        if (changed) {
          final encoded = json.encode(b.toMap());
          if (kIsWeb) {
            await _prefs!.setString(key, encoded);
          } else {
            await File('${_dataDir!.path}/$key.json').writeAsString(encoded);
          }
        }
      } catch (e) {
        debugPrint('Error updating asset in board $key: $e');
      }
    }

    // 3. Update project JSON files if in dev mode
    if (!kIsWeb && _projectRoot != null) {
      final root = Directory(p.join(_projectRoot!, 'lib', 'data', 'boards'));
      if (await root.exists()) {
        await for (final areaDir in root.list(recursive: false)) {
          if (areaDir is! Directory) continue;
          final files = areaDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
          for (final f in files) {
            try {
              final raw = await f.readAsString();
              final m = json.decode(raw) as Map<String, dynamic>;
              final b = _boardFromJson(m);
              
              bool changed = false;
              for (int i = 0; i < b.tiles.length; i++) {
                if (b.tiles[i].imageAsset.replaceAll('\\', '/') == oldPath) {
                  b.tiles[i] = b.tiles[i].copyWith(imageAsset: newPath);
                  changed = true;
                }
              }

              if (changed) {
                await f.writeAsString(JsonEncoder.withIndent('  ').convert(_boardToJson(b)));
              }
            } catch (_) {}
          }
        }
      }
    }
  }

  List<SymbolTile> _generateSubjectVocabularyTiles() {
    final names = [
      'Lessons',
      'Sentence Creator',
      'Small Words (Subject)',
      'Letters (Subject)',
      'Numbers (Subject)',
      'Breaktime',
      'Lunchtime',
      'Tutor Time',
      'English',
      'Maths',
      'Science',
      'T.F.L. / I.T.',
      'P.D.',
      'P.E.E.P.',
      'E.P.I.C.',
      'P.E.',
      'Art',
      'Performing Arts',
      'Sustainability',
      'Cooking',
      'Resistant Materials',
      'Textiles',
      'Religion and Worldviews',
      'Music',
      'Horticulture',
      'Retail',
      'Photography',
      'Construction',
      'Engineering',
      'Design Technology',
      'Hair and Beauty',
      'Health and Social Care',
      'Public Services',
      'S.T.E.M.',
      'Option A',
      'Option B',
      'Option C',
      'Tech Rotation',
    ];

    return names.indexed.map((entry) {
      final (index, name) = entry;
      final id = prebuiltBoardId(name);
      final label = name.replaceFirst(' (Subject)', '');
      
      // Try to find a matching icon in Subjects folder
      String imagePath = '';
      if (label == 'T.F.L. / I.T.') {
          imagePath = 'assets/symbols/Subjects/Information Technology.png';
      } else {
          imagePath = 'assets/symbols/Subjects/${_toTitleCase(label)}.png';
      }

      return SymbolTile(
        id: 'subject_hub_$index',
        label: label,
        category: 'Subject Vocab',
        imageAsset: imagePath,
        isBoardLink: true,
        linkedBoardId: id,
        bgColor: '#000000',
        textColor: '#FFFFFF',
      );
    }).toList();
  }

  List<SymbolTile> _generatePeopleAtSchoolTiles() {
    final words = [
      'teacher', 'teaching assistant', 'yellow lanyard', 'tutor team',
      'duty staff', 'head teacher', 'office staff', 'first aid staff',
      'dinner hall', 'drivers and escorts', 'speech and language', 'friends',
    ];
    return words.map((w) => SymbolTile(
      id: 'school_people_${w.replaceAll(RegExp(r"[^a-z0-9]"), '_')}',
      label: w,
      category: 'My School',
      imageAsset: 'assets/symbols/4. My School/People At School/${w.toLowerCase()}.png',
    )).toList();
  }

  List<SymbolTile> _generateBaycroftExpectsTiles() {
    final words = [
      'be kind', 'be safe', 'be respectful', 'be responsible',
      'be ready to learn', 'try your best', 'help others', 'listen carefully',
      'follow instructions', 'keep trying', 'be honest', 'take turns',
    ];
    return words.map((w) => SymbolTile(
      id: 'baycroft_${w.replaceAll(RegExp(r"[^a-z0-9]"), '_')}',
      label: w,
      category: 'My School',
      imageAsset: 'assets/symbols/4. My School/Baycroft Expects/${w.toLowerCase()}.png',
    )).toList();
  }

  List<SymbolTile> _generateActionsTiles() {
    final words = [
      'run', 'walk', 'jump', 'hop', 'skip', 'climb',
      'swim', 'throw', 'catch', 'kick', 'hit', 'push',
      'pull', 'carry', 'lift', 'drop', 'pick up', 'put down',
      'open', 'close', 'turn', 'move', 'stop', 'start',
      'sit', 'stand', 'lie down', 'roll', 'slide', 'spin',
    ];
    return words.map((w) => SymbolTile(
      id: 'action_${w.replaceAll(RegExp(r"[^a-z0-9]"), '_')}',
      label: w,
      category: 'Actions',
      imageAsset: 'assets/symbols/1. Main Boards/Actions/${w.toLowerCase()}.png',
    )).toList();
  }

  List<SymbolTile> _generatePhonicsTiles() {
    final phaseNames = [
      'Letters', 'Phase 2 Phonics', 'Phase 3 Phonics',
      'Phase 4 Phonics', 'Phase 5 Phonics', 'Phase 6 Phonics',
    ];
    return phaseNames.map((phase) => SymbolTile(
      id: 'phonics_link_${phase.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), '_')}',
      label: phase,
      category: 'Phonics',
      imageAsset: 'assets/symbols/1. Main Boards/Phonics/${phase.toLowerCase()}.png',
      isBoardLink: true,
      linkedBoardId: prebuiltBoardId(phase),
      bgColor: 'transparent',
      textColor: '#000000',
    )).toList();
  }

  List<SymbolTile> _generatePhase2PhonicsTiles() {
    final words = [
      's', 'a', 't', 'p', 'I', 'i', 'n', 'm', 'd', 'to',
      'g', 'o', 'c', 'k', 'no', 'ck', 'e', 'u', 'r', 'go',
      'h', 'b', 'f', 'ff', 'the', 'l', 'll', 'ss', '', 'into',
    ];
    return words.map((w) {
      final id = 'phase2_${w.isEmpty ? "blank" : w.replaceAll(RegExp(r"[^a-z0-9]"), "_")}';
      if (w.isEmpty) {
        return SymbolTile(
          id: id, label: '', category: 'Phonics',
          imageAsset: '', bgColor: 'transparent',
        );
      }
      return SymbolTile(
        id: id,
        label: w,
        category: 'Phonics',
        imageAsset: 'assets/symbols/1. Main Boards/Phonics/Phase 2/${w.toLowerCase()}.png',
      );
    }).toList();
  }

  List<SymbolTile> _generateDisneyStoriesTiles() {
    final movies = [
      '1937 Snow White and The Seven Dwarfs',
      '1940 Pinocchio',
      '1940 Fantasia',
      '1941 Dumbo',
      '1942 Bambi',
      '1950 Cinderella',
      '1951 Alice In Wonderland',
      '1953 Peter Pan',
      '1955 Lady and The Tramp',
      '1959 Sleeping Beauty',
      '1961 101 Dalmatians',
      '1963 The Sword In The Stone',
      '1967 The Jungle Book',
      '1970 The Aristocats',
      '1973 Robin Hood',
      '1977 Winnie The Pooh',
      '1977 The Rescuers',
      '1981 The Fox and The Hound',
      '1985 The Black Cauldron',
      '1986 The Great Mouse Detective',
      '1988 Oliver and Company',
      '1989 The Little Mermaid',
      '1991 Beauty and The Beast',
      '1992 Aladdin',
      '1993 The Nightmare Before Christmas',
      '1994 The Lion King',
      '1995 Pocahontas',
      '1995 Toy Story',
      '1996 The Hunchback Of Notre Dame',
      '1997 Hercules',
      '1998 Mulan',
      '1998 A Bug\'s Life',
      '1999 Tarzan',
      '2000 Dinosaur',
      '2000 The Emperor\'s New Groove',
      '2001 Atlantis - The Lost Empire',
      '2001 Monsters, Inc.',
      '2002 Lilo and Stitch',
      '2002 Treasure Planet',
      '2003 Brother Bear',
      '2003 Finding Nemo',
      '2004 Home On The Range',
      '2004 The Incredibles',
      '2005 Chicken Little',
      '2006 Cars',
      '2007 Meet The Robinsons',
      '2007 Ratatouille',
      '2008 Bolt',
      '2008 WALL-E',
      '2009 The Princess and The Frog',
      '2009 Up',
      '2010 Tangled',
      '2012 Wreck-It Ralph',
      '2012 Brave',
      '2013 Frozen',
      '2014 Big Hero 6',
      '2015 Inside Out',
      '2015 The Good Dinosaur',
      '2016 Zootopia',
      '2016 Moana',
      '2017 Coco',
      '2020 Onward',
      '2020 Soul',
      '2021 Raya and The Last Dragon',
      '2021 Encanto',
      '2021 Luca',
      '2022 Turning Red',
      '2022 Strange World',
      '2023 Wish',
      '2023 Elemental',
      '2025 Elio',
    ];
    return movies.map<SymbolTile>((m) {
      final label = m.substring(5); // Remove "YYYY "
      final id = prebuiltBoardId(m);
      return SymbolTile(
        id: 'disney_link_${id.replaceAll('prebuilt_', '')}',
        label: label,
        category: 'Characters',
        imageAsset: '',
        isBoardLink: true,
        linkedBoardId: id,
        bgColor: 'transparent',
        textColor: '#000000',
      );
    }).toList();
  }

  /// JSON SOURCE-OF-TRUTH HELPERS
  /// These methods convert between the runtime Board/SymbolTile models and the
  /// canonical JSON format stored at lib/data/boards/[Area]/.

  /// Returns the area for [name] using the hierarchy as the primary source.
  /// Falls back to the legacy hardcoded sets for boards not yet in the
  /// hierarchy (e.g. My School / Subject Vocab boards).
  String _areaForBoardName(String name) {
    // 1. Try the hierarchy (authoritative).
    final hierArea = hierarchyArea(name);
    if (hierArea != 'Common' || findHierarchyEntry(name) != null) {
      return hierArea;
    }

    // 2. No legacy fallback: the 7 starter boards are the single source of truth.
    return 'Common';
  }

  Future<Board?> _loadBoardFromAssets(String id, String name, {bool includeTiles = true}) async {
    final area = _areaForBoardName(name);

    // In live web preview, prefer the dev server copy so edits made in the
    // preview persist over the compiled asset bundle.
    if (kIsWeb && Uri.base.host == 'localhost') {
      try {
        final uri = Uri.parse('http://localhost:8787/loadBoard?id=$id&area=$area');
        final response = await http.get(uri).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          return _boardFromJson(json.decode(response.body) as Map<String, dynamic>, includeTiles: includeTiles);
        }
      } catch (_) {}
    }

    // Find the canonical asset key for this board in the manifest.
    // On the web the manifest keys are prefixed with 'assets/' and may be
    // URL-encoded, so we decode and compare but keep the original key for the
    // actual load.
    String? originalAsset;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      String _fullyDecode(String p) {
        while (p.contains('%')) {
          try {
            final next = Uri.decodeComponent(p);
            if (next == p) break;
            p = next;
          } catch (_) {
            break;
          }
        }
        return p;
      }

      String _normalize(String p) {
        final stripped = p.startsWith('assets/') ? p.substring(7) : p;
        return _fullyDecode(stripped);
      }

      final areaPrefix = 'lib/data/boards/$area/';
      final boardsPrefix = 'lib/data/boards/';
      for (var i = 0; i < allAssets.length; i++) {
        final original = allAssets[i];
        final np = _normalize(original);
        if (np.startsWith(areaPrefix) && np.endsWith('/$id.json')) {
          originalAsset = original;
          break;
        }
      }

      if (originalAsset == null) {
        for (var i = 0; i < allAssets.length; i++) {
          final original = allAssets[i];
          final np = _normalize(original);
          if (np.startsWith(boardsPrefix) && np.endsWith('/$id.json')) {
            originalAsset = original;
            break;
          }
        }
      }
    } catch (_) {}

    // Built-in prebuilt boards that are not in the asset bundle have no
    // backing JSON; skip them instead of generating 404s.
    if (originalAsset == null && id.startsWith('prebuilt_')) {
      return null;
    }

    if (originalAsset != null) {
      try {
        final raw = await rootBundle.loadString(originalAsset);
        final board = _boardFromJson(json.decode(raw) as Map<String, dynamic>, includeTiles: includeTiles);
        if (board != null && _prefs != null) {
          final stored = _prefs!.getInt(_getSortOrderKey(board.id));
          if (stored != null) board.sortOrder = stored;
        }
        return board;
      } catch (_) {}
    }

    return null;
  }

  /// In the web preview, the dev save server persists board JSONs to the
  /// project source tree. On startup, if the browser's local storage has been
  /// cleared (or is empty for a fresh preview), this loads any board JSONs
  /// from the asset bundle back into local storage so the user's previous
  /// edits remain visible.
  Future<void> _ensureProjectBoardsFromAssets() async {
    // On web, do not bulk-cache prebuilt boards in localStorage; load on demand.
    if (kIsWeb) return;
    try {
      // In native dev mode, read directly from disk JSON files so edits
      // take effect immediately on next launch without a full rebuild.
      if (!kIsWeb && _projectRoot != null) {
        final root = Directory(p.join(_projectRoot!, 'lib', 'data', 'boards'));
        if (await root.exists()) {
          await for (final entity in root.list(recursive: true)) {
            if (entity is! File || !entity.path.endsWith('.json')) continue;
            try {
              final raw = await entity.readAsString();
              final assetBoard = _boardFromJson(json.decode(raw) as Map<String, dynamic>);
              if (_deletedBoardIds.contains(assetBoard.id)) continue;
              final storedBoard = await loadBoard(assetBoard.id);
              if (storedBoard == null) {
                await _writeBoard(assetBoard, mirrorToDisk: false);
              } else {
                // Always prefer on-disk JSON in dev mode — it's the source of truth
                await _writeBoard(assetBoard, mirrorToDisk: false);
              }
            } catch (e) {
              debugPrint('Error loading project board from disk ${entity.path}: $e');
            }
          }
        }
        return;
      }

      // Fallback: use Flutter asset manifest (production mode / web)
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetList = manifest.listAssets();
      for (final assetPath in assetList) {
        // Fix double-assets prefixing on some web platforms
        final path = assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
        if (!path.startsWith('lib/data/boards/') || !path.endsWith('.json')) continue;

        try {
          final raw = await rootBundle.loadString(assetPath);
          final assetBoard = _boardFromJson(json.decode(raw) as Map<String, dynamic>);
          if (_deletedBoardIds.contains(assetBoard.id)) continue;
          final storedBoard = await loadBoard(assetBoard.id);
          if (storedBoard == null) {
            // Board does not exist in storage yet — load it from the asset.
            await _writeBoard(assetBoard, mirrorToDisk: false);
          } else if (storedBoard.tiles.isNotEmpty) {
            // Check if stored board has missing images
            final tilesWithImages = storedBoard.tiles.where((t) => t.imageAsset.isNotEmpty && t.imageAsset.startsWith('assets/')).length;
            if (tilesWithImages < storedBoard.tiles.length * 0.5) {
              debugPrint('Board "${assetBoard.name}" has missing images — reloading from asset');
              await _writeBoard(assetBoard, mirrorToDisk: false);
            }
          }
        } catch (e) {
          debugPrint('Error loading project board from asset $assetPath: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading project boards from assets: $e');
    }
  }

  /// Check if a board's tiles have valid image files on disk.
  /// Returns the fraction (0.0–1.0) of tiles with existing asset files.
  double _imageFileExistenceRatio(List<dynamic> tiles) {
    if (tiles.isEmpty) return 1.0;
    var valid = 0;
    for (final t in tiles) {
      final img = (t['image'] as String? ?? t['imageAsset'] as String? ?? '').trim();
      if (img.isEmpty) continue;
      // Only validate assets/ paths — skip URLs, data: URIs, empty
      if (!img.startsWith('assets/')) { valid++; continue; }
      // Check if the file actually exists on disk
      if (kIsWeb || _projectRoot == null) { valid++; continue; }
      final fullPath = p.join(_projectRoot!, img);
      if (File(fullPath).existsSync()) valid++;
    }
    return valid / tiles.length;
  }

  Future<File?> _findProjectJsonFile(String id) async {
    if (kIsWeb || _projectRoot == null) return null;
    final root = Directory(p.join(_projectRoot!, 'lib', 'data', 'boards'));
    if (!await root.exists()) return null;
    final matches = <File>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && p.basename(entity.path) == '$id.json') {
        matches.add(entity);
      }
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aHas = a.path.contains(' (Montessori)');
      final bHas = b.path.contains(' (Montessori)');
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      // Prefer deeper canonical paths.
      return b.path.split(p.separator).length.compareTo(a.path.split(p.separator).length);
    });
    return matches.first;
  }

  String _boardFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .trim();
  }

  Future<File> _projectJsonFileForBoard(Board board) async {
    if (kIsWeb) throw UnsupportedError('Mirroring to disk not supported on web');
    // Root-level boards (like Favorites) are stored directly under lib/data/boards/
    if (board.id == 'prebuilt_favorites') {
      final rootDir = Directory(p.join(_projectRoot!, 'lib', 'data', 'boards'));
      if (!await rootDir.exists()) await rootDir.create(recursive: true);
      return File(p.join(rootDir.path, '${board.id}.json'));
    }
    return boardJsonPathUnder(board, _projectRoot!);
  }

  String _linkedBoardNameFromId(String linkedBoardId) {
    if (linkedBoardId.isEmpty) return '';
    if (linkedBoardId == 'prebuilt_a-z_of_sign' || linkedBoardId == 'prebuilt_a-z_of_sign') {
      return 'A-Z Of Sign';
    }
    if (linkedBoardId.startsWith('prebuilt_')) {
      return linkedBoardId;
    }
    return linkedBoardId;
  }

  /// Public wrapper so the board editor can import JSON files.
  Board boardFromJson(Map<String, dynamic> json) => _boardFromJson(json);

  Board _boardFromJson(Map<String, dynamic> json, {bool includeTiles = true}) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? 'Board';
    final columns = (json['columns'] as num?)?.toInt() ?? (json['layout']?['columns'] as num?)?.toInt() ?? defaultBoardColumns;
    final layout = json['layout'] as Map<String, dynamic>?;
    // Look for rows in 'layout' (canonical) or top-level (toMap/SharedPreferences)
    final rows = (layout?['rows'] as num?)?.toInt() ?? (json['rows'] as num?)?.toInt() ?? defaultBoardRows;
    final tilesJson = includeTiles ? (json['tiles'] as List<dynamic>?) ?? [] : [] as List<dynamic>;
    final tiles = tilesJson.map((t) {
      final tileMap = Map<String, dynamic>.from(t);
      var tile = _tileFromJson(tileMap, boardName: name);
      
      // Automatic data sanitization for known folder changes
      if (tile.imageAsset.contains('Completed SymboTalk Board Screenshots')) {
        tile = tile.copyWith(imageAsset: '');
      }
      // Fix double-assets prefixing (canonical path should only have one 'assets/')
      if (tile.imageAsset.startsWith('assets/assets/')) {
        tile = tile.copyWith(imageAsset: tile.imageAsset.replaceFirst('assets/assets/', 'assets/'));
      }
      // Redirect legacy lesson paths to the consolidated Subjects folder (Case-Sensitive on Web!)
      if (tile.imageAsset.contains('3. Lesson Vocab/Tutor Time, Events and Clubs/')) {
        final fileName = tile.imageAsset.split('/').last;
        // Asset paths on Web are case-sensitive. Most files in Subjects/ are Title Case.
        final fixedName = '${_toTitleCase(fileName.replaceAll('.png', '')).trim()}.png';
        tile = tile.copyWith(imageAsset: 'assets/symbols/Subjects/$fixedName');
      }
      // Redirect legacy baycroft paths
      if (tile.imageAsset.contains('2. Baycroft Specific/People At School/')) {
        final fileName = tile.imageAsset.split('/').last;
        tile = tile.copyWith(imageAsset: 'assets/symbols/2. Baycroft Specific/People At School/$fileName');
      }
      
      // Redirect legacy 1. Main Boards paths to the new Common/... layout.
      // Common Words board lives in assets/Common/Common Words/.
      if (tile.imageAsset.contains('1. Main Boards/Common/')) {
        final fileName = tile.imageAsset.split('/').last;
        tile = tile.copyWith(imageAsset: 'assets/Common/Common Words/$fileName');
      } else if (tile.imageAsset.startsWith('assets/symbols/1. Main Boards/')) {
        final rest = tile.imageAsset.substring('assets/symbols/1. Main Boards/'.length);
        tile = tile.copyWith(imageAsset: 'assets/Common/$rest');
      }
      
      // Redirect legacy BOARDS and Subjects prefixes to the current top-level folders.
      if (tile.imageAsset.startsWith('assets/symbols/BOARDS/')) {
        tile = tile.copyWith(imageAsset: tile.imageAsset.replaceFirst('assets/symbols/BOARDS/', 'assets/BOARDS/'));
      }
      if (tile.imageAsset.startsWith('assets/symbols/Subjects/')) {
        tile = tile.copyWith(imageAsset: tile.imageAsset.replaceFirst('assets/symbols/Subjects/', 'assets/Subject Vocab/'));
      }
      
      return tile;
    }).toList();
    
    // Use the hierarchy for sub-board / tier / parent classification.
    final storedArea = json['area'] as String?;
    final storedParentBoardId = json['parentBoardId'] as String?;
    var parentBoardId = storedParentBoardId;

    var isSubBoard = (json['isSubBoard'] as bool?) ?? hierarchyIsSubBoard(name);
    var isTertiaryBoard = (json['isTertiaryBoard'] as bool?) ?? (hierarchyTier(name) >= 3);

    // Fill in missing parent IDs from the hierarchy.
    if (parentBoardId == null || parentBoardId.isEmpty) {
      parentBoardId = hierarchyParentId(name);
    }

    final fixedLayoutBoards = {
      'Feelings', 'Prepositions', 'Colours', 'Shades Of Colours',
      'Letters', 'Numbers',
      'Sad', 'Mad', 'Scared', 'Joyful', 'Strong', 'Calm',
    };

    final adjustableLayout = (json['adjustableLayout'] as bool?) ?? 
        !fixedLayoutBoards.contains(name);

    final area = (storedArea != null && storedArea.isNotEmpty) ? storedArea : _areaForBoardName(name);

    final isQuaternaryBoard = (json['isQuaternaryBoard'] as bool?) ?? false;
    final isQuinaryBoard = (json['isQuinaryBoard'] as bool?) ?? false;
    final tier = json['tier'] ?? (isQuinaryBoard ? 5 : (isQuaternaryBoard ? 4 : hierarchyTier(name)));

    return Board(
      id: id,
      name: name,
      area: area,
      parentBoardId: parentBoardId,
      rows: rows,
      columns: columns,
      adjustableLayout: adjustableLayout,
      backgroundColor: (json['backgroundColor'] as String?) ?? defaultBoardColor,
      boxScale: (json['boxScale'] as num?)?.toDouble() ?? 1.0,
      tileHeight: (json['tileHeight'] as num?)?.toDouble() ?? 100.0,
      tileWidth: (json['tileWidth'] as num?)?.toDouble() ?? 100.0,
      tiles: tiles,
      isSubBoard: isSubBoard,
      isTertiaryBoard: isTertiaryBoard,
      isQuaternaryBoard: isQuaternaryBoard,
      isQuinaryBoard: isQuinaryBoard,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      tier: tier,
      iconAssetPath: json['iconAssetPath'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  SymbolTile _tileFromJson(Map<String, dynamic> json, {String boardName = ''}) {
    final rawType = json['type'] as String? ?? 'vocabulary';
    final label = json['label'] as String? ?? '';
    // Read from "image" (project JSON format) OR "imageAsset" (Board.toMap() format)
    var image = json['image'] as String? ?? json['imageAsset'] as String?;

    // Sanitization: Never allow blob URLs to be loaded from saved JSON.
    if (image != null && image.startsWith('blob:')) {
      image = null;
    }

    final linkedBoardName = json['linkedBoardName'] as String?;
    final id = json['id'] as String? ?? 'tile_${DateTime.now().millisecondsSinceEpoch}';

    // Prefer the saved linkedBoardId; only fall back to deriving from name.
    String linkedBoardId = (json['linkedBoardId'] as String?) ?? '';
    if (linkedBoardId.isEmpty && linkedBoardName != null && linkedBoardName.isNotEmpty) {
      linkedBoardId = linkedBoardName.startsWith('prebuilt_')
          ? linkedBoardName
          : prebuiltBoardId(linkedBoardName);
    }

    // Determine logical flags from the type and fields
    final explicitBoardLink = (json['isBoardLink'] as bool?) == true;
    final isBoardLink = rawType == 'board_link' || explicitBoardLink || linkedBoardId.isNotEmpty;
    final isFullScreenImage = rawType == 'image_viewer' || (json['isFullScreenImage'] as bool?) == true;
    
    var bgColor = (json['bgColor'] as String?) ?? 'transparent';
    var textColor = (json['textColor'] as String?) ?? '#000000';

    // Fix corrupted transparent values written by older normalization code.
    if (bgColor.trim().isEmpty || bgColor.toLowerCase() == '#transparent') bgColor = 'transparent';
    if (textColor.trim().isEmpty || textColor.toLowerCase() == '#transparent') textColor = '#000000';

    if (isBoardLink && linkedBoardId.isNotEmpty) {
      if (bgColor == 'transparent') bgColor = '#000000';
      if (textColor == '#000000') textColor = '#FFFFFF';
    } else if (isFullScreenImage && bgColor == 'transparent') {
      bgColor = '#FFCDD2';
    }
    
    return SymbolTile(
      id: id,
      label: label,
      category: (json['category'] as String?) ?? 'Custom',
      imageAsset: image ?? '',
      emoji: (json['emoji'] as String?) ?? '',
      bgColor: bgColor,
      textColor: textColor,
      isBoardLink: isBoardLink,
      isFullScreenImage: isFullScreenImage,
      linkedBoardId: linkedBoardId,
      tileSize: (json['tileSize'] as num?)?.toDouble() ?? 1.0,
      colSpan: (json['colSpan'] as num?)?.toInt() ?? 1,
      rowSpan: (json['rowSpan'] as num?)?.toInt() ?? 1,
      customVoice: (json['customVoice'] as String?) ?? '',
    );
  }

  void _normalizePersistentIds(Board board) {
    // Link placeholders already have a unique, stable id; do not remap them to
    // the original prebuilt id, otherwise they would overwrite the real board.
    if (board.id.startsWith('link_')) return;
    board.id = prebuiltBoardId(board.name);
    final usedIds = <String>{};
    for (var index = 0; index < board.tiles.length; index++) {
      final tile = board.tiles[index];
      final label = tile.label.trim();
      final baseId = label.isEmpty
          ? '${board.id}_tile_${index + 1}'
          : '${board.id}_${label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '')}';
      var tileId = baseId;
      var suffix = 2;
      while (!usedIds.add(tileId)) {
        tileId = '${baseId}_$suffix';
        suffix++;
      }
      tile.id = tileId;
    }
  }

  Map<String, dynamic> _boardToJson(Board board) {
    final area = board.area.isNotEmpty ? board.area : _areaForBoardName(board.name);
    final json = <String, dynamic>{
      'id': board.id,
      'name': board.name,
      'area': area,
      'columns': board.columns,
      'backgroundColor': board.backgroundColor,
      'adjustableLayout': board.adjustableLayout,
      'isSubBoard': board.isSubBoard,
      'isTertiaryBoard': board.isTertiaryBoard,
      'isQuaternaryBoard': board.isQuaternaryBoard,
      'isQuinaryBoard': board.isQuinaryBoard,
      'sortOrder': board.sortOrder,
      'tier': board.tier,
      'boxScale': board.boxScale,
      'tileHeight': board.tileHeight,
      'tileWidth': board.tileWidth,
      'layout': {
        'rows': board.rows,
        'blankTilesAdded': 0,
      },
      'tiles': board.tiles.map((t) => _tileToJson(t)).toList(),
    };
    if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
      json['parentBoardId'] = board.parentBoardId;
    }
    return json;
  }

  Map<String, dynamic> _tileToJson(SymbolTile tile) {
    String type = 'vocabulary';
    String? linkedBoardName;
    
    // STRICT BLANK CHECK: If it has no label and no image and no linked board
    if (tile.label.isEmpty && tile.imageAsset.isEmpty && tile.emoji.isEmpty && tile.linkedBoardId.isEmpty) {
      type = 'blank';
    } else if (tile.isBoardLink && tile.linkedBoardId.isNotEmpty) {
      type = 'board_link';
      linkedBoardName = _linkedBoardNameFromId(tile.linkedBoardId);
    } else if (tile.isFullScreenImage) {
      type = 'image_viewer';
    }

    var imageAsset = tile.imageAsset;
    // CRITICAL: Never persist session-specific blob URLs to disk.
    // If we have a cached persistent path for this blob, use it.
    if (imageAsset.startsWith('blob:')) {
      imageAsset = ExternalSymbolService.getPersistentPath(imageAsset) ?? '';
    }

    // Generate human-readable ID if it's currently a timestamp or generic
    String persistentId = tile.id;

    return {
      'id': persistentId,
      'type': type,
      'label': tile.label,
      'category': tile.category,
      'imageAsset': imageAsset.isNotEmpty ? imageAsset : null,
      'emoji': tile.emoji,
      'isBoardLink': tile.isBoardLink,
      'linkedBoardId': tile.linkedBoardId,
      'linkedBoardName': linkedBoardName,
      'isFullScreenImage': tile.isFullScreenImage,
      'bgColor': tile.bgColor,
      'textColor': tile.textColor,
      'tileSize': tile.tileSize,
      'colSpan': tile.colSpan,
      'rowSpan': tile.rowSpan,
      'customVoice': tile.customVoice,
    };
  }

  List<SymbolTile> _generateCommonWordsTiles() {
    final words = [
      'I', 'blow nose', 'brain break', 'colouring', 'cubbie', 'do not want',
      'drink', 'ear defenders', 'eat', 'finished', 'first aid', 'focus', 'go',
      'good afternoon', 'good morning', 'goodbye', 'help', 'listen', 'need',
      'no', 'play', 'please', 'point', 'raise a hand', 'read', 'rest', 'run',
      'sensory toys', 'sign', 'silence', 'snack', 'sorry', 'stop', 'talk',
      'thank-you', 'toilet', 'want', 'wash', 'watch', 'weighted blanket',
      'write', 'yes',
    ];
    return words.map((w) => SymbolTile(
      id: 'common_${w.replaceAll(' ', '_').toLowerCase()}',
      label: w,
      category: 'Common',
      imageAsset: 'assets/Common/Common Words/$w.png',
    )).toList();
  }

  List<SymbolTile> _generateMainBoardTiles(String name) {
    if (name == 'Common Words') return _generateCommonWordsTiles();

    final area = _areaForBoardName(name);
    if (area == name) {
      final children = hierarchyTopLevel(area)
          .where((n) => n.toLowerCase() != name.toLowerCase());
      if (children.isNotEmpty) {
        return children.map((child) {
          final id = prebuiltBoardId(child);
          return SymbolTile(
            id: 'main_link_${id.replaceAll('prebuilt_', '')}',
            label: child,
            category: area,
            imageAsset: '',
            isBoardLink: true,
            linkedBoardId: id,
            bgColor: '#000000',
            textColor: '#FFFFFF',
          );
        }).toList();
      }
    }

    return [
      SymbolTile(
        id: 'main_${name.toLowerCase().replaceAll(' ', '_')}',
        label: name,
        category: name,
        imageAsset: '',
      ),
    ];
  }
}
