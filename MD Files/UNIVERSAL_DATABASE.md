# Universal Database Architecture

## Overview

This document provides a comprehensive database strategy for Charlie Chat that works across Android, iOS, Web, Windows, and macOS with shared schema, local storage, cloud replication, fast search, and version migrations.

---

## 1. Technology Selection

### Recommended: Drift (formerly Moor)

**Why Drift?**
- ✅ Cross-platform support (SQLite on native, IndexedDB on web)
- ✅ Type-safe queries with compile-time verification
- ✅ Shared schema via Dart code
- ✅ Built-in migration system
- ✅ Fast queries with SQLite on native platforms
- ✅ Excellent developer experience
- ✅ Active maintenance and community

**Alternative Options:**
- **Isar** - Object database, fast, but less mature for web
- **sqflite** - SQLite only, no web support
- **Hive** - NoSQL, fast, but no SQL queries
- **ObjectBox** - Fast, but limited web support

### Dependencies

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3: ^2.3.0
  sqlite3_flutter_libs: ^3.1.0
  path_provider: ^2.0.13
  path: ^1.8.3
  
dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

---

## 2. Database Schema

### Database Definition

```dart
// lib/data/database/app_database.dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Boards,
  SymbolTiles,
  UserProfiles,
  AppSettings,
  SyncRecords,
  Favorites,
  PhraseHistory,
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
        await _seedInitialData(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await _upgradeFrom(m, from, to);
      },
    );
  }

  Future<void> _createIndexes(Migrator m) async {
    // Performance indexes
    await m.createIndex(boards_name_index);
    await m.createIndex(symbolTiles_board_id_index);
    await m.createIndex(symbolTiles_category_index);
    await m.createIndex(userProfiles_name_index);
    await m.createIndex(syncRecords_status_index);
    await m.createIndex(syncRecords_entity_type_index);
  }

  Future<void> _seedInitialData(Migrator m) async {
    // Seed initial data if needed
  }

  Future<void> _upgradeFrom(Migrator m, int from, int to) async {
    // Handle version migrations
    if (from == 1 && to == 2) {
      await m.addColumn(boards, boards.adjustableLayout);
      await m.addColumn(boards, boards.boxScale);
    }
    // Add more migrations as needed
  }
}
```

### Table Definitions

#### Boards Table

```dart
@DataClassName('Board')
class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get rows => integer().withDefault(const Constant(6))();
  IntColumn get columns => integer().withDefault(const Constant(5))();
  BoolColumn get adjustableLayout => boolean().withDefault(const Constant(false))();
  RealColumn get boxScale => real().withDefault(const Constant(1.0))();
  RealColumn get tileHeight => real().withDefault(const Constant(100.0))();
  RealColumn get tileWidth => real().withDefault(const Constant(100.0))();
  TextColumn get backgroundColor => text().withDefault(const Constant('transparent'))();
  BoolColumn get isSubBoard => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Indexes
final boards_name_index = Index('boards_name_index', [Boards.name]);
```

#### SymbolTiles Table

```dart
@DataClassName('SymbolTile')
class SymbolTiles extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id)();
  TextColumn get label => text()();
  TextColumn get category => text()();
  TextColumn get imageAsset => text()();
  TextColumn get emoji => text().nullable()();
  TextColumn get linkedBoardId => text().nullable()();
  BoolColumn get isBoardLink => boolean().withDefault(const Constant(false))();
  RealColumn get tileSize => real().withDefault(const Constant(1.0))();
  TextColumn get bgColor => text().withDefault(const Constant('transparent'))();
  TextColumn get textColor => text().withDefault(const Constant('#000000'))();
  TextColumn get customVoice => text().nullable()();
  IntColumn get position => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Indexes
final symbolTiles_board_id_index = Index('symbolTiles_board_id_index', [SymbolTiles.boardId]);
final symbolTiles_category_index = Index('symbolTiles_category_index', [SymbolTiles.category]);
```

#### UserProfiles Table

