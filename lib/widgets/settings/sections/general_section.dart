import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

class GeneralSection extends StatelessWidget {
  const GeneralSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.tune_rounded,
          title: 'General',
          subtitle: 'Sentence bar behaviour and board defaults',
        ),

        SettingsGroup(
          title: 'Sentence Bar',
          children: [
            SettingsSegmentedTile<String>(
              icon: Icons.format_size_rounded,
              title: 'Bar Size',
              options: const [('small', 'Small'), ('medium', 'Medium'), ('large', 'Large')],
              selected: settings.sentenceSize,
              onChanged: (v) => onChanged(settings.copyWith(sentenceSize: v)),
            ),
            SettingsSegmentedTile<String>(
              icon: Icons.emoji_symbols_rounded,
              title: 'Display Mode',
              subtitle: 'What to show in the built sentence',
              options: const [('words', 'Words'), ('symbols', 'Symbols'), ('both', 'Both')],
              selected: settings.sentenceType,
              onChanged: (v) => onChanged(settings.copyWith(sentenceType: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.record_voice_over_rounded,
              title: 'Read Sentence Only',
              subtitle: 'Do not speak individual symbols when tapped',
              value: settings.readSentenceOnly,
              onChanged: (v) => onChanged(settings.copyWith(readSentenceOnly: v)),
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Symbol Grid',
          children: [
            SettingsSwitchTile(
              icon: Icons.label_rounded,
              title: 'Show Symbol Labels',
              subtitle: 'Display text labels beneath each symbol',
              value: settings.showSymbolLabels,
              onChanged: (v) => onChanged(settings.copyWith(showSymbolLabels: v)),
            ),
            SettingsSegmentedTile<String>(
              icon: Icons.vertical_align_bottom_rounded,
              title: 'Label Position',
              options: const [('above', 'Above'), ('below', 'Below'), ('none', 'None')],
              selected: settings.labelPosition,
              onChanged: (v) => onChanged(settings.copyWith(labelPosition: v)),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}
