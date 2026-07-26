# Offline-First Architecture

## Overview

This document provides a comprehensive offline-first architecture for Charlie Chat, ensuring the app is fully functional without internet while providing seamless cloud synchronization when connectivity is restored.

---

## 1. Architecture Principles

### Core Principles

1. **Local-First** - All data and assets are stored locally first
2. **Offline-Default** - App assumes offline by default
3. **Optimistic UI** - UI updates immediately, sync happens in background
4. **Conflict Resolution** - Automatic conflict detection and resolution
5. **Graceful Degradation** - App works with limited functionality when offline
6. **Transparent Sync** - Sync happens automatically without user intervention

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Interface                          │
│  - Immediate UI updates                                      │
│  - Local asset loading                                       │
│  - Local TTS playback                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Local Storage Layer                         │
│  - Local Database (Drift/SQLite/IndexedDB)                  │
│  - Local Asset Storage (File System/Blob Storage)           │
│  - Local Settings (SharedPreferences)                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Sync Queue Layer                          │
│  - Operation Queue                                           │
│  - Conflict Detection                                        │
│  - Retry Logic                                               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Network Layer                              │
│  - Connectivity Detection                                    │
│  - HTTP Client with Retry                                    │
│  - WebSocket (optional)                                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Backend                             │
│  - REST API                                                  │
│  - Cloud Storage                                             │
│  - Real-time Sync (optional)                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Local Storage Strategy

### Local Database (Drift)

```dart
// lib/data/database/app_database.dart
@DriftDatabase(tables: [
  Boards,
  SymbolTiles,
  UserProfiles,
  AppSettings,
  SyncQueue,
  AssetMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAllTables();
        await _createIndexes(m);
      },
    );
  }

  Future<void> _createIndexes(Migrator m) async {
    await m.createIndex(boards_name_index);
    await m.createIndex(symbolTiles_board_id_index);
    await m.createIndex(syncQueue_status_index);
    await m.createIndex(assetMetadata_local_path_index);
  }
}
```

### Local Asset Storage

```dart
// lib/services/local_asset_service.dart
class LocalAssetService {
  static const String _symbolsDir = 'symbols';
  static const String _boardsDir = 'boards';
  static const String _backupsDir = 'backups';

  Future<Directory> _getSymbolsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final symbolsDir = Directory('${appDir.path}/$_symbolsDir');
    
    if (!await symbolsDir.exists()) {
      await symbolsDir.create(recursive: true);
    }
    
    return symbolsDir;
  }

  Future<String> saveAsset(String assetPath, Uint8List data) async {
    final dir = await _getSymbolsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data);
    return file.path;
  }

  Future<Uint8List?> getAsset(String assetPath) async {
    // First check local storage
    final dir = await _getSymbolsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');
    
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    
    // Check bundled assets
    try {
      final byteData = await rootBundle.load('assets/$assetPath');
      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAsset(String assetPath) async {
    final dir = await _getSymbolsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> getAllLocalAssets() async {
    final dir = await _getSymbolsDirectory();
    final files = dir.listSync().whereType<File>();
    return files.map((f) => f.path).toList();
  }
}
```

### Asset Metadata Table

```dart
@DataClassName('AssetMetadata')
class AssetMetadata extends Table {
  TextColumn get id => text()();
  TextColumn get originalPath => text()();
  TextColumn get localPath => text()();
  TextColumn get cloudUrl => text().nullable()();
  IntColumn get fileSize => integer()();
  TextColumn get checksum => text()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isLocal => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}

final assetMetadata_local_path_index = Index('assetMetadata_local_path_index', [AssetMetadata.localPath]);
```

### Local Settings

