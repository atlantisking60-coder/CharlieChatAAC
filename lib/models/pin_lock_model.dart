import 'dart:convert';

/// Represents a user role in the PIN lock system
enum PinUserRole {
  caregiver, // Full access, can set/change PIN
  user,      // Restricted access, cannot bypass lock
}

/// Represents a permission that can be granted/revoked per-role
enum PinPermission {
  editSymbols,
  editBoards,
  accessSettings,
  exportData,
  viewProfiles,
  editProfiles,
}

/// Immutable model describing the PIN lock configuration
class PinLockConfig {
  final bool isEnabled;
  final String? hashedPin;      // SHA-256 hash of PIN + salt
  final String? salt;           // Random per-installation salt
  final int maxAttempts;        // Default: 5
  final int timeoutSeconds;     // Lock timeout after inactivity (seconds)
  final int lockoutDurationSeconds; // Lockout after max failed attempts
  final DateTime? lastUnlocked;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final Map<PinPermission, bool> userPermissions;

  const PinLockConfig({
    this.isEnabled = false,
    this.hashedPin,
    this.salt,
    this.maxAttempts = 5,
    this.timeoutSeconds = 300,       // 5 minutes default
    this.lockoutDurationSeconds = 60, // 1 minute lockout
    this.lastUnlocked,
    this.failedAttempts = 0,
    this.lockedUntil,
    Map<PinPermission, bool>? userPermissions,
  }) : userPermissions = userPermissions ?? const {
    PinPermission.editSymbols: false,
    PinPermission.editBoards: false,
    PinPermission.accessSettings: false,
    PinPermission.exportData: false,
    PinPermission.viewProfiles: false,
    PinPermission.editProfiles: false,
  };

  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  bool get isConfigured => isEnabled && hashedPin != null && salt != null;

  Duration get remainingLockout {
    if (!isLockedOut) return Duration.zero;
    return lockedUntil!.difference(DateTime.now());
  }

  bool hasPermission(PinPermission permission) =>
      userPermissions[permission] ?? false;

  PinLockConfig copyWith({
    bool? isEnabled,
    String? hashedPin,
    String? salt,
    int? maxAttempts,
    int? timeoutSeconds,
    int? lockoutDurationSeconds,
    DateTime? lastUnlocked,
    int? failedAttempts,
    DateTime? lockedUntil,
    Map<PinPermission, bool>? userPermissions,
    bool clearLockedUntil = false,
    bool clearLastUnlocked = false,
  }) {
    return PinLockConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      hashedPin: hashedPin ?? this.hashedPin,
      salt: salt ?? this.salt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      lockoutDurationSeconds: lockoutDurationSeconds ?? this.lockoutDurationSeconds,
      lastUnlocked: clearLastUnlocked ? null : (lastUnlocked ?? this.lastUnlocked),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
      userPermissions: userPermissions ?? this.userPermissions,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'hashedPin': hashedPin,
    'salt': salt,
    'maxAttempts': maxAttempts,
    'timeoutSeconds': timeoutSeconds,
    'lockoutDurationSeconds': lockoutDurationSeconds,
    'lastUnlocked': lastUnlocked?.toIso8601String(),
    'failedAttempts': failedAttempts,
    'lockedUntil': lockedUntil?.toIso8601String(),
    'userPermissions': userPermissions.map(
      (k, v) => MapEntry(k.name, v),
    ),
  };

  factory PinLockConfig.fromJson(Map<String, dynamic> json) {
    final permJson = (json['userPermissions'] as Map<String, dynamic>?) ?? {};
    final perms = <PinPermission, bool>{};
    for (final p in PinPermission.values) {
      perms[p] = permJson[p.name] as bool? ?? false;
    }
    return PinLockConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      hashedPin: json['hashedPin'] as String?,
      salt: json['salt'] as String?,
      maxAttempts: json['maxAttempts'] as int? ?? 5,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 300,
      lockoutDurationSeconds: json['lockoutDurationSeconds'] as int? ?? 60,
      lastUnlocked: json['lastUnlocked'] != null
          ? DateTime.parse(json['lastUnlocked'] as String)
          : null,
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      lockedUntil: json['lockedUntil'] != null
          ? DateTime.parse(json['lockedUntil'] as String)
          : null,
      userPermissions: perms,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PinLockConfig.fromJsonString(String s) =>
      PinLockConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Sealed state for the PIN lock screen
enum PinLockStatus {
  unlocked,      // Caregiver has authenticated
  locked,        // Waiting for PIN
  lockedOut,     // Too many failed attempts, countdown active
  notConfigured, // No PIN set yet
}

/// Result of a PIN verification attempt
class PinVerifyResult {
  final bool success;
  final int remainingAttempts;
  final Duration? lockoutDuration;
  final String? message;

  const PinVerifyResult.success()
      : success = true, remainingAttempts = 0, lockoutDuration = null, message = null;

  const PinVerifyResult.failure({
    required this.remainingAttempts,
    this.lockoutDuration,
    this.message,
  }) : success = false;
}
