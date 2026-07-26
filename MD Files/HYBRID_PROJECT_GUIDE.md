# Charlie Chat Hybrid Project Guide

## Overview

Charlie Chat is a hybrid AAC (Augmentative and Alternative Communication) application that combines:
- **Flutter Frontend**: Cross-platform UI from AppCreation project
- **SymbolTalk Backend**: Kotlin/Ktor API server for cloud sync and advanced features

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                       │
│  (AppCreation UI - Working, Offline-First)              │
│  - Symbol Grid & Boards                                  │
│  - Phrase Builder                                        │
│  - Text-to-Speech                                        │
│  - Local Storage (SharedPreferences/Files)               │
│  - Multi-Profile Support                                 │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Optional API Integration
                            │
┌─────────────────────────────────────────────────────────┐
│              SymbolTalk Backend API                       │
│  (Kotlin/Ktor/PostgreSQL)                                │
│  - Authentication (JWT)                                   │
│  - Cloud Sync                                            │
│  - Board Sharing                                         │
│  - Multi-language Symbol Library                         │
│  - Analytics                                             │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
C:\Users\Craig\Downloads\Charlie Chat\
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── web/                  # Web platform files
├── windows/              # Windows platform files
├── lib/                  # Flutter source code
│   ├── data/            # Data models
│   ├── models/          # UI models
│   ├── services/        # Business logic
│   │   ├── symboltalk_api_service.dart  # SymbolTalk API client
│   │   ├── profile_service.dart         # Local profile management
│   │   ├── board_service.dart           # Local board storage
│   │   ├── sync_service.dart            # Local sync tracking
│   │   └── ...                          # Other services
│   └── widgets/         # UI components
├── assets/              # Symbol assets
├── pubspec.yaml         # Flutter dependencies
├── README.md            # Project overview
├── CONFLICTS_ANALYSIS.md # Detailed conflict analysis
└── HYBRID_PROJECT_GUIDE.md # This file
```

## Key Design Decisions

### 1. Offline-First Approach
- **Decision**: Keep AppCreation's local storage as primary
- **Reason**: Works without network, faster, simpler
- **SymbolTalk Integration**: Optional cloud sync when online

### 2. Multi-Profile Support
- **Decision**: Keep AppCreation's multi-profile system
- **Reason**: Multiple users on same device, no authentication required
- **SymbolTalk Integration**: Optional cloud backup per profile

### 3. Simple Board Structure
- **Decision**: Keep AppCreation's embedded symbol tiles in boards
- **Reason**: Simpler, works offline, easier to manage
- **SymbolTalk Integration**: Use SymbolTalk API for external symbol library search

### 4. Local Authentication
- **Decision**: Keep AppCreation's simple username/password
- **Reason**: No server dependency, works offline
- **SymbolTalk Integration**: Optional JWT authentication for cloud features

## Getting Started

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **SymbolTalk Backend** (optional, for cloud features)
   - Kotlin/JDK 17
   - PostgreSQL
   - See SymbolTalk backend documentation

### Running the App

#### Local Mode (No Backend)
```bash
cd C:\Users\Craig\Downloads\Charlie Chat
flutter pub get
flutter run
```

#### Web Mode
```bash
flutter run -d chrome
```

#### With SymbolTalk Backend
1. Start SymbolTalk backend (default: http://localhost:8080)
2. Enable cloud sync in app settings
3. Use SymbolTalk API features (sharing, multi-language, etc.)

## SymbolTalk API Integration

### API Client Service

The `SymbolTalkApiService` class provides access to SymbolTalk backend:

```dart
import 'package:charliechat/services/symboltalk_api_service.dart';

// Initialize API service
final apiService = SymbolTalkApiService(baseUrl: 'http://localhost:8080');

// Authenticate
await apiService.login(email: 'user@example.com', password: 'password');

