# Flutter Universal Client Architecture

## Overview

This document provides a practical implementation guide for building a cross-platform AAC communication app using Flutter, supporting Android, iOS, iPadOS, Windows, macOS, Linux, and Web with shared code, responsive layouts, and offline-first design.

---

## 1. Folder Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                          # App widget configuration
│
├── core/                             # Core utilities
│   ├── constants/
│   │   ├── app_constants.dart       # App-wide constants
│   │   ├── board_constants.dart     # Board-related constants
│   │   └── storage_constants.dart   # Storage keys
│   ├── theme/
│   │   ├── app_theme.dart          # Theme configuration
│   │   ├── light_theme.dart         # Light theme
│   │   ├── dark_theme.dart          # Dark theme
│   │   └── text_styles.dart        # Text styles
│   ├── di/
│   │   └── di_config.dart           # Dependency injection (GetIt)
│   ├── routes/
│   │   └── app_router.dart          # Navigation (go_router)
│   └── utils/
│       ├── responsive.dart          # Responsive utilities
│       ├── validators.dart          # Input validators
│       └── formatters.dart          # Data formatters
│
├── data/                             # Data layer
│   ├── models/                       # Data transfer objects
│   │   ├── board_model.dart
│   │   ├── symbol_tile_model.dart
│   │   ├── user_profile_model.dart
│   │   └── app_settings_model.dart
│   ├── repositories/                 # Repository implementations
│   │   ├── board_repository_impl.dart
│   │   ├── profile_repository_impl.dart
│   │   ├── settings_repository_impl.dart
│   │   └── sync_repository_impl.dart
│   ├── datasources/                  # Data sources
│   │   ├── local/                    # Local storage
│   │   │   ├── board_local_datasource.dart
│   │   │   ├── profile_local_datasource.dart
│   │   │   ├── settings_local_datasource.dart
│   │   │   └── favorites_local_datasource.dart
│   │   └── remote/                   # Remote APIs
│   │       ├── symboltalk_api_datasource.dart
│   │       └── sync_remote_datasource.dart
│   ├── mappers/                      # Model-Entity converters
│   │   ├── board_mapper.dart
│   │   ├── symbol_tile_mapper.dart
│   │   ├── profile_mapper.dart
│   │   └── settings_mapper.dart
│   └── services/                     # Data services (legacy)
│       ├── board_service.dart
│       ├── profile_service.dart
│       ├── settings_service.dart
│       ├── sync_service.dart
│       ├── tts_service.dart
│       ├── favorites_service.dart
│       └── phrase_service.dart
│
├── domain/                           # Domain layer (business logic)
│   ├── entities/                     # Core business objects
│   │   ├── board.dart
│   │   ├── symbol_tile.dart
│   │   ├── user_profile.dart
│   │   └── app_settings.dart
│   ├── usecases/                     # Use cases
│   │   ├── board/
│   │   │   ├── get_boards_usecase.dart
│   │   │   ├── get_board_usecase.dart
│   │   │   ├── save_board_usecase.dart
│   │   │   └── delete_board_usecase.dart
│   │   ├── profile/
│   │   │   ├── get_profiles_usecase.dart
│   │   │   ├── create_profile_usecase.dart
│   │   │   └── update_profile_usecase.dart
│   │   └── tts/
│   │       ├── speak_text_usecase.dart
│   │       └── set_voice_usecase.dart
│   └── repositories/                 # Repository interfaces
│       ├── board_repository_interface.dart
│       ├── profile_repository_interface.dart
│       └── settings_repository_interface.dart
│
├── presentation/                     # Presentation layer
│   ├── pages/                        # Full-screen pages
│   │   ├── home/
│   │   │   ├── home_page.dart
│   │   │   └── home_page_view.dart
│   │   ├── settings/
│   │   │   ├── settings_page.dart
│   │   │   └── settings_page_view.dart
│   │   ├── profile/
│   │   │   ├── profile_page.dart
│   │   │   └── profile_page_view.dart
│   │   ├── editor/
│   │   │   ├── board_editor_page.dart
│   │   │   └── board_editor_page_view.dart
│   │   └── welcome/
│   │       └── welcome_page.dart
│   ├── widgets/                      # Reusable widgets
│   │   ├── common/                   # Common widgets
│   │   │   ├── app_bar.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state.dart
│   │   ├── board/                    # Board widgets
│   │   │   ├── symbol_grid.dart
│   │   │   ├── symbol_tile.dart
│   │   │   └── board_header.dart
│   │   ├── symbol/                   # Symbol widgets
│   │   │   ├── symbol_button.dart
│   │   │   └── symbol_image.dart
│   │   └── sentence/                 # Sentence widgets
│   │       ├── sentence_panel.dart
│   │       └── phrase_panel.dart
│   ├── providers/                    # State management (Riverpod)
│   │   ├── board_provider.dart
│   │   ├── settings_provider.dart
│   │   ├── profile_provider.dart
│   │   ├── tts_provider.dart
│   │   └── sync_provider.dart
│   └── viewmodels/                   # View models (MVVM)
│       ├── board_viewmodel.dart
│       ├── settings_viewmodel.dart
│       └── profile_viewmodel.dart
│
└── platform/                         # Platform-specific code
    ├── android/                      # Android-specific
    │   └── main.dart                # Android entry point
    ├── ios/                          # iOS-specific
    │   └── main.dart                # iOS entry point
    ├── windows/                      # Windows-specific
    │   └── main.dart                # Windows entry point
    ├── macos/                        # macOS-specific
    │   └── main.dart                # macOS entry point
    ├── linux/                        # Linux-specific
    │   └── main.dart                # Linux entry point
    └── web/                          # Web-specific
        ├── tts_impl.dart             # Web TTS implementation
        ├── pwa_service_worker.dart   # PWA service worker
        └── index.html                # Web entry point