```dart
@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get settingsJson => text()();
  TextColumn get tabOrderJson => text().withDefault(const Constant('[]'))();
  TextColumn get preferredSymbolSetsJson => text().withDefault(const Constant('[]'))();
  TextColumn get startingBoardId => text().withDefault(const Constant(''))();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Indexes
final userProfiles_name_index = Index('userProfiles_name_index', [UserProfiles.name]);
```

#### AppSettings Table

```dart
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  RealColumn get voiceRate => real().withDefault(const Constant(0.5))();
  RealColumn get voicePitch => real().withDefault(const Constant(1.0))();
  RealColumn get voiceVolume => real().withDefault(const Constant(1.0))();
  TextColumn get voiceLanguage => text().withDefault(const Constant('en-GB'))();
  TextColumn get voiceName => text().withDefault(const Constant('Google UK English Female'))();
  TextColumn get sentenceSize => text().withDefault(const Constant('medium'))();
  TextColumn get sentenceType => text().withDefault(const Constant('both'))();
  BoolColumn get readSentenceOnly => boolean().withDefault(const Constant(false))();
  TextColumn get profileImage => text().withDefault(const Constant(''))();
  TextColumn get fontSize => text().withDefault(const Constant('medium'))();
  BoolColumn get highContrast => boolean().withDefault(const Constant(false))();
  TextColumn get projectRoot => text().withDefault(const Constant(''))();
  
  @override
  Set<Column> get primaryKey => {profileId};
}
```

#### SyncRecords Table

```dart
@DataClassName('SyncRecord')
class SyncRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get localRevision => integer()();
  IntColumn get baseRemoteRevision => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get conflictResolution => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get remotePayloadJson => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Indexes
final syncRecords_status_index = Index('syncRecords_status_index', [SyncRecords.status]);
final syncRecords_entity_type_index = Index('syncRecords_entity_type_index', [SyncRecords.entityType]);
```

#### Favorites Table

