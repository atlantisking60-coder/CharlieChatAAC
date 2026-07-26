# Navigation Architecture

## Overview

This document provides the complete navigation architecture for Charlie Chat, including the final tech stack, project structure, database schema, API specification, sync strategy, and navigation map with Flutter/go_router implementation.

---

## 1. Final Tech Stack

### Frontend (Flutter)

```yaml
Framework: Flutter 3.24+
Language: Dart 3.6+
State Management: Riverpod 2.4+
Navigation: go_router 13.0+
Dependency Injection: GetIt 7.6+
Database: Drift 2.14+ (SQLite/IndexedDB)
Networking: http 1.6+
Connectivity: connectivity_plus 5.0+
```

### Backend (Node.js)

```yaml
Framework: Node.js 18+ with Express/Fastify
Language: TypeScript 5+
Database: PostgreSQL 15+
Cache: Redis 7+
Storage: AWS S3 / Cloud Storage
Authentication: JWT + OAuth 2.0
API: REST + WebSocket (optional)
```

### Cross-Platform Support

- **Android** - Native APK, Play Store
- **iOS** - Native IPA, App Store
- **iPadOS** - Native iPad-optimized
- **Windows** - MSIX, Microsoft Store
- **macOS** - DMG, Mac App Store
- **Linux** - AppImage, Snap
- **Web** - PWA, web browsers

---

## 2. Project Structure

