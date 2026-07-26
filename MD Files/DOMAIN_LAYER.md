# Domain Layer Documentation

## Overview

The Domain Layer is the core of the application, containing business logic and enterprise rules. It has no dependencies on external frameworks, UI, or data storage - making it completely testable and independent.

---

## Structure

```
domain/
├── entities/              # Core business objects
│   ├── board.dart
│   ├── symbol_tile.dart
│   ├── user_profile.dart
│   └── app_settings.dart
├── usecases/              # Application-specific business rules
│   ├── board/
│   │   ├── get_boards_usecase.dart
│   │   ├── get_board_usecase.dart
│   │   ├── save_board_usecase.dart
│   │   ├── delete_board_usecase.dart
│   │   └── export_board_usecase.dart
│   ├── profile/
│   │   ├── get_profiles_usecase.dart
│   │   ├── create_profile_usecase.dart
│   │   ├── update_profile_usecase.dart
│   │   └── delete_profile_usecase.dart
│   ├── tts/
│   │   ├── speak_text_usecase.dart
│   │   ├── set_voice_usecase.dart
│   │   └── get_voices_usecase.dart
│   └── sync/
│       ├── sync_data_usecase.dart
│       └── resolve_conflict_usecase.dart
├── repositories/          # Repository interfaces (abstractions)
│   ├── board_repository_interface.dart
│   ├── profile_repository_interface.dart
│   ├── settings_repository_interface.dart
│   ├── sync_repository_interface.dart
│   └── tts_repository_interface.dart
└── value_objects/         # Immutable objects with no identity
    ├── voice_option.dart
    ├── board_color.dart
    └── tile_size.dart
```

---

## Entities

Entities represent core business objects with identity. They are pure Dart classes with no external dependencies.

### Board Entity

```dart
class Board {
  final String id;
  final String name;
  final int rows;
  final int columns;
  final List<SymbolTile> tiles;
  final String backgroundColor;
  final bool isSubBoard;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Board({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.tiles,
    this.backgroundColor = 'transparent',
    this.isSubBoard = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Board copyWith({
    String? id,
    String? name,
    int? rows,
    int? columns,
    List<SymbolTile>? tiles,
    String? backgroundColor,
    bool? isSubBoard,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      tiles: tiles ?? this.tiles,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isSubBoard: isSubBoard ?? this.isSubBoard,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  bool get isEmpty => tiles.isEmpty;
  int get tileCount => tiles.length;
}
```

### SymbolTile Entity

```dart
class SymbolTile {
  final String id;
  final String label;
  final String category;
  final String imageAsset;
  final String emoji;
  final String linkedBoardId;
  final bool isBoardLink;
  final double tileSize;
  final String bgColor;
  final String textColor;
  final String customVoice;
  
  const SymbolTile({
    required this.id,
    required this.label,
    required this.category,
    required this.imageAsset,
    this.emoji = '',
    this.linkedBoardId = '',
    this.isBoardLink = false,
    this.tileSize = 1.0,
    this.bgColor = 'transparent',
    this.textColor = '#000000',
    this.customVoice = '',
  });
  
  bool get speaks => !isBoardLink;
  String get speechText => speaks ? label : '';
  
  SymbolTile copyWith({
    String? id,
    String? label,
    String? category,
    String? imageAsset,
    String? emoji,
    String? linkedBoardId,
    bool? isBoardLink,
    double? tileSize,
    String? bgColor,
    String? textColor,
    String? customVoice,
  }) {
    return SymbolTile(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      emoji: emoji ?? this.emoji,
      linkedBoardId: linkedBoardId ?? this.linkedBoardId,
      isBoardLink: isBoardLink ?? this.isBoardLink,
      tileSize: tileSize ?? this.tileSize,
      bgColor: bgColor ?? this.bgColor,
      textColor: textColor ?? this.textColor,
      customVoice: customVoice ?? this.customVoice,
    );
  }
}
```

### UserProfile Entity