```dart
@DataClassName('Favorite')
class Favorites extends Table {
  TextColumn get id => text()();
  TextColumn get tileId => text()();
  DateTimeColumn get addedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

#### PhraseHistory Table

```dart
@DataClassName('Phrase')
class PhraseHistory extends Table {
  TextColumn get id => text()();
  TextColumn get phrase => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. Database Initialization

### Platform-Specific Initialization

```dart
// lib/data/database/database_factory.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/web.dart';
import 'package:drift/sqlite3.dart' as sqlite3;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_database.dart';

class DatabaseFactory {
  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    
    if (kIsWeb) {
      _instance = AppDatabase(_createWebDatabase());
    } else {
      _instance = AppDatabase(await _createNativeDatabase());
    }
    
    return _instance!;
  }

  static QueryExecutor _createWebDatabase() {
    return WebDatabase('charliechat_db');
  }

  static Future<QueryExecutor> _createNativeDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'charliechat.db');
    
    // For better performance on native platforms
    final nativeDB = sqlite3.Sqlite3.openInVfs(
      path,
      mode: sqlite3.OpenMode.readWriteCreate,
    );
    
    return NativeDatabase.createInBackground(nativeDB);
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
```

### Database Access Layer

```dart
// lib/data/database/database_repository.dart
import 'package:drift/drift.dart';

import 'app_database.dart';

class DatabaseRepository {
  final AppDatabase _db;

  DatabaseRepository(this._db);

  // Boards
  Future<List<Board>> getAllBoards() => _db.select(_db.boards).get();
  
  Future<Board?> getBoard(String id) => (_db.select(_db.boards)
    ..where((b) => b.id.equals(id))
  ).getSingleOrNull();
  
  Future<void> insertBoard(BoardsCompanion board) => _db.into(_db.boards).insert(board);
  
  Future<void> updateBoard(Board board) => _db.update(_db.boards).replace(board);
  
  Future<void> deleteBoard(String id) => (_db.delete(_db.boards)
    ..where((b) => b.id.equals(id))
  ).go();

  // Symbol Tiles
  Future<List<SymbolTile>> getTilesForBoard(String boardId) => (_db.select(_db.symbolTiles)
    ..where((t) => t.boardId.equals(boardId))
    ..orderBy([(t) => OrderingTerm.asc(t.position)])
  ).get();
  
  Future<void> insertTile(SymbolTilesCompanion tile) => _db.into(_db.symbolTiles).insert(tile);
  
  Future<void> updateTile(SymbolTile tile) => _db.update(_db.symbolTiles).replace(tile);
  
  Future<void> deleteTile(String id) => (_db.delete(_db.symbolTiles)
    ..where((t) => t.id.equals(id))
  ).go();

  // User Profiles
  Future<List<UserProfile>> getAllProfiles() => _db.select(_db.userProfiles).get();
  
  Future<UserProfile?> getProfile(String id) => (_db.select(_db.userProfiles)
    ..where((p) => p.id.equals(id))
  ).getSingleOrNull();
  
  Future<void> insertProfile(UserProfilesCompanion profile) => _db.into(_db.userProfiles).insert(profile);
  
  Future<void> updateProfile(UserProfile profile) => _db.update(_db.userProfiles).replace(profile);
  
  Future<void> deleteProfile(String id) => (_db.delete(_db.userProfiles)
    ..where((p) => p.id.equals(id))
  ).go();

  // Sync Records
  Future<List<SyncRecord>> getPendingSyncRecords() => (_db.select(_db.syncRecords)
    ..where((s) => s.status.equals('pending'))
  ).get();
  
  Future<void> insertSyncRecord(SyncRecordsCompanion record) => _db.into(_db.syncRecords).insert(record);
  
  Future<void> updateSyncRecord(SyncRecord record) => _db.update(_db.syncRecords).replace(record);
  
  Future<void> deleteSyncRecord(String id) => (_db.delete(_db.syncRecords)
    ..where((s) => s.id.equals(id))
  ).go();

  // Favorites
  Future<List<Favorite>> getAllFavorites() => _db.select(_db.favorites).get();
  
  Future<void> addFavorite(FavoritesCompanion favorite) => _db.into(_db.favorites).insert(favorite);
  
  Future<void> removeFavorite(String id) => (_db.delete(_db.favorites)
    ..where((f) => f.id.equals(id))
  ).go();

  // Phrase History
  Future<List<Phrase>> getPhraseHistory({int limit = 12}) => (_db.select(_db.phraseHistory)
    ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
    ..limit(limit)
  ).get();
  
  Future<void> addPhrase(PhrasesCompanion phrase) => _db.into(_db.phraseHistory).insert(phrase);
  
  Future<void> clearPhraseHistory() => _db.delete(_db.phraseHistory).go();

  // Search
  Future<List<SymbolTile>> searchTiles(String query) => (_db.select(_db.symbolTiles)
    ..where((t) => t.label.like('%$query%'))
  ).get();
  
  Future<List<Board>> searchBoards(String query) => (_db.select(_db.boards)
    ..where((b) => b.name.like('%$query%'))
  ).get();
}
```

---

## 4. Cloud Replication Strategy

### Sync Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Local Database                         │
│                    (Drift/SQLite/IndexedDB)                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Sync Service Layer                        │
│  - Change Detection              - Conflict Resolution        │
│  - Operation Queueing            - Retry Logic               │
│  - Batch Processing              - Error Handling            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Network Layer                             │
│  - HTTP/WebSocket               - Authentication            │
│  - Compression                  - Encryption                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Backend                             │
│  - REST API                     - Real-time Sync             │
│  - Database                     - Conflict Detection         │
└─────────────────────────────────────────────────────────────┘
```

### Sync Service Implementation

```dart
// lib/services/sync/database_sync_service.dart
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/database_repository.dart';

class DatabaseSyncService {
  final DatabaseRepository _db;
  final SyncApiClient _api;
  
  DatabaseSyncService(this._db, this._api);