```dart
// lib/services/local_settings_service.dart
class LocalSettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _voiceRateKey = 'voice_rate';
  static const String _voicePitchKey = 'voice_pitch';
  static const String _voiceVolumeKey = 'voice_volume';
  static const String _voiceLanguageKey = 'voice_language';
  static const String _voiceNameKey = 'voice_name';
  static const String _fontSizeKey = 'font_size';
  static const String _highContrastKey = 'high_contrast';

  final SharedPreferences _prefs;

  LocalSettingsService(this._prefs);

  ThemeMode get themeMode {
    final value = _prefs.getString(_themeModeKey) ?? 'system';
    switch (value) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light ? 'light' : 
                  mode == ThemeMode.dark ? 'dark' : 'system';
    await _prefs.setString(_themeModeKey, value);
  }

  double get voiceRate => _prefs.getDouble(_voiceRateKey) ?? 0.5;
  Future<void> setVoiceRate(double value) => _prefs.setDouble(_voiceRateKey, value);

  double get voicePitch => _prefs.getDouble(_voicePitchKey) ?? 1.0;
  Future<void> setVoicePitch(double value) => _prefs.setDouble(_voicePitchKey, value);

  double get voiceVolume => _prefs.getDouble(_voiceVolumeKey) ?? 1.0;
  Future<void> setVoiceVolume(double value) => _prefs.setDouble(_voiceVolumeKey, value);

  String get voiceLanguage => _prefs.getString(_voiceLanguageKey) ?? 'en-GB';
  Future<void> setVoiceLanguage(String value) => _prefs.setString(_voiceLanguageKey, value);

  String get voiceName => _prefs.getString(_voiceNameKey) ?? '';
  Future<void> setVoiceName(String value) => _prefs.setString(_voiceNameKey, value);

  String get fontSize => _prefs.getString(_fontSizeKey) ?? 'medium';
  Future<void> setFontSize(String value) => _prefs.setString(_fontSizeKey, value);

  bool get highContrast => _prefs.getBool(_highContrastKey) ?? false;
  Future<void> setHighContrast(bool value) => _prefs.setBool(_highContrastKey, value);
}
```

---

## 3. Local Speech Engine

### Cross-Platform TTS

```dart
// lib/services/cross_platform_tts_service.dart
class CrossPlatformTtsService {
  static final CrossPlatformTtsService _instance = CrossPlatformTtsService._internal();
  factory CrossPlatformTtsService() => _instance;
  CrossPlatformTtsService._internal();

  FlutterTts? _tts;
  bool _initialized = false;
  String? _voiceName;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;

  Future<void> initialize() async {
    if (_initialized) return;

    _tts = FlutterTts();
    
    await _tts!.setSharedInstance(true);
    await _tts!.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [
        IosTextToSpeechAudioCategoryOption.allowBackgroundAudioPlayback,
        IosTextToSpeechAudioCategoryOption.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.spokenAudio,
    );

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await initialize();

    await _tts!.setSpeechRate(_speechRate);
    await _tts!.setPitch(_pitch);
    await _tts!.setVolume(_volume);
    
    if (_voiceName != null && _voiceName!.isNotEmpty) {
      await _tts!.setVoice({'name': _voiceName});
    }

    await _tts!.speak(text);
  }

  Future<void> stop() async {
    if (_initialized) {
      await _tts!.stop();
    }
  }

  Future<List<Map<String, String>>> getVoices() async {
    if (!_initialized) await initialize();
    return await _tts!.getVoices;
  }

  Future<void> setVoice(String voiceName, {String locale = ''}) async {
    _voiceName = voiceName;
    if (!_initialized) await initialize();

    if (!kIsWeb) {
      final voices = await getVoices();
      var matchingVoice = voices.firstWhere(
        (v) => v['name'] == voiceName && (locale.isEmpty || v['locale'] == locale),
        orElse: () => <String, String>{},
      );

      if (matchingVoice.isEmpty && voices.isNotEmpty) {
        matchingVoice = voices.first;
      }

      if (matchingVoice.isNotEmpty) {
        await _tts!.setVoice({'name': matchingVoice['name'], 'locale': matchingVoice['locale']});
      }
    }
  }

  Future<void> setLanguage(String language) async {
    if (!_initialized) await initialize();
    await _tts!.setLanguage(language);
  }
}
```

### Voice Caching

