import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pin_lock_model.dart';
import '../services/pin_lock_service.dart';
import '../services/pin_repository.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final pinRepositoryProvider = Provider<PinRepository>((_) => PinRepository());

final pinLockServiceProvider = Provider<PinLockService>((ref) {
  return PinLockService(repository: ref.read(pinRepositoryProvider));
});

// ── UI state ──────────────────────────────────────────────────────────────────

class PinLockState {
  final PinLockStatus status;
  final PinLockConfig config;
  final int failedAttempts;
  final Duration? lockoutRemaining;
  final String? errorMessage;
  final bool isLoading;

  const PinLockState({
    this.status = PinLockStatus.notConfigured,
    this.config = const PinLockConfig(),
    this.failedAttempts = 0,
    this.lockoutRemaining,
    this.errorMessage,
    this.isLoading = false,
  });

  PinLockState copyWith({
    PinLockStatus? status,
    PinLockConfig? config,
    int? failedAttempts,
    Duration? lockoutRemaining,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return PinLockState(
      status: status ?? this.status,
      config: config ?? this.config,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutRemaining: clearLockout ? null : (lockoutRemaining ?? this.lockoutRemaining),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PinLockNotifier extends Notifier<PinLockState> {
  Timer? _lockoutTimer;
  Timer? _timeoutTimer;

  @override
  PinLockState build() {
    ref.onDispose(() {
      _lockoutTimer?.cancel();
      _timeoutTimer?.cancel();
    });
    _loadInitialState();
    return const PinLockState(isLoading: true);
  }

  PinLockService get _service => ref.read(pinLockServiceProvider);

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> _loadInitialState() async {
    final config = await _service.getConfig();
    final timedOut = await _service.hasTimedOut();

    PinLockStatus status;
    if (!config.isEnabled || !config.isConfigured) {
      status = PinLockStatus.notConfigured;
    } else if (config.isLockedOut) {
      status = PinLockStatus.lockedOut;
      _startLockoutCountdown(config.remainingLockout);
    } else if (timedOut) {
      status = PinLockStatus.locked;
    } else {
      status = PinLockStatus.unlocked;
    }

    state = PinLockState(
      status: status,
      config: config,
      failedAttempts: config.failedAttempts,
    );

    _startTimeoutWatcher();
  }

  // ── PIN actions ─────────────────────────────────────────────────────────────

  /// Verify PIN entered by caregiver.
  Future<bool> verifyPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.verifyPin(pin);
    final config = await _service.getConfig();

    if (result.success) {
      _lockoutTimer?.cancel();
      state = PinLockState(
        status: PinLockStatus.unlocked,
        config: config,
        failedAttempts: 0,
      );
      _startTimeoutWatcher();
      return true;
    }

    if (result.lockoutDuration != null) {
      state = state.copyWith(
        status: PinLockStatus.lockedOut,
        config: config,
        failedAttempts: config.failedAttempts,
        lockoutRemaining: result.lockoutDuration,
        errorMessage: result.message,
        isLoading: false,
      );
      _startLockoutCountdown(result.lockoutDuration!);
    } else {
      state = state.copyWith(
        status: PinLockStatus.locked,
        config: config,
        failedAttempts: config.failedAttempts,
        errorMessage: result.message,
        isLoading: false,
      );
    }
    return false;
  }

  /// Set up a new PIN (caregiver). Returns recovery code.
  Future<String> setupPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final recoveryCode = await _service.setupPin(pin);
    final config = await _service.getConfig();
    state = PinLockState(
      status: PinLockStatus.unlocked,
      config: config,
    );
    _startTimeoutWatcher();
    return recoveryCode;
  }

  /// Disable PIN lock (caregiver must be unlocked to call this).
  Future<void> disablePin() async {
    state = state.copyWith(isLoading: true);
    await _service.disablePin();
    _lockoutTimer?.cancel();
    _timeoutTimer?.cancel();
    state = const PinLockState(status: PinLockStatus.notConfigured);
  }

  /// Lock immediately (e.g. caregiver taps "Lock Now").
  void lockNow() {
    _timeoutTimer?.cancel();
    state = state.copyWith(
      status: PinLockStatus.locked,
      clearError: true,
    );
  }

  /// Reset PIN via recovery code.
  Future<bool> resetWithRecovery(String code, String newPin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final ok = await _service.resetWithRecoveryCode(code, newPin);
    if (ok) {
      final config = await _service.getConfig();
      state = PinLockState(
        status: PinLockStatus.unlocked,
        config: config,
      );
      _startTimeoutWatcher();
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid recovery code',
      );
    }
    return ok;
  }

  // ── Activity / timeout ──────────────────────────────────────────────────────

  /// Call on every significant user interaction to reset inactivity timer.
  Future<void> recordActivity() async {
    if (state.status != PinLockStatus.unlocked) return;
    await _service.recordActivity();
    _restartTimeoutWatcher();
  }

  void _startTimeoutWatcher() {
    _timeoutTimer?.cancel();
    final seconds = state.config.timeoutSeconds;
    if (seconds <= 0 || state.status != PinLockStatus.unlocked) return;
    _timeoutTimer = Timer(Duration(seconds: seconds), () {
      if (state.status == PinLockStatus.unlocked) {
        state = state.copyWith(status: PinLockStatus.locked);
      }
    });
  }

  void _restartTimeoutWatcher() {
    _timeoutTimer?.cancel();
    _startTimeoutWatcher();
  }

  // ── Lockout countdown ───────────────────────────────────────────────────────

  void _startLockoutCountdown(Duration duration) {
    _lockoutTimer?.cancel();
    var remaining = duration;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining -= const Duration(seconds: 1);
      if (remaining.isNegative || remaining == Duration.zero) {
        t.cancel();
        state = state.copyWith(
          status: PinLockStatus.locked,
          failedAttempts: 0,
          clearLockout: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(lockoutRemaining: remaining);
      }
    });
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<void> setPermission(PinPermission permission, bool allowed) async {
    await _service.setUserPermission(permission, allowed);
    final config = await _service.getConfig();
    state = state.copyWith(config: config);
  }

  // ── Settings ────────────────────────────────────────────────────────────────

  Future<void> updateSettings({
    int? timeoutSeconds,
    int? maxAttempts,
    int? lockoutDurationSeconds,
  }) async {
    await _service.updateSettings(
      timeoutSeconds: timeoutSeconds,
      maxAttempts: maxAttempts,
      lockoutDurationSeconds: lockoutDurationSeconds,
    );
    final config = await _service.getConfig();
    state = state.copyWith(config: config);
    _restartTimeoutWatcher();
  }
}

// ── Top-level providers ───────────────────────────────────────────────────────

final pinLockProvider =
    NotifierProvider<PinLockNotifier, PinLockState>(PinLockNotifier.new);

/// Convenience: is the app currently locked?
final pinIsLockedProvider = Provider<bool>((ref) {
  final status = ref.watch(pinLockProvider).status;
  return status == PinLockStatus.locked || status == PinLockStatus.lockedOut;
});

/// Convenience: does the current user-role have a given permission?
final pinPermissionProvider =
    Provider.family<bool, PinPermission>((ref, permission) {
  final s = ref.watch(pinLockProvider);
  // Unlocked = caregiver = full access
  if (s.status == PinLockStatus.unlocked) return true;
  return s.config.hasPermission(permission);
});
