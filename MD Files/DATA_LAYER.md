# Data Layer Documentation

## Overview

The Data Layer is responsible for providing data to the Domain Layer. It implements repository interfaces defined in the Domain Layer and handles all data access logic, including local storage, remote APIs, and data transformation.

---

## Structure

```
data/
├── models/                # Data transfer objects (DTOs)
│   ├── board_model.dart
│   ├── symbol_tile_model.dart
│   ├── user_profile_model.dart
│   └── app_settings_model.dart
├── repositories/          # Repository implementations
│   ├── board_repository_impl.dart
│   ├── profile_repository_impl.dart
│   ├── settings_repository_impl.dart
│   ├── sync_repository_impl.dart
│   └── tts_repository_impl.dart
├── datasources/           # Data sources
│   ├── local/            # Local storage
│   │   ├── board_local_datasource.dart
│   │   ├── profile_local_datasource.dart
│   │   ├── settings_local_datasource.dart
│   │   └── favorites_local_datasource.dart
│   └── remote/           # Remote APIs
│       ├── symboltalk_api_datasource.dart
│       └── sync_remote_datasource.dart
├── mappers/              # Convert between models and entities
│   ├── board_mapper.dart
│   ├── symbol_tile_mapper.dart
│   ├── profile_mapper.dart
│   └── settings_mapper.dart
└── services/             # Data services (legacy, being refactored)
    ├── board_service.dart
    ├── profile_service.dart
    ├── settings_service.dart
    ├── sync_service.dart
    └── tts_service.dart
```

---

## Models

Models are data transfer objects that represent data as it's stored or received from external sources.

### BoardModel

```dart
class BoardModel {
  final String id;
  final String name;
  final int rows;
  final int columns;
  final bool adjustableLayout;
  final double boxScale;
  final double tileHeight;
  final double tileWidth;
  final String backgroundColor;
  final List<SymbolTileModel> tiles;
  final bool isSubBoard;
  
  BoardModel({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.tiles,
    this.adjustableLayout = false,
    this.boxScale = 1.0,
    this.tileHeight = 100.0,
    this.tileWidth = 100.0,
    this.backgroundColor = 'transparent',
    this.isSubBoard = false,
  });
  
  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Board',
      rows: json['rows'] ?? 6,
      columns: json['columns'] ?? 5,
      adjustableLayout: json['adjustableLayout'] ?? false,
      boxScale: (json['boxScale'] is num) ? (json['boxScale'] as num).toDouble() : 1.0,
      tileHeight: (json['tileHeight'] is num) ? (json['tileHeight'] as num).toDouble() : 100.0,
      tileWidth: (json['tileWidth'] is num) ? (json['tileWidth'] as num).toDouble() : 100.0,
      backgroundColor: json['backgroundColor'] ?? 'transparent',
      tiles: (json['tiles'] as List?)
          ?.map((t) => SymbolTileModel.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      isSubBoard: json['isSubBoard'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rows': rows,
      'columns': columns,
      'adjustableLayout': adjustableLayout,
      'boxScale': boxScale,
      'tileHeight': tileHeight,
      'tileWidth': tileWidth,
      'backgroundColor': backgroundColor,
      'tiles': tiles.map((t) => t.toJson()).toList(),
      'isSubBoard': isSubBoard,
    };
  }
}
```

### SymbolTileModel

```dart
class SymbolTileModel {
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
  
  SymbolTileModel({
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
  
  factory SymbolTileModel.fromJson(Map<String, dynamic> json) {
    return SymbolTileModel(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      category: json['category'] ?? 'Home',
      imageAsset: json['imageAsset'] ?? '',
      emoji: json['emoji'] ?? '',
      linkedBoardId: json['linkedBoardId'] ?? '',
      isBoardLink: json['isBoardLink'] ?? false,
      tileSize: (json['tileSize'] is num) ? (json['tileSize'] as num).toDouble() : 1.0,
      bgColor: json['bgColor'] ?? 'transparent',
      textColor: json['textColor'] ?? '#000000',
      customVoice: json['customVoice'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'category': category,
      'imageAsset': imageAsset,
      'emoji': emoji,
      'linkedBoardId': linkedBoardId,
      'isBoardLink': isBoardLink,
      'tileSize': tileSize,
      'bgColor': bgColor,
      'textColor': textColor,
      'customVoice': customVoice,
    };
  }
}
```

### UserProfileModel