```dart
// lib/services/voice_cache_service.dart
class VoiceCacheService {
  final SharedPreferences _prefs;
  static const String _cachedVoicesKey = 'cached_voices';

  VoiceCacheService(this._prefs);

  Future<void> cacheVoices(List<Map<String, String>> voices) async {
    final json = jsonEncode(voices);
    await _prefs.setString(_cachedVoicesKey, json);
  }

  List<Map<String, String>> getCachedVoices() {
    final json = _prefs.getString(_cachedVoicesKey);
    if (json == null) return [];
    
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((v) => Map<String, String>.from(v)).toList();
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cachedVoicesKey);
  }
}
```

---

## 4. Sync Architecture

### Sync Queue Table

```dart
@DataClassName('SyncQueueItem')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

final syncQueue_status_index = Index('syncQueue_status_index', [SyncQueue.status]);
```

### Sync Service

```dart
// lib/services/sync_service.dart
class SyncService {
  final AppDatabase _db;
  final SyncApiClient _api;
  final LocalAssetService _assetService;
  final Connectivity _connectivity;
  
  SyncService(this._db, this._api, this._assetService, this._connectivity);

  Future<SyncResult> sync() async {
    if (!await _isOnline()) {
      return SyncResult(success: false, offline: true);
    }

    try {
      // 1. Push pending operations
      final pushResult = await _pushPendingOperations();
      
      // 2. Pull remote changes
      final pullResult = await _pullRemoteChanges();
      
      // 3. Sync assets
      final assetResult = await _syncAssets();
      
      return SyncResult(
        success: true,
        operationsPushed: pushResult.successful,
        operationsPulled: pullResult.applied,
        assetsSynced: assetResult.synced,
        conflicts: pushResult.conflicts + pullResult.conflicts,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<PushResult> _pushPendingOperations() async {
    int successful = 0;
    int conflicts = 0;
    int failed = 0;

    final pendingItems = await _db.getPendingSyncQueueItems();

    for (final item in pendingItems) {
      try {
        final result = await _api.pushOperation(item);

        if (result.conflict) {
          conflicts++;
          await _handleConflict(item, result.remoteData);
        } else {
          successful++;
          await _db.deleteSyncQueueItem(item.id);
        }
      } catch (e) {
        failed++;
        await _handleSyncError(item, e);
      }
    }

    return PushResult(successful: successful, conflicts: conflicts, failed: failed);
  }

  Future<PullResult> _pullRemoteChanges() async {
    int applied = 0;
    int conflicts = 0;

    final lastSyncTimestamp = await _getLastSyncTimestamp();
    final remoteChanges = await _api.getRemoteChanges(lastSyncTimestamp);

    for (final change in remoteChanges) {
      try {
        final localItem = await _db.getSyncQueueItemByEntityId(change.entityId);

        if (localItem != null && localItem.status == 'pending') {
          // Conflict
          conflicts++;
          await _handleConflict(localItem, change);
        } else {
          // Apply remote change
          await _applyRemoteChange(change);
          applied++;
        }
      } catch (e) {
        debugPrint('Error applying remote change: $e');
      }
    }

    await _updateLastSyncTimestamp();

    return PullResult(applied: applied, conflicts: conflicts);
  }

  Future<AssetSyncResult> _syncAssets() async {
    int synced = 0;
    int failed = 0;

    // Upload local assets not in cloud
    final localAssets = await _assetService.getAllLocalAssets();
    for (final assetPath in localAssets) {
      try {
        final metadata = await _db.getAssetMetadataByLocalPath(assetPath);
        if (metadata != null && metadata.cloudUrl == null) {
          await _api.uploadAsset(assetPath, metadata);
          synced++;
        }
      } catch (e) {
        failed++;
      }
    }

    // Download missing assets from cloud
    final cloudAssets = await _api.getRemoteAssets();
    for (final cloudAsset in cloudAssets) {
      try {
        final localData = await _assetService.getAsset(cloudAsset.originalPath);
        if (localData == null) {
          await _api.downloadAsset(cloudAsset.cloudUrl, cloudAsset.originalPath);
          synced++;
        }
      } catch (e) {
        failed++;
      }
    }

    return AssetSyncResult(synced: synced, failed: failed);
  }

  Future<void> _applyRemoteChange(RemoteChange change) async {
    switch (change.entityType) {
      case 'board':
        await _applyBoardChange(change);
        break;
      case 'symbol_tile':
        await _applyTileChange(change);
        break;
      case 'user_profile':
        await _applyProfileChange(change);
        break;
    }
  }

  Future<void> _applyBoardChange(RemoteChange change) async {
    final board = Board.fromJson(change.payload);
    
    switch (change.operation) {
      case 'upsert':
        final existing = await _db.getBoard(board.id);
        if (existing == null) {
          await _db.insertBoard(board.toCompanion());
        } else {
          await _db.updateBoard(board);
        }
        break;
      case 'delete':
        await _db.deleteBoard(board.id);
        break;
    }
  }

  Future<void> _handleConflict(SyncQueueItem localItem, dynamic remoteData) async {
    // Last-write-wins based on timestamp
    final localTimestamp = localItem.updatedAt;
    final remoteTimestamp = DateTime.parse(remoteData['updatedAt'] as String);

    if (remoteTimestamp.isAfter(localTimestamp)) {
      // Remote wins
      await _applyRemoteChange(RemoteChange.fromJson(remoteData));
      await _db.deleteSyncQueueItem(localItem.id);
    } else {
      // Local wins, mark as synced
      localItem = localItem.copyWith(status: 'synced');
      await _db.updateSyncQueueItem(localItem);
    }
  }

  Future<void> _handleSyncError(SyncQueueItem item, dynamic error) async {
    final retryCount = item.retryCount + 1;
    
    if (retryCount >= item.maxRetries) {
      // Max retries reached, mark as failed
      await _db.updateSyncQueueItem(item.copyWith(
        status: 'failed',
        retryCount: retryCount,
        errorMessage: error.toString(),
      ));
    } else {
      // Schedule retry with exponential backoff
      final delay = Duration(seconds: pow(2, retryCount).toInt());
      final nextRetryAt = DateTime.now().add(delay);
      
      await _db.updateSyncQueueItem(item.copyWith(
        retryCount: retryCount,
        nextRetryAt: nextRetryAt,
      ));
    }
  }

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<DateTime?> _getLastSyncTimestamp() async {
    // Implement timestamp retrieval
    return null;
  }

  Future<void> _updateLastSyncTimestamp() async {
    // Implement timestamp update
  }
}
```

