import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../services/sync_service.dart';
import '../settings_widgets.dart';

class CloudSyncSection extends StatefulWidget {
  const CloudSyncSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends State<CloudSyncSection> {
  List<SyncRecord> _pendingRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final svc = await SyncService.init();
      final records = svc.pendingRecords;
      if (mounted) setState(() { _pendingRecords = records; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forceSyncNow() async {
    setState(() => _loading = true);
    await _loadSyncStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync queued — will upload when connected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.cloud_outlined,
          title: 'Cloud Sync',
          subtitle: 'Keep your boards and settings in sync across devices',
        ),

        SettingsGroup(
          title: 'Sync Settings',
          children: [
            SettingsSwitchTile(
              icon: Icons.cloud_sync_outlined,
              title: 'Enable Cloud Sync',
              subtitle: 'Automatically back up boards and settings',
              value: widget.settings.cloudSyncEnabled,
              onChanged: (v) =>
                  widget.onChanged(widget.settings.copyWith(cloudSyncEnabled: v)),
            ),
            if (widget.settings.cloudSyncEnabled) ...[
              SettingsSwitchTile(
                icon: Icons.wifi_rounded,
                title: 'Wi-Fi Only',
                subtitle: 'Only sync when connected to Wi-Fi',
                value: widget.settings.syncOnWifiOnly,
                onChanged: (v) =>
                    widget.onChanged(widget.settings.copyWith(syncOnWifiOnly: v)),
              ),
              SettingsSwitchTile(
                icon: Icons.launch_rounded,
                title: 'Sync on Launch',
                subtitle: 'Check for updates when app opens',
                value: widget.settings.autoSyncOnLaunch,
                onChanged: (v) => widget.onChanged(
                    widget.settings.copyWith(autoSyncOnLaunch: v)),
                showDivider: false,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                child: Text(
                  'Enable cloud sync to unlock these options.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),

        if (widget.settings.cloudSyncEnabled) ...[
          // ── Status card ──────────────────────────────────────────────
          SettingsGroup(
            title: 'Sync Status',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _SyncStatusCard(
                        pendingCount: _pendingRecords.length,
                        onSyncNow: _forceSyncNow,
                      ),
              ),
            ],
          ),
        ],

        // ── Info ─────────────────────────────────────────────────────────
        _SyncInfoCard(),
      ],
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.pendingCount, required this.onSyncNow});
  final int pendingCount;
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allSynced = pendingCount == 0;
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: allSynced
                ? Colors.green.withValues(alpha: 0.12)
                : cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            allSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
            color: allSynced ? Colors.green : cs.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allSynced ? 'All synced' : '$pendingCount change(s) pending',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                allSynced
                    ? 'Your data is up to date'
                    : 'Tap to sync now',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: onSyncNow,
          child: const Text('Sync Now'),
        ),
      ],
    );
  }
}

class _SyncInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_outlined, color: cs.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your data is encrypted before being stored in the cloud. '
              'Only you can access your boards and settings.',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
