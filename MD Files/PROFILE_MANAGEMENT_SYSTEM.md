# Profile Management System

## Overview

This document provides a complete profile management system architecture for Charlie Chat, supporting multiple users, caregiver and child profiles, profile images, assigned boards, permissions, and locked settings.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  - ProfileViewModel (State management)                      │
│  - ProfileListWidget                                        │
│  - ProfileEditorWidget                                      │
│  - ProfileSelectorWidget                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
│  - Use Cases (Profile operations)                           │
│  - Entities (Profile, Permission, BoardAssignment)         │
│  - Repository Interfaces                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
│  - Repository Implementations                               │
│  - Data Sources (Local/Remote)                              │
│  - Mappers (Entity ↔ Model conversion)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Domain Layer - Entities

### Profile Entity

```dart
// lib/domain/entities/profile.dart
class Profile {
  final String id;
  final String name;
  final String? avatarPath;
  final ProfileType type;
  final String? caregiverId; // For child profiles
  final List<String> assignedBoardIds;
  final String startingBoardId;
  final ProfilePermissions permissions;
  final ProfileSettings settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;

  const Profile({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.type,
    this.caregiverId,
    this.assignedBoardIds = const [],
    this.startingBoardId = '',
    required this.permissions,
    required this.settings,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    ProfileType? type,
    String? caregiverId,
    List<String>? assignedBoardIds,
    String? startingBoardId,
    ProfilePermissions? permissions,
    ProfileSettings? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      type: type ?? this.type,
      caregiverId: caregiverId ?? this.caregiverId,
      assignedBoardIds: assignedBoardIds ?? this.assignedBoardIds,
      startingBoardId: startingBoardId ?? this.startingBoardId,
      permissions: permissions ?? this.permissions,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
```

### ProfileType Enum

```dart
// lib/domain/entities/profile_type.dart
enum ProfileType {
  caregiver,
  child,
  adult,
}

extension ProfileTypeExtension on ProfileType {
  String get displayName {
    switch (this) {
      case ProfileType.caregiver:
        return 'Caregiver';
      case ProfileType.child:
        return 'Child';
      case ProfileType.adult:
        return 'Adult';
    }
  }

  String get description {
    switch (this) {
      case ProfileType.caregiver:
        return 'Full access to all features and settings';
      case ProfileType.child:
        return 'Restricted access with caregiver supervision';
      case ProfileType.adult:
        return 'Standard user access';
    }
  }
}
```

### ProfilePermissions Entity

```dart
// lib/domain/entities/profile_permissions.dart
class ProfilePermissions {
  final bool canEditBoards;
  final bool canCreateBoards;
  final bool canDeleteBoards;
  final bool canShareBoards;
  final bool canAccessSettings;
  final bool canEditSettings;
  final bool canManageProfiles;
  final bool canAccessCloudSync;
  final bool canExportData;
  final bool canImportData;
  final bool canAccessHelp;
  final bool canSwitchProfiles;

  const ProfilePermissions({
    this.canEditBoards = true,
    this.canCreateBoards = true,
    this.canDeleteBoards = true,
    this.canShareBoards = true,
    this.canAccessSettings = true,
    this.canEditSettings = true,
    this.canManageProfiles = true,
    this.canAccessCloudSync = true,
    this.canExportData = true,
    this.canImportData = true,
    this.canAccessHelp = true,
    this.canSwitchProfiles = true,
  });

  ProfilePermissions copyWith({
    bool? canEditBoards,
    bool? canCreateBoards,
    bool? canDeleteBoards,
    bool? canShareBoards,
    bool? canAccessSettings,
    bool? canEditSettings,
    bool? canManageProfiles,
    bool? canAccessCloudSync,
    bool? canExportData,
    bool? canImportData,
    bool? canAccessHelp,
    bool? canSwitchProfiles,
  }) {
    return ProfilePermissions(
      canEditBoards: canEditBoards ?? this.canEditBoards,
      canCreateBoards: canCreateBoards ?? this.canCreateBoards,
      canDeleteBoards: canDeleteBoards ?? this.canDeleteBoards,
      canShareBoards: canShareBoards ?? this.canShareBoards,
      canAccessSettings: canAccessSettings ?? this.canAccessSettings,
      canEditSettings: canEditSettings ?? this.canEditSettings,
      canManageProfiles: canManageProfiles ?? this.canManageProfiles,
      canAccessCloudSync: canAccessCloudSync ?? this.canAccessCloudSync,
      canExportData: canExportData ?? this.canExportData,
      canImportData: canImportData ?? this.canImportData,
      canAccessHelp: canAccessHelp ?? this.canAccessHelp,
      canSwitchProfiles: canSwitchProfiles ?? this.canSwitchProfiles,
    );
  }

  // Default permissions for each profile type
  static ProfilePermissions defaultForType(ProfileType type) {
    switch (type) {
      case ProfileType.caregiver:
        return const ProfilePermissions(
          canEditBoards: true,
          canCreateBoards: true,
          canDeleteBoards: true,
          canShareBoards: true,
          canAccessSettings: true,
          canEditSettings: true,
          canManageProfiles: true,
          canAccessCloudSync: true,
          canExportData: true,
          canImportData: true,
          canAccessHelp: true,
          canSwitchProfiles: true,
        );
      case ProfileType.child:
        return const ProfilePermissions(
          canEditBoards: false,
          canCreateBoards: false,
          canDeleteBoards: false,
          canShareBoards: false,
          canAccessSettings: false,
          canEditSettings: false,
          canManageProfiles: false,
          canAccessCloudSync: false,
          canExportData: false,
          canImportData: false,
          canAccessHelp: true,
          canSwitchProfiles: false,
        );
      case ProfileType.adult:
        return const ProfilePermissions(
          canEditBoards: true,
          canCreateBoards: true,
          canDeleteBoards: true,
          canShareBoards: true,
          canAccessSettings: true,
          canEditSettings: true,
          canManageProfiles: false,
          canAccessCloudSync: true,
          canExportData: true,
          canImportData: true,
          canAccessHelp: true,
          canSwitchProfiles: true,
        );
    }
  }
}
```