### Operation Queueing

```dart
// lib/services/operation_queue_service.dart
class OperationQueueService {
  final AppDatabase _db;

  OperationQueueService(this._db);

  Future<void> queueOperation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItemsCompanion.insert(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: jsonEncode(payload),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: const Value('pending'),
    );

    await _db.insertSyncQueueItem(item);
  }

  Future<void> queueBoardOperation(String boardId, String operation, Board board) async {
    await queueOperation(
      entityType: 'board',
      entityId: boardId,
      operation: operation,
      payload: board.toJson(),
    );
  }

  Future<void> queueTileOperation(String tileId, String operation, SymbolTile tile) async {
    await queueOperation(
      entityType: 'symbol_tile',
      entityId: tileId,
      operation: operation,
      payload: tile.toJson(),
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
```

---

## 5. Conflict Resolution

### Conflict Detection

```dart
// lib/services/conflict_detection_service.dart
class ConflictDetectionService {
  final AppDatabase _db;

  ConflictDetectionService(this._db);

  Future<List<Conflict>> detectConflicts() async {
    final conflicts = <Conflict>[];

    // Check for pending operations with remote changes
    final pendingItems = await _db.getPendingSyncQueueItems();

    for (final item in pendingItems) {
      final remoteChange = await _api.getRemoteChange(item.entityId);
      
      if (remoteChange != null) {
        final localTimestamp = item.updatedAt;
        final remoteTimestamp = DateTime.parse(remoteChange['updatedAt'] as String);

        if (remoteTimestamp.isAfter(localTimestamp)) {
          conflicts.add(Conflict(
            entityId: item.entityId,
            entityType: item.entityType,
            localData: jsonDecode(item.payloadJson),
            remoteData: remoteChange,
            localTimestamp: localTimestamp,
            remoteTimestamp: remoteTimestamp,
          ));
        }
      }
    }

    return conflicts;
  }
}
```

### Conflict Resolution Strategies