```

---

## 2. State Management (Riverpod)

### Provider Setup

```dart
// lib/core/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

final boardServiceProvider = Provider<BoardService>((ref) {
  throw UnimplementedError('BoardService must be initialized');
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  throw UnimplementedError('ProfileService must be initialized');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('SettingsService must be initialized');
});

// Board state
final boardsProvider = FutureProvider<List<Board>>((ref) async {
  final service = ref.watch(boardServiceProvider);
  final boards = await service.listBoards();
  return boards;
});

final currentBoardProvider = StateProvider<Board?>((ref) => null);

// Profile state
final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.profiles;
});

final activeProfileProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.activeProfile;
});

// Settings state
final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  return service.settings;
});

// TTS state
final ttsProvider = Provider<CrossPlatformTtsService>((ref) {
  return CrossPlatformTtsService.instance;
});

final voicesProvider = FutureProvider<List<VoiceOption>>((ref) async {
  final tts = ref.watch(ttsProvider);
  final voices = await tts.getVoices();
  return voices.map((v) => VoiceOption(
    name: v['name'] ?? '',
    locale: v['locale'] ?? '',
  )).toList();
});
```

### State Notifier Pattern

```dart
// lib/presentation/providers/board_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoardNotifier extends StateNotifier<BoardState> {
  final BoardService _service;
  
  BoardNotifier(this._service) : super(BoardState.initial());
  
  Future<void> loadBoards() async {
    state = BoardState.loading();
    try {
      final boards = await _service.listBoards();
      state = BoardState.loaded(boards);
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
  
  Future<void> saveBoard(Board board) async {
    try {
      await _service.saveBoard(board);
      await loadBoards();
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
  
  Future<void> deleteBoard(String id) async {
    try {
      await _service.deleteBoard(id);
      await loadBoards();
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
}

class BoardState {
  final bool isLoading;
  final List<Board>? boards;
  final String? error;
  
  BoardState.initial() : isLoading = false, boards = null, error = null;
  BoardState.loading() : isLoading = true, boards = null, error = null;
  BoardState.loaded(this.boards) : isLoading = false, error = null;
  BoardState.error(this.error) : isLoading = false, boards = null;
}

final boardNotifierProvider = StateNotifierProvider<BoardNotifier, BoardState>((ref) {
  final service = ref.watch(boardServiceProvider);
  return BoardNotifier(service);
});
```

### Using Providers in Widgets

```dart
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    final boardNotifier = ref.watch(boardNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Charlie Chat')),
      body: boardsAsync.when(
        data: (boards) => BoardListView(boards: boards),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => boardNotifier.loadBoards(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## 3. Navigation (go_router)

### Router Configuration

```dart
// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) {
        final boardId = state.uri.queryParameters['boardId'];
        return BoardEditorPage(boardId: boardId);
      },
    ),
    GoRoute(
      path: '/board/:id',
      name: 'board',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailPage(boardId: id);
      },
    ),
  ],
);
```

### Navigation Extensions

```dart
extension NavigationExtensions on BuildContext {
  void goToHome() => go('/');
  void goToSettings() => go('/settings');
  void goToProfile() => go('/profile');
  void goToEditor({String? boardId}) {
    if (boardId != null) {
      go('/editor?boardId=$boardId');
    } else {
      go('/editor');
    }
  }
  void goToBoard(String id) => go('/board/$id');
}
```

### Deep Linking

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/board/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailPage(boardId: id);
      },
    ),
  ],
);
```

---

## 4. Data Layer

### Repository Pattern

```dart
// lib/data/repositories/board_repository_impl.dart
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _local;
  final BoardRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  
  BoardRepositoryImpl(this._local, this._remote, this._networkInfo);
  
  @override
  Future<List<Board>> getBoards() async {
    // Try local first (offline-first)
    try {
      final boardModels = await _local.getBoards();
      return boardModels.map(BoardMapper.toEntity).toList();
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<void> saveBoard(Board board) async {
    try {
      final boardModel = BoardMapper.toModel(board);
      await _local.saveBoard(boardModel);
      
      // Sync to remote if online
      if (await _networkInfo.isConnected) {
        try {
          await _remote.uploadBoard(boardModel);
        } catch (e) {
          debugPrint('Failed to sync board: $e');
        }
      }
    } catch (e) {
      throw CacheException();
    }
  }
}
```

### Local Data Source

```dart
// lib/data/datasources/local/board_local_datasource.dart
class BoardLocalDataSource {
  final SharedPreferences _prefs;
  final Directory? _dataDir;
  
  BoardLocalDataSource(this._prefs, this._dataDir);
  
  Future<List<BoardModel>> getBoards() async {
    if (kIsWeb) {
      return _getBoardsFromPrefs();
    } else {
      return _getBoardsFromFileSystem();
    }
  }
  
  Future<List<BoardModel>> _getBoardsFromPrefs() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('board_'));
    final boards = <BoardModel>[];
    
    for (final key in keys) {
      try {
        final json = jsonDecode(_prefs.getString(key)!) as Map<String, dynamic>;
        boards.add(BoardModel.fromJson(json));
      } catch (e) {
        debugPrint('Error loading board: $e');
      }
    }
    
    return boards;
  }
  
  Future<List<BoardModel>> _getBoardsFromFileSystem() async {
    if (_dataDir == null) return [];
    
    final files = _dataDir!.listSync().whereType<File>();
    final boards = <BoardModel>[];
    
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        boards.add(BoardModel.fromJson(json));
      } catch (e) {
        debugPrint('Error loading board: $e');
      }
    }
    
    return boards;
  }
  
  Future<void> saveBoard(BoardModel board) async {
    final json = board.toJson();
    final jsonString = jsonEncode(json);
    
    if (kIsWeb) {
      await _prefs.setString('board_${board.id}', jsonString);
    } else {
      final file = File('${_dataDir!.path}/${board.id}.json');
      await file.writeAsString(jsonString);
    }
  }
}
```

### Remote Data Source

```dart
// lib/data/datasources/remote/symboltalk_api_datasource.dart
class SymbolTalkApiDataSource {
  final http.Client _client;
  final String _baseUrl;
  String? _accessToken;
  
  SymbolTalkApiDataSource(this._client, {String baseUrl = 'http://localhost:8080'})
      : _baseUrl = baseUrl;
  
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };
  
  Future<List<BoardModel>> getRemoteBoards() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/boards'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded
          .map((json) => BoardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ServerException();
    }
  }
  
  Future<void> uploadBoard(BoardModel board) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/boards'),
      headers: _headers,
      body: jsonEncode(board.toJson()),
    );
    
    if (response.statusCode != 201) {
      throw ServerException();
    }
  }
}
```

---

## 5. Sync Layer

### Sync Service

```dart
// lib/services/sync_service.dart
class SyncService {
  static const _syncKey = 'sync_records';
  static const _lastSyncKey = 'last_sync_timestamp';
  final SharedPreferences _prefs;
  final SymbolTalkApiService _api;
  
