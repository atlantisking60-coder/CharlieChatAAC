import '../models/pin_lock_model.dart';
import 'pin_repository.dart';

/// Business logic for the caregiver PIN lock system.
/// - Validates format (exactly 4 digits)
/// - Manages failed-attempt counter + lockout
/// - Tracks inactivity timeout
/// - Handles reset via recovery code
class PinLockService {
  PinLockService({PinRepository? repository})
      : _repo = repository ?? PinRepository();

  final PinRepository _repo;

  // ── Setup ───────────────────────────────────────────────────────────────────

  /// Creates or replaces the PIN. Returns the recovery code on success.
  Future<String> setupPin(String pin) async {
    _validatePinFormat(pin);
    final config = await _repo.loadConfig();
    final salt = _repo.generateSalt();
    final hashed = _repo.hashPin(pin, salt);
    final recoveryCode = _repo.generateRecoveryCode();

    final updated = config.copyWith(
      isEnabled: true,
      hashedPin: hashed,
      salt: salt,
      failedAttempts: 0,
      clearLockedUntil: true,
      lastUnlocked: DateTime.now(),
    );

    await _repo.saveConfig(updated);
    await _repo.saveRecoveryCode(_repo.hashPin(recoveryCode, salt));
    return recoveryCode; // Show once to caregiver, never stored plain
  }

  /// Disables PIN lock entirely (caregiver authenticated first).
  Future<void> disablePin() async {
    await _repo.clearAll();
  }

  // ── Verify ──────────────────────────────────────────────────────────────────

  Future<PinVerifyResult> verifyPin(String pin) async {
    var config = await _repo.loadConfig();

    if (!config.isConfigured) {
      return const PinVerifyResult.failure(
        remainingAttempts: 0,
        message: 'PIN not configured',
      );
    }

    // Still in lockout window
    if (config.isLockedOut) {
      return PinVerifyResult.failure(
        remainingAttempts: 0,
        lockoutDuration: config.remainingLockout,
        message: 'Too many attempts. Try again in ${config.remainingLockout.inSeconds}s',
      );
    }

    final hashed = _repo.hashPin(pin, config.salt!);
    if (hashed == config.hashedPin) {
      // ✅ Correct
      config = config.copyWith(
        failedAttempts: 0,
        lastUnlocked: DateTime.now(),
        clearLockedUntil: true,
      );
      await _repo.saveConfig(config);
      return const PinVerifyResult.success();
    }

    // ❌ Wrong — increment counter
    final newFailed = config.failedAttempts + 1;
    final remaining = config.maxAttempts - newFailed;

    if (newFailed >= config.maxAttempts) {
      final lockUntil = DateTime.now().add(
        Duration(seconds: config.lockoutDurationSeconds),
      );
      config = config.copyWith(
        failedAttempts: newFailed,
        lockedUntil: lockUntil,
      );
      await _repo.saveConfig(config);
      return PinVerifyResult.failure(
        remainingAttempts: 0,
        lockoutDuration: Duration(seconds: config.lockoutDurationSeconds),
        message: 'Locked out for ${config.lockoutDurationSeconds}s',
      );
    }

    config = config.copyWith(failedAttempts: newFailed);
    await _repo.saveConfig(config);
    return PinVerifyResult.failure(
      remainingAttempts: remaining,
      message: remaining == 1
          ? '1 attempt remaining before lockout'
          : '$remaining attempts remaining',
    );
  }

  // ── Recovery ─────────────────────────────────────────────────────────────────

  /// Resets the PIN using the caregiver's recovery code.
  /// Returns true if the code matched.
  Future<bool> resetWithRecoveryCode(String code, String newPin) async {
    _validatePinFormat(newPin);
    final config = await _repo.loadConfig();
    if (config.salt == null) return false;

    final storedHash = await _repo.loadRecoveryCode();
    if (storedHash == null) return false;

    final inputHash = _repo.hashPin(code.trim().toUpperCase(), config.salt!);
    if (inputHash != storedHash) return false;

    // Valid — set new PIN
    await setupPin(newPin);
    return true;
  }

  // ── Timeout ──────────────────────────────────────────────────────────────────

  /// Returns true if the session has timed out due to inactivity.
  Future<bool> hasTimedOut() async {
    final config = await _repo.loadConfig();
    if (!config.isEnabled || config.lastUnlocked == null) return false;
    final elapsed = DateTime.now().difference(config.lastUnlocked!);
    return elapsed.inSeconds >= config.timeoutSeconds;
  }

  /// Call this on any user interaction to reset the inactivity timer.
  Future<void> recordActivity() async {
    final config = await _repo.loadConfig();
    if (!config.isEnabled) return;
    await _repo.saveConfig(config.copyWith(lastUnlocked: DateTime.now()));
  }

  // ── Permissions ──────────────────────────────────────────────────────────────

  Future<void> setUserPermission(PinPermission permission, bool allowed) async {
    final config = await _repo.loadConfig();
    final perms = Map<PinPermission, bool>.from(config.userPermissions);
    perms[permission] = allowed;
    await _repo.saveConfig(config.copyWith(userPermissions: perms));
  }

  Future<bool> checkPermission(PinPermission permission) async {
    final config = await _repo.loadConfig();
    return config.hasPermission(permission);
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  Future<void> updateSettings({
    int? timeoutSeconds,
    int? maxAttempts,
    int? lockoutDurationSeconds,
  }) async {
    final config = await _repo.loadConfig();
    await _repo.saveConfig(config.copyWith(
      timeoutSeconds: timeoutSeconds,
      maxAttempts: maxAttempts,
      lockoutDurationSeconds: lockoutDurationSeconds,
    ));
  }

  Future<PinLockConfig> getConfig() => _repo.loadConfig();

  // ── Private ──────────────────────────────────────────────────────────────────

  void _validatePinFormat(String pin) {
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
  }
}