```dart
enum ConflictResolutionStrategy {
  localWins,
  remoteWins,
  manual,
  lastWriteWins,
  merge
}

class ConflictResolver {
  Future<ConflictResolution> resolve(
    Conflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return ConflictResolution(localWins: true);
      
      case ConflictResolutionStrategy.remoteWins:
        return ConflictResolution(remoteWins: true);
      
      case ConflictResolutionStrategy.lastWriteWins:
        if (conflict.remoteTimestamp.isAfter(conflict.localTimestamp)) {
          return ConflictResolution(remoteWins: true);
        } else {
          return ConflictResolution(localWins: true);
        }
      
      case ConflictResolutionStrategy.manual:
        // Return conflict for manual resolution
        return ConflictResolution(manual: true, conflict: conflict);
      
      case ConflictResolutionStrategy.merge:
        return await _mergeConflict(conflict);
    }
  }

  Future<ConflictResolution> _mergeConflict(Conflict conflict) async {
    // Implement merge logic based on entity type
    final mergedData = await _mergeData(
      conflict.entityType,
      conflict.localData,
      conflict.remoteData,
    );

    return ConflictResolution(merged: true, mergedData: mergedData);
  }

  Future<Map<String, dynamic>> _mergeData(
    String entityType,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    // Simple merge: remote wins for new fields, local wins for existing
    final merged = Map<String, dynamic>.from(localData);
    
    for (final key in remoteData.keys) {
      if (!merged.containsKey(key)) {
        merged[key] = remoteData[key];
      }
    }
    
    return merged;
  }
}
```

---

## 6. Recovery Mechanisms

### Sync Recovery

```dart
// lib/services/sync_recovery_service.dart
class SyncRecoveryService {
  final AppDatabase _db;
  final SyncService _syncService;

  SyncRecoveryService(this._db, this._syncService);

  Future<RecoveryResult> recoverSync() async {
    // 1. Check for stuck operations
    final stuckItems = await _db.getStuckSyncQueueItems();
    
    // 2. Reset retry count for stuck items
    for (final item in stuckItems) {
      await _db.updateSyncQueueItem(item.copyWith(
        retryCount: 0,
        nextRetryAt: DateTime.now(),
        status: 'pending',
      ));
    }

    // 3. Retry sync
    final syncResult = await _syncService.sync();

    return RecoveryResult(
      itemsRecovered: stuckItems.length,
      syncResult: syncResult,
    );
  }

  Future<void> resetSyncQueue() async {
    await _db.deleteAllSyncQueueItems();
  }

  Future<void> exportSyncQueue() async {
    final items = await _db.getAllSyncQueueItems();
    final json = jsonEncode(items.map((i) => i.toJson()).toList());
    // Export to file
  }

  Future<void> importSyncQueue(String json) async {
    final List<dynamic> decoded = jsonDecode(json);
    for (final item in decoded) {
      await _db.insertSyncQueueItem(SyncQueueItem.fromJson(item));
    }
  }
}
```

### Data Recovery

```dart
// lib/services/data_recovery_service.dart
class DataRecoveryService {
  final AppDatabase _db;
  final LocalAssetService _assetService;

  DataRecoveryService(this._db, this._assetService);

  Future<void> createBackup() async {
    // Export database
    final dbBackup = await _db.export();
    
    // Export assets
    final assets = await _assetService.getAllLocalAssets();
    final assetBackup = <String, Uint8List>{};
    for (final assetPath in assets) {
      final data = await _assetService.getAsset(assetPath);
      if (data != null) {
        assetBackup[assetPath] = data;
      }
    }

    // Create backup package
    final backup = BackupPackage(
      database: dbBackup,
      assets: assetBackup,
      timestamp: DateTime.now(),
    );

    // Save backup
    await _saveBackup(backup);
  }

  Future<void> restoreBackup(BackupPackage backup) async {
    // Restore database
    await _db.import(backup.database);
    
    // Restore assets
    for (final entry in backup.assets.entries) {
      await _assetService.saveAsset(entry.key, entry.value);
    }
  }

  Future<void> _saveBackup(BackupPackage backup) async {
    // Save to file or cloud
  }
}
```

---

## 7. Cloud Sync UI