// Use API features
final boards = await apiService.getBoards();
final symbols = await apiService.searchSymbols(query: 'hello');
```

### Available API Features

#### Authentication
- `register()` - Create new account
- `login()` - Login with email/password
- `logout()` - Logout
- `refreshToken()` - Refresh access token
- `getCurrentUser()` - Get current user info

#### Profiles
- `getProfile()` - Get user profile
- `updateProfile()` - Update profile
- `getSettings()` - Get settings
- `updateSettings()` - Update settings

#### Boards
- `getBoards()` - Get user's boards
- `createBoard()` - Create new board
- `getBoard()` - Get specific board
- `updateBoard()` - Update board
- `deleteBoard()` - Delete board
- `duplicateBoard()` - Duplicate board

#### Symbols
- `searchSymbols()` - Search symbol library
- `getSymbolsByCategory()` - Get symbols by category

#### Sentences & Favorites
- `getSentences()` - Get user's sentences
- `createSentence()` - Create sentence
- `getFavorites()` - Get favorites

#### Sync
- `getSyncStatus()` - Get sync status
- `pullChanges()` - Pull changes from server
- `pushChanges()` - Push changes to server
- `getConflicts()` - Get sync conflicts
- `resolveConflict()` - Resolve conflict

#### Sharing
- `shareBoard()` - Share board with users
- `createShareLink()` - Create shareable link
- `getSharedBoard()` - Get shared board via token

#### Languages
- `getLanguages()` - Get available languages
- `getLanguage()` - Get language by code

### Optional Integration Pattern

The SymbolTalk API is designed to be **optional**. The app works perfectly without it:

```dart
// Check if API is available
if (await apiService.healthCheck()) {
  // Use cloud features
  final cloudBoards = await apiService.getBoards();
} else {
  // Use local storage
  final localBoards = await boardService.listBoards();
}
```

## Migration from AppCreation

### What's Preserved
- All UI components and layouts
- All local storage logic
- All user-facing features
- Cross-platform support
- Offline functionality

### What's Added
- SymbolTalk API client service
- Optional cloud sync capability
- Board sharing functionality
- Multi-language symbol library access
- Analytics integration (optional)

### What's Changed
- Project renamed to "Charlie Chat"
- Package name changed to "charliechat"
- Documentation updated to reflect hybrid nature

## Development Workflow

### Adding New Features

1. **Local-First**: Implement using local storage (AppCreation pattern)
2. **Optional Cloud**: Add SymbolTalk API integration if needed
3. **Offline Support**: Ensure feature works without network

### Example: Adding a New Board

```dart
// Local storage (always works)
await boardService.saveBoard(newBoard);

// Optional cloud sync
if (apiService.isAuthenticated) {
  try {
    await apiService.createBoard(boardToApiFormat(newBoard));
  } catch (e) {
    // Cloud sync failed, but local save succeeded
    debugPrint('Cloud sync failed: $e');
  }
}
```

## Testing

### Local Storage Tests
```bash
flutter test
```

### Integration Tests (with backend)
1. Start SymbolTalk backend
2. Run integration tests with API service
3. Test cloud sync functionality

### Offline Tests
1. Disable network
2. Run app
3. Verify all features work locally

## Deployment

### Web Deployment
```bash
flutter build web --web-renderer canvaskit
```
Output: `build/web/`

### Android Deployment
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Deployment
```bash
flutter build ios --release
```
Output: Xcode archive

## Troubleshooting

### API Connection Issues
- Check SymbolTalk backend is running
- Verify base URL is correct
- Check network connectivity
- Use `apiService.healthCheck()` to test connection

### Sync Conflicts
- Use `apiService.getConflicts()` to list conflicts
- Use `apiService.resolveConflict()` to resolve
- Local changes take precedence by default

### Offline Mode
- App automatically falls back to local storage
- All features work without network
- Cloud sync resumes when connection restored

## Future Enhancements

### Phase 1: Current State
- Local storage only
- No cloud features
- Single language

### Phase 2: Optional Cloud Sync
- Add cloud sync toggle in settings
- Implement backup/restore
- Add board sharing UI

### Phase 3: Full Integration
- Multi-language support
- Advanced analytics
- Real-time collaboration
- Voice recognition integration

## Support

### Documentation Files
- `README.md` - Project overview
- `CONFLICTS_ANALYSIS.md` - Detailed conflict analysis
- `HYBRID_PROJECT_GUIDE.md` - This file
- `CROSS_PLATFORM_SUPPORT.md` - Platform-specific guide (from AppCreation)

### SymbolTalk Backend
- Located at: `C:\Users\Craig\Downloads\SymbolTalk\backend`
- API documentation: See backend controller files
- Database schema: See backend database schema files

## Summary

Charlie Chat is a hybrid AAC application that:
- **Works offline** using local storage (AppCreation pattern)
- **Optionally syncs** with SymbolTalk backend for cloud features
- **Supports multiple platforms** (Web, iOS, Android, Windows)
- **Preserves all existing functionality** from AppCreation
- **Adds optional enhancements** via SymbolTalk API

The hybrid approach ensures the app remains functional without the backend while providing advanced features when the backend is available.
