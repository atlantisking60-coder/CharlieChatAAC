import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

class AccessibilitySection extends StatelessWidget {
  const AccessibilitySection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.accessibility_new_rounded,
          title: 'Accessibility',
          subtitle: 'Motion, touch targets, bold text and button spacing',
        ),

        SettingsGroup(
          title: 'Visual',
          children: [
            SettingsSwitchTile(
              icon: Icons.motion_photos_off_outlined,
              title: 'Reduce Motion',
              subtitle: 'Disable animations and transitions',
              value: settings.reduceMotion,
              onChanged: (v) => onChanged(settings.copyWith(reduceMotion: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.format_bold_rounded,
              title: 'Bold Text',
              subtitle: 'Increase font weight throughout the app',
              value: settings.boldText,
              onChanged: (v) => onChanged(settings.copyWith(boldText: v)),
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Interaction',
          children: [
            SettingsSwitchTile(
              icon: Icons.touch_app_rounded,
              title: 'Larger Touch Targets',
              subtitle: 'Increase tap area on buttons and symbols',
              value: settings.largerTouchTargets,
              onChanged: (v) => onChanged(settings.copyWith(largerTouchTargets: v)),
            ),
            SettingsSliderTile(
              icon: Icons.space_bar_rounded,
              title: 'Button Spacing',
              value: settings.buttonSpacing,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              displayValue: _spacingLabel(settings.buttonSpacing),
              onChanged: (v) => onChanged(settings.copyWith(buttonSpacing: v)),
              showDivider: false,
            ),
          ],
        ),

        // Info card
        _AccessibilityInfoCard(),
      ],
    );
  }

  static String _spacingLabel(double v) {
    if (v <= 0.6) return 'Compact';
    if (v <= 0.9) return 'Tight';
    if (v <= 1.1) return 'Normal';
    if (v <= 1.5) return 'Relaxed';
    return 'Spacious';
  }
}

class _AccessibilityInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: cs.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Some accessibility features also follow your device\'s system '
              'settings. For best results, combine app settings with OS-level '
              'display options.',
              style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