```dart
class UserProfile {
  final String id;
  final String name;
  final AppSettings settings;
  final List<String> tabOrder;
  final List<String> preferredSymbolSets;
  final String startingBoardId;
  final String? username;
  final String? password;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  
  const UserProfile({
    required this.id,
    required this.name,
    required this.settings,
    this.tabOrder = const [],
    this.preferredSymbolSets = const [],
    this.startingBoardId = '',
    this.username,
    this.password,
    this.isAdmin = false,
    required this.createdAt,
    required this.lastUsedAt,
  });
  
  UserProfile copyWith({
    String? id,
    String? name,
    AppSettings? settings,
    List<String>? tabOrder,
    List<String>? preferredSymbolSets,
    String? startingBoardId,
    String? username,
    String? password,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      settings: settings ?? this.settings,
      tabOrder: tabOrder ?? this.tabOrder,
      preferredSymbolSets: preferredSymbolSets ?? this.preferredSymbolSets,
      startingBoardId: startingBoardId ?? this.startingBoardId,
      username: username ?? this.username,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
```

### AppSettings Entity

```dart
class AppSettings {
  final ThemeMode themeMode;
  final double voiceRate;
  final double voicePitch;
  final double voiceVolume;
  final String voiceLanguage;
  final String voiceName;
  final String sentenceSize;
  final String sentenceType;
  final bool readSentenceOnly;
  final String profileImage;
  final String fontSize;
  final bool highContrast;
  final String projectRoot;
  
  const AppSettings({
    required this.themeMode,
    required this.voiceRate,
    required this.voicePitch,
    required this.voiceVolume,
    this.voiceLanguage = 'en-GB',
    this.voiceName = 'Google UK English Female',
    this.sentenceSize = 'medium',
    this.sentenceType = 'both',
    this.readSentenceOnly = false,
    this.profileImage = '',
    this.fontSize = 'medium',
    this.highContrast = false,
    this.projectRoot = '',
  });
  
  AppSettings copyWith({
    ThemeMode? themeMode,
    double? voiceRate,
    double? voicePitch,
    double? voiceVolume,
    String? voiceLanguage,
    String? voiceName,
    String? sentenceSize,
    String? sentenceType,
    bool? readSentenceOnly,
    String? profileImage,
    String? fontSize,
    bool? highContrast,
    String? projectRoot,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      voiceRate: voiceRate ?? this.voiceRate,
      voicePitch: voicePitch ?? this.voicePitch,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceName: voiceName ?? this.voiceName,
      sentenceSize: sentenceSize ?? this.sentenceSize,
      sentenceType: sentenceType ?? this.sentenceType,
      readSentenceOnly: readSentenceOnly ?? this.readSentenceOnly,
      profileImage: profileImage ?? this.profileImage,
      fontSize: fontSize ?? this.fontSize,
      highContrast: highContrast ?? this.highContrast,
      projectRoot: projectRoot ?? this.projectRoot,
    );
  }
}
```

---

## Use Cases

Use cases encapsulate application-specific business rules. Each use case represents a single action the application can perform.

### Board Use Cases

#### GetBoardsUseCase

```dart
class GetBoardsUseCase {
  final BoardRepository _repository;
  
  GetBoardsUseCase(this._repository);
  
  Future<Either<Failure, List<Board>>> call() async {
    try {
      final boards = await _repository.getBoards();
      return Right(boards);
    } on ServerException {
      return Left(ServerFailure());
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
```

#### GetBoardUseCase

```dart
class GetBoardUseCase {
  final BoardRepository _repository;
  
  GetBoardUseCase(this._repository);
  
  Future<Either<Failure, Board>> call(String id) async {
    try {
      final board = await _repository.getBoard(id);
      if (board == null) {
        return Left(NotFoundFailure());
      }
      return Right(board);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### SaveBoardUseCase

```dart
class SaveBoardUseCase {
  final BoardRepository _repository;
  
  SaveBoardUseCase(this._repository);
  
