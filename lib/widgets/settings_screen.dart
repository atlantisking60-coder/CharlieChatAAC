import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/symbol_data.dart';
import '../services/board_service.dart';
import '../services/cross_platform_tts_service.dart';
import '../services/settings_service.dart';
import '../services/backup_service.dart';

class VoiceOption {
  final String name;
  final String locale;

  const VoiceOption({required this.name, required this.locale});
}

class ProfileSettingsResult {
  final AppSettings settings;
  final List<String> preferredSymbolSets;
  final String startingBoardId;
  final String? navigateToBoardId;

  ProfileSettingsResult({
    required this.settings,
    required this.preferredSymbolSets,
    required this.startingBoardId,
    this.navigateToBoardId,
  });
}

class SettingsScreen extends StatefulWidget {
  final AppSettings initialSettings;
  final List<String> availableLanguages;
  final List<VoiceOption> availableVoices;
  final List<Board> availableBoards;
  final List<String> selectedPreferredSets;
  final String startingBoardId;

  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.availableLanguages,
    required this.availableVoices,
    required this.availableBoards,
    required this.selectedPreferredSets,
    required this.startingBoardId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late List<String> _preferredSymbolSets;
  late String _startingBoardId;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _preferredSymbolSets = List.from(widget.selectedPreferredSets);
    _startingBoardId = widget.startingBoardId;
  }

  void _updateSettings(AppSettings patch) {
    setState(() {
      _settings = _settings.copyWith(
        themeMode: patch.themeMode,
        voiceRate: patch.voiceRate,
        voicePitch: patch.voicePitch,
        voiceVolume: patch.voiceVolume,
        voiceLanguage: patch.voiceLanguage,
        voiceName: patch.voiceName,
        sentenceSize: patch.sentenceSize,
        sentenceType: patch.sentenceType,
        readSentenceOnly: patch.readSentenceOnly,
        profileImage: patch.profileImage,
        fontSize: patch.fontSize,
        highContrast: patch.highContrast,
        projectRoot: patch.projectRoot,
      );
    });
  }

  ImageProvider? _getProfileImageProvider() {
    if (_settings.profileImage.isEmpty || _settings.profileImage == 'assets/charlie_chat_aac_logo.png' || _settings.profileImage == 'assets/symbols/baycroft.png') {
      return const AssetImage('assets/charlie_chat_aac_default_profile.png');
    }
    if (_settings.profileImage.startsWith('data:')) {
      return MemoryImage(base64Decode(_settings.profileImage.split(',').last));
    }
    if (kIsWeb) {
      return NetworkImage(_settings.profileImage);
    }
    if (_settings.profileImage.startsWith('assets/')) return AssetImage(_settings.profileImage);
    return FileImage(File(_settings.profileImage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: _getProfileImageProvider(),
                child: _settings.profileImage.isEmpty
                    ? ClipOval(child: Image.asset('assets/charlie_chat_aac_default_profile.png'))
                    : null,
              ),
              title: const Text('Change profile image'),
              onTap: () async {
                try {
                  final result = await FilePicker.pickFiles(type: FileType.image);
                  if (!mounted) return;
                  if (result != null) {
                    // For web, use the bytes directly
                    if (kIsWeb) {
                      final bytes = await result.files.single.readAsBytes();
                      setState(() {
                        _settings = _settings.copyWith(profileImage: 'data:image/png;base64,${base64Encode(bytes)}');
                      });
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile image updated.')),
                        );
                      }
                    } else {
                      // For native, use the file path
                      if (result.files.single.path != null) {
                        setState(() {
                          _settings = _settings.copyWith(profileImage: result.files.single.path);
                        });
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile image updated.')),
                          );
                        }
                      }
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error selecting image: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
            _AppearanceSection(
              settings: _settings,
              onChanged: _updateSettings,
            ),

            const SizedBox(height: 24),
            const Text('Sentence Bar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Sentence Size'),
              initialValue: _settings.sentenceSize,

              items: ['small', 'medium', 'large']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                  .toList(),
              onChanged: (v) => _updateSettings(_settings.copyWith(sentenceSize: v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Sentence Type'),
              initialValue: _settings.sentenceType,

              items: ['words', 'symbols', 'both']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                  .toList(),
              onChanged: (v) => _updateSettings(_settings.copyWith(sentenceType: v)),
            ),
            SwitchListTile(
              title: const Text('Read Sentence Only'),
              subtitle: const Text('Does not speak individual symbols when tapped'),
              value: _settings.readSentenceOnly,
              onChanged: (v) => _updateSettings(_settings.copyWith(readSentenceOnly: v)),
            ),
            const SizedBox(height: 24),
            const Text('Voice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Language'),
              initialValue: widget.availableLanguages.contains(_settings.voiceLanguage)
                  ? _settings.voiceLanguage
                  : (widget.availableLanguages.isNotEmpty
                      ? widget.availableLanguages.first
                      : null),

              items: widget.availableLanguages
                  .map((lang) =>
                      DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSettings(_settings.copyWith(voiceLanguage: value));
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Voice'),
              initialValue: widget.availableVoices
                      .any((voice) => voice.name == _settings.voiceName)
                  ? _settings.voiceName
                  : (widget.availableVoices.isNotEmpty
                      ? widget.availableVoices.first.name
                      : null),

              items: widget.availableVoices
                  .map((voice) => DropdownMenuItem(
                      value: voice.name,
                      child: Text('${voice.name} (${voice.locale})')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSettings(_settings.copyWith(voiceName: value));
                  // Immediately apply the voice change to TTS
                  final tts = CrossPlatformTtsService.instance;
                  tts.setVoice(value, locale: _settings.voiceLanguage);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rate'),
                Text(_settings.voiceRate.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              min: 0.2,
              max: 1.0,
              divisions: 20,
              value: _settings.voiceRate,
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(voiceRate: value)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pitch'),
                Text(_settings.voicePitch.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              min: 0.5,
              max: 2.0,
              divisions: 20,
              value: _settings.voicePitch,
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(voicePitch: value)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Volume'),
                Text(_settings.voiceVolume.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              min: 0.0,
              max: 1.0,
              divisions: 20,
              value: _settings.voiceVolume,
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(voiceVolume: value)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final tts = CrossPlatformTtsService.instance;
                await tts.setLanguage(_settings.voiceLanguage);
                if (_settings.voiceName.isNotEmpty) {
                  await tts.setVoice(_settings.voiceName, locale: _settings.voiceLanguage);
                }
                await tts.setSpeechRate(_settings.voiceRate);
                await tts.setPitch(_settings.voicePitch);
                await tts.setVolume(_settings.voiceVolume);
                await tts.speak('This is a test of your voice settings.');
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Voice'),
            ),
            const SizedBox(height: 24),
            if (!kIsWeb && (Theme.of(context).platform == TargetPlatform.windows || Theme.of(context).platform == TargetPlatform.macOS || Theme.of(context).platform == TargetPlatform.linux)) ...[
              const Text('Developer / Project Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Project Source Location'),
                subtitle: Text(_settings.projectRoot.isEmpty ? 'Not set' : _settings.projectRoot),
                trailing: const Icon(Icons.folder_open),
                onTap: () async {
                  final path = await FilePicker.getDirectoryPath(
                    dialogTitle: 'Select Charlie Chat Project Root',
                  );
                  if (path != null) {
                    _updateSettings(_settings.copyWith(projectRoot: path));
                    final service = await BoardService.getInstance();
                    service.setProjectRoot(path);
                  }
                },
              ),
              if (_settings.projectRoot.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final service = await BoardService.getInstance();
                      await service.exportToProject(_settings.projectRoot);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All boards exported to project assets.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Sync All Boards to Project'),
                  ),
                ),
              const SizedBox(height: 24),
            ],
            const Text('Board Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Boards'),
                    content: const Text('This will remove all tiles from all boards. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    final boardService = await BoardService.getInstance();
                    await boardService.clearAllBoardTiles();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All boards cleared successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error clearing boards: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Board Tiles'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Restore Default Boards'),
                    content: const Text(
                      'This will restore all default boards that may have been deleted or lost. '
                      'Your custom boards will not be affected.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    final boardService = await BoardService.getInstance();
                    await boardService.restoreDefaultBoards();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Default boards restored successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error restoring boards: $e')),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restore Default Boards'),
            ),
            const SizedBox(height: 24),
            const Text('Backup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final backupService = await BackupService.init();
                  await backupService.exportBackupFile();
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup exported successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error exporting backup: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.backup),
              label: const Text('Export Backup File'),
            ),
            const SizedBox(height: 24),
            const Text('Other Profile Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Preferred symbol sets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allCategories.map((category) {
                final selected = _preferredSymbolSets.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _preferredSymbolSets.add(category);
                      } else {
                        _preferredSymbolSets.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Starting board'),
              initialValue: widget.availableBoards.any((board) => board.id == _startingBoardId)
                  ? _startingBoardId
                  : '',

              items: [
                const DropdownMenuItem(value: '', child: Text('None')),
                ...widget.availableBoards
                    .map((board) => DropdownMenuItem(
                          value: board.id,
                          child: Text(board.name),
                        ))
                    ,
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _startingBoardId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(ProfileSettingsResult(
                    settings: _settings,
                    preferredSymbolSets: _preferredSymbolSets,
                    startingBoardId: _startingBoardId,
                  ));
                },
                child: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appearance Section
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  static const _themes = [
    ('teal',   'Teal',    Color(0xFF009688)),
    ('blue',   'Blue',    Color(0xFF1565C0)),
    ('purple', 'Purple',  Color(0xFF6A1B9A)),
    ('green',  'Green',   Color(0xFF2E7D32)),
    ('orange', 'Orange',  Color(0xFFE64A19)),
    ('rose',   'Rose',    Color(0xFFE91E8C)),
    ('mono',   'Mono',    Color(0xFF546E7A)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Row(children: [
          Icon(Icons.palette_outlined, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text('Appearance',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),

        // ── Theme mode ──────────────────────────────────────────────────────
        Text('Theme Mode', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _ThemeModeSelector(
          value: settings.themeMode,
          onChanged: (m) => onChanged(settings.copyWith(themeMode: m)),
        ),
        const SizedBox(height: 24),

        // ── Colour themes ───────────────────────────────────────────────────
        Text('Colour Theme', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _ColourThemeGrid(
          themes: _themes,
          selected: settings.colourTheme,
          onChanged: (t) => onChanged(settings.copyWith(colourTheme: t)),
        ),
        const SizedBox(height: 24),

        // ── Symbol size slider ──────────────────────────────────────────────
        _LabelledSlider(
          label: 'Symbol Size',
          icon: Icons.grid_view_rounded,
          value: settings.symbolSize,
          min: 0.6,
          max: 1.6,
          divisions: 10,
          displayValue: _symbolSizeLabel(settings.symbolSize),
          onChanged: (v) => onChanged(settings.copyWith(symbolSize: v)),
          preview: _SymbolSizePreview(scale: settings.symbolSize),
        ),
        const SizedBox(height: 24),

        // ── Grid spacing slider ─────────────────────────────────────────────
        _LabelledSlider(
          label: 'Grid Spacing',
          icon: Icons.space_dashboard_outlined,
          value: settings.gridSpacing,
          min: 4,
          max: 24,
          divisions: 10,
          displayValue: '${settings.gridSpacing.round()} dp',
          onChanged: (v) => onChanged(settings.copyWith(gridSpacing: v)),
        ),
        const SizedBox(height: 24),

        // ── Font size ───────────────────────────────────────────────────────
        Text('Font Size', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _SegmentedRow<String>(
          options: const [
            ('small',  'Small'),
            ('medium', 'Medium'),
            ('large',  'Large'),
          ],
          selected: settings.fontSize,
          onChanged: (v) => onChanged(settings.copyWith(fontSize: v)),
        ),
        const SizedBox(height: 24),

        // ── High contrast toggle ────────────────────────────────────────────
        _ContrastToggle(
          value: settings.highContrast,
          onChanged: (v) => onChanged(settings.copyWith(highContrast: v)),
        ),
      ],
    );
  }

  static String _symbolSizeLabel(double v) {
    if (v <= 0.7) return 'XS';
    if (v <= 0.9) return 'S';
    if (v <= 1.1) return 'M';
    if (v <= 1.3) return 'L';
    return 'XL';
  }
}

// ── Theme mode selector ───────────────────────────────────────────────────────

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
        final selected = value == mode;
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
                  color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
                  border: Border.all(
                    color: selected ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        size: 26),
                    const SizedBox(height: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected ? cs.primary : cs.onSurfaceVariant)),
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

// ── Colour theme grid ─────────────────────────────────────────────────────────

class _ColourThemeGrid extends StatelessWidget {
  const _ColourThemeGrid({
    required this.themes,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, String, Color)> themes;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: themes.map((entry) {
        final (id, label, color) = entry;
        final isSelected = selected == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: isSelected ? 1.0 : 0.15),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Labelled slider ───────────────────────────────────────────────────────────

class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
    this.preview,
  });

  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(displayValue,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
          ),
        ]),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        if (preview != null) ...[
          const SizedBox(height: 6),
          preview!,
        ],
      ],
    );
  }
}

// ── Symbol size mini preview ──────────────────────────────────────────────────

class _SymbolSizePreview extends StatelessWidget {
  const _SymbolSizePreview({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = (52.0 * scale).clamp(20.0, 100.0);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                [Icons.emoji_emotions_outlined, Icons.directions_walk,
                 Icons.home_outlined, Icons.star_outline][i],
                size: size * 0.5,
                color: cs.onPrimaryContainer,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Segmented row (generic) ───────────────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: options.map((entry) {
        final (value, label) = entry;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? cs.primaryContainer
                      : cs.surfaceContainerHigh,
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? cs.primary : cs.onSurface)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── High contrast toggle ──────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? Colors.black : cs.surfaceContainerHigh,
          border: Border.all(
            color: value ? Colors.white : cs.outlineVariant,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Colors.white : cs.primaryContainer,
              ),
              child: Icon(
                value ? Icons.contrast : Icons.contrast_outlined,
                color: value ? Colors.black : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('High Contrast',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: value ? Colors.white : cs.onSurface)),
                  const SizedBox(height: 3),
                  Text(
                    'Black & white palette for maximum readability',
                    style: TextStyle(
                        fontSize: 12,
                        color: value
                            ? Colors.white70
                            : cs.onSurfaceVariant),
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
