import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour themes catalogue
// ─────────────────────────────────────────────────────────────────────────────

const _colourThemes = [
  ('teal',   'Teal',    Color(0xFF009688)),
  ('blue',   'Blue',    Color(0xFF1565C0)),
  ('purple', 'Purple',  Color(0xFF6A1B9A)),
  ('green',  'Green',   Color(0xFF2E7D32)),
  ('orange', 'Orange',  Color(0xFFE64A19)),
  ('rose',   'Rose',    Color(0xFFE91E8C)),
  ('mono',   'Mono',    Color(0xFF546E7A)),
];

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme, colour palette, symbol size and spacing',
        ),

        // ── Theme Mode ────────────────────────────────────────────────────
        SettingsGroup(
          title: 'Theme Mode',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _ThemeModeSelector(
                value: settings.themeMode,
                onChanged: (m) => onChanged(settings.copyWith(themeMode: m)),
              ),
            ),
          ],
        ),

        // ── Colour Theme ──────────────────────────────────────────────────
        SettingsGroup(
          title: 'Colour Theme',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _ColourThemeGrid(
                selected: settings.colourTheme,
                onChanged: (t) => onChanged(settings.copyWith(colourTheme: t)),
              ),
            ),
          ],
        ),

        // ── Typography ────────────────────────────────────────────────────
        SettingsGroup(
          title: 'Typography',
          children: [
            SettingsSegmentedTile<String>(
              icon: Icons.format_size_rounded,
              title: 'Font Size',
              options: const [('small', 'Small'), ('medium', 'Medium'), ('large', 'Large')],
              selected: settings.fontSize,
              onChanged: (v) => onChanged(settings.copyWith(fontSize: v)),
              showDivider: false,
            ),
          ],
        ),

        // ── Grid ─────────────────────────────────────────────────────────
        SettingsGroup(
          title: 'Symbol Grid',
          children: [
            SettingsSliderTile(
              icon: Icons.grid_view_rounded,
              title: 'Symbol Size',
              value: settings.symbolSize,
              min: 0.6,
              max: 1.6,
              divisions: 10,
              displayValue: _sizeLabel(settings.symbolSize),
              onChanged: (v) => onChanged(settings.copyWith(symbolSize: v)),
            ),
            // Live preview strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _SymbolPreview(scale: settings.symbolSize),
            ),
            SettingsSliderTile(
              icon: Icons.space_dashboard_outlined,
              title: 'Grid Spacing',
              value: settings.gridSpacing,
              min: 4,
              max: 24,
              divisions: 10,
              displayValue: '${settings.gridSpacing.round()} dp',
              onChanged: (v) => onChanged(settings.copyWith(gridSpacing: v)),
              showDivider: false,
            ),
          ],
        ),

        // ── High Contrast ─────────────────────────────────────────────────
        SettingsGroup(
          title: 'Contrast',
          children: [
            _ContrastToggle(
              value: settings.highContrast,
              onChanged: (v) => onChanged(settings.copyWith(highContrast: v)),
            ),
          ],
        ),
      ],
    );
  }

  static String _sizeLabel(double v) {
    if (v <= 0.7) return 'XS';
    if (v <= 0.9) return 'S';
    if (v <= 1.1) return 'M';
    if (v <= 1.3) return 'L';
    return 'XL';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme mode selector
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [
      (ThemeMode.system, Icons.brightness_auto_outlined, 'System'),
      (ThemeMode.light,  Icons.light_mode_outlined,      'Light'),
      (ThemeMode.dark,   Icons.dark_mode_outlined,       'Dark'),
    ];
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: modes.map((entry) {
        final (mode, icon, label) = entry;
        final sel = value == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sel ? cs.primaryContainer : cs.surfaceContainerHigh,
                  border: Border.all(
                    color: sel ? cs.primary : Colors.transparent, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: sel ? cs.primary : cs.onSurfaceVariant,
                        size: 26),
                    const SizedBox(height: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            color: sel ? cs.primary : cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour theme grid
// ─────────────────────────────────────────────────────────────────────────────

class _ColourThemeGrid extends StatelessWidget {
  const _ColourThemeGrid({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colourThemes.map((entry) {
        final (id, label, color) = entry;
        final sel = selected == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: sel ? 1.0 : 0.12),
              border: Border.all(
                  color: sel ? color : Colors.transparent, width: 2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: sel
                        ? [BoxShadow(
                            color: color.withValues(alpha: 0.45), blurRadius: 8)]
                        : [],
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.bold : FontWeight.normal,
                        color: sel ? color : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symbol size preview
// ─────────────────────────────────────────────────────────────────────────────

class _SymbolPreview extends StatelessWidget {
  const _SymbolPreview({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = (48.0 * scale).clamp(22.0, 96.0);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icons.emoji_emotions_outlined,
          Icons.directions_walk,
          Icons.home_outlined,
          Icons.star_outline,
        ].map((ic) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ic, size: size * 0.5, color: cs.onPrimaryContainer),
          ),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// High contrast toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ContrastToggle extends StatelessWidget {
  const _ContrastToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? Colors.black : cs.surfaceContainerHigh,
          border: Border.all(
              color: value ? Colors.white54 : cs.outlineVariant,
              width: value ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Colors.white : cs.primaryContainer,
              ),
              child: Icon(
                value ? Icons.contrast : Icons.contrast_outlined,
                color: value ? Colors.black : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('High Contrast',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: value ? Colors.white : cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('Black & white for maximum readability',
                      style: TextStyle(
                          fontSize: 11,
                          color: value ? Colors.white70 : cs.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