```dart
class UserProfileModel {
  final String id;
  final String name;
  final AppSettingsModel settings;
  final List<String> tabOrder;
  final List<String> preferredSymbolSets;
  final String startingBoardId;
  final String? username;
  final String? password;
  final bool isAdmin;
  final String createdAt;
  final String lastUsedAt;
  
  UserProfileModel({
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
  
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      settings: AppSettingsModel.fromJson(json['settings'] ?? {}),
      tabOrder: List<String>.from(json['tabOrder'] ?? []),
      preferredSymbolSets: List<String>.from(json['preferredSymbolSets'] ?? []),
      startingBoardId: json['startingBoardId'] ?? '',
      username: json['username'],
      password: json['password'],
      isAdmin: json['isAdmin'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      lastUsedAt: json['lastUsedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'settings': settings.toJson(),
      'tabOrder': tabOrder,
      'preferredSymbolSets': preferredSymbolSets,
      'startingBoardId': startingBoardId,
      'username': username,
      'password': password,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'lastUsedAt': lastUsedAt,
    };
  }
}
```

### AppSettingsModel

```dart
class AppSettingsModel {
  final String themeMode;
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
  
  AppSettingsModel({
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
  
  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      themeMode: json['themeMode'] ?? 'system',
      voiceRate: (json['voiceRate'] is num) ? (json['voiceRate'] as num).toDouble() : 0.5,
      voicePitch: (json['voicePitch'] is num) ? (json['voicePitch'] as num).toDouble() : 1.0,
      voiceVolume: (json['voiceVolume'] is num) ? (json['voiceVolume'] as num).toDouble() : 1.0,
      voiceLanguage: json['voiceLanguage'] ?? 'en-GB',
      voiceName: json['voiceName'] ?? 'Google UK English Female',
      sentenceSize: json['sentenceSize'] ?? 'medium',
      sentenceType: json['sentenceType'] ?? 'both',
      readSentenceOnly: json['readSentenceOnly'] ?? false,
      profileImage: json['profileImage'] ?? '',
      fontSize: json['fontSize'] ?? 'medium',
      highContrast: json['highContrast'] ?? false,
      projectRoot: json['projectRoot'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'voiceRate': voiceRate,
      'voicePitch': voicePitch,
      'voiceVolume': voiceVolume,
      'voiceLanguage': voiceLanguage,
      'voiceName': voiceName,
      'sentenceSize': sentenceSize,
      'sentenceType': sentenceType,
      'readSentenceOnly': readSentenceOnly,
      'profileImage': profileImage,
      'fontSize': fontSize,
      'highContrast': highContrast,
      'projectRoot': projectRoot,
    };
  }
}
```

---

## Data Sources

Data sources are the actual places where data comes from - local storage, remote APIs, etc.

### Local Data Sources

#### BoardLocalDataSource

```dart
class BoardLocalDataSource {
  final SharedPreferences _prefs;
  final Directory? _dataDir;
  static const String _boardKeyPrefix = 'board_';
  
  BoardLocalDataSource(this._prefs, this._dataDir);
  
  Future<List<BoardModel>> getBoards() async {
    if (kIsWeb) {
      return _getBoardsFromPrefs();
    } else {
      return _getBoardsFromFileSystem();
    }
  }
  
  Future<List<BoardModel>> _getBoardsFromPrefs() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_boardKeyPrefix));
    final boards = <BoardModel>[];
    
    for (final key in keys) {
      try {
        final json = jsonDecode(_prefs.getString(key)!) as Map<String, dynamic>;
        boards.add(BoardModel.fromJson(json));
      } catch (e) {
        debugPrint('Error loading board from prefs: $e');
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
        debugPrint('Error loading board from file: $e');
      }
    }
    
    return boards;
  }
  
  Future<BoardModel?> getBoard(String id) async {
    final boards = await getBoards();
    try {
      return boards.firstWhere((board) => board.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveBoard(BoardModel board) async {
    final json = board.toJson();
    final jsonString = jsonEncode(json);
    
    if (kIsWeb) {
      await _prefs.setString('$_boardKeyPrefix${board.id}', jsonString);
    } else {
      final file = File('${_dataDir!.path}/${board.id}.json');
      await file.writeAsString(jsonString);
    }
  }
  
  Future<void> deleteBoard(String id) async {
    if (kIsWeb) {
      await _prefs.remove('$_boardKeyPrefix$id');
    } else {
      final file = File('${_dataDir!.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
```

#### ProfileLocalDataSource