### Sync Status Page

```dart
// lib/presentation/pages/sync_status_page.dart
class SyncStatusPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncNotifier = ref.watch(syncStatusProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => syncNotifier.sync(),
          ),
        ],
      ),
      body: syncStatus.when(
        data: (status) => _buildStatusContent(context, status, syncNotifier),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }

  Widget _buildStatusContent(
    BuildContext context,
    SyncStatus status,
    SyncNotifier notifier,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConnectionStatus(status),
        const SizedBox(height: 16),
        _buildSyncProgress(status),
        const SizedBox(height: 16),
        _buildPendingOperations(status),
        const SizedBox(height: 16),
        _buildConflicts(status, notifier),
        const SizedBox(height: 16),
        _buildRecoveryActions(notifier),
      ],
    );
  }

  Widget _buildConnectionStatus(SyncStatus status) {
    return Card(
      child: ListTile(
        leading: Icon(
          status.isOnline ? Icons.cloud_done : Icons.cloud_off,
          color: status.isOnline ? Colors.green : Colors.grey,
        ),
        title: Text(status.isOnline ? 'Connected' : 'Offline'),
        subtitle: Text(
          status.isOnline 
              ? 'Last synced: ${_formatDate(status.lastSyncTime)}'
              : 'Changes will sync when connection is restored',
        ),
      ),
    );
  }

  Widget _buildSyncProgress(SyncStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (status.isSyncing)
              Column(
                children: [
                  LinearProgressIndicator(value: status.syncProgress),
                  const SizedBox(height: 8),
                  Text(status.syncMessage),
                ],
              )
            else
              Text('Sync complete'),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOperations(SyncStatus status) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pending_actions),
        title: Text('Pending Operations: ${status.pendingCount}'),
        subtitle: Text('Failed: ${status.failedCount}'),
        trailing: status.pendingCount > 0
            ? TextButton(
                onPressed: () => _showPendingOperationsDialog(context, status),
                child: const Text('View'),
              )
            : null,
      ),
    );
  }

  Widget _buildConflicts(SyncStatus status, SyncNotifier notifier) {
    if (status.conflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text('Conflicts: ${status.conflicts.length}'),
        subtitle: const Text('Tap to resolve'),
        onTap: () => _showConflictsDialog(context, status, notifier),
      ),
    );
  }

  Widget _buildRecoveryActions(SyncNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => notifier.recoverSync(),
              icon: const Icon(Icons.healing),
              label: const Text('Recover Sync'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => notifier.resetSyncQueue(),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Reset Sync Queue'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}
```

### Cloud Upload/Download Page

```dart
// lib/presentation/pages/cloud_sync_page.dart
class CloudSyncPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    final cloudBoardsAsync = ref.watch(cloudBoardsProvider);
    final syncNotifier = ref.watch(cloudSyncProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUploadSection(context, boardsAsync, syncNotifier),
          const SizedBox(height: 24),
          _buildDownloadSection(context, cloudBoardsAsync, syncNotifier),
          const SizedBox(height: 24),
          _buildBulkActions(context, syncNotifier),
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    BuildContext context,
    AsyncValue<List<Board>> boardsAsync,
    CloudSyncNotifier syncNotifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Upload to Cloud',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            boardsAsync.when(
              data: (boards) => Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => syncNotifier.uploadAllBoards(boards),
                    icon: const Icon(Icons.upload_all),
                    label: const Text('Upload All Boards'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Or upload individual boards:'),
                  const SizedBox(height: 8),
                  ...boards.map((board) => ListTile(
                    title: Text(board.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: () => syncNotifier.uploadBoard(board),
                    ),
                  )),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(
    BuildContext context,
    AsyncValue<List<CloudBoard>> cloudBoardsAsync,
    CloudSyncNotifier syncNotifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Download from Cloud',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            cloudBoardsAsync.when(
              data: (cloudBoards) => Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => syncNotifier.downloadAllBoards(cloudBoards),
                    icon: const Icon(Icons.download_all),
                    label: const Text('Download All Boards'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Or download individual boards:'),
                  const SizedBox(height: 8),
                  ...cloudBoards.map((cloudBoard) => ListTile(
                    title: Text(cloudBoard.name),
                    subtitle: Text('Updated: ${_formatDate(cloudBoard.updatedAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.cloud_download),
                      onPressed: () => syncNotifier.downloadBoard(cloudBoard),
                    ),
                  )),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActions(BuildContext context, CloudSyncNotifier syncNotifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => syncNotifier.syncAll(),
              icon: const Icon(Icons.sync),
              label: const Text('Sync All (Bidirectional)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showBackupDialog(context, syncNotifier),
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showRestoreDialog(context, syncNotifier),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}
```

