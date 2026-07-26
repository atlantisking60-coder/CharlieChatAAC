import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/board_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../providers/pin_lock_provider.dart';
import '../models/pin_lock_model.dart';
import '../utils/responsive_layout.dart';
import 'pin_lock_guard.dart';
import 'pin_setup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Callbacks passed in from the parent (HomePage / main.dart)
// ─────────────────────────────────────────────────────────────────────────────
class AacHomeScreen extends ConsumerStatefulWidget {
  const AacHomeScreen({
    super.key,
    required this.profiles,
    required this.activeProfile,
    required this.boards,
    required this.favoritesService,
    required this.settings,
    required this.onBoardSelected,
    required this.onProfileSwitch,
    required this.onOpenSettings,
    required this.onMeModeToggle,
    required this.isMeMode,
  });

  final List<UserProfile> profiles;
  final UserProfile activeProfile;
  final List<Board> boards;
  final FavoritesService favoritesService;
  final AppSettings settings;
  final ValueChanged<Board> onBoardSelected;
  final ValueChanged<String> onProfileSwitch;
  final VoidCallback onOpenSettings;
  final VoidCallback onMeModeToggle;
  final bool isMeMode;

  @override
  ConsumerState<AacHomeScreen> createState() => _AacHomeScreenState();
}