```dart
class ProfileLocalDataSource {
  final SharedPreferences _prefs;
  static const String _profilesKey = 'user_profiles';
  static const String _activeProfileKey = 'active_profile_id';
  
  ProfileLocalDataSource(this._prefs);
  
  Future<List<UserProfileModel>> getProfiles() async {
    final profilesJson = _prefs.getString(_profilesKey);
    if (profilesJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(profilesJson);
      return decoded
          .map((json) => UserProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      return [];
    }
  }
  
  Future<UserProfileModel?> getProfile(String id) async {
    final profiles = await getProfiles();
    try {
      return profiles.firstWhere((profile) => profile.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveProfiles(List<UserProfileModel> profiles) async {
    final encoded = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_profilesKey, encoded);
  }
  
  Future<String> getActiveProfileId() async {
    return _prefs.getString(_activeProfileKey) ?? '';
  }
  
  Future<void> setActiveProfileId(String id) async {
    await _prefs.setString(_activeProfileKey, id);
  }
}
```

### Remote Data Sources

#### SymbolTalkApiDataSource

```dart
class SymbolTalkApiDataSource {
  final http.Client _client;
  final String _baseUrl;
  String? _accessToken;
  
  SymbolTalkApiDataSource(this._client, {String baseUrl = 'http://localhost:8080'})
      : _baseUrl = baseUrl;
  
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
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
  
  Future<String> authenticate(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['accessToken'] as String;
    } else {
      throw AuthException();
    }
  }
}
```

---

## Repository Implementations

Repositories implement the interfaces defined in the Domain Layer and coordinate between data sources.

### BoardRepositoryImpl

```dart
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _localDataSource;
  final SymbolTalkApiDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  
  BoardRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._networkInfo,
  );
  
  @override
  Future<List<Board>> getBoards() async {
    // Try local first (offline-first)
    try {
      final boardModels = await _localDataSource.getBoards();
      return boardModels.map(BoardMapper.toEntity).toList();
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<Board?> getBoard(String id) async {
    try {
      final boardModel = await _localDataSource.getBoard(id);
      return boardModel != null ? BoardMapper.toEntity(boardModel) : null;
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<void> saveBoard(Board board) async {
    try {
      final boardModel = BoardMapper.toModel(board);
      await _localDataSource.saveBoard(boardModel);
      
      // Sync to remote if online
      if (await _networkInfo.isConnected) {
        try {
          await _remoteDataSource.uploadBoard(boardModel);
        } catch (e) {
          // Don't fail if sync fails, just log it
          debugPrint('Failed to sync board to remote: $e');
        }
      }
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<void> deleteBoard(String id) async {
    try {
      await _localDataSource.deleteBoard(id);
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<List<Board>> searchBoards(String query) async {
    final boards = await getBoards();
    return boards.where((board) => 
      board.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  @override
  Future<void> exportBoard(String id, String path) async {
    final board = await getBoard(id);
    if (board == null) throw NotFoundFailure();
    
    final boardModel = BoardMapper.toModel(board);
    final jsonString = jsonEncode(boardModel.toJson());
    final file = File(path);
    await file.writeAsString(jsonString);
  }
  
  @override
  Future<Board> importBoard(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final boardModel = BoardModel.fromJson(json);
    return BoardMapper.toEntity(boardModel);
  }
}
```

### ProfileRepositoryImpl

```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource _localDataSource;
  
  ProfileRepositoryImpl(this._localDataSource);
  
  @override
  Future<List<UserProfile>> getProfiles() async {
    try {
      final profileModels = await _localDataSource.getProfiles();
      return profileModels.map(ProfileMapper.toEntity).toList();
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<UserProfile?> getProfile(String id) async {
    try {
      final profileModel = await _localDataSource.getProfile(id);
      return profileModel != null ? ProfileMapper.toEntity(profileModel) : null;
    } catch (e) {
      throw CacheException();
    }
  }
  
  @override
  Future<UserProfile> createProfile(String name) async {
    final profiles = await getProfiles();
    final newProfile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      settings: const AppSettings(
        themeMode: ThemeMode.system,
        voiceRate: 0.5,
        voicePitch: 1.0,
        voiceVolume: 1.0,
      ),
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    
    final profileModel = ProfileMapper.toModel(newProfile);
    final updatedProfiles = [...profiles.map(ProfileMapper.toModel), profileModel];
    await _localDataSource.saveProfiles(updatedProfiles);
    
    return newProfile;
  }
  
  @override
  Future<void> updateProfile(UserProfile profile) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    
    if (index >= 0) {
      profiles[index] = profile;
      final profileModels = profiles.map(ProfileMapper.toModel).toList();
      await _localDataSource.saveProfiles(profileModels);
    }
  }
  
  @override
  Future<void> deleteProfile(String id) async {
    final profiles = await getProfiles();
    final filtered = profiles.where((p) => p.id != id).toList();
    final profileModels = filtered.map(ProfileMapper.toModel).toList();
    await _localDataSource.saveProfiles(profileModels);
  }
  
  @override
  Future<void> setActiveProfile(String id) async {
    await _localDataSource.setActiveProfileId(id);
  }
  
  @override
  Future<UserProfile> getActiveProfile() async {
    final activeId = await _localDataSource.getActiveProfileId();
    if (activeId.isEmpty) {
      final profiles = await getProfiles();
      if (profiles.isNotEmpty) {
        await setActiveProfile(profiles.first.id);
        return profiles.first;
      }
      throw Exception('No profiles available');
    }
    final profile = await getProfile(activeId);
    if (profile == null) {
      throw Exception('Active profile not found');
    }
    return profile;
  }
}
```