### ProfileSettings Entity

```dart
// lib/domain/entities/profile_settings.dart
class ProfileSettings {
  final VoiceSettings voiceSettings;
  final DisplaySettings displaySettings;
  final BoardSettings boardSettings;
  final SyncSettings syncSettings;
  final bool locked; // If true, settings cannot be changed by the profile

  const ProfileSettings({
    required this.voiceSettings,
    required this.displaySettings,
    required this.boardSettings,
    required this.syncSettings,
    this.locked = false,
  });

  ProfileSettings copyWith({
    VoiceSettings? voiceSettings,
    DisplaySettings? displaySettings,
    BoardSettings? boardSettings,
    SyncSettings? syncSettings,
    bool? locked,
  }) {
    return ProfileSettings(
      voiceSettings: voiceSettings ?? this.voiceSettings,
      displaySettings: displaySettings ?? this.displaySettings,
      boardSettings: boardSettings ?? this.boardSettings,
      syncSettings: syncSettings ?? this.syncSettings,
      locked: locked ?? this.locked,
    );
  }

  static ProfileSettings defaultSettings() {
    return ProfileSettings(
      voiceSettings: VoiceSettings.defaultSettings(),
      displaySettings: DisplaySettings.defaultSettings(),
      boardSettings: BoardSettings.defaultSettings(),
      syncSettings: SyncSettings.defaultSettings(),
    );
  }
}
```

### VoiceSettings Entity

```dart
// lib/domain/entities/voice_settings.dart
class VoiceSettings {
  final String language;
  final String voiceName;
  final double speechRate;
  final double pitch;
  final double volume;

  const VoiceSettings({
    this.language = 'en-US',
    this.voiceName = '',
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  VoiceSettings copyWith({
    String? language,
    String? voiceName,
    double? speechRate,
    double? pitch,
    double? volume,
  }) {
    return VoiceSettings(
      language: language ?? this.language,
      voiceName: voiceName ?? this.voiceName,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }

  static VoiceSettings defaultSettings() {
    return const VoiceSettings(
      language: 'en-US',
      voiceName: '',
      speechRate: 0.5,
      pitch: 1.0,
      volume: 1.0,
    );
  }
}
```

### DisplaySettings Entity

```dart
// lib/domain/entities/display_settings.dart
class DisplaySettings {
  final String themeMode; // light, dark, system
  final String fontSize; // small, medium, large, extra-large
  final bool highContrast;
  final bool showLabels;
  final bool showEmoji;

  const DisplaySettings({
    this.themeMode = 'system',
    this.fontSize = 'medium',
    this.highContrast = false,
    this.showLabels = true,
    this.showEmoji = true,
  });

  DisplaySettings copyWith({
    String? themeMode,
    String? fontSize,
    bool? highContrast,
    bool? showLabels,
    bool? showEmoji,
  }) {
    return DisplaySettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      highContrast: highContrast ?? this.highContrast,
      showLabels: showLabels ?? this.showLabels,
      showEmoji: showEmoji ?? this.showEmoji,
    );
  }

  static DisplaySettings defaultSettings() {
    return const DisplaySettings(
      themeMode: 'system',
      fontSize: 'medium',
      highContrast: false,
      showLabels: true,
      showEmoji: true,
    );
  }
}
```

### BoardSettings Entity

```dart
// lib/domain/entities/board_settings.dart
class BoardSettings {
  final int defaultRows;
  final int defaultColumns;
  final double defaultTileSize;
  final String defaultBackgroundColor;
  final bool adjustableLayout;
  final bool showSubboardIndicator;

  const BoardSettings({
    this.defaultRows = 6,
    this.defaultColumns = 5,
    this.defaultTileSize = 1.0,
    this.defaultBackgroundColor = '#FFFFFF',
    this.adjustableLayout = false,
    this.showSubboardIndicator = true,
  });

  BoardSettings copyWith({
    int? defaultRows,
    int? defaultColumns,
    double? defaultTileSize,
    String? defaultBackgroundColor,
    bool? adjustableLayout,
    bool? showSubboardIndicator,
  }) {
    return BoardSettings(
      defaultRows: defaultRows ?? this.defaultRows,
      defaultColumns: defaultColumns ?? this.defaultColumns,
      defaultTileSize: defaultTileSize ?? this.defaultTileSize,
      defaultBackgroundColor: defaultBackgroundColor ?? this.defaultBackgroundColor,
      adjustableLayout: adjustableLayout ?? this.adjustableLayout,
      showSubboardIndicator: showSubboardIndicator ?? this.showSubboardIndicator,
    );
  }

  static BoardSettings defaultSettings() {
    return const BoardSettings(
      defaultRows: 6,
      defaultColumns = 5,
      defaultTileSize: 1.0,
      defaultBackgroundColor: '#FFFFFF',
      adjustableLayout: false,
      showSubboardIndicator: true,
    );
  }
}
```

### SyncSettings Entity

```dart
// lib/domain/entities/sync_settings.dart
class SyncSettings {
  final bool autoSync;
  final bool syncOnWifiOnly;
  final int syncIntervalMinutes;
  final bool syncImages;

  const SyncSettings({
    this.autoSync = true,
    this.syncOnWifiOnly = false,
    this.syncIntervalMinutes = 30,
    this.syncImages = true,
  });

  SyncSettings copyWith({
    bool? autoSync,
    bool? syncOnWifiOnly,
    int? syncIntervalMinutes,
    bool? syncImages,
  }) {
    return SyncSettings(
      autoSync: autoSync ?? this.autoSync,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      syncImages: syncImages ?? this.syncImages,
    );
  }

  static SyncSettings defaultSettings() {
    return const SyncSettings(
      autoSync: true,
      syncOnWifiOnly: false,
      syncIntervalMinutes: 30,
      syncImages: true,
    );
  }
}
```

### BoardAssignment Entity

