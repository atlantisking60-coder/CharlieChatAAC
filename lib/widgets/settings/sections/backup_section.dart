import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/backup_service.dart';
import '../settings_widgets.dart';

class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  double? _progress;
  bool _busy = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _doBackup() async {
    setState(() { _busy = true; _progress = 0; _statusMessage = null; _isError = false; });
    try {
      final svc = await BackupService.init();
      await svc.backupToDevice(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() { _busy = false; _progress = null; _statusMessage = 'Backup complete'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _busy = false; _progress = null; _statusMessage = 'Backup failed: $e'; _isError = true; });
      }
    }
  }

  Future<void> _doRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
            'This will overwrite your current boards and settings with the backup. '
            'This cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _busy = true; _progress = 0; _statusMessage = null; _isError = false; });
    try {
      PlatformFile? file;
      if (!kIsWeb) {
        file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['json', 'zip'],
        );
        if (file == null || !mounted) {
          setState(() => _busy = false);
          return;
        }
      }
      final svc = await BackupService.init();
      if (file != null && file.path != null) {
        await svc.restoreBackup(file.path!);
        if (mounted) setState(() => _progress = 1.0);
      }
      if (mounted) {
        setState(() { _busy = false; _progress = null; _statusMessage = 'Restore complete — please restart'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _busy = false; _progress = null; _statusMessage = 'Restore failed: $e'; _isError = true; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.backup_outlined,
          title: 'Backup and Restore',
          subtitle: 'Export your boards and settings or restore from a previous backup',
        ),

        // Status message
        if (_statusMessage != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isError
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(_isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _isError ? Colors.red : Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_statusMessage!,
                      style: TextStyle(
                          color: _isError ? Colors.red : Colors.green,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Progress bar
        if (_busy && _progress != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: 16),
        ],

        SettingsGroup(
          title: 'Backup',
          children: [
            SettingsTile(
              icon: Icons.upload_rounded,
              title: 'Back Up to Device',
              subtitle: 'Save all boards and settings as a local file',
              trailing: _busy
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : FilledButton.tonal(
                      onPressed: _doBackup,
                      child: const Text('Backup'),
                    ),
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Restore',
          children: [
            SettingsTile(
              icon: Icons.download_rounded,
              title: 'Restore from File',
              subtitle: 'Load a previously saved backup file',
              trailing: _busy
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : OutlinedButton(
                      onPressed: _doRestore,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange)),
                      child: const Text('Restore'),
                    ),
              showDivider: false,
            ),
          ],
        ),

        // Warning card
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Restoring a backup will permanently replace your current boards '
                  'and settings. We recommend creating a backup first.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
