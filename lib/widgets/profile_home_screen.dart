import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class ProfileHomeScreen extends StatelessWidget {
  final List<UserProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onCreateProfile;
  final ValueChanged<UserProfile> onDeleteProfile;
  final VoidCallback? onBackPressed;

  const ProfileHomeScreen({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onProfileSelected,
    required this.onCreateProfile,
    required this.onDeleteProfile,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Filter out admin profile from the list
    final filteredProfiles = profiles.where((profile) => profile.id != 'admin').toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Choose AAC Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Create profile',
            onPressed: onCreateProfile,
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Profile',
            onPressed: () => _showAdminPasswordDialog(context, onProfileSelected),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Select who is using the app',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(18),
                  sliver: SliverGrid.builder(
                    itemCount: filteredProfiles.length + 1,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.25 : 0.98,
                    ),
                    itemBuilder: (context, index) {
                      if (index == filteredProfiles.length) {
                        return _CreateProfileTile(onPressed: onCreateProfile);
                      }

                      final profile = filteredProfiles[index];
                      final isActive = profile.id == activeProfileId;
                      return _ProfileTile(
                        profile: profile,
                        isActive: isActive,
                        color: _profileColor(colorScheme, index),
                        onTap: () => onProfileSelected(profile.id),
                        onDelete: filteredProfiles.length > 1
                            ? () => onDeleteProfile(profile)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _profileColor(ColorScheme colorScheme, int index) {
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHighest,
    ];
    return colors[index % colors.length];
  }

  Future<void> _showAdminPasswordDialog(BuildContext context, ValueChanged<String> onProfileSelected) async {
    final passwordController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (passwordController.text == 'Baycr0ft') {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Incorrect password')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
    
    passwordController.dispose();
    
    if (result == true) {
      // Find the admin profile and select it
      final adminProfile = profiles.firstWhere(
        (profile) => profile.id == 'admin',
        orElse: () => profiles.isNotEmpty ? profiles.first : UserProfile.defaultProfile(),
      );
      onProfileSelected(adminProfile.id);
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final UserProfile profile;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.primary,
                    backgroundImage: _getProfileImageProvider(),
                    child: profile.settings.profileImage.isEmpty
                        ? ClipOval(child: Image.asset('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png'))
                        : null,
                  ),
                  const Spacer(),
                  if (isActive)
                    Icon(Icons.check_circle, color: colorScheme.primary),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete profile',
                      onPressed: onDelete,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                profile.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _profileSummary(profile),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider() {
    final profileImage = profile.settings.profileImage;
    if (profileImage.isEmpty || profileImage == 'assets/symbols/baycroft.png') {
      return const AssetImage('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png');
    }
    if (profileImage.startsWith('data:')) {
      return MemoryImage(base64Decode(profileImage.split(',').last));
    }
    if (profileImage.startsWith('assets/')) {
      return AssetImage(profileImage);
    }
    if (kIsWeb) {
      return NetworkImage(profileImage);
    }
    return FileImage(File(profileImage));
  }

  String _profileSummary(UserProfile profile) {
    final sets = profile.preferredSymbolSets;
    if (sets.isEmpty) return 'Uses default boards and symbols';
    if (sets.length == 1) return 'Starts with ${sets.first} symbols';
    return '${sets.length} preferred symbol sets';
  }
}

class _CreateProfileTile extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateProfileTile({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outline),
      ),
      onPressed: onPressed,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 38),
          SizedBox(height: 10),
          Text('New Profile', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