  SyncService._(this._prefs, this._api);
  
  static Future<SyncService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final api = SymbolTalkApiService();
    return SyncService._(prefs, api);
  }
  
  Future<SyncResult> sync() async {
    try {
      // Get local changes
      final localChanges = _getPendingSyncRecords();
      
      // Push local changes to server
      for (final record in localChanges) {
        await _pushRecord(record);
      }
      
      // Pull remote changes
      final remoteChanges = await _api.getChanges(_getLastSyncTimestamp());
      
      // Apply remote changes locally
      for (final change in remoteChanges) {
        await _applyRemoteChange(change);
      }
      
      // Update last sync timestamp
      await _updateLastSyncTimestamp();
      
      // Clear synced records
      await _clearSyncedRecords();
      
      return SyncResult(success: true, changesProcessed: localChanges.length + remoteChanges.length);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }
  
  Future<void> recordChange({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final record = SyncRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
      status: SyncRecordStatus.pending,
    );
    
    final records = _getSyncRecords();
    records.add(record);
    await _saveSyncRecords(records);
  }
  
  List<SyncRecord> _getSyncRecords() {
    final json = _prefs.getString(_syncKey);
    if (json == null) return [];
    
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((j) => SyncRecord.fromJson(j as Map<String, dynamic>)).toList();
  }
  
  Future<void> _saveSyncRecords(List<SyncRecord> records) async {
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await _prefs.setString(_syncKey, encoded);
  }
  
  List<SyncRecord> _getPendingSyncRecords() {
    return _getSyncRecords().where((r) => r.status == SyncRecordStatus.pending).toList();
  }
  
  Future<void> _pushRecord(SyncRecord record) async {
    try {
      await _api.pushChange(record);
      record.status = SyncRecordStatus.synced;
    } catch (e) {
      record.status = SyncRecordStatus.failed;
      record.errorMessage = e.toString();
    }
  }
  
  Future<void> _applyRemoteChange(Map<String, dynamic> change) async {
    // Apply remote change to local storage
    final entityType = change['entityType'] as String;
    final operation = change['operation'] as String;
    final payload = change['payload'] as Map<String, dynamic>;
    
    switch (entityType) {
      case 'board':
        await _applyBoardChange(operation, payload);
        break;
      case 'profile':
        await _applyProfileChange(operation, payload);
        break;
      // Add other entity types
    }
  }
  
  Future<void> _applyBoardChange(String operation, Map<String, dynamic> payload) async {
    final boardService = await BoardService.getInstance();
    
    switch (operation) {
      case 'upsert':
        final board = Board.fromMap(payload);
        await boardService.saveBoard(board);
        break;
      case 'delete':
        await boardService.deleteBoard(payload['id'] as String);
        break;
    }
  }
  
  DateTime? _getLastSyncTimestamp() {
    final timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  Future<void> _updateLastSyncTimestamp() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<void> _clearSyncedRecords() async {
    final records = _getSyncRecords();
    final filtered = records.where((r) => r.status != SyncRecordStatus.synced).toList();
    await _saveSyncRecords(filtered);
  }
}
```

### Conflict Resolution

```dart
class ConflictResolver {
  Future<ConflictResolution> resolveConflict(
    SyncRecord localRecord,
    Map<String, dynamic> remoteRecord,
  ) async {
    // Simple strategy: local wins for now
    // Could be enhanced with UI for user to choose
    
    final localTimestamp = localRecord.createdAt;
    final remoteTimestamp = DateTime.parse(remoteRecord['createdAt'] as String);
    
    if (localTimestamp.isAfter(remoteTimestamp)) {
      return ConflictResolution.localWins;
    } else {
      return ConflictResolution.remoteWins;
    }
  }
}
```

---

## 6. Responsive Layouts

### Responsive Utilities

```dart
// lib/core/utils/responsive.dart
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && width < ResponsiveBreakpoints.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }
  
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) return 2;
    if (width < ResponsiveBreakpoints.tablet) return 4;
    return 6;
  }
}
```

### Responsive Widget

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
          return mobile;
        } else if (constraints.maxWidth < ResponsiveBreakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
```

