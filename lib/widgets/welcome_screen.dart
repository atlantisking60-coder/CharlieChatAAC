import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:uuid/uuid.dart';

import '../services/firebase_profile_sync_service.dart';
import '../services/profile_service.dart';
import 'auth_guard.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final List<UserProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onCreateProfile;
  final ValueChanged<UserProfile> onDeleteProfile;
  final ValueChanged<UserProfile>? onDownloadedProfile;

  const WelcomeScreen({
    super.key,
    required this.onContinue,
    required this.profiles,
    required this.activeProfileId,
    required this.onProfileSelected,
    required this.onCreateProfile,
    required this.onDeleteProfile,
    this.onDownloadedProfile,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final monthName = _getMonthName(now.month);
    final dayNumber = now.day;
    final year = now.year;
    final colorScheme = Theme.of(context).colorScheme;

    final filteredProfiles = profiles.where((p) => p.id != 'admin').toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return CustomScrollView(
              slivers: [
                // ── Date section ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      children: [
                        Text(
                          'Today is',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dayName ${_ordinal(dayNumber)} $monthName $year',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DateTile(
                                label: dayName,
                                assetPath: _getDayAssetPath(now.weekday),
                              ),
                              const SizedBox(width: 16),
                              _DateNumberTile(dayNumber: dayNumber),
                              const SizedBox(width: 16),
                              _DateTile(
                                label: monthName,
                                assetPath: _getMonthAssetPath(now.month),
                              ),
                              const SizedBox(width: 16),
                              _YearTile(year: year),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Divider ───────────────────────────────────────────────────
                const SliverToBoxAdapter(child: Divider(height: 32)),

                // ── Profile section header ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose AAC Profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cloud_download_outlined),
                              tooltip: 'Download profile',
                              onPressed: () => _showDownloadDialog(context),
                            ),
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
                      ],
                    ),
                  ),
                ),

                // ── Profile grid ──────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
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
                        onDelete: (filteredProfiles.length > 1 && profile.id != 'default')
                            ? () => onDeleteProfile(profile)
                            : null,
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: BetaFooter()),
              ],
            );
          },
        ),
      ),

    );
  }

  Color _profileColor(ColorScheme cs, int index) {
    final colors = [cs.primaryContainer, cs.secondaryContainer, cs.tertiaryContainer, cs.surfaceContainerHighest];
    return colors[index % colors.length];
  }

  Future<void> _showAdminPasswordDialog(BuildContext context, ValueChanged<String> onProfileSelected) async {
    final adminProfile = profiles.cast<UserProfile?>().firstWhere((p) => p?.id == 'admin', orElse: () => null);
    
    if (adminProfile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin profile not found')));
      }
      return;
    }

    onProfileSelected(adminProfile.id);
  }

  Future<void> _showDownloadDialog(BuildContext context) async {
    final idController = TextEditingController();
    final passwordController = TextEditingController();

    final onlineId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Profile ID',
                hintText: 'Enter the online profile ID',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
                hintText: 'If the profile is protected',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(idController.text.trim()),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (onlineId == null || onlineId.isEmpty) return;
    if (!context.mounted) return;

    try {
      final downloaded = await FirebaseProfileSyncService.instance
          .downloadProfile(onlineId);
      if (downloaded == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile not found')),
          );
        }
        return;
      }

      // Assign a fresh local ID so it doesn't collide with existing profiles
      final localId = const Uuid().v4();
      final imported = downloaded.copyWith(
        id: localId,
        onlineId: onlineId,
      );

      if (context.mounted) {
        onDownloadedProfile?.call(imported);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      idController.dispose();
      passwordController.dispose();
    }
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return 'January';
    }
  }

  String _getDayAssetPath(int weekday) {
    switch (weekday) {
      case 1:
        return 'assets/Common/Time/monday.png';
      case 2:
        return 'assets/Common/Time/tuesday.png';
      case 3:
        return 'assets/Common/Time/wednesday.png';
      case 4:
        return 'assets/Common/Time/thursday.png';
      case 5:
        return 'assets/Common/Time/friday.png';
      case 6:
        return 'assets/Common/Time/saturday.png';
      case 7:
        return 'assets/Common/Time/sunday.png';
      default:
        return 'assets/Common/Time/monday.png';
    }
  }

  String _getMonthAssetPath(int month) {
    switch (month) {
      case 1:
        return 'assets/Common/Time/Months/january.png';
      case 2:
        return 'assets/Common/Time/Months/february.png';
      case 3:
        return 'assets/Common/Time/Months/march.png';
      case 4:
        return 'assets/Common/Time/Months/april.png';
      case 5:
        return 'assets/Common/Time/Months/may.png';
      case 6:
        return 'assets/Common/Time/Months/june.png';
      case 7:
        return 'assets/Common/Time/Months/july.png';
      case 8:
        return 'assets/Common/Time/Months/august.png';
      case 9:
        return 'assets/Common/Time/Months/september.png';
      case 10:
        return 'assets/Common/Time/Months/october.png';
      case 11:
        return 'assets/Common/Time/Months/november.png';
      case 12:
        return 'assets/Common/Time/Months/december.png';
      default:
        return 'assets/Common/Time/Months/january.png';
    }
  }
}