```
charliechat/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                          # App widget configuration
│   │
│   ├── core/                             # Core utilities
│   │   ├── constants/
│   │   │   ├── app_constants.dart       # App-wide constants
│   │   │   ├── board_constants.dart     # Board constants
│   │   │   └── storage_constants.dart   # Storage keys
│   │   ├── theme/
│   │   │   ├── app_theme.dart          # Theme configuration
│   │   │   ├── light_theme.dart         # Light theme
│   │   │   ├── dark_theme.dart          # Dark theme
│   │   │   └── text_styles.dart        # Text styles
│   │   ├── di/
│   │   │   └── di_config.dart           # Dependency injection
│   │   ├── routes/
│   │   │   └── app_router.dart          # Navigation (go_router)
│   │   └── utils/
│   │       ├── responsive.dart          # Responsive utilities
│   │       ├── validators.dart          # Input validators
│   │       └── formatters.dart          # Data formatters
│   │
│   ├── data/                             # Data layer
│   │   ├── models/                       # Data transfer objects
│   │   │   ├── board_model.dart
│   │   │   ├── symbol_tile_model.dart
│   │   │   ├── user_profile_model.dart
│   │   │   └── app_settings_model.dart
│   │   ├── repositories/                 # Repository implementations
│   │   │   ├── board_repository_impl.dart
│   │   │   ├── profile_repository_impl.dart
│   │   │   ├── settings_repository_impl.dart
│   │   │   └── sync_repository_impl.dart
│   │   ├── datasources/                  # Data sources
│   │   │   ├── local/                    # Local storage
│   │   │   │   ├── board_local_datasource.dart
│   │   │   │   ├── profile_local_datasource.dart
│   │   │   │   ├── settings_local_datasource.dart
│   │   │   │   └── favorites_local_datasource.dart
│   │   │   └── remote/                   # Remote APIs
│   │   │       ├── symboltalk_api_datasource.dart
│   │   │       └── sync_remote_datasource.dart
│   │   ├── database/                     # Database (Drift)
│   │   │   ├── app_database.dart         # Database definition
│   │   │   ├── dao/                      # Data access objects
│   │   │   └── migrations/               # Database migrations
│   │   ├── mappers/                      # Model-Entity converters
│   │   │   ├── board_mapper.dart
│   │   │   ├── symbol_tile_mapper.dart
│   │   │   ├── profile_mapper.dart
│   │   │   └── settings_mapper.dart
│   │   └── services/                     # Data services
│   │       ├── board_service.dart
│   │       ├── profile_service.dart
│   │       ├── settings_service.dart
│   │       ├── sync_service.dart
│   │       ├── tts_service.dart
│   │       ├── favorites_service.dart
│   │       ├── phrase_service.dart
│   │       ├── asset_service.dart
│   │       └── operation_queue_service.dart
│   │
│   ├── domain/                           # Domain layer
│   │   ├── entities/                     # Core business objects
│   │   │   ├── board.dart
│   │   │   ├── symbol_tile.dart
│   │   │   ├── user_profile.dart
│   │   │   └── app_settings.dart
│   │   ├── usecases/                     # Use cases
│   │   │   ├── board/
│   │   │   │   ├── get_boards_usecase.dart
│   │   │   │   ├── get_board_usecase.dart
│   │   │   │   ├── save_board_usecase.dart
│   │   │   │   └── delete_board_usecase.dart
│   │   │   ├── profile/
│   │   │   │   ├── get_profiles_usecase.dart
│   │   │   │   ├── create_profile_usecase.dart
│   │   │   │   └── update_profile_usecase.dart
│   │   │   └── tts/
│   │   │       ├── speak_text_usecase.dart
│   │   │       └── set_voice_usecase.dart
│   │   └── repositories/                 # Repository interfaces
│   │       ├── board_repository_interface.dart
│   │       ├── profile_repository_interface.dart
│   │       └── settings_repository_interface.dart
│   │
│   ├── presentation/                     # Presentation layer
│   │   ├── pages/                        # Full-screen pages
│   │   │   ├── splash/
│   │   │   │   └── splash_page.dart
│   │   │   ├── onboarding/
│   │   │   │   ├── onboarding_page.dart
│   │   │   │   └── onboarding_steps.dart
│   │   │   ├── home/
│   │   │   │   ├── home_page.dart
│   │   │   │   └── home_page_view.dart
│   │   │   ├── boards/
│   │   │   │   ├── boards_page.dart
│   │   │   │   ├── boards_page_view.dart
│   │   │   │   └── board_detail_page.dart
│   │   │   ├── communication/
│   │   │   │   ├── communication_page.dart
│   │   │   │   └── communication_page_view.dart
│   │   │   ├── build_mode/
│   │   │   │   ├── build_mode_page.dart
│   │   │   │   └── board_editor_page.dart
│   │   │   ├── me_mode/
│   │   │   │   ├── me_mode_page.dart
│   │   │   │   └── me_mode_page_view.dart
│   │   │   ├── settings/
│   │   │   │   ├── settings_page.dart
│   │   │   │   ├── settings_page_view.dart
│   │   │   │   ├── voice_settings_page.dart
│   │   │   │   ├── display_settings_page.dart
│   │   │   │   └── sync_settings_page.dart
│   │   │   ├── profiles/
│   │   │   │   ├── profiles_page.dart
│   │   │   │   ├── profiles_page_view.dart
│   │   │   │   └── profile_editor_page.dart
│   │   │   ├── search/
│   │   │   │   ├── search_page.dart
│   │   │   │   └── search_page_view.dart
│   │   │   ├── cloud_sync/
│   │   │   │   ├── cloud_sync_page.dart
│   │   │   │   ├── sync_status_page.dart
│   │   │   │   └── cloud_sync_page_view.dart
│   │   │   └── help/
│   │   │       ├── help_page.dart
│   │   │       └── help_page_view.dart
│   │   ├── widgets/                      # Reusable widgets
│   │   │   ├── common/                   # Common widgets
│   │   │   │   ├── app_bar.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   ├── empty_state.dart
│   │   │   │   └── offline_banner.dart
│   │   │   ├── board/                    # Board widgets
│   │   │   │   ├── symbol_grid.dart
│   │   │   │   ├── symbol_tile.dart
│   │   │   │   ├── board_header.dart
│   │   │   │   └── board_navigation.dart
│   │   │   ├── symbol/                   # Symbol widgets
│   │   │   │   ├── symbol_button.dart
│   │   │   │   ├── symbol_image.dart
│   │   │   │   └── symbol_emoji.dart
│   │   │   └── sentence/                 # Sentence widgets
│   │   │       ├── sentence_panel.dart
│   │   │       ├── phrase_panel.dart
│   │   │       └── speech_button.dart
│   │   ├── providers/                    # State management (Riverpod)
│   │   │   ├── board_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   ├── profile_provider.dart
│   │   │   ├── tts_provider.dart
│   │   │   ├── sync_provider.dart
│   │   │   ├── cloud_sync_provider.dart
│   │   │   └── connectivity_provider.dart
│   │   └── viewmodels/                   # View models (MVVM)
│   │       ├── board_viewmodel.dart
│   │       ├── settings_viewmodel.dart
│   │       └── profile_viewmodel.dart
│   │
│   └── platform/                         # Platform-specific code
│       ├── android/                      # Android-specific
│       ├── ios/                          # iOS-specific
│       ├── windows/                      # Windows-specific
│       ├── macos/                        # macOS-specific
│       ├── linux/                        # Linux-specific
│       └── web/                          # Web-specific
│
├── assets/
│   ├── symbols/                          # Symbol images
│   ├── fonts/                            # Custom fonts
│   └── sounds/                           # Sound effects
│
├── test/                                 # Tests
│   ├── unit/                             # Unit tests
│   ├── widget/                           # Widget tests
│   └── integration/                      # Integration tests
│
├── docs/                                 # Documentation
│   ├── CLEAN_ARCHITECTURE.md
│   ├── DOMAIN_LAYER.md
│   ├── DATA_LAYER.md
│   ├── PRESENTATION_LAYER.md
│   ├── UNIVERSAL_DATABASE.md
│   ├── BACKEND_COMPATIBILITY.md
│   ├── API_VERSIONING.md
│   ├── OFFLINE_FIRST_ARCHITECTURE.md
│   └── NAVIGATION_ARCHITECTURE.md
│
├── pubspec.yaml                          # Dependencies
├── analysis_options.yaml                 # Lint rules
└── README.md                             # Project README
```

