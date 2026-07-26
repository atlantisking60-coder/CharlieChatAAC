import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

const _appLanguages = [
  ('en-GB', 'English (UK)',        '🇬🇧'),
  ('en-US', 'English (US)',        '🇺🇸'),
  ('fr-FR', 'Français',            '🇫🇷'),
  ('de-DE', 'Deutsch',             '🇩🇪'),
  ('es-ES', 'Español',             '🇪🇸'),
  ('it-IT', 'Italiano',            '🇮🇹'),
  ('pt-BR', 'Português (Brasil)',  '🇧🇷'),
  ('nl-NL', 'Nederlands',          '🇳🇱'),
  ('sv-SE', 'Svenska',             '🇸🇪'),
  ('nb-NO', 'Norsk',               '🇳🇴'),
  ('da-DK', 'Dansk',               '🇩🇰'),
  ('fi-FI', 'Suomi',               '🇫🇮'),
  ('ar-SA', 'العربية',             '🇸🇦'),
  ('zh-CN', '中文 (简体)',           '🇨🇳'),
  ('ja-JP', '日本語',               '🇯🇵'),
];

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'App interface language and symbol label display',
        ),

        SettingsGroup(
          title: 'Interface Language',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: _LanguageGrid(
                selected: settings.appLanguage,
                onChanged: (lang) => onChanged(settings.copyWith(appLanguage: lang)),
              ),
            ),
          ],
        ),

        SettingsGroup(
          title: 'Symbol Labels',
          children: [
            SettingsSwitchTile(
              icon: Icons.label_rounded,
              title: 'Show Labels',
              subtitle: 'Display text under each symbol tile',
              value: settings.showSymbolLabels,
              onChanged: (v) => onChanged(settings.copyWith(showSymbolLabels: v)),
            ),
            SettingsSegmentedTile<String>(
              icon: Icons.vertical_align_bottom_rounded,
              title: 'Label Position',
              options: const [
                ('above', 'Above'),
                ('below', 'Below'),
                ('none',  'None'),
              ],
              selected: settings.labelPosition,
              onChanged: (v) => onChanged(settings.copyWith(labelPosition: v)),
              showDivider: false,
            ),
          ],
        ),

        // Restart notice
        Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A restart may be required for language changes to take full effect.',
                  style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: _appLanguages.map((entry) {
        final (code, label, flag) = entry;
        final sel = selected == code;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: sel ? cs.primaryContainer : Colors.transparent,
              border: Border.all(
                color: sel ? cs.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? cs.primary : cs.onSurface)),
                ),
                if (sel)
                  Icon(Icons.check_circle_rounded,
                      color: cs.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
