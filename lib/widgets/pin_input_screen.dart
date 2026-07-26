import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pin_lock_model.dart';
import '../providers/pin_lock_provider.dart';

/// Shown whenever the app is locked. Caregiver enters PIN to unlock.
class PinInputScreen extends ConsumerStatefulWidget {
  const PinInputScreen({super.key});

  @override
  ConsumerState<PinInputScreen> createState() => _PinInputScreenState();
}

class _PinInputScreenState extends ConsumerState<PinInputScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += d);
    if (_pin.length == _pinLength) {
      _submit();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final ok = await ref.read(pinLockProvider.notifier).verifyPin(_pin);
    if (!ok && mounted) {
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinLockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
                  const SizedBox(height: 24),
                  const Text(
                    'Caregiver PIN Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your 4-digit PIN to unlock',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // PIN dots
                  _PinDots(
                    filled: _pin.length,
                    shakeAnimation: _shakeAnimation,
                  ),
                  const SizedBox(height: 16),

                  // Error / lockout message
                  if (pinState.status == PinLockStatus.lockedOut)
                    _LockoutBanner(remaining: pinState.lockoutRemaining)
                  else if (pinState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        pinState.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Numpad
                  _Numpad(
                    onDigit: pinState.status == PinLockStatus.lockedOut ? null : _onDigit,
                    onDelete: pinState.status == PinLockStatus.lockedOut ? null : _onDelete,
                    onBiometric: null, // Hook in local_auth if desired
                  ),

                  const SizedBox(height: 32),

                  TextButton(
                    onPressed: () => _showRecoveryDialog(context),
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _RecoverySheet(),
    );
  }
}

// ── PIN dots ──────────────────────────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.shakeAnimation});

  final int filled;
  final Animation<double> shakeAnimation;
  static const _total = 4;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (_, child) {
        final offset = shakeAnimation.value == 0
            ? 0.0
            : 8.0 * (0.5 - (shakeAnimation.value % 0.25) / 0.25).abs();
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_total, (i) {
          final isFilled = i < filled;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.blueAccent : Colors.transparent,
              border: Border.all(
                color: isFilled ? Colors.blueAccent : Colors.white38,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Numpad ────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  final ValueChanged<String>? onDigit;
  final VoidCallback? onDelete;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
    ];

    return Column(
      children: [
        ...keys.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((d) => _NumKey(
            label: d,
            onTap: onDigit == null ? null : () => onDigit!(d),
          )).toList(),
        )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NumKey(
              icon: onBiometric != null ? Icons.fingerprint : null,
              label: onBiometric != null ? '' : ' ',
              onTap: onBiometric,
            ),
            _NumKey(
              label: '0',
              onTap: onDigit == null ? null : () => onDigit!('0'),
            ),
            _NumKey(
              icon: Icons.backspace_outlined,
              label: '',
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({this.label, this.icon, this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: Colors.white70, size: 26)
                  : Text(
                      label ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lockout banner ────────────────────────────────────────────────────────────

class _LockoutBanner extends StatelessWidget {
  const _LockoutBanner({required this.remaining});
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final secs = remaining?.inSeconds ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            'Locked. Try again in ${secs}s',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Recovery bottom sheet ─────────────────────────────────────────────────────

class _RecoverySheet extends ConsumerStatefulWidget {
  const _RecoverySheet();

  @override
  ConsumerState<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends ConsumerState<_RecoverySheet> {
  final _codeCtrl = TextEditingController();
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final pin = _pin1Ctrl.text.trim();
    final confirm = _pin2Ctrl.text.trim();

    if (code.isEmpty || pin.length != 4 || pin != confirm) {
      setState(() => _error = pin != confirm
          ? 'PINs do not match'
          : 'Please fill in all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final ok = await ref.read(pinLockProvider.notifier).resetWithRecovery(code, pin);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN reset successfully'), backgroundColor: Colors.green),
        );
      } else {
        setState(() { _loading = false; _error = 'Invalid recovery code'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reset PIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Enter the recovery code shown when PIN was created.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          _field(_codeCtrl, 'Recovery Code', false),
          const SizedBox(height: 12),
          _field(_pin1Ctrl, 'New PIN (4 digits)', true, maxLength: 4),
          const SizedBox(height: 12),
          _field(_pin2Ctrl, 'Confirm New PIN', true, maxLength: 4),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reset PIN', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, bool isPin, {int? maxLength}) {
    return TextField(
      controller: ctrl,
      obscureText: isPin,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        counterText: '',
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