```dart
// lib/domain/entities/board_assignment.dart
class BoardAssignment {
  final String boardId;
  final String boardName;
  final bool isSubBoard;
  final String? parentBoardId;
  final DateTime assignedAt;

  const BoardAssignment({
    required this.boardId,
    required this.boardName,
    this.isSubBoard = false,
    this.parentBoardId,
    required this.assignedAt,
  });

  BoardAssignment copyWith({
    String? boardId,
    String? boardName,
    bool? isSubBoard,
    String? parentBoardId,
    DateTime? assignedAt,
  }) {
    return BoardAssignment(
      boardId: boardId ?? this.boardId,
      boardName: boardName ?? this.boardName,
      isSubBoard: isSubBoard ?? this.isSubBoard,
      parentBoardId: parentBoardId ?? this.parentBoardId,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}
```

---

## 3. Domain Layer - Repository Interfaces

### Profile Repository Interface

```dart
// lib/domain/repositories/profile_repository.dart
import '../entities/profile.dart';
import '../entities/board_assignment.dart';

abstract class ProfileRepository {
  Future<List<Profile>> getAllProfiles();
  Future<Profile?> getProfileById(String id);
  Future<Profile?> getActiveProfile();
  Future<List<Profile>> getProfilesByType(ProfileType type);
  Future<List<Profile>> getProfilesByCaregiver(String caregiverId);
  
  Future<void> createProfile(Profile profile);
  Future<void> updateProfile(Profile profile);
  Future<void> deleteProfile(String id);
  Future<void> setActiveProfile(String id);
  Future<void> deactivateAllProfiles();
  
  Future<List<BoardAssignment>> getAvailableBoards();
  Future<void> assignBoardToProfile(String profileId, String boardId);
  Future<void> removeBoardFromProfile(String profileId, String boardId);
  Future<void> updateStartingBoard(String profileId, String boardId);
  
  Future<void> updateProfilePermissions(String profileId, ProfilePermissions permissions);
  Future<void> updateProfileSettings(String profileId, ProfileSettings settings);
  Future<void> lockProfileSettings(String profileId, bool locked);
  
  Future<void> updateProfileAvatar(String profileId, String avatarPath);
  Future<void> deleteProfileAvatar(String profileId);
}
```

---

## 4. Domain Layer - Use Cases

### Get Profiles Use Case

```dart
// lib/domain/usecases/get_profiles_usecase.dart
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfilesUseCase {
  final ProfileRepository _repository;

  GetProfilesUseCase(this._repository);

  Future<List<Profile>> call() async {
    return await _repository.getAllProfiles();
  }
}
```

### Get Active Profile Use Case

```dart
// lib/domain/usecases/get_active_profile_usecase.dart
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetActiveProfileUseCase {
  final ProfileRepository _repository;

  GetActiveProfileUseCase(this._repository);

  Future<Profile?> call() async {
    return await _repository.getActiveProfile();
  }
}
```

### Create Profile Use Case

```dart
// lib/domain/usecases/profile/create_profile_usecase.dart
import '../entities/profile.dart';
import '../entities/profile_type.dart';
import '../entities/profile_permissions.dart';
import '../entities/profile_settings.dart';
import '../repositories/profile_repository.dart';

class CreateProfileUseCase {
  final ProfileRepository _repository;

  CreateProfileUseCase(this._repository);

  Future<void> call({
    required String name,
    required ProfileType type,
    String? avatarPath,
    String? caregiverId,
    List<String>? assignedBoardIds,
    String? startingBoardId,
    ProfilePermissions? permissions,
    ProfileSettings? settings,
  }) async {
    final profile = Profile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      avatarPath: avatarPath,
      type: type,
      caregiverId: caregiverId,
      assignedBoardIds: assignedBoardIds ?? [],
      startingBoardId: startingBoardId ?? '',
      permissions: permissions ?? ProfilePermissions.defaultForType(type),
      settings: settings ?? ProfileSettings.defaultSettings(),
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.createProfile(profile);
  }
}
```

### Update Profile Use Case

```dart
// lib/domain/usecases/profile/update_profile_usecase.dart
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<void> call(Profile profile) async {
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );
    await _repository.updateProfile(updatedProfile);
  }
}
```

### Delete Profile Use Case

```dart
// lib/domain/usecases/profile/delete_profile_usecase.dart
import '../repositories/profile_repository.dart';

class DeleteProfileUseCase {
  final ProfileRepository _repository;

  DeleteProfileUseCase(this._repository);

  Future<void> call(String profileId) async {
    await _repository.deleteProfile(profileId);
  }
}
```

### Switch Profile Use Case

```dart
// lib/domain/usecases/profile/switch_profile_usecase.dart
import '../repositories/profile_repository.dart';

class SwitchProfileUseCase {
  final ProfileRepository _repository;

  SwitchProfileUseCase(this._repository);

  Future<void> call(String profileId) async {
    await _repository.deactivateAllProfiles();
    await _repository.setActiveProfile(profileId);
  }
}
```

### Get Available Boards Use Case

```dart
// lib/domain/usecases/profile/get_available_boards_usecase.dart
import '../entities/board_assignment.dart';
import '../repositories/profile_repository.dart';

class GetAvailableBoardsUseCase {
  final ProfileRepository _repository;

  GetAvailableBoardsUseCase(this._repository);

  Future<List<BoardAssignment>> call() async {
    return await _repository.getAvailableBoards();
  }
}
```

### Assign Board Use Case

```dart
// lib/domain/usecases/profile/assign_board_usecase.dart
import '../repositories/profile_repository.dart';

class AssignBoardUseCase {
  final ProfileRepository _repository;

  AssignBoardUseCase(this._repository);

  Future<void> call(String profileId, String boardId) async {
    await _repository.assignBoardToProfile(profileId, boardId);
  }
}
```

### Update Starting Board Use Case

```dart
// lib/domain/usecases/profile/update_starting_board_usecase.dart
import '../repositories/profile_repository.dart';

class UpdateStartingBoardUseCase {
  final ProfileRepository _repository;

  UpdateStartingBoardUseCase(this._repository);

  Future<void> call(String profileId, String boardId) async {
    await _repository.updateStartingBoard(profileId, boardId);
  }
}
```