---

## 3. Database Schema

### Drift Database Definition

```dart
// lib/data/database/app_database.dart
@DriftDatabase(tables: [
  Boards,
  SymbolTiles,
  UserProfiles,
  AppSettings,
  SyncQueue,
  AssetMetadata,
  Favorites,
  PhraseHistory,
  OnboardingState,
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
    await m.createIndex(boards_name_index);
    await m.createIndex(symbolTiles_board_id_index);
    await m.createIndex(symbolTiles_category_index);
    await m.createIndex(userProfiles_name_index);
    await m.createIndex(syncQueue_status_index);
    await m.createIndex(assetMetadata_local_path_index);
  }

  Future<void> _seedInitialData(Migrator m) async {
    // Seed initial data
  }

  Future<void> _upgradeFrom(Migrator m, int from, int to) async {
    // Handle version migrations
  }
}
```

### Boards Table

```dart
@DataClassName('Board')
class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get userId => text()();
  IntColumn get rows => integer().withDefault(const Constant(6))();
  IntColumn get columns => integer().withDefault(const Constant(5))();
  BoolColumn get adjustableLayout => boolean().withDefault(const Constant(false))();
  RealColumn get boxScale => real().withDefault(const Constant(1.0))();
  RealColumn get tileHeight => real().withDefault(const Constant(100.0))();
  RealColumn get tileWidth => real().withDefault(const Constant(100.0))();
  TextColumn get backgroundColor => text().withDefault(const Constant('transparent'))();
  BoolColumn get isSubBoard => boolean().withDefault(const Constant(false))();
  TextColumn get parentBoardId => text().nullable()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### SymbolTiles Table

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
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### UserProfiles Table

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
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### AppSettings Table

```dart
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  RealColumn get voiceRate => real().withDefault(const Constant(0.5))();
  RealColumn get voicePitch => real().withDefault(const Constant(1.0))();
  RealColumn get voiceVolume => real().withDefault(const Constant(1.0))();
  TextColumn get voiceLanguage => text().withDefault(const Constant('en-GB'))();
  TextColumn get voiceName => text().withDefault(const Constant(''))();
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

### SyncQueue Table

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
```

### AssetMetadata Table

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
```

### Favorites Table

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

### PhraseHistory Table

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

### OnboardingState Table

```dart
@DataClassName('OnboardingState')
class OnboardingState extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get completedStepsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 4. API Specification

### Base URL

```
Production: https://api.charliechat.app
Staging: https://api-staging.charliechat.app
Development: http://localhost:3000
```

### Authentication Endpoints

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
POST   /api/v1/auth/oauth/google
POST   /api/v1/auth/oauth/apple
```

### User Profile Endpoints

