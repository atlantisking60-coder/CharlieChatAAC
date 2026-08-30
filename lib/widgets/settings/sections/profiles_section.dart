import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/board_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/settings_service.dart';
import '../settings_widgets.dart';

class ProfilesSection extends StatefulWidget {
  const ProfilesSection({
    super.key,
    required this.settings,
    required this.onChanged,
    this.profile,
    this.onProfileChanged,
    required this.availableBoards,
    required this.preferredSets,
    required this.startingBoardId,
    required this.onPreferredSetsChanged,
    required this.onStartingBoardChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileChanged;
  final List<Board> availableBoards;
  final List<String> preferredSets;
  final String startingBoardId;
  final ValueChanged<List<String>> onPreferredSetsChanged;
  final ValueChanged<String> onStartingBoardChanged;

  @override
  State<ProfilesSection> createState() => _ProfilesSectionState();
}

class _ProfilesSectionState extends State<ProfilesSection> {
  ImageProvider? _getProfileImageProvider() {
    final img = widget.settings.profileImage;
    if (img.isEmpty || img == 'assets/symbols/baycroft.png') {
      return const AssetImage('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png');
    }
    if (img.startsWith('data:')) {
      return MemoryImage(base64Decode(img.split(',').last));
    }
    if (img.startsWith('assets/')) return AssetImage(img);
    if (kIsWeb) return NetworkImage(img);
    return FileImage(File(img));
  }

  Future<void> _pickProfileImage() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty || !mounted) return;
      final file = files.single;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        widget.onChanged(widget.settings.copyWith(
            profileImage: 'data:image/png;base64,${base64Encode(bytes)}'));
      } else {
        if (file.path != null) {
          widget.onChanged(
              widget.settings.copyWith(profileImage: file.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageProvider = _getProfileImageProvider();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.people_outline_rounded,
          title: 'Profiles',
          subtitle: 'Profile image, symbol sets and starting board',
        ),

        if (widget.profile != null) _buildProfileIdentity(widget.profile!),

        // ── Profile image ─────────────────────────────────────────────────
        SettingsGroup(
          title: 'Profile Image',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: imageProvider,
                          backgroundColor: cs.primaryContainer,
                          child: imageProvider == null
                              ? ClipOval(child: Image.asset('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png'))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                            child: Icon(Icons.edit, size: 12,
                                color: cs.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Profile Photo',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Tap the avatar to change your photo',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickProfileImage,
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: const Text('Change Photo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Starting board ────────────────────────────────────────────────
        SettingsGroup(
          title: 'Starting Board',
          children: [
            SettingsDropdownTile<String>(
              icon: Icons.home_outlined,
              title: 'Default Board',
              subtitle: 'Board to show when this profile opens',
              value: widget.availableBoards.any((b) => b.id == widget.startingBoardId)
                  ? widget.startingBoardId
                  : '',
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('None', style: TextStyle(fontSize: 13))),
                ...widget.availableBoards.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                if (v != null) widget.onStartingBoardChanged(v);
              },
              showDivider: false,
            ),
          ],
        ),

        // ── Preferred symbol sets ─────────────────────────────────────────
        SettingsGroup(
          title: 'Preferred Symbol Sets (Drag to prioritize)',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search priority goes from top to bottom',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  _buildReorderableSetsList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileIdentity(UserProfile profile) {
    final cs = Theme.of(context).colorScheme;
    final isLocked = profile.role == 'default' || profile.role == 'admin';

    return SettingsGroup(
      title: 'Profile Identity',
      children: [
        // Online ID
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Profile ID'),
          subtitle: Text(
            profile.onlineId.isEmpty ? 'Not set' : profile.onlineId,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          trailing: profile.onlineId.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy profile ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: profile.onlineId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile ID copied')),
                    );
                  },
                ),
        ),
        // Role
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Role'),
          subtitle: Text(profile.role, style: TextStyle(color: cs.onSurfaceVariant)),
          trailing: isLocked
              ? const Icon(Icons.lock, size: 18)
              : null,
        ),
        // Password
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: TextEditingController(text: profile.password ?? ''),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Profile password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            onChanged: (value) {
              widget.onProfileChanged?.call(profile.copyWith(password: value));
            },
          ),
        ),
        // Sync online
        SwitchListTile(
          secondary: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Store this profile online'),
          value: profile.syncEnabled,
          onChanged: (value) {
            widget.onProfileChanged?.call(profile.copyWith(syncEnabled: value));
          },
        ),
      ],
    );
  }

  Widget _buildReorderableSetsList() {
    final allAvailable = [
      'In App Assets',
      'Sign',
      'ARASAAC',
      'OpenSymbols',
      'GlobalSymbols',
    ];

    // Ensure allAvailable are in the preferredSets list, maintaining existing order
    final currentOrder = List<String>.from(widget.preferredSets);
    for (final set in allAvailable) {
      if (!currentOrder.contains(set)) {
        currentOrder.add(set);
      }
    }
    // Remove any that are no longer available (though unlikely)
    currentOrder.removeWhere((s) => !allAvailable.contains(s));

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        final updated = List<String>.from(currentOrder);
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        widget.onPreferredSetsChanged(updated);
      },
      children: currentOrder.map((setName) {
        return ListTile(
          key: ValueKey(setName),
          dense: true,
          leading: const Icon(Icons.drag_handle, size: 20),
          title: Text(setName, style: const TextStyle(fontSize: 14)),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
