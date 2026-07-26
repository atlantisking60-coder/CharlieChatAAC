import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pin_lock_model.dart';
import '../providers/pin_lock_provider.dart';

/// Caregiver-facing screen to configure or change the PIN lock.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  String? _error;
  bool _loading = false;
  String? _recoveryCode; // shown after successful setup

  @override
  void dispose() {
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    final pin = _pin1Ctrl.text.trim();
    final confirm = _pin2Ctrl.text.trim();

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'PIN must be exactly 4 digits');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final code = await ref.read(pinLockProvider.notifier).setupPin(pin);
      if (mounted) setState(() { _loading = false; _recoveryCode = code; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _disablePin() async {
    final confirmed = await _confirmDisable();
    if (!confirmed || !mounted) return;
    await ref.read(pinLockProvider.notifier).disablePin();
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirmDisable() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable PIN Lock'),
        content: const Text('Are you sure? Anyone will be able to access settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinLockProvider);
    final isEnabled = pinState.config.isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnabled ? 'Change PIN' : 'Set Up PIN Lock'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _recoveryCode != null
            ? _RecoveryCodeDisplay(code: _recoveryCode!, onDone: () => Navigator.pop(context))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _InfoCard(),
                  const SizedBox(height: 24),

                  const Text('New PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _PinField(controller: _pin1Ctrl, hint: '4-digit PIN'),
                  const SizedBox(height: 16),

                  const Text('Confirm PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _PinField(controller: _pin2Ctrl, hint: 'Repeat PIN'),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],

                  const SizedBox(height: 24),

                  // ── Permissions section ────────────────────────────────────
                  const Text('User Permissions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('What locked users can do without the PIN:',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...PinPermission.values.map((p) => _PermissionTile(permission: p)),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _setupPin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEnabled ? 'Update PIN' : 'Enable PIN Lock',
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ),

                  if (isEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _disablePin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Disable PIN Lock', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],

                  // ── Timeout settings ───────────────────────────────────────
                  const SizedBox(height: 32),
                  const _TimeoutSettings(),
                ],
              ),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'The PIN lock prevents users from accessing settings, profiles, '
              'or symbol editing without caregiver approval. '
              'A recovery code will be shown once — store it safely.',
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PIN field ─────────────────────────────────────────────────────────────────

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Permission tile ───────────────────────────────────────────────────────────

class _PermissionTile extends ConsumerWidget {
  const _PermissionTile({required this.permission});
  final PinPermission permission;

  static const _labels = {
    PinPermission.editSymbols: 'Edit symbols',
    PinPermission.editBoards: 'Edit boards',
    PinPermission.accessSettings: 'Access settings',
    PinPermission.exportData: 'Export data',
    PinPermission.viewProfiles: 'View profiles',
    PinPermission.editProfiles: 'Edit profiles',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(pinLockProvider).config.hasPermission(permission);
    return SwitchListTile(
      value: allowed,
      onChanged: (v) => ref.read(pinLockProvider.notifier).setPermission(permission, v),
      title: Text(_labels[permission] ?? permission.name),
      dense: true,
    );
  }
}

// ── Timeout settings ──────────────────────────────────────────────────────────

class _TimeoutSettings extends ConsumerStatefulWidget {
  const _TimeoutSettings();

  @override
  ConsumerState<_TimeoutSettings> createState() => _TimeoutSettingsState();
}

class _TimeoutSettingsState extends ConsumerState<_TimeoutSettings> {
  static const _options = [60, 120, 300, 600, 1800, 0];
  static const _labels = ['1 min', '2 min', '5 min', '10 min', '30 min', 'Never'];

  @override
  Widget build(BuildContext context) {
    final timeout = ref.watch(pinLockProvider).config.timeoutSeconds;
    final maxAttempts = ref.watch(pinLockProvider).config.maxAttempts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Timeout Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        const Text('Lock after inactivity:', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _options.contains(timeout) ? timeout : 300,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: List.generate(_options.length, (i) =>
            DropdownMenuItem(value: _options[i], child: Text(_labels[i]))),
          onChanged: (v) {
            if (v != null) {
              ref.read(pinLockProvider.notifier).updateSettings(timeoutSeconds: v);
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('Max failed attempts:', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: [3, 5, 10].contains(maxAttempts) ? maxAttempts : 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 3, child: Text('3 attempts')),
            DropdownMenuItem(value: 5, child: Text('5 attempts')),
            DropdownMenuItem(value: 10, child: Text('10 attempts')),
          ],
          onChanged: (v) {
            if (v != null) {
              ref.read(pinLockProvider.notifier).updateSettings(maxAttempts: v);
            }
          },
        ),
      ],
    );
  }
}

// ── Recovery code display ─────────────────────────────────────────────────────

class _RecoveryCodeDisplay extends StatelessWidget {
  const _RecoveryCodeDisplay({required this.code, required this.onDone});
  final String code;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
        const SizedBox(height: 20),
        const Text('PIN Lock Enabled!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
          'Save your recovery code in a safe place.\nIt will NOT be shown again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300, width: 2),
          ),
          child: Column(
            children: [
              const Text('Recovery Code',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber)),
              const SizedBox(height: 12),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("I've saved my code", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