```
GET    /api/v1/users/me
PUT    /api/v1/users/me
GET    /api/v1/users/me/settings
PUT    /api/v1/users/me/settings
DELETE /api/v1/users/me
```

### Board Endpoints

```
GET    /api/v1/boards
POST   /api/v1/boards
GET    /api/v1/boards/:id
PUT    /api/v1/boards/:id
DELETE /api/v1/boards/:id
POST   /api/v1/boards/:id/share
DELETE /api/v1/boards/:id/share/:userId
GET    /api/v1/boards/:id/versions
POST   /api/v1/boards/:id/restore
```

### Sync Endpoints

```
GET    /api/v1/sync/status
POST   /api/v1/sync/push
GET    /api/v1/sync/pull
GET    /api/v1/sync/changes
POST   /api/v1/sync/resolve
```

### Backup Endpoints

```
GET    /api/v1/backups
POST   /api/v1/backups
GET    /api/v1/backups/:id
DELETE /api/v1/backups/:id
POST   /api/v1/backups/:id/restore
GET    /api/v1/backups/:id/download
```

### Analytics Endpoints

```
POST   /api/v1/analytics/events
GET    /api/v1/analytics/summary
GET    /api/v1/analytics/boards
GET    /api/v1/analytics/users
```

---

## 5. Sync Strategy

### Sync Architecture

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
│  - Drift Database (SQLite/IndexedDB)                        │
│  - Local Asset Storage                                       │
│  - Local Settings (SharedPreferences)                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Sync Queue Layer                          │
│  - Operation Queue                                           │
│  - Conflict Detection                                        │
│  - Retry Logic (Exponential Backoff)                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Network Layer                              │
│  - Connectivity Detection                                    │
│  - HTTP Client with Retry                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Backend                             │
│  - REST API                                                  │
│  - PostgreSQL                                                │
│  - S3/Cloud Storage                                          │
└─────────────────────────────────────────────────────────────┘
```

### Sync Flow

1. **User Action** - User makes changes locally
2. **Queue Operation** - Change is queued in SyncQueue
3. **UI Update** - UI updates immediately (optimistic)
4. **Sync Trigger** - Sync runs when online
5. **Push Changes** - Pending operations pushed to server
6. **Pull Changes** - Remote changes pulled from server
7. **Conflict Resolution** - Conflicts detected and resolved
8. **Asset Sync** - Assets synced as needed

### Conflict Resolution

- **Last-Write-Wins** - Default strategy based on timestamp
- **Local Wins** - User preference
- **Remote Wins** - User preference
- **Manual** - User resolves conflicts manually
- **Merge** - Automatic merge when possible

---

## 6. Navigation Map

### Navigation Graph

```
┌─────────────────────────────────────────────────────────────┐
│                        Splash Screen                         │
│                    (Initial Load)                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
        ┌────────────────────────┐
        │  Onboarding Complete?  │
        └──────────┬─────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
        NO                  YES
         │                   │
         ↓                   ↓
┌──────────────────┐  ┌──────────────────┐
│  Onboarding      │  │  Home Screen     │
│  (3 Steps)       │  │  (Main Hub)     │
└──────────────────┘  └────────┬─────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ↓               ↓               ↓
        ┌──────────────┐ ┌──────────┐ ┌──────────────┐
        │   Boards     │ │  Search  │ │   Profiles   │
        └──────┬───────┘ └────┬─────┘ └──────┬───────┘
               │                │              │
               ↓                │              ↓
        ┌──────────────┐       │       ┌──────────────┐
        │ Board Detail │       │       │ Profile      │
        │ (Subboards)  │       │       │ Editor       │
        └──────┬───────┘       │       └──────────────┘
               │                │
               ↓                │
        ┌──────────────┐       │
        │ Communication │       │
        │ (Speak Mode)  │       │
        └──────┬───────┘       │
               │                │
               ↓                │
        ┌──────────────┐       │
        │  Build Mode  │       │
        │  (Editor)    │       │
        └──────┬───────┘       │
               │                │
               ↓                │
        ┌──────────────┐       │
        │   Me Mode    │       │
        │  (Personal)  │       │
        └──────────────┘       │
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ↓               ↓               ↓
        ┌──────────────┐ ┌──────────┐ ┌──────────────┐
        │   Settings   │ │Cloud Sync│ │    Help     │
        └──────────────┘ └──────────┘ └──────────────┘
