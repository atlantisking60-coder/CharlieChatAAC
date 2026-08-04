import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings_widgets.dart';

const _appVersion = '1.0.0';
const _buildNumber = '1';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'Version info, licences and support',
        ),

        // ── App identity card ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.record_voice_over_rounded,
                    size: 36, color: cs.primary),
              ),
              const SizedBox(height: 12),
              Text('Charlie Chat',
                  style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text('Augmentative and Alternative Communication',
                  style: TextStyle(
                      fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              _VersionBadge(version: _appVersion, buildNumber: _buildNumber),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Info tiles ────────────────────────────────────────────────────
        SettingsGroup(
          title: 'App Info',
          children: [
            SettingsTile(
              icon: Icons.tag_rounded,
              title: 'Version',
              trailing: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(
                      ClipboardData(text: '$_appVersion+$_buildNumber'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version copied')));
                },
                child: Text('$_appVersion (build $_buildNumber)',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ),
            ),
            SettingsTile(
              icon: Icons.update_rounded,
              title: 'Check for Updates',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open app store */},
            ),
            SettingsTile(
              icon: Icons.gavel_rounded,
              title: 'Licences',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Charlie Chat',
                applicationVersion: _appVersion,
              ),
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Support',
          children: [
            SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help and Documentation',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open help URL */},
            ),
            SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open feedback form */},
            ),
            SettingsTile(
              icon: Icons.email_outlined,
              title: 'Contact Support',
              subtitle: 'support@charliechat.app',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: launch mailto */},
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Legal',
          children: [
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open URL */},
            ),
            SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open URL */},
              showDivider: false,
            ),
          ],
        ),

        Center(
          child: Text(
            '© ${DateTime.now().year} Charlie Chat. All rights reserved.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.buildNumber});
  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'v$version  •  build $buildNumber',
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cs.primary),
      ),
    );
  }
}
