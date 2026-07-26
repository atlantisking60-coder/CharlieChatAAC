import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pin_lock_model.dart';
import '../providers/pin_lock_provider.dart';
import 'pin_input_screen.dart';

/// Wraps any widget tree and intercepts navigation when the PIN lock is active.
/// Drop this at the root of the app (inside ProviderScope) just below MaterialApp.
///
/// Usage:
///   home: PinLockGuard(child: MyHomePage()),
class PinLockGuard extends ConsumerWidget {
  const PinLockGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pinLockProvider).status;

    // Still loading config from secure storage
    if (status == PinLockStatus.notConfigured) {
      // Not configured — pass through normally
      return _ActivityDetector(child: child);
    }

    if (status == PinLockStatus.unlocked) {
      return _ActivityDetector(child: child);
    }

    // Locked or lockedOut — show PIN screen instead
    return const PinInputScreen();
  }
}

/// Wraps the child in a GestureDetector that resets the inactivity timer
/// on any tap/scroll/key event.
class _ActivityDetector extends ConsumerWidget {
  const _ActivityDetector({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => ref.read(pinLockProvider.notifier).recordActivity(),
      onPanDown: (_) => ref.read(pinLockProvider.notifier).recordActivity(),
      child: Listener(
        onPointerDown: (_) => ref.read(pinLockProvider.notifier).recordActivity(),
        child: child,
      ),
    );
  }
}

/// A button that locks the app immediately — place in the caregiver toolbar.
class LockNowButton extends ConsumerWidget {
  const LockNowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(pinLockProvider).config;
    if (!config.isEnabled) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.lock_outline),
      tooltip: 'Lock app',
      onPressed: () => ref.read(pinLockProvider.notifier).lockNow(),
    );
  }
}

/// Guards a single widget/route behind a permission check.
/// If locked, replaces child with a "permission denied" placeholder.
///
/// Usage:
///   PermissionGuard(
///     permission: PinPermission.accessSettings,
///     child: SettingsScreen(),
///   )
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.placeholder,
  });

  final PinPermission permission;
  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(pinPermissionProvider(permission));
    if (allowed) return child;
    return placeholder ?? _DefaultDenied(permission: permission);
  }
}

class _DefaultDenied extends StatelessWidget {
  const _DefaultDenied({required this.permission});
  final PinPermission permission;

  static const _labels = {
    PinPermission.editSymbols: 'edit symbols',
    PinPermission.editBoards: 'edit boards',
    PinPermission.accessSettings: 'access settings',
    PinPermission.exportData: 'export data',
    PinPermission.viewProfiles: 'view profiles',
    PinPermission.editProfiles: 'edit profiles',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need caregiver permission to ${_labels[permission] ?? permission.name}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