---

## Mappers

Mappers convert between data models and domain entities.

### BoardMapper

```dart
class BoardMapper {
  static Board toEntity(BoardModel model) {
    return Board(
      id: model.id,
      name: model.name,
      rows: model.rows,
      columns: model.columns,
      tiles: model.tiles.map(SymbolTileMapper.toEntity).toList(),
      backgroundColor: model.backgroundColor,
      isSubBoard: model.isSubBoard,
      createdAt: DateTime.now(), // Would be stored in model in real implementation
      updatedAt: DateTime.now(),
    );
  }
  
  static BoardModel toModel(Board entity) {
    return BoardModel(
      id: entity.id,
      name: entity.name,
      rows: entity.rows,
      columns: entity.columns,
      tiles: entity.tiles.map(SymbolTileMapper.toModel).toList(),
      backgroundColor: entity.backgroundColor,
      isSubBoard: entity.isSubBoard,
    );
  }
}
```

### SymbolTileMapper

```dart
class SymbolTileMapper {
  static SymbolTile toEntity(SymbolTileModel model) {
    return SymbolTile(
      id: model.id,
      label: model.label,
      category: model.category,
      imageAsset: model.imageAsset,
      emoji: model.emoji,
      linkedBoardId: model.linkedBoardId,
      isBoardLink: model.isBoardLink,
      tileSize: model.tileSize,
      bgColor: model.bgColor,
      textColor: model.textColor,
      customVoice: model.customVoice,
    );
  }
  
  static SymbolTileModel toModel(SymbolTile entity) {
    return SymbolTileModel(
      id: entity.id,
      label: entity.label,
      category: entity.category,
      imageAsset: entity.imageAsset,
      emoji: entity.emoji,
      linkedBoardId: entity.linkedBoardId,
      isBoardLink: entity.isBoardLink,
      tileSize: entity.tileSize,
      bgColor: entity.bgColor,
      textColor: entity.textColor,
      customVoice: entity.customVoice,
    );
  }
}
```

### ProfileMapper

```dart
class ProfileMapper {
  static UserProfile toEntity(UserProfileModel model) {
    return UserProfile(
      id: model.id,
      name: model.name,
      settings: SettingsMapper.toEntity(model.settings),
      tabOrder: model.tabOrder,
      preferredSymbolSets: model.preferredSymbolSets,
      startingBoardId: model.startingBoardId,
      username: model.username,
      password: model.password,
      isAdmin: model.isAdmin,
      createdAt: DateTime.parse(model.createdAt),
      lastUsedAt: DateTime.parse(model.lastUsedAt),
    );
  }
  
  static UserProfileModel toModel(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      settings: SettingsMapper.toModel(entity.settings),
      tabOrder: entity.tabOrder,
      preferredSymbolSets: entity.preferredSymbolSets,
      startingBoardId: entity.startingBoardId,
      username: entity.username,
      password: entity.password,
      isAdmin: entity.isAdmin,
      createdAt: entity.createdAt.toIso8601String(),
      lastUsedAt: entity.lastUsedAt.toIso8601String(),
    );
  }
}
```

### SettingsMapper