class _AacHomeScreenState extends ConsumerState<AacHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showScrollToTop = false;
  late AnimationController _meModeController;
  late Animation<double> _meModeAnimation;

  // Quick-communication phrases (could later come from PhraseService)
  static const _quickPhrases = [
    'Yes',
    'No',
    'Help',
    'I want',
    'I need',
    'Stop',
    'More',
    'Finished',
    'Thank you',
    'Please',
  ];

  @override
  void initState() {
    super.initState();
    _meModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isMeMode ? 1.0 : 0.0,
    );
    _meModeAnimation = CurvedAnimation(
      parent: _meModeController,
      curve: Curves.easeInOut,
    );
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() { _showScrollToTop = show; });
      }
    });
  }

  @override
  void didUpdateWidget(AacHomeScreen old) {
    super.didUpdateWidget(old);
    if (old.isMeMode != widget.isMeMode) {
      widget.isMeMode
          ? _meModeController.forward()
          : _meModeController.reverse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _meModeController.dispose();
    super.dispose();
  }

  List<Board> get _favouriteBoards {
    final favIds = widget.favoritesService.favorites;
    return widget.boards.where((b) => favIds.contains(b.id)).toList();
  }

  List<Board> get _filteredBoards {
    if (_searchQuery.isEmpty) return widget.boards;
    final q = _searchQuery.toLowerCase();
    return widget.boards
        .where((b) => b.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLocked = ref.watch(pinIsLockedProvider);

    return ResponsiveLayout(
      symbolSizeScale: widget.settings.symbolSize,
      gridSpacingOverride: widget.settings.gridSpacing,
      builder: (context, layout) => AacLayoutProvider(
        layout: layout,
        child: _buildScaffold(context, layout, colorScheme, isLocked),
      ),
    );
  }

  Widget _buildScaffold(
      BuildContext context, AacLayout layout, ColorScheme colorScheme, bool isLocked) {
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.keyboard_arrow_up, size: 24),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          _buildAppBar(colorScheme, isLocked),

          // ── Search ────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSearch(colorScheme)),

          // Search results overlay
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(colorScheme)
          else ...[
            // ── Me Mode banner ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildMeModeBanner(colorScheme)),

            // ── Quick Communication ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.record_voice_over_rounded,
                title: 'Quick Communication',
                color: colorScheme.tertiary,
              ),
            ),
            SliverToBoxAdapter(child: _buildQuickComms(colorScheme)),

            // ── Favourite Boards ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.star_rounded,
                title: 'Favourite Boards',
                color: Colors.amber.shade700,
                trailing: _favouriteBoards.isEmpty ? null : TextButton(
                  onPressed: () => _showAllFavourites(context),
                  child: const Text('See all'),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFavouriteBoards(colorScheme)),

            // ── Profiles ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.people_alt_rounded,
                title: 'Profiles',
                color: colorScheme.primary,
              ),
            ),
            SliverToBoxAdapter(child: _buildProfiles(colorScheme)),

            // ── All Boards ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.grid_view_rounded,
                title: 'All Boards',
                color: colorScheme.secondary,
              ),
            ),
            _buildAllBoardsGrid(colorScheme),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(ColorScheme cs, bool isLocked) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
              child: _buildProfileAvatar(widget.activeProfile, 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${widget.activeProfile.name}',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.primaryContainer],
            ),
          ),
        ),
      ),
      actions: [
        // Me Mode toggle
        _MeModeToggle(
          isActive: widget.isMeMode,
          onToggle: widget.onMeModeToggle,
        ),
        // Settings (caregiver only)
        PermissionGuard(
          permission: PinPermission.accessSettings,
          placeholder: const SizedBox.shrink(),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ),
        // PIN lock button
        const _PinButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Widget _buildSearch(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SearchBar(
        controller: _searchController,
        hintText: 'Search boards and symbols…',
        leading: const Icon(Icons.search),
        trailing: _searchQuery.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ]
            : null,
        onChanged: (v) => setState(() => _searchQuery = v),
        elevation: const WidgetStatePropertyAll(1),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme cs) {
    final results = _filteredBoards;
    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: cs.outline),
              const SizedBox(height: 12),
              Text('No boards found for "$_searchQuery"',
                  style: TextStyle(color: cs.outline)),
            ],
          ),
        ),
      );
    }
    final layout = AacLayoutProvider.maybeOf(context);
    final maxExtent = ((layout?.tileSize ?? 64) * 2.2).clamp(120.0, 220.0);
    final spacing = layout?.gridSpacing ?? 12.0;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxExtent,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 0.85,
        ),
        itemCount: results.length,
        itemBuilder: (_, i) => _BoardCard(
          board: results[i],
          onTap: () => widget.onBoardSelected(results[i]),
        ),
      ),
    );
  }

  // ── Me Mode banner ─────────────────────────────────────────────────────────

  Widget _buildMeModeBanner(ColorScheme cs) {
    if (!widget.isMeMode) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _meModeAnimation,
      builder: (_, child) => Opacity(
        opacity: _meModeAnimation.value,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person_pin_rounded,
                color: Colors.deepPurple.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Me Mode Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  Text(
                    'Showing ${widget.activeProfile.name}\'s personalised layout',
                    style: TextStyle(
                        fontSize: 12, color: Colors.deepPurple.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Communication ────────────────────────────────────────────────────

  Widget _buildQuickComms(ColorScheme cs) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPhrases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final phrase = _quickPhrases[i];
          return _QuickPhraseChip(
            label: phrase,
            color: cs.secondaryContainer,
            labelColor: cs.onSecondaryContainer,
          );
        },
      ),
    );
  }

  // ── Favourite Boards ───────────────────────────────────────────────────────

  Widget _buildFavouriteBoards(ColorScheme cs) {
    final layout = AacLayoutProvider.maybeOf(context);
    final cardHeight = (layout?.tileSize ?? 64) * 1.9;
    final favs = _favouriteBoards;
    if (favs.isEmpty) {
      return _EmptySection(
        icon: Icons.star_border_rounded,
        message: 'Star a board to add it here',
        color: Colors.amber.shade700,
      );
    }
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: favs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _BoardCard(
          board: favs[i],
          onTap: () => widget.onBoardSelected(favs[i]),
          compact: true,
        ),
      ),
    );
  }

  void _showAllFavourites(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, ctrl) => _AllFavouritesSheet(
          boards: _favouriteBoards,
          onBoardSelected: (b) {
            Navigator.pop(context);
            widget.onBoardSelected(b);
          },
          scrollController: ctrl,
        ),
      ),
    );
  }

  // ── Profiles ───────────────────────────────────────────────────────────────

  Widget _buildProfiles(ColorScheme cs) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.profiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final profile = widget.profiles[i];
          final isActive = profile.id == widget.activeProfile.id;
          return _ProfileChip(
            profile: profile,
            isActive: isActive,
            onTap: () => widget.onProfileSwitch(profile.id),
          );
        },
      ),
    );
  }

  // ── All Boards grid ────────────────────────────────────────────────────────

  Widget _buildAllBoardsGrid(ColorScheme cs) {
    final layout = AacLayoutProvider.maybeOf(context);
    final maxExtent = ((layout?.tileSize ?? 64) * 2.2).clamp(120.0, 220.0);
    final spacing = layout?.gridSpacing ?? 12.0;
    final boards = widget.boards;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxExtent,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 0.85,
        ),
        itemCount: boards.length,
        itemBuilder: (_, i) => _BoardCard(
          board: boards[i],
          onTap: () => widget.onBoardSelected(boards[i]),
          isFavourite: widget.favoritesService.isFavorite(boards[i].id),
          onFavouriteToggle: () async {
            await widget.favoritesService.toggleFavorite(boards[i].id);
            setState(() {});
          },
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildProfileAvatar(UserProfile profile, double radius) {
    if (profile.settings.profileImage.isNotEmpty) {
      if (!kIsWeb) {
        final file = File(profile.settings.profileImage);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
          );
        }
      }
    }
    return Text(
      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: radius * 0.9,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _QuickPhraseChip extends StatefulWidget {
  const _QuickPhraseChip({
    required this.label,
    required this.color,
    required this.labelColor,
  });

  final String label;
  final Color color;
  final Color labelColor;

  @override
  State<_QuickPhraseChip> createState() => _QuickPhraseChipState();
}

class _QuickPhraseChipState extends State<_QuickPhraseChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          // TODO: hook into TTS service for speech output
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.label),
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.labelColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.board,
    required this.onTap,
    this.compact = false,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });

  final Board board;
  final VoidCallback onTap;
  final bool compact;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = compact ? 110.0 : 140.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BoardIcon(board: board, size: compact ? 44 : 56),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    board.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (onFavouriteToggle != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onFavouriteToggle,
                  child: Icon(
                    isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18,
                    color: isFavourite
                        ? Colors.amber.shade600
                        : cs.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardIcon extends StatelessWidget {
  const _BoardIcon({required this.board, required this.size});

  final Board board;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Try to load asset image; fall back to icon
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/symbols/BOARDS/${board.name}.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.grid_view_rounded,
            size: size * 0.5,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final UserProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  isActive ? cs.primary : cs.secondaryContainer,
              child: Text(
                profile.name.isNotEmpty
                    ? profile.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isActive ? cs.onPrimary : cs.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.5), size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                  color: color.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Me Mode Toggle ────────────────────────────────────────────────────────────

class _MeModeToggle extends StatelessWidget {
  const _MeModeToggle({required this.isActive, required this.onToggle});

  final bool isActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: isActive ? 'Me Mode: On' : 'Me Mode: Off',
        child: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.deepPurple.shade400
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_pin_rounded,
                  size: 16,
                  color: isActive ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  'Me',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIN button ────────────────────────────────────────────────────────────────

class _PinButton extends ConsumerWidget {
  const _PinButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinLockProvider);
    final isConfigured = pinState.config.isConfigured;

    return IconButton(
      icon: Icon(isConfigured ? Icons.lock_outline : Icons.lock_open_outlined),
      tooltip: isConfigured ? 'Lock / PIN settings' : 'Set up PIN lock',
      onPressed: () {
        if (isConfigured) {
          showModalBottomSheet(
            context: context,
            builder: (_) => _PinOptions(
              onLock: () {
                Navigator.pop(context);
                ref.read(pinLockProvider.notifier).lockNow();
              },
              onSetup: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PinSetupScreen()));
              },
            ),
          );
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PinSetupScreen()));
        }
      },
    );
  }
}

class _PinOptions extends StatelessWidget {
  const _PinOptions({required this.onLock, required this.onSetup});

  final VoidCallback onLock;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.red),
            title: const Text('Lock Now'),
            subtitle: const Text('Lock the app immediately'),
            onTap: onLock,
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('PIN Settings'),
            subtitle: const Text('Change PIN, timeout, permissions'),
            onTap: onSetup,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── All Favourites sheet ───────────────────────────────────────────────────────

class _AllFavouritesSheet extends StatelessWidget {
  const _AllFavouritesSheet({
    required this.boards,
    required this.onBoardSelected,
    required this.scrollController,
  });

  final List<Board> boards;
  final ValueChanged<Board> onBoardSelected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Favourite Boards',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ),
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: boards.length,
            itemBuilder: (_, i) => _BoardCard(
              board: boards[i],
              onTap: () => onBoardSelected(boards[i]),
            ),
          ),
        ),
      ],
    );
  }
}
