import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'settings_service.dart';
import 'sync_service.dart';

/// USER PROFILE MODEL
/// Each profile contains a unique name, a set of AppSettings (voice, theme, etc.),
/// and custom data like tab order and preferred symbol categories.

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
  final String onlineId;
  final String role;
  final bool syncEnabled;
  final String? lastSyncedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.settings,
    this.tabOrder = const [],
    this.preferredSymbolSets = const [],
    this.startingBoardId = '',
    this.username,
    this.password,
    this.isAdmin = false,
    this.onlineId = '',
    this.role = 'user',
    this.syncEnabled = false,
    this.lastSyncedAt,
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
    String? onlineId,
    String? role,
    bool? syncEnabled,
    String? lastSyncedAt,
    bool clearLastSyncedAt = false,
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
      onlineId: onlineId ?? this.onlineId,
      role: role ?? this.role,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'settings': settings.toMap(),
        'tabOrder': tabOrder,
        'preferredSymbolSets': preferredSymbolSets,
        'startingBoardId': startingBoardId,
        'username': username,
        'password': password,
        'isAdmin': isAdmin,
        'onlineId': onlineId,
        'role': role,
        'syncEnabled': syncEnabled,
        'lastSyncedAt': lastSyncedAt,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Profile',
        settings:
            AppSettings.fromMap(Map<String, dynamic>.from(m['settings'] ?? {})),
        tabOrder: (m['tabOrder'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        preferredSymbolSets: (m['preferredSymbolSets'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        startingBoardId: m['startingBoardId'] ?? '',
        username: m['username'],
        password: m['password'],
        isAdmin: m['isAdmin'] ?? false,
        onlineId: m['onlineId'] ?? '',
        role: m['role'] ?? 'user',
        syncEnabled: m['syncEnabled'] ?? false,
        lastSyncedAt: m['lastSyncedAt']?.toString(),
      );

  static UserProfile defaultProfile() => UserProfile(
        id: 'default',
        name: 'Default',
        onlineId: 'default',
        role: 'default',
        settings: const AppSettings(
          profileImage: 'assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png',
          themeMode: ThemeMode.light,
          voiceRate: 0.80,
          voicePitch: 1.0,
          voiceVolume: 1.0,
          voiceLanguage: 'en-GB',
          voiceName: 'Google UK English Female',
        ),
        tabOrder: [],
        preferredSymbolSets: const ['In App Assets'],
      );
}

/// PROFILE MANAGEMENT SERVICE
/// This service manages multiple users within the same app. 
/// It handles profile creation, deletion, and "switching" by 
/// saving the active profile ID in memory.
///
class ProfileService {
  static const _profilesKey = 'aac_user_profiles';
  static const _activeProfileKey = 'aac_active_profile';

  final SharedPreferences _prefs;

  ProfileService._(this._prefs);

  static Future<ProfileService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = ProfileService._(prefs);
    
    bool profilesChanged = false;
    final profiles = service.profiles;

    /** 1. Ensure Default profile exists and is first **/
    if (!profiles.any((p) => p.id == 'default' || p.name.toLowerCase() == 'default')) {
      profiles.insert(0, UserProfile.defaultProfile());
      profilesChanged = true;
    }

    /** 2. Migration: Ensure all profiles named 'Default' have ID 'default' and Admin has correct password **/
    for (int i = 0; i < profiles.length; i++) {
      var p = profiles[i];

      // Normalize asset-style profile images that are missing the assets/ prefix.
      final img = p.settings.profileImage;
      if (img.isNotEmpty &&
          !img.startsWith('assets/') &&
          !img.startsWith('data:') &&
          !img.startsWith('http') &&
          !img.startsWith('/') &&
          !img.contains(':')) {
        p = p.copyWith(settings: p.settings.copyWith(profileImage: 'assets/$img'));
        profiles[i] = p;
        profilesChanged = true;
      }
      if (p.name.toLowerCase() == 'default' && p.id != 'default') {
        final oldId = p.id;
        profiles[i] = p.copyWith(id: 'default');
        profilesChanged = true;
        
        // Update active profile pointer
        if (prefs.getString(_activeProfileKey) == oldId) {
          await prefs.setString(_activeProfileKey, 'default');
        }

        // CRITICAL: Migrate board data to the new ID
        final keys = prefs.getKeys().where((k) => k.startsWith('board_${oldId}_'));
        for (final key in keys) {
          final boardData = prefs.getString(key);
          if (boardData != null) {
            final newKey = key.replaceFirst('board_${oldId}_', 'board_default_');
            await prefs.setString(newKey, boardData);
          }
        }
      }
      
      // Fix admin password migration and ensure it has preferred symbol sets
      if (p.id == 'admin') {
        bool changed = false;
        String? newPassword = p.password;
        List<String> newPreferredSets = p.preferredSymbolSets;

        if (p.password == 'Baycr0ft' || p.password == null) {
          newPassword = 'baycr0ft';
          changed = true;
        }
        if (p.preferredSymbolSets.isEmpty) {
          newPreferredSets = const ['In App Assets'];
          changed = true;
        }

        if (changed) {
          profiles[i] = p.copyWith(password: newPassword, preferredSymbolSets: newPreferredSets);
          profilesChanged = true;
        }
      }

      // Ensure the default and admin profiles use the proper app icon if they have the logo or baycroft icon.
      final isDefaultOrAdmin = p.id == 'default' || p.id == 'admin';
      final hasWrongIcon = p.settings.profileImage == 'assets/Logos and Profile Pics/charlie_chat_aac_logo.png' || 
                           p.settings.profileImage == 'assets/symbols/baycroft.png';
      
      if (isDefaultOrAdmin && hasWrongIcon) {
        profiles[i] = p.copyWith(
          settings: p.settings.copyWith(profileImage: 'assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png'),
        );
        profilesChanged = true;
      }

      p = profiles[i];
      if (p.onlineId.isEmpty) {
        p = p.copyWith(onlineId: _generateOnlineIdFor(p));
        profilesChanged = true;
      }
      if (p.role.isEmpty || p.role == 'user') {
        final expectedRole = _roleFor(p);
        if (p.role != expectedRole) {
          p = p.copyWith(role: expectedRole);
          profilesChanged = true;
        }
      }
      profiles[i] = p;
    }

    /** 3. Ensure Admin profile exists **/
    if (!profiles.any((p) => p.id == 'admin')) {
      final globalSettings = await SettingsService.init();
      profiles.add(UserProfile(
        id: 'admin',
        name: 'Admin',
        username: 'admin',
        password: 'baycr0ft',
        isAdmin: true,
        onlineId: 'admin',
        role: 'admin',
        settings: globalSettings.settings.copyWith(
          profileImage: 'assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png',
          themeMode: ThemeMode.light,
        ),
        tabOrder: [],
        preferredSymbolSets: const ['In App Assets'],
      ));
      profilesChanged = true;
    }

    /** 4. Ensure Baycroft profile exists **/
    if (!profiles.any((p) => p.id == 'baycroft' || p.name.toLowerCase() == 'baycroft')) {
      final globalSettings = await SettingsService.init();
      profiles.add(UserProfile(
        id: 'baycroft',
        name: 'Baycroft',
        username: 'baycroft',
        password: 'baycr0ft',
        isAdmin: false,
        onlineId: 'baycroft',
        role: 'user',
        settings: globalSettings.settings.copyWith(
          profileImage: 'assets/My School/baycroft.png',
          themeMode: ThemeMode.light,
        ),
        tabOrder: [],
        preferredSymbolSets: const ['In App Assets'],
      ));
      profilesChanged = true;
    }

    if (profilesChanged) {
      await service.saveProfiles(profiles, recordSync: false);
    }

    return service;
  }

  /// PROFILES GETTER
  /// Decodes a JSON string from storage into a list of Profile objects.
  ///
  static const _backupKey = 'aac_user_profiles_backup';

  List<UserProfile> get profiles {
    final raw = _prefs.getString(_profilesKey);
    if (raw == null || raw.isEmpty) {
      // Try backup
      final backup = _prefs.getString(_backupKey);
      if (backup != null && backup.isNotEmpty) {
        debugPrint('Profiles primary empty, restoring from backup');
        try {
          final decoded = json.decode(backup) as List<dynamic>;
          final result = decoded
              .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          if (result.isNotEmpty) {
            // Restore primary from backup
            _prefs.setString(_profilesKey, backup);
            return result;
          }
        } catch (_) {
          debugPrint('Backup also corrupted');
        }
      }
      return [];
    }
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Profile JSON parse error: $e');
      // Try backup
      final backup = _prefs.getString(_backupKey);
      if (backup != null && backup.isNotEmpty) {
        debugPrint('Restoring profiles from backup');
        try {
          final decoded = json.decode(backup) as List<dynamic>;
          final result = decoded
              .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          if (result.isNotEmpty) {
            _prefs.setString(_profilesKey, backup);
            return result;
          }
        } catch (_) {
          debugPrint('Backup also corrupted');
        }
      }
      return [];
    }
  }

  /// ACTIVE PROFILE GETTER
  /// Identifies which user is currently logged in.
  ///
  UserProfile get activeProfile {
    final profiles = this.profiles;
    final activeId = _prefs.getString(_activeProfileKey);
    if (activeId != null) {
      final profile = profiles.firstWhere(
        (profile) => profile.id == activeId,
        orElse: () =>
            profiles.isNotEmpty ? profiles.first : UserProfile.defaultProfile(),
      );
      return profile;
    }
    return profiles.isNotEmpty ? profiles.first : UserProfile.defaultProfile();
  }

  Future<void> setActiveProfile(String id) async {
    await _prefs.setString(_activeProfileKey, id);
  }

  Future<bool> authenticate(String username, String password) async {
    try {
      final profiles = this.profiles;
      final profile = profiles.firstWhere(
        (p) =>
            (p.username == username || p.name == username) &&
            p.password == password,
        orElse: () => UserProfile(
          id: '',
          name: '',
          settings: const AppSettings(
            themeMode: ThemeMode.light,
            voiceRate: 0.80,
            voicePitch: 1.0,
            voiceVolume: 1.0,
          ),
        ),
      );
      return profile.id.isNotEmpty;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  Future<void> saveProfiles(
    List<UserProfile> profiles, {
    bool recordSync = true,
  }) async {
    // Backup current profiles before overwriting
    final current = _prefs.getString(_profilesKey);
    if (current != null && current.isNotEmpty) {
      _prefs.setString(_backupKey, current);
    }
    await _prefs.setString(
        _profilesKey, json.encode(profiles.map((p) => p.toMap()).toList()));
    if (recordSync) {
      final sync = await SyncService.init();
      await sync.recordChange(
        entityType: SyncEntityType.profile,
        entityId: 'collection',
        operation: SyncOperation.upsert,
        payload: {'profiles': profiles.map((p) => p.toMap()).toList()},
      );
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final profiles = this.profiles;
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await saveProfiles(profiles, recordSync: false);
    await _recordProfileChange(profile, SyncOperation.upsert);
  }

  Future<void> createProfile(UserProfile profile) async {
    var p = profile;
    if (p.onlineId.isEmpty) {
      p = p.copyWith(onlineId: const Uuid().v4());
    }
    if (p.role.isEmpty) {
      p = p.copyWith(role: 'user');
    }
    final profiles = this.profiles;
    profiles.add(p);
    await saveProfiles(profiles, recordSync: false);
    await _recordProfileChange(p, SyncOperation.upsert);
    await setActiveProfile(p.id);
  }

  Future<void> deleteProfile(String id) async {
    final profiles =
        this.profiles.where((profile) => profile.id != id).toList();
    await saveProfiles(profiles, recordSync: false);
    await _recordProfileChange(
      UserProfile(
        id: id,
        name: '',
        settings: const AppSettings(
          themeMode: ThemeMode.system,
          voiceRate: 0.80,
          voicePitch: 1.0,
          voiceVolume: 1.0,
        ),
      ),
      SyncOperation.delete,
    );
    if (_prefs.getString(_activeProfileKey) == id) {
      final nextProfile =
          profiles.isNotEmpty ? profiles.first : UserProfile.defaultProfile();
      if (!profiles.any((p) => p.id == nextProfile.id)) {
        profiles.add(nextProfile);
        await saveProfiles(profiles, recordSync: false);
      }
      await setActiveProfile(nextProfile.id);
    }
  }

  Future<void> _recordProfileChange(
    UserProfile profile,
    SyncOperation operation,
  ) async {
    final sync = await SyncService.init();
    await sync.recordChange(
      entityType: SyncEntityType.profile,
      entityId: profile.id,
      operation: operation,
      payload: operation == SyncOperation.delete ? const {} : profile.toMap(),
    );
  }

  static String _generateOnlineIdFor(UserProfile p) {
    if (p.id == 'default') return 'default';
    if (p.id == 'admin') return 'admin';
    return const Uuid().v4();
  }

  static String _roleFor(UserProfile p) {
    if (p.id == 'default') return 'default';
    if (p.id == 'admin' || p.isAdmin) return 'admin';
    return 'user';
  }
}