```dart
class SettingsMapper {
  static AppSettings toEntity(AppSettingsModel model) {
    return AppSettings(
      themeMode: _stringToThemeMode(model.themeMode),
      voiceRate: model.voiceRate,
      voicePitch: model.voicePitch,
      voiceVolume: model.voiceVolume,
      voiceLanguage: model.voiceLanguage,
      voiceName: model.voiceName,
      sentenceSize: model.sentenceSize,
      sentenceType: model.sentenceType,
      readSentenceOnly: model.readSentenceOnly,
      profileImage: model.profileImage,
      fontSize: model.fontSize,
      highContrast: model.highContrast,
      projectRoot: model.projectRoot,
    );
  }
  
  static AppSettingsModel toModel(AppSettings entity) {
    return AppSettingsModel(
      themeMode: _themeModeToString(entity.themeMode),
      voiceRate: entity.voiceRate,
      voicePitch: entity.voicePitch,
      voiceVolume: entity.voiceVolume,
      voiceLanguage: entity.voiceLanguage,
      voiceName: entity.voiceName,
      sentenceSize: entity.sentenceSize,
      sentenceType: entity.sentenceType,
      readSentenceOnly: entity.readSentenceOnly,
      profileImage: entity.profileImage,
      fontSize: entity.fontSize,
      highContrast: entity.highContrast,
      projectRoot: entity.projectRoot,
    );
  }
  
  static ThemeMode _stringToThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
```

---

## Exceptions

Define custom exceptions for error handling.

```dart
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error occurred']);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Validation error occurred']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication failed']);
}
```

---

## NetworkInfo

Helper to check network connectivity.

```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  
  NetworkInfoImpl(this.connectivity);
  
  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

---

## Testing Data Layer

Test repository implementations with mock data sources.

```dart
test('BoardRepositoryImpl returns boards from local source', () async {
  // Arrange
  final mockLocal = MockBoardLocalDataSource();
  final mockRemote = MockSymbolTalkApiDataSource();
  final mockNetwork = MockNetworkInfo();
  
  when(mockNetwork.isConnected).thenAnswer((_) async => false);
  when(mockLocal.getBoards()).thenAnswer((_) async => [testBoardModel]);
  
  final repository = BoardRepositoryImpl(mockLocal, mockRemote, mockNetwork);
  
  // Act
  final result = await repository.getBoards();
  
  // Assert
  expect(result.length, 1);
  expect(result.first.name, testBoardModel.name);
  verify(mockLocal.getBoards()).called(1);
  verifyNever(mockRemote.getRemoteBoards());
});

test('BoardRepositoryImpl saves to local and syncs to remote when online', () async {
  // Arrange
  final mockLocal = MockBoardLocalDataSource();
  final mockRemote = MockSymbolTalkApiDataSource();
  final mockNetwork = MockNetworkInfo();
  
  when(mockNetwork.isConnected).thenAnswer((_) async => true);
  when(mockLocal.saveBoard(any)).thenAnswer((_) async {});
  when(mockRemote.uploadBoard(any)).thenAnswer((_) async {});
  
  final repository = BoardRepositoryImpl(mockLocal, mockRemote, mockNetwork);
  
  // Act
  await repository.saveBoard(testBoard);
  
  // Assert
  verify(mockLocal.saveBoard(any)).called(1);
  verify(mockRemote.uploadBoard(any)).called(1);
});
```

---

## Best Practices

### 1. Separate Models from Entities

❌ **Bad:**
```dart
class Board {
  // Used for both domain and data
  Map<String, dynamic> toJson() { /* ... */ }
}
```

✅ **Good:**
```dart
// Domain Layer
class Board {
  // Pure domain entity
}

// Data Layer
class BoardModel {
  Map<String, dynamic> toJson() { /* ... */ }
}
```

### 2. Use Mappers for Conversion

❌ **Bad:**
```dart
class BoardRepositoryImpl {
  Future<List<Board>> getBoards() {
    return _dataSource.getBoards().then((models) => 
      models.map((m) => Board(
        id: m.id,
        name: m.name,
        // ... manual mapping
      )).toList()
    );
  }
}
```

✅ **Good:**
```dart
class BoardRepositoryImpl {
  Future<List<Board>> getBoards() {
    return _dataSource.getBoards().then((models) => 
      models.map(BoardMapper.toEntity).toList()
    );
  }
}
```

### 3. Handle Offline-First

❌ **Bad:**
```dart
Future<List<Board>> getBoards() async {
  return await _remoteDataSource.getBoards(); // Fails offline
}
```

✅ **Good:**
```dart
Future<List<Board>> getBoards() async {
  try {
    return await _localDataSource.getBoards();
  } catch (e) {
    if (await _networkInfo.isConnected) {
      return await _remoteDataSource.getBoards();
    }
    throw NetworkException();
  }
}
```

---

## Summary

The Data Layer provides:

1. **Data access abstraction** - Repository interfaces hide implementation details
2. **Multiple data sources** - Local and remote data sources
3. **Data transformation** - Mappers convert between models and entities
4. **Offline-first support** - Local storage with optional remote sync
5. **Error handling** - Custom exceptions for different failure scenarios

This layer ensures the Domain Layer remains pure and independent of data storage technologies.

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