### Update Profile Permissions Use Case

```dart
// lib/domain/usecases/profile/update_profile_permissions_usecase.dart
import '../entities/profile_permissions.dart';
import '../repositories/profile_repository.dart';

class UpdateProfilePermissionsUseCase {
  final ProfileRepository _repository;

  UpdateProfilePermissionsUseCase(this._repository);

  Future<void> call(String profileId, ProfilePermissions permissions) async {
    await _repository.updateProfilePermissions(profileId, permissions);
  }
}
```

### Update Profile Settings Use Case

```dart
// lib/domain/usecases/profile/update_profile_settings_usecase.dart
import '../entities/profile_settings.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileSettingsUseCase {
  final ProfileRepository _repository;

  UpdateProfileSettingsUseCase(this._repository);

  Future<void> call(String profileId, ProfileSettings settings) async {
    await _repository.updateProfileSettings(profileId, settings);
  }
}
```

### Lock Profile Settings Use Case

```dart
// lib/domain/usecases/profile/lock_profile_settings_usecase.dart
import '../repositories/profile_repository.dart';

class LockProfileSettingsUseCase {
  final ProfileRepository _repository;

  LockProfileSettingsUseCase(this._repository);

  Future<void> call(String profileId, bool locked) async {
    await _repository.lockProfileSettings(profileId, locked);
  }
}
```

---

## 5. Data Layer - Repository Implementation

### Profile Repository Implementation

```dart
// lib/data/repositories/profile_repository_impl.dart
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/entities/profile_permissions.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/entities/board_assignment.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/local/profile_local_datasource.dart';
import '../datasources/remote/profile_remote_datasource.dart';
import '../mappers/profile_mapper.dart';
import '../mappers/board_assignment_mapper.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource _localDataSource;
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileMapper _mapper;
  final BoardAssignmentMapper _boardAssignmentMapper;

  ProfileRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._mapper,
    this._boardAssignmentMapper,
  );

  @override
  Future<List<Profile>> getAllProfiles() async {
    final models = await _localDataSource.getAllProfiles();
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<Profile?> getProfileById(String id) async {
    final model = await _localDataSource.getProfileById(id);
    return model != null ? _mapper.toEntity(model) : null;
  }

  @override
  Future<Profile?> getActiveProfile() async {
    final model = await _localDataSource.getActiveProfile();
    return model != null ? _mapper.toEntity(model) : null;
  }

  @override
  Future<List<Profile>> getProfilesByType(ProfileType type) async {
    final models = await _localDataSource.getProfilesByType(type.name);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Profile>> getProfilesByCaregiver(String caregiverId) async {
    final models = await _localDataSource.getProfilesByCaregiver(caregiverId);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<void> createProfile(Profile profile) async {
    final model = _mapper.toModel(profile);
    await _localDataSource.createProfile(model);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    final model = _mapper.toModel(profile);
    await _localDataSource.updateProfile(model);
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _localDataSource.deleteProfile(id);
  }

  @override
  Future<void> setActiveProfile(String id) async {
    await _localDataSource.setActiveProfile(id);
  }

  @override
  Future<void> deactivateAllProfiles() async {
    await _localDataSource.deactivateAllProfiles();
  }

  @override
  Future<List<BoardAssignment>> getAvailableBoards() async {
    // Get all boards from board repository
    final boardModels = await _localDataSource.getAllBoards();
    return boardModels.map((model) => _boardAssignmentMapper.toEntity(model)).toList();
  }

  @override
  Future<void> assignBoardToProfile(String profileId, String boardId) async {
    await _localDataSource.assignBoardToProfile(profileId, boardId);
  }

  @override
  Future<void> removeBoardFromProfile(String profileId, String boardId) async {
    await _localDataSource.removeBoardFromProfile(profileId, boardId);
  }

  @override
  Future<void> updateStartingBoard(String profileId, String boardId) async {
    await _localDataSource.updateStartingBoard(profileId, boardId);
  }

  @override
  Future<void> updateProfilePermissions(String profileId, ProfilePermissions permissions) async {
    await _localDataSource.updateProfilePermissions(profileId, permissions);
  }

  @override
  Future<void> updateProfileSettings(String profileId, ProfileSettings settings) async {
    await _localDataSource.updateProfileSettings(profileId, settings);
  }

  @override
  Future<void> lockProfileSettings(String profileId, bool locked) async {
    await _localDataSource.lockProfileSettings(profileId, locked);
  }

  @override
  Future<void> updateProfileAvatar(String profileId, String avatarPath) async {
    await _localDataSource.updateProfileAvatar(profileId, avatarPath);
  }

  @override
  Future<void> deleteProfileAvatar(String profileId) async {
    await _localDataSource.deleteProfileAvatar(profileId);
  }
}
```

---

## 6. Data Layer - Local Data Source

### Profile Local Data Source

