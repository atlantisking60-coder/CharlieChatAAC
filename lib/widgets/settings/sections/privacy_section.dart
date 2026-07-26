import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.shield_outlined,
          title: 'Privacy',
          subtitle: 'Control data collection and history retention',
        ),

        SettingsGroup(
          title: 'Data Collection',
          children: [
            SettingsSwitchTile(
              icon: Icons.analytics_outlined,
              title: 'Usage Analytics',
              subtitle: 'Help improve the app by sharing anonymous usage data',
              value: settings.analyticsEnabled,
              onChanged: (v) => onChanged(settings.copyWith(analyticsEnabled: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.bug_report_outlined,
              title: 'Crash Reporting',
              subtitle: 'Automatically send crash reports to our team',
              value: settings.crashReportingEnabled,
              onChanged: (v) => onChanged(settings.copyWith(crashReportingEnabled: v)),
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'History',
          children: [
            SettingsSwitchTile(
              icon: Icons.history_rounded,
              title: 'Save Phrase History',
              subtitle: 'Keep a log of spoken phrases for quick re-use',
              value: settings.saveHistory,
              onChanged: (v) => onChanged(settings.copyWith(saveHistory: v)),
            ),
            if (settings.saveHistory)
              SettingsDropdownTile<int>(
                icon: Icons.schedule_rounded,
                title: 'Keep History For',
                subtitle: 'Automatically delete older entries',
                value: settings.historyRetentionDays,
                items: const [
                  DropdownMenuItem(value: 7,   child: Text('7 days')),
                  DropdownMenuItem(value: 14,  child: Text('14 days')),
                  DropdownMenuItem(value: 30,  child: Text('30 days')),
                  DropdownMenuItem(value: 90,  child: Text('3 months')),
                  DropdownMenuItem(value: 365, child: Text('1 year')),
                  DropdownMenuItem(value: 0,   child: Text('Forever')),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(settings.copyWith(historyRetentionDays: v));
                },
                showDivider: false,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                child: Text('Enable history to configure retention.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ),
          ],
        ),

        SettingsGroup(
          title: 'Data Management',
          children: [
            SettingsDangerTile(
              icon: Icons.delete_outline_rounded,
              title: 'Clear Phrase History',
              subtitle: 'Remove all saved phrase history permanently',
              buttonLabel: 'Clear',
              onTap: () => _confirmClear(context,
                  title: 'Clear Phrase History',
                  message: 'All phrase history will be permanently deleted. This cannot be undone.',
                  onConfirm: () {/* TODO: clear history via service */}),
              showDivider: true,
            ),
            SettingsDangerTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Reset Privacy Settings',
              subtitle: 'Restore all privacy options to defaults',
              buttonLabel: 'Reset',
              onTap: () => _confirmClear(context,
                  title: 'Reset Privacy Settings',
                  message: 'All privacy settings will be reset to their defaults.',
                  onConfirm: () => onChanged(settings.copyWith(
                    analyticsEnabled: true,
                    crashReportingEnabled: true,
                    saveHistory: true,
                    historyRetentionDays: 30,
                  ))),
            ),
          ],
        ),

        // Privacy policy link
        _PrivacyPolicyCard(),
      ],
    );
  }

  void _confirmClear(BuildContext context,
      {required String title,
      required String message,
      required VoidCallback onConfirm}) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () { Navigator.pop(ctx); onConfirm(); },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm')),
        ],
      ),
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {/* TODO: open privacy policy URL */},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.open_in_new_rounded, color: cs.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy Policy',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.primary)),
                  Text('View our full privacy policy',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.outlineVariant),
          ],
        ),
      ),
    );
  }
}
