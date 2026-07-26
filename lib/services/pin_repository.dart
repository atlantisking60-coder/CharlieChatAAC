import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pin_lock_model.dart';

/// Keys used in secure storage
class _Keys {
  static const config = 'pin_lock_config';
  static const recoveryCode = 'pin_recovery_code';
}

/// Repository: all PIN persistence goes through here.
/// Sensitive data (hashed PIN, salt, recovery code) lives in
/// flutter_secure_storage (Keystore on Android, Keychain on iOS).
class PinRepository {
  PinRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  // ── Read ────────────────────────────────────────────────────────────────────

  Future<PinLockConfig> loadConfig() async {
    final raw = await _storage.read(key: _Keys.config);
    if (raw == null) return const PinLockConfig();
    try {
      return PinLockConfig.fromJsonString(raw);
    } catch (_) {
      return const PinLockConfig();
    }
  }

  Future<String?> loadRecoveryCode() =>
      _storage.read(key: _Keys.recoveryCode);

  // ── Write ───────────────────────────────────────────────────────────────────

  Future<void> saveConfig(PinLockConfig config) =>
      _storage.write(key: _Keys.config, value: config.toJsonString());

  Future<void> saveRecoveryCode(String code) =>
      _storage.write(key: _Keys.recoveryCode, value: code);

  // ── Crypto helpers ──────────────────────────────────────────────────────────

  /// Generates a cryptographically random 16-byte hex salt.
  String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// SHA-256( pin + salt )
  String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin$salt');
    return sha256.convert(bytes).toString();
  }

  /// Generates a 6-character alphanumeric recovery code.
  String generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.delete(key: _Keys.config);
    await _storage.delete(key: _Keys.recoveryCode);
  }
}