### Cloud Sync Provider

```dart
// lib/presentation/providers/cloud_sync_provider.dart
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  final BoardService _boardService;
  final SyncService _syncService;
  final CloudApiClient _cloudApi;

  CloudSyncNotifier(this._boardService, this._syncService, this._cloudApi)
      : super(CloudSyncState.initial());

  Future<void> uploadBoard(Board board) async {
    state = CloudSyncState.uploading(boardId: board.id);
    try {
      await _cloudApi.uploadBoard(board);
      state = CloudSyncState.success('Board uploaded successfully');
    } catch (e) {
      state = CloudSyncState.error(e.toString());
    }
  }

  Future<void> uploadAllBoards(List<Board> boards) async {
    state = CloudSyncState.uploading();
    int success = 0;
    int failed = 0;

    for (final board in boards) {
      try {
        await _cloudApi.uploadBoard(board);
        success++;
      } catch (e) {
        failed++;
      }
    }

    state = CloudSyncState.success(
      'Uploaded $success boards, $failed failed',
    );
  }

  Future<void> downloadBoard(CloudBoard cloudBoard) async {
    state = CloudSyncState.downloading(boardId: cloudBoard.id);
    try {
      final board = await _cloudApi.downloadBoard(cloudBoard.id);
      await _boardService.saveBoard(board);
      state = CloudSyncState.success('Board downloaded successfully');
    } catch (e) {
      state = CloudSyncState.error(e.toString());
    }
  }

  Future<void> downloadAllBoards(List<CloudBoard> cloudBoards) async {
    state = CloudSyncState.downloading();
    int success = 0;
    int failed = 0;

    for (final cloudBoard in cloudBoards) {
      try {
        final board = await _cloudApi.downloadBoard(cloudBoard.id);
        await _boardService.saveBoard(board);
        success++;
      } catch (e) {
        failed++;
      }
    }

    state = CloudSyncState.success(
      'Downloaded $success boards, $failed failed',
    );
  }

  Future<void> syncAll() async {
    state = CloudSyncState.syncing();
    final result = await _syncService.sync();
    
    if (result.success) {
      state = CloudSyncState.success(
        'Sync complete: ${result.operationsPushed} pushed, ${result.operationsPulled} pulled',
      );
    } else {
      state = CloudSyncState.error(result.error ?? 'Sync failed');
    }
  }
}

class CloudSyncState {
  final bool isUploading;
  final bool isDownloading;
  final bool isSyncing;
  final String? uploadingBoardId;
  final String? downloadingBoardId;
  final String? message;
  final String? error;

  CloudSyncState.initial()
      : isUploading = false,
        isDownloading = false,
        isSyncing = false,
        uploadingBoardId = null,
        downloadingBoardId = null,
        message = null,
        error = null;

  CloudSyncState.uploading({this.uploadingBoardId})
      : isUploading = true,
        isDownloading = false,
        isSyncing = false,
        downloadingBoardId = null,
        message = null,
        error = null;

  CloudSyncState.downloading({this.downloadingBoardId})
      : isUploading = false,
        isDownloading = true,
        isSyncing = false,
        uploadingBoardId = null,
        message = null,
        error = null;

  CloudSyncState.syncing()
      : isUploading = false,
        isDownloading = false,
        isSyncing = true,
        uploadingBoardId = null,
        downloadingBoardId = null,
        message = null,
        error = null;

  CloudSyncState.success(this.message)
      : isUploading = false,
        isDownloading = false,
        isSyncing = false,
        uploadingBoardId = null,
        downloadingBoardId = null,
        error = null;

  CloudSyncState.error(this.error)
      : isUploading = false,
        isDownloading = false,
        isSyncing = false,
        uploadingBoardId = null,
        downloadingBoardId = null,
        message = null;
}

final cloudSyncProvider = StateNotifierProvider<CloudSyncNotifier, CloudSyncState>((ref) {
  return CloudSyncNotifier(
    ref.watch(boardServiceProvider),
    ref.watch(syncServiceProvider),
    ref.watch(cloudApiProvider),
  );
});
```