```dart
// lib/data/datasources/local/profile_local_datasource.dart
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../domain/entities/profile_permissions.dart';
import '../../domain/entities/profile_settings.dart';

class ProfileLocalDataSource {
  final AppDatabase _database;

  ProfileLocalDataSource(this._database);

  Future<List<ProfileModel>> getAllProfiles() async {
    return await _database.getAllProfiles();
  }

  Future<ProfileModel?> getProfileById(String id) async {
    return await _database.getProfileById(id);
  }

  Future<ProfileModel?> getActiveProfile() async {
    return await _database.getActiveProfile();
  }

  Future<List<ProfileModel>> getProfilesByType(String type) async {
    return await _database.getProfilesByType(type);
  }

  Future<List<ProfileModel>> getProfilesByCaregiver(String caregiverId) async {
    return await _database.getProfilesByCaregiver(caregiverId);
  }

  Future<void> createProfile(ProfileModel profile) async {
    await _database.insertProfile(profile);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _database.updateProfile(profile);
  }

  Future<void> deleteProfile(String id) async {
    await _database.deleteProfile(id);
  }

  Future<void> setActiveProfile(String id) async {
    await _database.deactivateAllProfiles();
    await _database.setActiveProfile(id);
  }

  Future<void> deactivateAllProfiles() async {
    await _database.deactivateAllProfiles();
  }

  Future<List<BoardModel>> getAllBoards() async {
    return await _database.getAllBoards();
  }

  Future<void> assignBoardToProfile(String profileId, String boardId) async {
    await _database.assignBoardToProfile(profileId, boardId);
  }

  Future<void> removeBoardFromProfile(String profileId, String boardId) async {
    await _database.removeBoardFromProfile(profileId, boardId);
  }

  Future<void> updateStartingBoard(String profileId, String boardId) async {
    await _database.updateStartingBoard(profileId, boardId);
  }

  Future<void> updateProfilePermissions(String profileId, ProfilePermissions permissions) async {
    await _database.updateProfilePermissions(profileId, permissions);
  }

  Future<void> updateProfileSettings(String profileId, ProfileSettings settings) async {
    await _database.updateProfileSettings(profileId, settings);
  }

  Future<void> lockProfileSettings(String profileId, bool locked) async {
    await _database.lockProfileSettings(profileId, locked);
  }

  Future<void> updateProfileAvatar(String profileId, String avatarPath) async {
    await _database.updateProfileAvatar(profileId, avatarPath);
  }

  Future<void> deleteProfileAvatar(String profileId) async {
    await _database.deleteProfileAvatar(profileId);
  }
}
```

---

## 7. Data Layer - Database Queries

### Profile DAO (Drift)

```dart
// lib/data/database/daos/profile_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(AppDatabase db) : super(db);

  Future<List<Profile>> getAllProfiles() => select(profiles).get();

  Future<Profile?> getProfileById(String id) =>
      (select(profiles)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Profile?> getActiveProfile() =>
      (select(profiles)..where((p) => p.isActive.equals(true))).getSingleOrNull();

  Future<List<Profile>> getProfilesByType(String type) =>
      (select(profiles)..where((p) => p.type.equals(type))).get();

  Future<List<Profile>> getProfilesByCaregiver(String caregiverId) =>
      (select(profiles)..where((p) => p.caregiverId.equals(caregiverId))).get();

  Future<int> insertProfile(Profile profile) => into(profiles).insert(profile);

  Future<bool> updateProfile(Profile profile) => update(profiles).replace(profile);

  Future<int> deleteProfile(String id) =>
      (delete(profiles)..where((p) => p.id.equals(id))).go();

  Future<void> deactivateAllProfiles() =>
      (update(profiles)..where((p) => p.isActive.equals(true)))
          .write(const ProfilesCompanion(isActive: const Value(false)));

  Future<void> setActiveProfile(String id) =>
      (update(profiles)..where((p) => p.id.equals(id)))
          .write(ProfilesCompanion(isActive: const Value(true), lastUsedAt: Value(DateTime.now())));

  Future<List<Board>> getAllBoards() => select(boards).get();

  Future<void> assignBoardToProfile(String profileId, String boardId) {
    // Implementation depends on your junction table structure
    return Future.value();
  }

  Future<void> removeBoardFromProfile(String profileId, String boardId) {
    // Implementation depends on your junction table structure
    return Future.value();
  }

  Future<void> updateStartingBoard(String profileId, String boardId) =>
      (update(profiles)..where((p) => p.id.equals(profileId)))
          .write(ProfilesCompanion(startingBoardId: Value(boardId)));

  Future<void> updateProfilePermissions(String profileId, ProfilePermissions permissions) {
    final permissionsJson = jsonEncode(permissions.toJson());
    return (update(profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(permissionsJson: Value(permissionsJson)));
  }

  Future<void> updateProfileSettings(String profileId, ProfileSettings settings) {
    final settingsJson = jsonEncode(settings.toJson());
    return (update(profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(settingsJson: Value(settingsJson)));
  }

  Future<void> lockProfileSettings(String profileId, bool locked) {
    final profile = getProfileById(profileId);
    return profile.then((p) {
      if (p == null) return Future.value();
      final settings = ProfileSettings.fromJson(jsonDecode(p.settingsJson));
      final updatedSettings = settings.copyWith(locked: locked);
      return updateProfileSettings(profileId, updatedSettings);
    });
  }

  Future<void> updateProfileAvatar(String profileId, String avatarPath) =>
      (update(profiles)..where((p) => p.id.equals(profileId)))
          .write(ProfilesCompanion(avatarPath: Value(avatarPath)));

  Future<void> deleteProfileAvatar(String profileId) =>
      (update(profiles)..where((p) => p.id.equals(profileId)))
          .write(const ProfilesCompanion(avatarPath: Value(null)));
}
```

---

## 8. Presentation Layer - ViewModel

### Profile ViewModel