```

### Route Definitions

```dart
// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/boards/boards_page.dart';
import '../presentation/pages/boards/board_detail_page.dart';
import '../presentation/pages/communication/communication_page.dart';
import '../presentation/pages/build_mode/build_mode_page.dart';
import '../presentation/pages/me_mode/me_mode_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/profiles/profiles_page.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/cloud_sync/cloud_sync_page.dart';
import '../presentation/pages/cloud_sync/sync_status_page.dart';
import '../presentation/pages/help/help_page.dart';

/// GoRouter Configuration
final router = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => ErrorPage(error: state.error),
  routes: [
    // Splash Screen
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    
    // Onboarding
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        final step = int.tryParse(state.uri.queryParameters['step'] ?? '0') ?? 0;
        return OnboardingPage(currentStep: step);
      },
    ),
    
    // Home Screen (Main Hub)
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    
    // Boards
    GoRoute(
      path: '/boards',
      name: 'boards',
      builder: (context, state) => const BoardsPage(),
    ),
    
    // Board Detail (with subboards)
    GoRoute(
      path: '/boards/:id',
      name: 'board-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailPage(boardId: id);
      },
    ),
    
    // Communication Mode
    GoRoute(
      path: '/communication',
      name: 'communication',
      builder: (context, state) {
        final boardId = state.uri.queryParameters['boardId'];
        return CommunicationPage(initialBoardId: boardId);
      },
    ),
    
    // Build Mode (Editor)
    GoRoute(
      path: '/build-mode',
      name: 'build-mode',
      builder: (context, state) {
        final boardId = state.uri.queryParameters['boardId'];
        return BuildModePage(boardId: boardId);
      },
    ),
    
    // Me Mode
    GoRoute(
      path: '/me-mode',
      name: 'me-mode',
      builder: (context, state) => const MeModePage(),
    ),
    
    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'voice',
          name: 'voice-settings',
          builder: (context, state) => const VoiceSettingsPage(),
        ),
        GoRoute(
          path: 'display',
          name: 'display-settings',
          builder: (context, state) => const DisplaySettingsPage(),
        ),
        GoRoute(
          path: 'sync',
          name: 'sync-settings',
          builder: (context, state) => const SyncSettingsPage(),
        ),
      ],
    ),
    
    // Profiles
    GoRoute(
      path: '/profiles',
      name: 'profiles',
      builder: (context, state) => const ProfilesPage(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'profile-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProfileEditorPage(profileId: id);
          },
        ),
        GoRoute(
          path: 'new',
          name: 'profile-new',
          builder: (context, state) => const ProfileEditorPage(),
        ),
      ],
    ),
    
    // Search
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'];
        return SearchPage(initialQuery: query);
      },
    ),
    
    // Cloud Sync
    GoRoute(
      path: '/cloud-sync',
      name: 'cloud-sync',
      builder: (context, state) => const CloudSyncPage(),
    ),
    
    // Sync Status
    GoRoute(
      path: '/sync-status',
      name: 'sync-status',
      builder: (context, state) => const SyncStatusPage(),
    ),
    
    // Help
    GoRoute(
      path: '/help',
      name: 'help',
      builder: (context, state) => const HelpPage(),
    ),
  ],
);

/// Error Page
class ErrorPage extends StatelessWidget {
  final Object? error;
  