class _DateNumberTile extends StatelessWidget {
  final int dayNumber;
  const _DateNumberTile({required this.dayNumber});

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Dates/$dayNumber.png',
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.calendar_today, size: 80),
          ),
          const SizedBox(height: 8),
          Text(
            _ordinal(dayNumber),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _YearTile extends StatelessWidget {
  final int year;
  const _YearTile({required this.year});

  String _getZodiacAsset(int year) {
    // 2024: Dragon, 2025: Snake, 2026: Horse...
    // 2020 was Rat (Year of the Rat).
    final index = (year - 2020) % 12;
    final zodiacIndex = index < 0 ? index + 12 : index;
    
    const assets = [
      'assets/Common/Animals/Mammals/rat.png',           // 0: Rat
      'assets/Common/Animals/Mammals/cow.png',           // 1: Ox
      'assets/Common/Animals/Mammals/tiger.png',         // 2: Tiger
      'assets/Common/Animals/Mammals/rabbit.png',        // 3: Rabbit
      'assets/Common/Animals/Reptiles/komodo dragon.png', // 4: Dragon (Fallback to Komodo)
      'assets/Common/Animals/Reptiles/snake.png',        // 5: Snake
      'assets/Common/Animals/Mammals/horse.png',         // 6: Horse
      'assets/Common/Animals/Mammals/goat.png',          // 7: Goat
      'assets/Common/Animals/Mammals/monkey.png',        // 8: Monkey
      'assets/Common/Animals/Birds/rooster.png',         // 9: Rooster
      'assets/Common/Animals/Mammals/dog.png',           // 10: Dog
      'assets/Common/Animals/Mammals/pig.png'            // 11: Pig
    ];
    
    if (zodiacIndex >= 0 && zodiacIndex < assets.length) {
      return assets[zodiacIndex];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _getZodiacAsset(year);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: assetPath.isNotEmpty
                ? Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) {
                      debugPrint('Zodiac image failed to load: $assetPath');
                      return const Icon(Icons.calendar_today, size: 40, color: Colors.blueAccent);
                    },
                  )
                : const Icon(Icons.calendar_today, size: 40, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(
            year.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String assetPath;
  const _DateTile({required this.label, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          assetPath.toLowerCase().endsWith('.svg')
              ? SvgPicture.asset(assetPath, width: 80, height: 80, fit: BoxFit.contain)
              : Image.asset(assetPath, width: 80, height: 80, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (isActive) Icon(Icons.check_circle, color: colorScheme.primary),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete profile',
                      onPressed: onDelete,
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.primary,
                    backgroundImage: _getProfileImageProvider(),
                    child: profile.settings.profileImage.isEmpty
                        ? ClipOval(child: Image.asset('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png'))
                        : null,
                  ),
                ),
              ),
              Text(
                _profileNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _profileNote {
    if (profile.isAdmin) {
      return 'Changes made to this profile affect all profiles across all devices.';
    }
    if (profile.id == 'default') {
      return 'Changes to this profile affect only this device.';
    }
    return 'Changes to this profile affect only this profile on all devices you download the profile to.';
  }

  ImageProvider? _getProfileImageProvider() {
    final img = profile.settings.profileImage;
    if (img.isEmpty || img == 'assets/symbols/baycroft.png') {
      return const AssetImage('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png');
    }
    if (img.startsWith('data:')) return MemoryImage(base64Decode(img.split(',').last));
    if (img.startsWith('assets/')) return AssetImage(img);
    if (kIsWeb) return NetworkImage(img);
    return FileImage(File(img));
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
