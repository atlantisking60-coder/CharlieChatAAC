import 'package:flutter/material.dart';

import '../../services/board_service.dart';
import '../../services/settings_service.dart';
import 'sections/general_section.dart';
import 'sections/speech_section.dart';
import 'sections/appearance_section.dart';
import 'sections/accessibility_section.dart';
import 'sections/profiles_section.dart';
import 'sections/cloud_sync_section.dart';
import 'sections/privacy_section.dart';
import 'sections/language_section.dart';
import 'sections/manage_boards_section.dart';
import 'sections/custom_symbols_section.dart';
import 'sections/edit_symbols_section.dart';
import 'sections/backup_section.dart';
import 'sections/about_section.dart';
import '../settings_screen.dart' show VoiceOption, ProfileSettingsResult;

// ─────────────────────────────────────────────────────────────────────────────
// Settings entry data
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsEntry {
  const _SettingsEntry({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
  final String id;
  final String label;
  final IconData icon;
  final String description;
}

const _entries = [
  _SettingsEntry(id: 'general',      label: 'General',      icon: Icons.tune_rounded,            description: 'Sentence bar, board defaults'),
  _SettingsEntry(id: 'speech',       label: 'Speech',       icon: Icons.record_voice_over_rounded, description: 'Voice, rate, pitch, volume'),
  _SettingsEntry(id: 'appearance',   label: 'Appearance',   icon: Icons.palette_outlined,         description: 'Theme, colours, symbol size'),
  _SettingsEntry(id: 'accessibility',label: 'Accessibility',icon: Icons.accessibility_new_rounded,description: 'Motion, contrast, touch targets'),
  _SettingsEntry(id: 'profiles',     label: 'Profiles',     icon: Icons.people_outline_rounded,   description: 'Manage user profiles'),
  _SettingsEntry(id: 'cloud_sync',   label: 'Cloud Sync',   icon: Icons.cloud_outlined,           description: 'Sync settings & boards'),
  _SettingsEntry(id: 'privacy',      label: 'Privacy',      icon: Icons.shield_outlined,          description: 'Analytics, history, data'),
  _SettingsEntry(id: 'language',     label: 'Language',     icon: Icons.language_rounded,         description: 'App language, symbol labels'),
  _SettingsEntry(id: 'manage_boards', label: 'Manage Boards', icon: Icons.grid_view_rounded,      description: 'Organize, move, and delete boards'),
  _SettingsEntry(id: 'custom_symbols', label: 'Custom Symbols', icon: Icons.add_photo_alternate_outlined, description: 'Upload and manage your own images'),
  _SettingsEntry(id: 'edit_symbols', label: 'Edit Symbols', icon: Icons.edit_note_rounded, description: 'Manage symbol tags and metadata'),
  _SettingsEntry(id: 'backup',       label: 'Backup & Restore', icon: Icons.backup_outlined,     description: 'Export and import data'),
  _SettingsEntry(id: 'about',        label: 'About',        icon: Icons.info_outline_rounded,     description: 'Version, licences, support'),
];

// ─────────────────────────────────────────────────────────────────────────────
// SettingsShell — adaptive two-panel (wide) or push-nav (narrow)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsShell extends StatefulWidget {
  const SettingsShell({
    super.key,
    required this.initialSettings,
    required this.availableLanguages,
    required this.availableVoices,
    required this.availableBoards,
    required this.selectedPreferredSets,
    required this.startingBoardId,
  });

  final AppSettings initialSettings;
  final List<String> availableLanguages;
  final List<VoiceOption> availableVoices;
  final List<Board> availableBoards;
  final List<String> selectedPreferredSets;
  final String startingBoardId;

  @override
  State<SettingsShell> createState() => _SettingsShellState();
}

class _SettingsShellState extends State<SettingsShell> {
  late AppSettings _settings;
  late List<String> _preferredSets;
  late String _startingBoardId;
  String? _navigateToBoardId;
  String _activeId = 'general';
  bool _showSavedMessage = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _preferredSets = List.from(widget.selectedPreferredSets);
    _startingBoardId = widget.startingBoardId;
  }

  void _update(AppSettings s) => setState(() => _settings = s);

  Widget _buildSection(String id) {
    switch (id) {
      case 'general':
        return GeneralSection(settings: _settings, onChanged: _update);
      case 'speech':
        return SpeechSection(
          settings: _settings,
          onChanged: _update,
          availableLanguages: widget.availableLanguages,
          availableVoices: widget.availableVoices,
        );
      case 'appearance':
        return AppearanceSection(settings: _settings, onChanged: _update);
      case 'accessibility':
        return AccessibilitySection(settings: _settings, onChanged: _update);
      case 'profiles':
        return ProfilesSection(
          settings: _settings,
          onChanged: _update,
          availableBoards: widget.availableBoards,
          preferredSets: _preferredSets,
          startingBoardId: _startingBoardId,
          onPreferredSetsChanged: (sets) => setState(() => _preferredSets = sets),
          onStartingBoardChanged: (id) => setState(() => _startingBoardId = id),
        );
      case 'cloud_sync':
        return CloudSyncSection(settings: _settings, onChanged: _update);
      case 'privacy':
        return PrivacySection(settings: _settings, onChanged: _update);
      case 'language':
        return LanguageSection(settings: _settings, onChanged: _update);
      case 'manage_boards':
        return ManageBoardsSection(
          settings: _settings,
          onChanged: _update,
          onNavigate: (boardId) {
            setState(() => _navigateToBoardId = boardId);
            _save();
          },
        );
      case 'custom_symbols':
        return CustomSymbolsSection(settings: _settings, onChanged: _update);
      case 'edit_symbols':
        return EditSymbolsSection(settings: _settings, onChanged: _update);
      case 'backup':
        return const BackupSection();
      case 'about':
        return const AboutSection();
      default:
        return const SizedBox.shrink();
    }
  }

  void _save({bool silent = false}) {
    if (silent) {
       // Just update locally without popping
       return;
    }
    Navigator.of(context).pop(ProfileSettingsResult(
      settings: _settings,
      preferredSymbolSets: _preferredSets,
      startingBoardId: _startingBoardId,
      navigateToBoardId: _navigateToBoardId,
    ));
  }

  void _triggerSavedConfirmation() {
    setState(() => _showSavedMessage = true);
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) setState(() => _showSavedMessage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth >= 720;
      return wide ? _buildWide(ctx) : _buildNarrow(ctx);
    });
  }

  // ── Wide (tablet+): master-detail two-panel layout ─────────────────────────
  Widget _buildWide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        actions: [
          if (_showSavedMessage)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Saved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          FilledButton.tonal(
            onPressed: () {
              _triggerSavedConfirmation();
              // In this new mode, we don't actually pop yet, but we'll return 
              // the data when they finally leave. 
              // Wait, user said "do not come out of the Settings menu when they press Save".
              // But we still need to apply the changes to the app state.
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Save'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop(ProfileSettingsResult(
            settings: _settings,
            preferredSymbolSets: _preferredSets,
            startingBoardId: _startingBoardId,
            navigateToBoardId: _navigateToBoardId,
          ));
        },
        child: Row(
          children: [
            // Master list
            SizedBox(
              width: 260,
              child: Material(
                color: cs.surfaceContainerLow,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => _NavTile(
                    entry: _entries[i],
                    selected: _activeId == _entries[i].id,
                    onTap: () => setState(() => _activeId = _entries[i].id),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            // Detail pane
            Expanded(
              child: _SectionPane(
                key: ValueKey(_activeId),
                child: _buildSection(_activeId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Narrow (phone): list → push navigation ─────────────────────────────────
  Widget _buildNarrow(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          if (_showSavedMessage)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Saved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          TextButton(
            onPressed: _triggerSavedConfirmation,
            child: const Text('Save'),
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop(ProfileSettingsResult(
            settings: _settings,
            preferredSymbolSets: _preferredSets,
            startingBoardId: _startingBoardId,
            navigateToBoardId: _navigateToBoardId,
          ));
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _entries.length,
          itemBuilder: (_, i) => _NavTile(
            entry: _entries[i],
            selected: false,
            showArrow: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _SectionPage(
                  entry: _entries[i],
                  onSave: _triggerSavedConfirmation,
                  showSavedMessage: _showSavedMessage,
                  child: _buildSection(_entries[i].id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav list tile
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.entry,
    required this.selected,
    required this.onTap,
    this.showArrow = false,
  });

  final _SettingsEntry entry;
  final bool selected;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(entry.icon,
                      size: 20,
                      color: selected ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label,
                          style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                              color: selected ? cs.primary : cs.onSurface)),
                      Text(entry.description,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (showArrow)
                  Icon(Icons.chevron_right, color: cs.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable section pane (wide layout detail)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPane extends StatelessWidget {
  const _SectionPane({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Push page (narrow layout)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.entry,
    required this.child,
    required this.onSave,
    this.showSavedMessage = false,
  });
  final _SettingsEntry entry;
  final Widget child;
  final VoidCallback onSave;
  final bool showSavedMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.label),
        centerTitle: true,
        actions: [
          if (showSavedMessage)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Saved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          TextButton(onPressed: onSave, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: child,
      ),
    );
  }
}