  const ErrorPage({this.error, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation Extensions
extension NavigationExtensions on BuildContext {
  void goToSplash() => go('/splash');
  void goToOnboarding({int step = 0}) => go('/onboarding?step=$step');
  void goToHome() => go('/');
  void goToBoards() => go('/boards');
  void goToBoard(String id) => go('/boards/$id');
  void goToCommunication({String? boardId}) {
    if (boardId != null) {
      go('/communication?boardId=$boardId');
    } else {
      go('/communication');
    }
  }
  void goToBuildMode({String? boardId}) {
    if (boardId != null) {
      go('/build-mode?boardId=$boardId');
    } else {
      go('/build-mode');
    }
  }
  void goToMeMode() => go('/me-mode');
  void goToSettings() => go('/settings');
  void goToVoiceSettings() => go('/settings/voice');
  void goToDisplaySettings() => go('/settings/display');
  void goToSyncSettings() => go('/settings/sync');
  void goToProfiles() => go('/profiles');
  void goToProfile(String id) => go('/profiles/$id');
  void goToNewProfile() => go('/profiles/new');
  void goToSearch({String? query}) {
    if (query != null) {
      go('/search?q=$query');
    } else {
      go('/search');
    }
  }
  void goToCloudSync() => go('/cloud-sync');
  void goToSyncStatus() => go('/sync-status');
  void goToHelp() => go('/help');
}
```

### Splash Screen Implementation

```dart
// lib/presentation/pages/splash/splash_page.dart
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize dependencies
    await ref.read(diConfigProvider.notifier).initialize();
    
    // Check onboarding status
    final onboardingCompleted = await ref.read(onboardingProvider.notifier).isCompleted();
    
    if (!mounted) return;
    
    if (onboardingCompleted) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset('assets/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading Charlie Chat...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Onboarding Page Implementation

```dart
// lib/presentation/pages/onboarding/onboarding_page.dart
class OnboardingPage extends ConsumerStatefulWidget {
  final int currentStep;
  
  const OnboardingPage({super.key, this.currentStep = 0});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.currentStep;
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[300],
            ),
            
            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: const [
                  OnboardingStep1(),
                  OnboardingStep2(),
                  OnboardingStep3(),
                ],
              ),
            ),
            
            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextStep,
                      child: Text(_currentStep == 2 ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Home Page Implementation

```dart
// lib/presentation/pages/home/home_page.dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final isOnline = ref.watch(connectivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Charlie Chat - ${activeProfile.value?.name ?? 'Loading...'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.goToSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () => context.goToCloudSync(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goToSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner
          if (!isOnline.value) const OfflineBanner(),
          
          // Main Content
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildNavigationCard(
                  context,
                  icon: Icons.grid_view,
                  title: 'Boards',
                  onTap: () => context.goToBoards(),
                ),
                _buildNavigationCard(
                  context,
                  icon: Icons.record_voice_over,
                  title: 'Communication',
                  onTap: () => context.goToCommunication(),
                ),
                _buildNavigationCard(
                  context,
                  icon: Icons.build,
                  title: 'Build Mode',
                  onTap: () => context.goToBuildMode(),
                ),
                _buildNavigationCard(
                  context,
                  icon: Icons.person,
                  title: 'Me Mode',
                  onTap: () => context.goToMeMode(),
                ),
                _buildNavigationCard(
                  context,
                  icon: Icons.people,
                  title: 'Profiles',
                  onTap: () => context.goToProfiles(),
                ),
                _buildNavigationCard(
                  context,
                  icon: Icons.help,
                  title: 'Help',
                  onTap: () => context.goToHelp(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Boards Page Implementation

```dart
// lib/presentation/pages/boards/boards_page.dart
class BoardsPage extends ConsumerWidget {
  const BoardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.goToBuildMode(),
          ),
        ],
      ),
      body: boardsAsync.when(
        data: (boards) => GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
          ),
          padding: const EdgeInsets.all(16),
          itemCount: boards.length,
          itemBuilder: (context, index) {
            final board = boards[index];
            return BoardCard(
              board: board,
              onTap: () => context.goToBoard(board.id),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

### Board Detail Page Implementation

```dart
// lib/presentation/pages/boards/board_detail_page.dart
class BoardDetailPage extends ConsumerWidget {
  final String boardId;
  
  const BoardDetailPage({super.key, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(boardProvider(boardId));

    return Scaffold(
      appBar: AppBar(
        title: boardAsync.when(
          data: (board) => Text(board?.name ?? 'Board'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.goToBuildMode(boardId: boardId),
          ),
        ],
      ),
      body: boardAsync.when(
        data: (board) {
          if (board == null) {
            return const Center(child: Text('Board not found'));
          }
          
          return Column(
            children: [
              // Symbol Grid
              Expanded(
                child: SymbolGrid(
                  tiles: board.tiles,
                  columns: board.columns,
                  onTileTap: (tile) => _handleTileTap(context, ref, tile),
                ),
              ),
              
              // Navigation for subboards
              if (board.isSubBoard)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }

  void _handleTileTap(BuildContext context, WidgetRef ref, SymbolTile tile) {
    if (tile.isBoardLink && tile.linkedBoardId != null) {
      // Navigate to subboard
      context.goToBoard(tile.linkedBoardId!);
    } else {
      // Speak the symbol
      ref.read(ttsProvider.notifier).speak(tile.label);
    }
  }
}
```

### Communication Page Implementation

```dart
// lib/presentation/pages/communication/communication_page.dart
class CommunicationPage extends ConsumerStatefulWidget {
  final String? initialBoardId;
  
  const CommunicationPage({super.key, this.initialBoardId});

  @override
  ConsumerState<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends ConsumerState<CommunicationPage> {
  final List<String> _sentence = [];
  String? _currentBoardId;

  @override
  void initState() {
    super.initState();
    _currentBoardId = widget.initialBoardId;
  }

  void _addToSentence(String text) {
    setState(() {
      _sentence.add(text);
    });
  }

  void _speakSentence() {
    final sentence = _sentence.join(' ');
    ref.read(ttsProvider.notifier).speak(sentence);
  }

  void _clearSentence() {
    setState(() {
      _sentence.clear();
    });
  }

  void _removeLast() {
    if (_sentence.isNotEmpty) {
      setState(() {
        _sentence.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goToSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sentence Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                // Sentence Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sentence.join(' '),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                // Sentence Controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.backspace),
                      onPressed: _removeLast,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSentence,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _speakSentence,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Speak'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Board Content
          Expanded(
            child: _currentBoardId != null
                ? BoardDetailPage(boardId: _currentBoardId!)
                : const Center(child: Text('Select a board to start')),
          ),
        ],
      ),
    );
  }
}
```

### Build Mode Page Implementation

```dart
// lib/presentation/pages/build_mode/build_mode_page.dart
class BuildModePage extends ConsumerStatefulWidget {
  final String? boardId;
  
  const BuildModePage({super.key, this.boardId});

  @override
  ConsumerState<BuildModePage> createState() => _BuildModePageState();
}

class _BuildModePageState extends ConsumerState<BuildModePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(boardId != null ? 'Edit Board' : 'New Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveBoard(context),
          ),
        ],
      ),
      body: const BoardEditor(),
    );
  }

  Future<void> _saveBoard(BuildContext context) async {
    // Save board logic
    context.pop();
  }
}
```

### Me Mode Page Implementation

```dart
// lib/presentation/pages/me_mode/me_mode_page.dart
class MeModePage extends ConsumerWidget {
  const MeModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Mode'),
      ),
      body: activeProfile.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile selected'));
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundImage: profile.profileImage.isNotEmpty
                    ? NetworkImage(profile.profileImage)
                    : null,
                child: profile.profileImage.isEmpty
                    ? Text(profile.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(height: 24),
              
              // Profile Name
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Profile Settings
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => context.goToSettings(),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Phrase History'),
                onTap: () => _showPhraseHistory(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Favorites'),
                onTap: () => _showFavorites(context),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }

  void _showPhraseHistory(BuildContext context) {
    // Show phrase history
  }

  void _showFavorites(BuildContext context) {
    // Show favorites
  }
}
```

### Settings Page Implementation

```dart
// lib/presentation/pages/settings/settings_page.dart
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settings.when(
        data: (settings) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Voice Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goToVoiceSettings(),
            ),
            ListTile(
              leading: const Icon(Icons.display_settings),
              title: const Text('Display Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goToDisplaySettings(),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Sync Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.goToSyncSettings(),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

### Profiles Page Implementation

```dart
// lib/presentation/pages/profiles/profiles_page.dart
class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: profilesAsync.when(
        data: (profiles) => ListView.builder(
          itemCount: profiles.length + 1,
          itemBuilder: (context, index) {
            if (index == profiles.length) {
              // Add new profile
              return ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add New Profile'),
                onTap: () => context.goToNewProfile(),
              );
            }
            
            final profile = profiles[index];
            final isActive = profile.id == activeProfileId;
            
            return ListTile(
              leading: CircleAvatar(
                child: Text(profile.name[0].toUpperCase()),
              ),
              title: Text(profile.name),
              trailing: isActive ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(profileProvider.notifier).setActiveProfile(profile.id);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

### Search Page Implementation

```dart
// lib/presentation/pages/search/search_page.dart
class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  
  const SearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late TextEditingController _controller;
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery != null) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    
    final results = await ref.read(searchServiceProvider).search(query);
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search symbols and boards...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              setState(() => _results = []);
            },
          ),
        ],
      ),
      body: _results.isEmpty
          ? const Center(child: Text('Search for symbols and boards'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return SearchResultTile(
                  result: result,
                  onTap: () => _handleResultTap(result),
                );
              },
            ),
    );
  }

  void _handleResultTap(SearchResult result) {
    if (result.type == SearchResultType.board) {
      context.goToBoard(result.id);
    } else {
      context.goToBoard(result.boardId);
    }
  }
}
```

### Cloud Sync Page Implementation

```dart
// lib/presentation/pages/cloud_sync/cloud_sync_page.dart
class CloudSyncPage extends ConsumerWidget {
  const CloudSyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(cloudSyncProvider.notifier).syncAll(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sync Status
          Card(
            child: ListTile(
              leading: Icon(
                syncState.isSyncing ? Icons.sync : Icons.cloud_done,
                color: syncState.isSyncing ? Colors.blue : Colors.green,
              ),
              title: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Complete'),
              subtitle: syncState.message != null ? Text(syncState.message!) : null,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Upload Section
          _buildUploadSection(context, ref),
          
          const SizedBox(height: 16),
          
          // Download Section
          _buildDownloadSection(context))),
    );
  }

  Widget _buildUploadSection(BuildContext context, WidgetRef ref) {
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
            FilledButton.icon(
              onPressed: () => ref.read(cloudSyncProvider.notifier).uploadAllBoards(),
              icon: const Icon(Icons.upload_all),
              label: const Text('Upload All Boards'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(BuildContext context, WidgetRef ref) {
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
            FilledButton.icon(
              onPressed: () => ref.read(cloudSyncProvider.notifier).downloadAllBoards(),
              icon: const Icon(Icons.download_all),
              label: const Text('Download All Boards'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Help Page Implementation

```dart
// lib/presentation/pages/help/help_page.dart
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpSection(
            context,
            title: 'Getting Started',
            icon: Icons.play_arrow,
            content: 'Learn how to use Charlie Chat for the first time.',
          ),
          _buildHelpSection(
            context,
            title: 'Creating Boards',
            icon: Icons.dashboard,
            content: 'Create and customize your own communication boards.',
          ),
          _buildHelpSection(
            context,
            title: 'Using Symbols',
            icon: Icons.grid_view,
            content: 'Add and organize symbols on your boards.',
          ),
          _buildHelpSection(
            context,
            title: 'Communication',
            icon: Icons.record_voice_over,
            content: 'Use symbols to communicate with others.',
          ),
          _buildHelpSection(
            context,
            title: 'Cloud Sync',
            icon: Icons.cloud_sync,
            content: 'Sync your boards across devices.',
          ),
          _buildHelpSection(
            context,
            title: 'Settings',
            icon: Icons.settings,
            content: 'Customize voice, display, and sync settings.',
          ),
          _buildHelpSection(
            context,
            title: 'Contact Support',
            icon: Icons.support_agent,
            content: 'Get help from our support team.',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(content),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to detailed help
        },
      ),
    );
  }
}
```

---

## 7. Summary

This navigation architecture provides:

1. **Complete Tech Stack** - Flutter, Riverpod, go_router, Drift, Node.js, PostgreSQL
2. **Project Structure** - Organized folder structure with clear separation of concerns
3. **Database Schema** - Comprehensive Drift database with all required tables
4. **API Specification** - REST API endpoints for all features
5. **Sync Strategy** - Offline-first with queue-based sync and conflict resolution
6. **Navigation Map** - Complete navigation graph with all screens and routes
7. **Implementation** - Full Flutter/go_router implementation for all screens

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [UNIVERSAL_DATABASE.md](UNIVERSAL_DATABASE.md)
- [BACKEND_COMPATIBILITY.md](BACKEND_COMPATIBILITY.md)
- [OFFLINE_FIRST_ARCHITECTURE.md](OFFLINE_FIRST_ARCHITECTURE.md)
- [API_VERSIONING.md](API_VERSIONING.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