### Adaptive Grid

```dart
class AdaptiveSymbolGrid extends StatelessWidget {
  final List<SymbolTile> tiles;
  final Function(SymbolTile) onTileTap;
  
  const AdaptiveSymbolGrid({
    required this.tiles,
    required this.onTileTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return SymbolTileWidget(
          tile: tile,
          onTap: () => onTileTap(tile),
        );
      },
    );
  }
}
```

---

## 7. Platform-Specific Optimizations

### Platform Detection

```dart
// lib/core/utils/platform_utils.dart
import 'dart:io' show Platform;

class PlatformUtils {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isTablet {
    if (isWeb) return false;
    // Add tablet detection logic
    return false;
  }
}
```

### Platform-Specific Widgets

```dart
class PlatformAdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  
  const PlatformAdaptiveAppBar({
    required this.title,
    this.actions,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions ?? [],
        ),
      );
    }
    
    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

---

## 8. Offline Operation

### Offline Detection

```dart
// lib/core/utils/network_utils.dart
class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  
  static Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((result) => result != ConnectivityResult.none);
  
  static Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### Offline Banner

```dart
class OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    
    return isOnlineAsync.when(
      data: (isOnline) => isOnline 
          ? const SizedBox.shrink() 
          : Container(
              color: Colors.orange,
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'You are offline. Changes will sync when connection is restored.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

final isOnlineProvider = StreamProvider<bool>((ref) {
  return NetworkUtils.onConnectivityChanged;
});
```