  Future<SyncResult> sync() async {
    try {
      // 1. Get pending local changes
      final pendingChanges = await _db.getPendingSyncRecords();
      
      // 2. Push local changes to server
      final pushResults = await _pushChanges(pendingChanges);
      
      // 3. Pull remote changes
      final remoteChanges = await _api.getRemoteChanges(_getLastSyncTimestamp());
      
      // 4. Apply remote changes locally
      final applyResults = await _applyRemoteChanges(remoteChanges);
      
      // 5. Update sync timestamp
      await _updateLastSyncTimestamp();
      
      // 6. Clean up synced records
      await _cleanupSyncedRecords();
      
      return SyncResult(
        success: true,
        changesPushed: pushResults.successful,
        changesPulled: applyResults.applied,
        conflicts: pushResults.conflicts + applyResults.conflicts,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<PushResult> _pushChanges(List<SyncRecord> changes) async {
    int successful = 0;
    int conflicts = 0;
    
    for (final change in changes) {
      try {
        final result = await _api.pushChange(change);
        
        if (result.conflict) {
          conflicts++;
          await _handleConflict(change, result.remoteData);
        } else {
          successful++;
          change.status = 'synced';
          await _db.updateSyncRecord(change);
        }
      } catch (e) {
        change.status = 'failed';
        change.errorMessage = e.toString();
        await _db.updateSyncRecord(change);
      }
    }
    
    return PushResult(successful: successful, conflicts: conflicts);
  }

  Future<ApplyResult> _applyRemoteChanges(List<RemoteChange> changes) async {
    int applied = 0;
    int conflicts = 0;
    
    for (final change in changes) {
      try {
        final localRecord = await _db.getSyncRecordByEntityId(change.entityId);
        
        if (localRecord != null && localRecord.status == 'pending') {
          // Conflict: both local and remote have changes
          conflicts++;
          await _handleConflict(localRecord, change);
        } else {
          // No conflict, apply remote change
          await _applyChange(change);
          applied++;
        }
      } catch (e) {
        debugPrint('Error applying remote change: $e');
      }
    }
    
    return ApplyResult(applied: applied, conflicts: conflicts);
  }

  Future<void> _handleConflict(SyncRecord localRecord, RemoteChange remoteChange) async {
    // Conflict resolution strategy: last-write-wins based on timestamp
    final localTimestamp = localRecord.updatedAt;
    final remoteTimestamp = remoteChange.updatedAt;
    
    if (remoteTimestamp.isAfter(localTimestamp)) {
      // Remote wins, apply remote change
      await _applyChange(remoteChange);
      
      // Mark local as synced
      localRecord.status = 'synced';
      localRecord.conflictResolution = 'remote_wins';
      await _db.updateSyncRecord(localRecord);
    } else {
      // Local wins, keep local change
      localRecord.status = 'synced';
      localRecord.conflictResolution = 'local_wins';
      await _db.updateSyncRecord(localRecord);
    }
  }

  Future<void> _applyChange(RemoteChange change) async {
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
      // Add other entity types
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

  Future<void> _applyTileChange(RemoteChange change) async {
    final tile = SymbolTile.fromJson(change.payload);
    
    switch (change.operation) {
      case 'upsert':
        final existing = await _db.getTile(tile.id);
        if (existing == null) {
          await _db.insertTile(tile.toCompanion());
        } else {
          await _db.updateTile(tile);
        }
        break;
      case 'delete':
        await _db.deleteTile(tile.id);
        break;
    }
  }

  Future<DateTime?> _getLastSyncTimestamp() async {
    // Implement timestamp retrieval
    return null;
  }

  Future<void> _updateLastSyncTimestamp() async {
    // Implement timestamp update
  }

  Future<void> _cleanupSyncedRecords() async {
    // Delete synced records older than 30 days
  }
}
```

### Change Tracking

```dart
// lib/data/database/change_tracker.dart
class ChangeTracker {
  final DatabaseRepository _db;
  
  ChangeTracker(this._db);

  Future<void> trackBoardChange(String boardId, String operation) async {
    final board = await _db.getBoard(boardId);
    if (board == null) return;
    
    await _db.insertSyncRecord(SyncRecordsCompanion.insert(
      id: _generateId(),
      entityType: 'board',
      entityId: boardId,
      operation: operation,
      payloadJson: board.toJson(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      localRevision: DateTime.now().millisecondsSinceEpoch,
      status: const Value('pending'),
    ));
  }

  Future<void> trackTileChange(String tileId, String operation) async {
    final tile = await _db.getTile(tileId);
    if (tile == null) return;
    
    await _db.insertSyncRecord(SyncRecordsCompanion.insert(
      id: _generateId(),
      entityType: 'symbol_tile',
      entityId: tileId,
      operation: operation,
      payloadJson: tile.toJson(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      localRevision: DateTime.now().millisecondsSinceEpoch,
      status: const Value('pending'),
    ));
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
```

---

## 5. Fast Search Implementation

### Full-Text Search

```dart
// lib/data/database/search_service.dart
class SearchService {
  final DatabaseRepository _db;
  
  SearchService(this._db);

  // Simple LIKE search
  Future<List<SymbolTile>> searchTiles(String query) async {
    return (_db.select(_db.symbolTiles)
      ..where((t) => t.label.like('%$query%'))
      ..limit(50)
    ).get();
  }

  // Multi-field search
  Future<List<SymbolTile>> searchTilesAdvanced(String query) async {
    return (_db.select(_db.symbolTiles)
      ..where((t) => 
        t.label.like('%$query%') |
        t.category.like('%$query%')
      )
      ..limit(50)
    ).get();
  }

  // Board search
  Future<List<Board>> searchBoards(String query) async {
    return (_db.select(_db.boards)
      ..where((b) => b.name.like('%$query%'))
      ..limit(20)
    ).get();
  }

  // Global search (boards + tiles)
  Future<SearchResults> globalSearch(String query) async {
    final boards = await searchBoards(query);
    final tiles = await searchTiles(query);
    
    return SearchResults(
      boards: boards,
      tiles: tiles,
    );
  }
}

class SearchResults {
  final List<Board> boards;
  final List<SymbolTile> tiles;
  
  SearchResults({required this.boards, required this.tiles});
  
  int get totalResults => boards.length + tiles.length;
}
```

### FTS (Full-Text Search) Extension

For advanced search performance, add SQLite FTS extension:

```dart
// In app_database.dart
@DriftDatabase(tables: [
  Boards,
  SymbolTiles,
  SymbolTilesFts, // FTS table
])
class AppDatabase extends _$AppDatabase {
  // ... existing code
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAllTables();
        await _createFtsTable(m);
      },
    );
  }

  Future<void> _createFtsTable(Migrator m) async {
    await m.createTable(symbolTilesFts);
    await m.createIndex(symbolTilesFts_content_index);
    
    // Create triggers to keep FTS table in sync
    await m.customStatement('''
      CREATE TRIGGER symbol_tiles_fts_insert AFTER INSERT ON symbol_tiles BEGIN
        INSERT INTO symbol_tiles_fts (rowid, label, category)
        VALUES (new.id, new.label, new.category);
      END;
    ''');
    
    await m.customStatement('''
      CREATE TRIGGER symbol_tiles_fts_delete AFTER DELETE ON symbol_tiles BEGIN
        DELETE FROM symbol_tiles_fts WHERE rowid = old.id;
      END;
    ''');
    
    await m.customStatement('''
      CREATE TRIGGER symbol_tiles_fts_update AFTER UPDATE ON symbol_tiles BEGIN
        UPDATE symbol_tiles_fts SET label = new.label, category = new.category
        WHERE rowid = new.id;
      END;
    ''');
  }
}

@DataClassName('SymbolTileFts')
class SymbolTilesFts extends Table {
  TextColumn get rowid => text()();
  TextColumn get label => text()();
  TextColumn get category => text()();
  
  @override
  Set<Column> get primaryKey => {rowid};
}

// FTS search
Future<List<SymbolTile>> ftsSearch(String query) async {
  return customSelect(
    'SELECT * FROM symbol_tiles WHERE id IN (SELECT rowid FROM symbol_tiles_fts WHERE symbol_tiles_fts MATCH ?)',
    variables: [Variable.withString(query)],
  ).map((row) => SymbolTile.fromData(row.data, _db)).get();
}
```

---

## 6. Version Migrations

### Migration Strategy

```dart
// lib/data/database/migrations.dart
class MigrationManager {
  final AppDatabase _db;
  
  MigrationManager(this._db);

  static const int currentVersion = 1;

  Future<void> migrateTo(int targetVersion) async {
    final currentVersion = _db.schemaVersion;
    
    if (currentVersion == targetVersion) return;
    
    if (currentVersion < targetVersion) {
      for (int version = currentVersion + 1; version <= targetVersion; version++) {
        await _migrateTo(version);
      }
    }
  }

  Future<void> _migrateTo(int version) async {
    switch (version) {
      case 2:
        await _migrateToV2();
        break;
      case 3:
        await _migrateToV3();
        break;
      // Add more migrations
    }
  }

  Future<void> _migrateToV2() async {
    // Add adjustableLayout and boxScale to boards
    await _db.customStatement('ALTER TABLE boards ADD COLUMN adjustable_layout BOOLEAN DEFAULT false');
    await _db.customStatement('ALTER TABLE boards ADD COLUMN box_scale REAL DEFAULT 1.0');
    
    // Create new index
    await _db.customStatement('CREATE INDEX IF NOT EXISTS boards_adjustable_layout_index ON boards(adjustable_layout)');
  }

  Future<void> _migrateToV3() async {
    // Add position column to symbol_tiles
    await _db.customStatement('ALTER TABLE symbol_tiles ADD COLUMN position INTEGER DEFAULT 0');
    
    // Update existing tiles with position
    await _db.customStatement('''
      UPDATE symbol_tiles 
      SET position = (
        SELECT COUNT(*) FROM symbol_tiles st2 
        WHERE st2.board_id = symbol_tiles.board_id AND st2.id <= symbol_tiles.id
      )
    ''');
    
    // Create index
    await _db.customStatement('CREATE INDEX IF NOT EXISTS symbol_tiles_position_index ON symbol_tiles(position)');
  }
}
```

### Data Migration

```dart
// lib/data/database/data_migration.dart
class DataMigration {
  final DatabaseRepository _db;
  
  DataMigration(this._db);

  Future<void> migrateFromJsonToDatabase() async {
    // Migrate from JSON files to Drift database
    // This is useful when transitioning from the old storage system
  }

  Future<void> migrateFromSharedPreferences() async {
    // Migrate from SharedPreferences to Drift database
  }

  Future<void> backupDatabase() async {
    // Create a backup of the database
  }

  Future<void> restoreDatabase(String backupPath) async {
    // Restore database from backup
  }
}
```

---

## 7. Performance Optimization

### Connection Pooling

```dart
// lib/data/database/connection_pool.dart
class DatabaseConnectionPool {
  static final DatabaseConnectionPool _instance = DatabaseConnectionPool._internal();
  factory DatabaseConnectionPool() => _instance;
  DatabaseConnectionPool._internal();

  final Map<String, AppDatabase> _connections = {};
  final int _maxConnections = 5;

  Future<AppDatabase> getConnection(String profileId) async {
    if (_connections.containsKey(profileId)) {
      return _connections[profileId]!;
    }

    if (_connections.length >= _maxConnections) {
      // Close oldest connection
      final oldestKey = _connections.keys.first;
      await _connections[oldestKey]?.close();
      _connections.remove(oldestKey);
    }

    final db = await DatabaseFactory.getInstance();
    _connections[profileId] = db;
    return db;
  }

  Future<void> closeAll() async {
    for (final db in _connections.values) {
      await db.close();
    }
    _connections.clear();
  }
}
```

### Query Optimization

```dart
// lib/data/database/query_optimizer.dart
class QueryOptimizer {
  // Use transactions for bulk operations
  static Future<void> bulkInsertTiles(List<SymbolTilesCompanion> tiles) async {
    final db = await DatabaseFactory.getInstance();
    await db.transaction(() async {
      for (final tile in tiles) {
        await db.into(db.symbolTiles).insert(tile);
      }
    });
  }

  // Batch updates
  static Future<void> bulkUpdateTiles(List<SymbolTile> tiles) async {
    final db = await DatabaseFactory.getInstance();
    await db.transaction(() async {
      for (final tile in tiles) {
        await db.update(db.symbolTiles).replace(tile);
      }
    });
  }

  // Lazy loading with pagination
  static Future<List<SymbolTile>> getTilesPaginated(
    String boardId, {
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await DatabaseFactory.getInstance();
    return (db.select(db.symbolTiles)
      ..where((t) => t.boardId.equals(boardId))
      ..limit(limit)
      ..offset(offset)
    ).get();
  }
}
```

---

## 8. Backup and Restore

### Backup Service

```dart
// lib/services/backup/database_backup_service.dart
class DatabaseBackupService {
  final DatabaseRepository _db;
  
  DatabaseBackupService(this._db);

  Future<String> createBackup() async {
    final db = await DatabaseFactory.getInstance();
    final backup = await db.export();
    final timestamp = DateTime.now().toIso8601String();
    final backupPath = 'charliechat_backup_$timestamp.json';
    
    // Save backup to file
    // Implementation depends on platform
    
    return backupPath;
  }

  Future<void> restoreBackup(String backupPath) async {
    final backupContent = await File(backupPath).readAsString();
    final backupData = jsonDecode(backupContent);
    
    // Clear existing data
    await _clearAllData();
    
    // Restore from backup
    await _restoreFromData(backupData);
  }

  Future<void> _clearAllData() async {
    await _db.deleteAllBoards();
    await _db.deleteAllTiles();
    await _db.deleteAllProfiles();
    // Clear other tables
  }

  Future<void> _restoreFromData(Map<String, dynamic> data) async {
    // Restore data from backup
    final boards = data['boards'] as List;
    for (final board in boards) {
      await _db.insertBoard(Board.fromJson(board).toCompanion());
    }
    // Restore other entities
  }
}
```

---

## 9. Testing

### Unit Tests

```dart
test('DatabaseRepository inserts and retrieves board', () async {
  final db = AppDatabase.inMemory();
  final repo = DatabaseRepository(db);
  
  final board = BoardsCompanion.insert(
    id: 'test-id',
    name: 'Test Board',
    rows: const Value(6),
    columns: const Value(5),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  await repo.insertBoard(board);
  final retrieved = await repo.getBoard('test-id');
  
  expect(retrieved?.name, 'Test Board');
});

test('SearchService finds tiles by label', () async {
  final db = AppDatabase.inMemory();
  final repo = DatabaseRepository(db);
  final searchService = SearchService(repo);
  
  await repo.insertTile(SymbolTilesCompanion.insert(
    id: 'tile-1',
    boardId: 'board-1',
    label: 'Apple',
    category: 'Food',
    position: 0,
  ));
  
  final results = await searchService.searchTiles('Apple');
  
  expect(results.length, 1);
  expect(results.first.label, 'Apple');
});
```

---

## 10. Summary

This database architecture provides:

1. **Cross-Platform Support** - Drift works on Android, iOS, Web, Windows, and macOS
2. **Shared Schema** - Single Dart codebase defines all tables
3. **Local Storage** - SQLite on native, IndexedDB on web
4. **Cloud Replication** - Sync service with conflict resolution
5. **Fast Search** - Indexed queries with optional FTS
6. **Version Migrations** - Built-in migration system
7. **Performance** - Connection pooling, batch operations, transactions
8. **Backup/Restore** - Database backup and restore functionality

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [FLUTTER_UNIVERSAL_CLIENT.md](FLUTTER_UNIVERSAL_CLIENT.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