```dart
// lib/presentation/viewmodels/profile_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/entities/profile_permissions.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/entities/board_assignment.dart';
import '../../domain/usecases/profile/get_profiles_usecase.dart';
import '../../domain/usecases/profile/get_active_profile_usecase.dart';
import '../../domain/usecases/profile/create_profile_usecase.dart';
import '../../domain/usecases/profile/update_profile_usecase.dart';
import '../../domain/usecases/profile/delete_profile_usecase.dart';
import '../../domain/usecases/profile/switch_profile_usecase.dart';
import '../../domain/usecases/profile/get_available_boards_usecase.dart';
import '../../domain/usecases/profile/assign_board_usecase.dart';
import '../../domain/usecases/profile/update_starting_board_usecase.dart';
import '../../domain/usecases/profile/update_profile_permissions_usecase.dart';
import '../../domain/usecases/profile/update_profile_settings_usecase.dart';
import '../../domain/usecases/profile/lock_profile_settings_usecase.dart';

class ProfileViewModel extends ChangeNotifier {
  final GetProfilesUseCase _getProfilesUseCase;
  final GetActiveProfileUseCase _getActiveProfileUseCase;
  final CreateProfileUseCase _createProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final DeleteProfileUseCase _deleteProfileUseCase;
  final SwitchProfileUseCase _switchProfileUseCase;
  final GetAvailableBoardsUseCase _getAvailableBoardsUseCase;
  final AssignBoardUseCase _assignBoardUseCase;
  final UpdateStartingBoardUseCase _updateStartingBoardUseCase;
  final UpdateProfilePermissionsUseCase _updateProfilePermissionsUseCase;
  final UpdateProfileSettingsUseCase _updateProfileSettingsUseCase;
  final LockProfileSettingsUseCase _lockProfileSettingsUseCase;

  // State
  List<Profile> _profiles = [];
  Profile? _activeProfile;
  List<BoardAssignment> _availableBoards = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Profile> get profiles => _profiles;
  Profile? get activeProfile => _activeProfile;
  List<BoardAssignment> get availableBoards => _availableBoards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProfileViewModel({
    required GetProfilesUseCase getProfilesUseCase,
    required GetActiveProfileUseCase getActiveProfileUseCase,
    required CreateProfileUseCase createProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required DeleteProfileUseCase deleteProfileUseCase,
    required SwitchProfileUseCase switchProfileUseCase,
    required GetAvailableBoardsUseCase getAvailableBoardsUseCase,
    required AssignBoardUseCase assignBoardUseCase,
    required UpdateStartingBoardUseCase updateStartingBoardUseCase,
    required UpdateProfilePermissionsUseCase updateProfilePermissionsUseCase,
    required UpdateProfileSettingsUseCase updateProfileSettingsUseCase,
    required LockProfileSettingsUseCase lockProfileSettingsUseCase,
  })  : _getProfilesUseCase = getProfilesUseCase,
        _getActiveProfileUseCase = getActiveProfileUseCase,
        _createProfileUseCase = createProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _deleteProfileUseCase = deleteProfileUseCase,
        _switchProfileUseCase = switchProfileUseCase,
        _getAvailableBoardsUseCase = getAvailableBoardsUseCase,
        _assignBoardUseCase = assignBoardUseCase,
        _updateStartingBoardUseCase = updateStartingBoardUseCase,
        _updateProfilePermissionsUseCase = updateProfilePermissionsUseCase,
        _updateProfileSettingsUseCase = updateProfileSettingsUseCase,
        _lockProfileSettingsUseCase = lockProfileSettingsUseCase;

  // Load all profiles
  Future<void> loadProfiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profiles = await _getProfilesUseCase();
      _activeProfile = await _getActiveProfileUseCase();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available boards
  Future<void> loadAvailableBoards() async {
    try {
      _availableBoards = await _getAvailableBoardsUseCase();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Create new profile
  Future<void> createProfile({
    required String name,
    required ProfileType type,
    String? avatarPath,
    String? caregiverId,
    List<String>? assignedBoardIds,
    String? startingBoardId,
    ProfilePermissions? permissions,
    ProfileSettings? settings,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _createProfileUseCase(
        name: name,
        type: type,
        avatarPath: avatarPath,
        caregiverId: caregiverId,
        assignedBoardIds: assignedBoardIds,
        startingBoardId: startingBoardId,
        permissions: permissions,
        settings: settings,
      );
      await loadProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile
  Future<void> updateProfile(Profile profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _updateProfileUseCase(profile);
      await loadProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete profile
  Future<void> deleteProfile(String profileId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteProfileUseCase(profileId);
      await loadProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Switch to profile
  Future<void> switchProfile(String profileId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _switchProfileUseCase(profileId);
      await loadProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign board to profile
  Future<void> assignBoard(String profileId, String boardId) async {
    try {
      await _assignBoardUseCase(profileId, boardId);
      await loadProfiles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update starting board
  Future<void> updateStartingBoard(String profileId, String boardId) async {
    try {
      await _updateStartingBoardUseCase(profileId, boardId);
      await loadProfiles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update permissions
  Future<void> updatePermissions(String profileId, ProfilePermissions permissions) async {
    try {
      await _updateProfilePermissionsUseCase(profileId, permissions);
      await loadProfiles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update settings
  Future<void> updateSettings(String profileId, ProfileSettings settings) async {
    try {
      await _updateProfileSettingsUseCase(profileId, settings);
      await loadProfiles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Lock/unlock settings
  Future<void> lockSettings(String profileId, bool locked) async {
    try {
      await _lockProfileSettingsUseCase(profileId, locked);
      await loadProfiles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 9. Presentation Layer - UI Components

### Profile List Widget

```dart
// lib/presentation/widgets/profile_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileListWidget extends ConsumerWidget {
  final Function(Profile) onProfileTap;
  final Function(Profile)? onProfileEdit;
  final Function(Profile)? onProfileDelete;

  const ProfileListWidget({
    super.key,
    required this.onProfileTap,
    this.onProfileEdit,
    this.onProfileDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(profileViewModelProvider);

    return viewModel.isLoading
        ? const Center(child: CircularProgressIndicator())
        : viewModel.errorMessage != null
            ? Center(child: Text(viewModel.errorMessage!))
            : ListView.builder(
                itemCount: viewModel.profiles.length,
                itemBuilder: (context, index) {
                  final profile = viewModel.profiles[index];
                  final isActive = viewModel.activeProfile?.id == profile.id;

                  return ProfileCard(
                    profile: profile,
                    isActive: isActive,
                    onTap: () => onProfileTap(profile),
                    onEdit: onProfileEdit,
                    onDelete: onProfileDelete,
                  );
                },
              );
  }
}

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final VoidCallback onTap;
  final Function(Profile)? onEdit;
  final Function(Profile)? onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.isActive,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profile.avatarPath != null
              ? AssetImage(profile.avatarPath!)
              : null,
          child: profile.avatarPath == null
              ? Text(profile.name[0].toUpperCase())
              : null,
        ),
        title: Text(profile.name),
        subtitle: Text(profile.type.displayName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              const Icon(Icons.check_circle, color: Colors.green),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit!(profile),
              ),
            if (onDelete != null && !isActive)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDelete!(profile),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