---

## 9. Main App Integration

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await setupDI();
  
  runApp(
    ProviderScope(
      child: CharlieChatApp(),
    ),
  );
}

class CharlieChatApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Charlie Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```

---

## 10. Testing Strategy

### Unit Tests

```dart
test('BoardRepositoryImpl returns boards from local source', () async {
  final mockLocal = MockBoardLocalDataSource();
  final mockRemote = MockBoardRemoteDataSource();
  final mockNetwork = MockNetworkInfo();
  
  when(mockNetwork.isConnected).thenAnswer((_) async => false);
  when(mockLocal.getBoards()).thenAnswer((_) async => [testBoardModel]);
  
  final repository = BoardRepositoryImpl(mockLocal, mockRemote, mockNetwork);
  final result = await repository.getBoards();
  
  expect(result.length, 1);
  verify(mockLocal.getBoards()).called(1);
});
```

### Widget Tests

```dart
testWidgets('HomePage displays loading indicator initially', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        boardsProvider.overrideWith((ref) => AsyncValue.loading()),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## Summary

This architecture provides:

1. **Shared Codebase** - Single Flutter project for all platforms
2. **Clean Architecture** - Separation of concerns with Domain/Data/Presentation layers
3. **State Management** - Riverpod for reactive state
4. **Navigation** - go_router for declarative routing
5. **Responsive Design** - Adaptive layouts for different screen sizes
6. **Offline-First** - Local storage with optional cloud sync
7. **Platform Optimizations** - Platform-specific UI and behavior

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)
- [CROSS_PLATFORM_ARCHITECTURE.md](CROSS_PLATFORM_ARCHITECTURE.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