---

## 8. Asset Loading Priority

### Asset Loader

```dart
// lib/services/asset_loader_service.dart
class AssetLoaderService {
  final LocalAssetService _localAssetService;
  final CloudApiClient _cloudApi;
  final AppDatabase _db;

  AssetLoaderService(
    this._localAssetService,
    this._cloudApi,
    this._db,
  );

  Future<Uint8List?> loadAsset(String assetPath) async {
    // Priority 1: Check local storage
    final localData = await _localAssetService.getAsset(assetPath);
    if (localData != null) {
      return localData;
    }

    // Priority 2: Check bundled assets
    try {
      final byteData = await rootBundle.load('assets/$assetPath');
      return byteData.buffer.asUint8List();
    } catch (e) {
      // Asset not bundled
    }

    // Priority 3: Check cloud (if online)
    if (await _isOnline()) {
      try {
        final cloudData = await _cloudApi.downloadAsset(assetPath);
        // Cache locally for future use
        await _localAssetService.saveAsset(assetPath, cloudData);
        return cloudData;
      } catch (e) {
        debugPrint('Failed to download asset from cloud: $e');
      }
    }

    return null;
  }

  Future<String?> loadAssetUrl(String assetPath) async {
    // Return local file path if available
    final localData = await _localAssetService.getAsset(assetPath);
    if (localData != null) {
      final dir = await _localAssetService._getSymbolsDirectory();
      final fileName = assetPath.split('/').last;
      return '${dir.path}/$fileName';
    }

    // Return bundled asset path
    return 'assets/$assetPath';
  }

  Future<void> preloadAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      await loadAsset(path);
    }
  }

  Future<bool> _isOnline() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### Symbol Tile Widget with Asset Loading

```dart
// lib/widgets/symbol_tile_widget.dart
class SymbolTileWidget extends ConsumerWidget {
  final SymbolTile tile;
  final VoidCallback onTap;

  const SymbolTileWidget({
    required this.tile,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetLoader = ref.watch(assetLoaderServiceProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(tile.bgColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: FutureBuilder<Uint8List?>(
          future: assetLoader.loadAsset(tile.imageAsset),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallback();
                },
              );
            }

            return _buildFallback();
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    if (tile.emoji.isNotEmpty) {
      return Center(
        child: Text(
          tile.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }

    return Center(
      child: Text(
        tile.label,
        style: TextStyle(
          color: _parseColor(tile.textColor),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _parseColor(String colorString) {
    if (colorString == 'transparent') return Colors.white;
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }
}
```

---

## 9. Offline Banner

```dart
// lib/widgets/offline_banner.dart
class OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'You are offline. Changes will sync when connection is restored.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
});
```

---

## 10. Summary

This offline-first architecture provides:

1. **Full Offline Functionality** - App works completely without internet
2. **Local Storage** - Drift database, local assets, local settings
3. **Local Speech Engine** - Cross-platform TTS with voice caching
4. **Sync Architecture** - Queue-based sync with automatic retry
5. **Conflict Resolution** - Multiple strategies including last-write-wins and manual
6. **Recovery Mechanisms** - Sync recovery and data backup/restore
7. **Cloud Sync UI** - Dedicated pages for upload/download and sync status
8. **Asset Loading Priority** - Local → Bundled → Cloud
9. **Offline Banner** - Visual indicator of offline status
10. **Transparent Sync** - Automatic sync when online

---

**Related Documents:**
- [UNIVERSAL_DATABASE.md](UNIVERSAL_DATABASE.md)
- [BACKEND_COMPATIBILITY.md](BACKEND_COMPATIBILITY.md)
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