```

### Profile Editor Widget

```dart
// lib/presentation/widgets/profile_editor_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_type.dart';
import '../../domain/entities/profile_permissions.dart';
import '../../domain/entities/profile_settings.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileEditorWidget extends ConsumerStatefulWidget {
  final Profile? profile;

  const ProfileEditorWidget({super.key, this.profile});

  @override
  ConsumerState<ProfileEditorWidget> createState() => _ProfileEditorWidgetState();
}

class _ProfileEditorWidgetState extends ConsumerState<ProfileEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late ProfileType _selectedType;
  String? _avatarPath;
  List<String> _assignedBoardIds = [];
  String _startingBoardId = '';
  late ProfilePermissions _permissions;
  late ProfileSettings _settings;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _selectedType = widget.profile?.type ?? ProfileType.child;
    _avatarPath = widget.profile?.avatarPath;
    _assignedBoardIds = widget.profile?.assignedBoardIds ?? [];
    _startingBoardId = widget.profile?.startingBoardId ?? '';
    _permissions = widget.profile?.permissions ?? ProfilePermissions.defaultForType(_selectedType);
    _settings = widget.profile?.settings ?? ProfileSettings.defaultSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveProfile(viewModel),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarPath != null
                        ? AssetImage(_avatarPath!)
                        : null,
                    child: _avatarPath == null
                        ? Text(_nameController.text.isEmpty
                            ? '?'
                            : _nameController.text[0].toUpperCase())
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => _pickAvatar(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Profile Type
            DropdownButtonFormField<ProfileType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Profile Type',
                border: OutlineInputBorder(),
              ),
              items: ProfileType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.displayName),
                      Text(
                        type.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _permissions = ProfilePermissions.defaultForType(value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Starting Board
            DropdownButtonFormField<String>(
              value: _startingBoardId.isEmpty ? null : _startingBoardId,
              decoration: const InputDecoration(
                labelText: 'Starting Board',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select starting board'),
              items: viewModel.availableBoards.map((board) {
                return DropdownMenuItem(
                  value: board.boardId,
                  child: Text(board.boardName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _startingBoardId = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),

            // Assigned Boards
            ExpansionTile(
              title: const Text('Assigned Boards'),
              children: [
                CheckboxListTile(
                  title: const Text('All Boards'),
                  value: _assignedBoardIds.isEmpty,
                  onChanged: (value) {
                    setState(() {
                      _assignedBoardIds = value == true ? [] : viewModel.availableBoards.map((b) => b.boardId).toList();
                    });
                  },
                ),
                ...viewModel.availableBoards.map((board) {
                  return CheckboxListTile(
                    title: Text(board.boardName),
                    subtitle: board.isSubBoard ? const Text('Subboard') : null,
                    value: _assignedBoardIds.contains(board.boardId) || _assignedBoardIds.isEmpty,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _assignedBoardIds.add(board.boardId);
                        } else {
                          _assignedBoardIds.remove(board.boardId);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Permissions
            ExpansionTile(
              title: const Text('Permissions'),
              children: [
                _buildPermissionCheckbox('Can Edit Boards', _permissions.canEditBoards, (value) {
                  setState(() => _permissions = _permissions.copyWith(canEditBoards: value));
                }),
                _buildPermissionCheckbox('Can Create Boards', _permissions.canCreateBoards, (value) {
                  setState(() => _permissions = _permissions.copyWith(canCreateBoards: value));
                }),
                _buildPermissionCheckbox('Can Delete Boards', _permissions.canDeleteBoards, (value) {
                  setState(() => _permissions = _permissions.copyWith(canDeleteBoards: value));
                }),
                _buildPermissionCheckbox('Can Share Boards', _permissions.canShareBoards, (value) {
                  setState(() => _permissions = _permissions.copyWith(canShareBoards: value));
                }),
                _buildPermissionCheckbox('Can Access Settings', _permissions.canAccessSettings, (value) {
                  setState(() => _permissions = _permissions.copyWith(canAccessSettings: value));
                }),
                _buildPermissionCheckbox('Can Edit Settings', _permissions.canEditSettings, (value) {
                  setState(() => _permissions = _permissions.copyWith(canEditSettings: value));
                }),
                _buildPermissionCheckbox('Can Manage Profiles', _permissions.canManageProfiles, (value) {
                  setState(() => _permissions = _permissions.copyWith(canManageProfiles: value));
                }),
                _buildPermissionCheckbox('Can Access Cloud Sync', _permissions.canAccessCloudSync, (value) {
                  setState(() => _permissions = _permissions.copyWith(canAccessCloudSync: value));
                }),
                _buildPermissionCheckbox('Can Switch Profiles', _permissions.canSwitchProfiles, (value) {
                  setState(() => _permissions = _permissions.copyWith(canSwitchProfiles: value));
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Settings Lock
            SwitchListTile(
              title: const Text('Lock Settings'),
              subtitle: const Text('Prevent this profile from changing settings'),
              value: _settings.locked,
              onChanged: (value) {
                setState(() => _settings = _settings.copyWith(locked: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _pickAvatar() async {
    // Implement image picker
  }

  Future<void> _saveProfile(ProfileViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.profile == null) {
      await viewModel.createProfile(
        name: _nameController.text,
        type: _selectedType,
        avatarPath: _avatarPath,
        assignedBoardIds: _assignedBoardIds,
        startingBoardId: _startingBoardId,
        permissions: _permissions,
        settings: _settings,
      );
    } else {
      final updatedProfile = widget.profile!.copyWith(
        name: _nameController.text,
        type: _selectedType,
        avatarPath: _avatarPath,
        assignedBoardIds: _assignedBoardIds,
        startingBoardId: _startingBoardId,
        permissions: _permissions,
        settings: _settings,
      );
      await viewModel.updateProfile(updatedProfile);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
```

### Profile Selector Widget

```dart
// lib/presentation/widgets/profile_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileSelectorWidget extends ConsumerWidget {
  final Function(Profile) onProfileSelected;

  const ProfileSelectorWidget({
    super.key,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(profileViewModelProvider);

    return viewModel.isLoading
        ? const Center(child: CircularProgressIndicator())
        : viewModel.errorMessage != null
            ? Center(child: Text(viewModel.errorMessage!))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                ),
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.profiles.length,
                itemBuilder: (context, index) {
                  final profile = viewModel.profiles[index];
                  final isActive = viewModel.activeProfile?.id == profile.id;

                  return ProfileSelectorCard(
                    profile: profile,
                    isActive: isActive,
                    onTap: () => onProfileSelected(profile),
                  );
                },
              );
  }
}

class ProfileSelectorCard extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final VoidCallback onTap;

  const ProfileSelectorCard({
    super.key,
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profile.avatarPath != null
                        ? AssetImage(profile.avatarPath!)
                        : null,
                    child: profile.avatarPath == null
                        ? Text(profile.name[0].toUpperCase())
                        : null,
                  ),
                  if (isActive)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                profile.type.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 10. Riverpod Providers

### Profile ViewModel Provider

```dart
// lib/presentation/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/profile/get_profiles_usecase.dart';
import '../../domain/usecases/profile/get_active_profile_usecase.dart';
import '../../domain/usecases/profile/create_profile_usecase.dart';
import '../../domain/usecases/profile/update_profile_usecase.dart';
import '../../domain/usecases/profile/delete_profile_usecase.dart';
import '../../domain/usecases/profile/switch_profile_usecase.dart';
import '../../domain/usecases/profile/get_available_boards_usecase.dart';
import '../../domain/usecases/profile/assign_board_usecase.dart';
import '../../domain/usecases/profile/update_starting_board_usecase.dart';
import '../../domain/usecases/profile/update_profile_permissions_usecase.dart';
import '../../domain/usecases/profile/update_profile_settings_usecase.dart';
import '../../domain/usecases/profile/lock_profile_settings_usecase.dart';
import '../viewmodels/profile_viewmodel.dart';

// Use case providers
final getProfilesUseCaseProvider = Provider<GetProfilesUseCase>((ref) {
  return GetProfilesUseCase(ref.watch(profileRepositoryProvider));
});

final getActiveProfileUseCaseProvider = Provider<GetActiveProfileUseCase>((ref) {
  return GetActiveProfileUseCase(ref.watch(profileRepositoryProvider));
});

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>((ref) {
  return CreateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final deleteProfileUseCaseProvider = Provider<DeleteProfileUseCase>((ref) {
  return DeleteProfileUseCase(ref.watch(profileRepositoryProvider));
});

final switchProfileUseCaseProvider = Provider<SwitchProfileUseCase>((ref) {
  return SwitchProfileUseCase(ref.watch(profileRepositoryProvider));
});

final getAvailableBoardsUseCaseProvider = Provider<GetAvailableBoardsUseCase>((ref) {
  return GetAvailableBoardsUseCase(ref.watch(profileRepositoryProvider));
});

final assignBoardUseCaseProvider = Provider<AssignBoardUseCase>((ref) {
  return AssignBoardUseCase(ref.watch(profileRepositoryProvider));
});

final updateStartingBoardUseCaseProvider = Provider<UpdateStartingBoardUseCase>((ref) {
  return UpdateStartingBoardUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfilePermissionsUseCaseProvider = Provider<UpdateProfilePermissionsUseCase>((ref) {
  return UpdateProfilePermissionsUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileSettingsUseCaseProvider = Provider<UpdateProfileSettingsUseCase>((ref) {
  return UpdateProfileSettingsUseCase(ref.watch(profileRepositoryProvider));
});

final lockProfileSettingsUseCaseProvider = Provider<LockProfileSettingsUseCase>((ref) {
  return LockProfileSettingsUseCase(ref.watch(profileRepositoryProvider));
});

// ViewModel provider
final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((ref) {
  return ProfileViewModel(
    getProfilesUseCase: ref.watch(getProfilesUseCaseProvider),
    getActiveProfileUseCase: ref.watch(getActiveProfileUseCaseProvider),
    createProfileUseCase: ref.watch(createProfileUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    deleteProfileUseCase: ref.watch(deleteProfileUseCaseProvider),
    switchProfileUseCase: ref.watch(switchProfileUseCaseProvider),
    getAvailableBoardsUseCase: ref.watch(getAvailableBoardsUseCaseProvider),
    assignBoardUseCase: ref.watch(assignBoardUseCaseProvider),
    updateStartingBoardUseCase: ref.watch(updateStartingBoardUseCaseProvider),
    updateProfilePermissionsUseCase: ref.watch(updateProfilePermissionsUseCaseProvider),
    updateProfileSettingsUseCase: ref.watch(updateProfileSettingsUseCaseProvider),
    lockProfileSettingsUseCase: ref.watch(lockProfileSettingsUseCaseProvider),
  );
});
```

---

## 11. Summary

This Profile Management System provides:

1. **Profile Types** - Caregiver, Child, and Adult profiles with different default permissions
2. **Profile Entity** - Complete profile with avatar, type, assigned boards, starting board, permissions, and settings
3. **Permissions System** - Granular permissions for all app features
4. **Settings Locking** - Ability to lock settings for specific profiles (e.g., child profiles)
5. **Board Assignment** - Assign specific boards to profiles with starting board selection
6. **All Boards Available** - All existing and future boards/subboards appear in settings as options
7. **Repository Pattern** - Clean separation of data access
8. **Use Cases** - Business logic for all profile operations
9. **ViewModel** - State management with ChangeNotifier
10. **UI Components** - Profile list, editor, and selector widgets
11. **Riverpod Providers** - Dependency injection and state management

The system ensures that:
- Caregivers have full access to all features
- Child profiles have restricted access with locked settings
- Adult profiles have standard access
- All boards (including subboards) are available for assignment
- Starting board can be set for each profile
- Settings can be locked to prevent changes by specific profiles

---

**Related Documents:**
- [ROOM_DATABASE_SCHEMA.md](ROOM_DATABASE_SCHEMA.md)
- [AAC_CORE_ENGINE.md](AAC_CORE_ENGINE.md)
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