  Future<Either<Failure, void>> call(Board board) async {
    try {
      await _repository.saveBoard(board);
      return const Right(null);
    } on ValidationException {
      return Left(ValidationFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### DeleteBoardUseCase

```dart
class DeleteBoardUseCase {
  final BoardRepository _repository;
  
  DeleteBoardUseCase(this._repository);
  
  Future<Either<Failure, void>> call(String id) async {
    try {
      await _repository.deleteBoard(id);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

### Profile Use Cases

#### GetProfilesUseCase

```dart
class GetProfilesUseCase {
  final ProfileRepository _repository;
  
  GetProfilesUseCase(this._repository);
  
  Future<Either<Failure, List<UserProfile>>> call() async {
    try {
      final profiles = await _repository.getProfiles();
      return Right(profiles);
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
```

#### CreateProfileUseCase

```dart
class CreateProfileUseCase {
  final ProfileRepository _repository;
  
  CreateProfileUseCase(this._repository);
  
  Future<Either<Failure, UserProfile>> call(String name) async {
    try {
      final profile = await _repository.createProfile(name);
      return Right(profile);
    } on ValidationException {
      return Left(ValidationFailure());
    }
  }
}
```

### TTS Use Cases

#### SpeakTextUseCase

```dart
class SpeakTextUseCase {
  final TTSRepository _repository;
  
  SpeakTextUseCase(this._repository);
  
  Future<Either<Failure, void>> call(String text) async {
    if (text.trim().isEmpty) {
      return Left(ValidationFailure());
    }
    
    try {
      await _repository.speak(text);
      return const Right(null);
    } on TTSServiceException {
      return Left(TTSFailure());
    }
  }
}
```

#### SetVoiceUseCase

```dart
class SetVoiceUseCase {
  final TTSRepository _repository;
  
  SetVoiceUseCase(this._repository);
  
  Future<Either<Failure, void>> call(String voiceName, String locale) async {
    try {
      await _repository.setVoice(voiceName, locale: locale);
      return const Right(null);
    } on TTSServiceException {
      return Left(TTSFailure());
    }
  }
}
```

### Sync Use Cases

#### SyncDataUseCase

```dart
class SyncDataUseCase {
  final SyncRepository _repository;
  
  SyncDataUseCase(this._repository);
  
  Future<Either<Failure, SyncResult>> call() async {
    try {
      final result = await _repository.sync();
      return Right(result);
    } on NetworkException {
      return Left(NetworkFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

---

## Repository Interfaces

Repository interfaces define the contract for data access without specifying implementation details.

### BoardRepository Interface

```dart
abstract class BoardRepository {
  Future<List<Board>> getBoards();
  Future<Board?> getBoard(String id);
  Future<void> saveBoard(Board board);
  Future<void> deleteBoard(String id);
  Future<List<Board>> searchBoards(String query);
  Future<void> exportBoard(String id, String path);
  Future<Board> importBoard(String path);
}
```

### ProfileRepository Interface

```dart
abstract class ProfileRepository {
  Future<List<UserProfile>> getProfiles();
  Future<UserProfile?> getProfile(String id);
  Future<UserProfile> createProfile(String name);
  Future<void> updateProfile(UserProfile profile);
  Future<void> deleteProfile(String id);
  Future<void> setActiveProfile(String id);
  Future<UserProfile> getActiveProfile();
}
```

### SettingsRepository Interface

```dart
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> resetSettings();
}
```

### SyncRepository Interface

```dart
abstract class SyncRepository {
  Future<SyncResult> sync();
  Future<void> enableSync(String username, String password);
  Future<void> disableSync();
  Future<SyncStatus> getSyncStatus();
  Future<List<SyncConflict>> getConflicts();
  Future<void> resolveConflict(String conflictId, ConflictResolution resolution);
}
```

### TTSRepository Interface

```dart
abstract class TTSRepository {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setVoice(String voiceName, {String locale});
  Future<void> setLanguage(String language);
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setVolume(double volume);
  Future<List<VoiceOption>> getVoices();
  Future<List<String>> getLanguages();
}
```

---

## Value Objects

Value objects are immutable objects defined by their attributes rather than identity.

### VoiceOption

```dart
class VoiceOption {
  final String name;
  final String locale;
  final String gender;
  
  const VoiceOption({
    required this.name,
    required this.locale,
    this.gender = 'unknown',
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceOption &&
        other.name == name &&
        other.locale == locale;
  }
  
  @override
  int get hashCode => name.hashCode ^ locale.hashCode;
}
```

### BoardColor

```dart
class BoardColor {
  final String hex;
  final String name;
  
  const BoardColor({
    required this.hex,
    required this.name,
  });
  
  static const transparent = BoardColor(hex: 'transparent', name: 'Transparent');
  static const lightGreen = BoardColor(hex: '#90EE90', name: 'Light Green');
  static const darkBlue = BoardColor(hex: '#1E3A8A', name: 'Dark Blue');
}
```

---

## Failures

Define common failure types for error handling.

```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error occurred']) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) : super(message);
}

class TTSFailure extends Failure {
  const TTSFailure([String message = 'TTS error occurred']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}
```

---

## Either Pattern

Use the Either pattern for error handling instead of exceptions.

```dart
class Either<L, R> {
  final L? _left;
  final R? _right;
  
  Either.left(L value) : _left = value, _right = null;
  Either.right(R value) : _left = null, _left = value;
  
  bool isLeft() => _left != null;
  bool isRight() => _right != null;
  
  L? get left => _left;
  R? get right => _right;
  
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) {
    if (isLeft()) return ifLeft(_left!);
    return ifRight(_right!);
  }
}
```

---

## Testing Domain Layer

Domain layer tests are pure unit tests with no dependencies.

```dart
test('GetBoardsUseCase returns boards from repository', () async {
  // Arrange
  final mockRepository = MockBoardRepository();
  final useCase = GetBoardsUseCase(mockRepository);
  
  final testBoards = [
    Board(id: '1', name: 'Test', rows: 6, columns: 5, tiles: [], 
          createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
  
  when(mockRepository.getBoards()).thenAnswer((_) async => testBoards);
  
  // Act
  final result = await useCase();
  
  // Assert
  expect(result.isRight(), true);
  expect(result.right, testBoards);
  verify(mockRepository.getBoards()).called(1);
});

test('SaveBoardUseCase validates board before saving', () async {
  // Arrange
  final mockRepository = MockBoardRepository();
  final useCase = SaveBoardUseCase(mockRepository);
  
  final invalidBoard = Board(
    id: '', name: '', rows: 0, columns: 0, tiles: [],
    createdAt: DateTime.now(), updatedAt: DateTime.now(),
  );
  
  when(mockRepository.saveBoard(any)).thenThrow(ValidationException());
  
  // Act
  final result = await useCase(invalidBoard);
  
  // Assert
  expect(result.isLeft(), true);
  expect(result.left, isA<ValidationFailure>());
});
```

---

## Best Practices

### 1. Keep Entities Pure

❌ **Bad:**
```dart
class Board {
  void saveToDatabase() {
    // Database logic in entity!
  }
}
```

✅ **Good:**
```dart
class Board {
  // Pure data, no methods that access external systems
}
```

### 2. Use Value Objects for Concepts

❌ **Bad:**
```dart
class Board {
  String color; // Just a string
}
```

✅ **Good:**
```dart
class Board {
  BoardColor color; // Type-safe value object
}
```

### 3. Use Cases Should Be Single Purpose

❌ **Bad:**
```dart
class BoardUseCase {
  Future<void> execute() {
    // Does multiple things
    saveBoard();
    syncBoard();
    sendNotification();
  }
}
```

✅ **Good:**
```dart
class SaveBoardUseCase {
  Future<void> call(Board board) => _repository.saveBoard(board);
}

class SyncBoardUseCase {
  Future<void> call(Board board) => _repository.syncBoard(board);
}
```

### 4. Repository Interfaces Should Be Abstract

❌ **Bad:**
```dart
class BoardRepository {
  Future<List<Board>> getBoards() {
    return File('boards.json').readAsString(); // Concrete implementation
  }
}
```

✅ **Good:**
```dart
abstract class BoardRepository {
  Future<List<Board>> getBoards();
}
```

---

## Summary

The Domain Layer provides:

1. **Pure business logic** - No external dependencies
2. **Testable code** - Easy to unit test
3. **Clear contracts** - Repository interfaces define data access
4. **Single responsibility** - Each use case does one thing
5. **Type safety** - Value objects for domain concepts

This layer is the heart of the application and should remain stable as UI and data storage technologies change.

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
