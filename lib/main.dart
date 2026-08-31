import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle, HardwareKeyboard, LogicalKeyboardKey;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'data/symbol_data.dart';
import 'data/board_icon_assets.dart';
import 'data/symbol_icon_assets.dart';
import 'data/board_hierarchy.dart';
import 'models/symbol_tile.dart';
import 'services/board_icon_resolver.dart';
import 'services/board_service.dart';
import 'services/cross_platform_tts_service.dart';
import 'services/external_symbol_service.dart';
import 'services/filesystem_access.dart' as fsa;
import 'services/image_cleanup_service.dart';
import 'services/favorites_service.dart';
import 'services/phrase_service.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';
import 'services/symbol_metadata_service.dart';
import 'widgets/settings_screen.dart';
import 'widgets/settings/settings_shell.dart';
import 'widgets/symbol_grid.dart';
import 'widgets/sync_status_screen.dart';
import 'widgets/empty_boards_screen.dart';
import 'services/empty_boards_service.dart';
import 'widgets/board_editor.dart';
import 'widgets/board_search_dialog.dart';
import 'widgets/welcome_screen.dart';
import 'widgets/new_profile_dialog.dart';
import 'widgets/auth_guard.dart';
import 'utils/board_export_utils.dart';
import 'utils/board_export_download.dart';
import 'widgets/pin_lock_guard.dart';
import 'utils/responsive_layout.dart';

const int defaultBoardRows = 1;
const int defaultBoardColumns = 8;

enum AppMode {
  home,
  school,
  sign,
  mySchool,
  legends,
  recipes,
  personal,
  unassigned,
}

/// ENTRY POINT
/// This is where the app starts. We initialize Firebase and wrap the root
/// with Riverpod for state management and authentication.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface build/runtime errors directly instead of leaving a white screen.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('STACK: ${details.stack}');
  };
  ErrorWidget.builder = (details) {
    return Material(
      child: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(24),
        child: SelectableText(
          'Error:\n${details.exception}\n\n${details.stack ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  };

  try {
    if (FirebaseConfigValidator.isConfigured()) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // Firebase not available; auth guard will fall back to offline mode.
  }
  runApp(const ProviderScope(child: CharlieChatApp()));
}

class CharlieChatApp extends StatefulWidget {
  const CharlieChatApp({super.key});

  @override
  State<CharlieChatApp> createState() => _CharlieChatAppState();
}

class _CharlieChatAppState extends State<CharlieChatApp> {
  bool _loading = true;
  bool _showWelcome = true;
  final _navigatorKey = GlobalKey<NavigatorState>();
  late SettingsService _settingsService;
  late ProfileService _profileService;
  List<UserProfile> _profiles = [];
  String _activeProfileId = '';
  String? _selectedProfileId;
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

/// INITIAL LOAD
/// We initialize the settings and profile services here.
/// This determines which user profile was last active and sets the theme.

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.init();
    _profileService = await ProfileService.init();
    _profiles = _profileService.profiles;
    final activeProfile = _profileService.activeProfile;
    setState(() {
      _activeProfileId = activeProfile.id;
      _settings = activeProfile.settings;
      _loading = false;
    });
  }

/// GLOBAL SETTINGS UPDATER
/// When a user changes volume or font size in the settings menu, 
/// this function saves it to the profile and refreshes the UI.

  Future<void> _updateSettings(AppSettings settings) async {
    await _settingsService.saveSettings(settings);
    if (_selectedProfileId != null) {
      final profiles = _profileService.profiles;
      final index =
          profiles.indexWhere((profile) => profile.id == _selectedProfileId);
      if (index >= 0) {
        await _profileService.saveProfile(
          profiles[index].copyWith(settings: settings),
        );
      }
      _profiles = _profileService.profiles;
    }
    setState(() {
      _settings = settings;
    });
  }

  static Color _seedColorFor(String theme) {
    switch (theme) {
      case 'blue':   return Colors.blue;
      case 'purple': return Colors.deepPurple;
      case 'green':  return Colors.green;
      case 'orange': return Colors.deepOrange;
      case 'rose':   return const Color(0xFFE91E8C);
      case 'mono':   return Colors.blueGrey;
      default:       return Colors.teal;
    }
  }

  static double _textScaleFor(String size) {
    switch (size) {
      case 'small': return 0.85;
      case 'large': return 1.2;
      default:      return 1.0;
    }
  }

  static ThemeData _buildTheme(
      Color seed, Brightness brightness, bool highContrast) {
    if (highContrast) {
      final isLight = brightness == Brightness.light;
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: isLight ? Colors.black : Colors.white,
          onPrimary: isLight ? Colors.white : Colors.black,
          secondary: isLight ? Colors.black87 : Colors.white70,
          onSecondary: isLight ? Colors.white : Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: isLight ? Colors.white : Colors.black,
          onSurface: isLight ? Colors.black : Colors.white,
          // ignore: deprecated_member_use
          background: isLight ? Colors.white : Colors.black,
          // ignore: deprecated_member_use
          onBackground: isLight ? Colors.black : Colors.white,
        ),
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
    );
  }

  Future<bool> _selectProfile(String profileId) async {
    final profile = _profileService.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => _profileService.activeProfile,
    );
    if (profile.id != 'default') {
      final dialogContext = _navigatorKey.currentContext;
      if (dialogContext == null) return false;
      final authenticated = await showDialog<bool>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (ctx) => _LoginDialog(
            profile: profile, profileService: _profileService),
      );
      if (authenticated != true) return false;
    }

    await _profileService.setActiveProfile(profileId);
    setState(() {
      _activeProfileId = profile.id;
      _selectedProfileId = profile.id;
      _settings = profile.settings;
    });
    return true;
  }

  Future<void> _showProfileHome() async {
    _profiles = _profileService.profiles;
    final activeProfile = _profileService.activeProfile;
    setState(() {
      _activeProfileId = activeProfile.id;
      _settings = activeProfile.settings;
      _selectedProfileId = null;
    });
  }

  void _activeProfileChanged(String profileId) {
    _profiles = _profileService.profiles;
    final profile = _profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => _profiles.isNotEmpty ? _profiles.first : UserProfile.defaultProfile(),
    );
    setState(() {
      _activeProfileId = profileId;
      _selectedProfileId = profileId;
      _settings = profile.settings;
    });
  }

  Future<void> _createNewProfile() async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;
    final profile = await NewProfileDialog.show(
        dialogContext, _profileService.activeProfile);
    if (profile == null) return;

    await _profileService.createProfile(profile);
    setState(() {
      _profiles = _profileService.profiles;
      _activeProfileId = profile.id;
      // Stay on ProfileHomeScreen — do NOT set _selectedProfileId
    });
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;
    final confirmed = await showDialog<bool>(
          context: dialogContext,
          builder: (ctx) => AlertDialog(
            title: Text('Delete ${profile.name}?'),
            content: const Text(
                'This removes saved settings for this profile. Boards and symbols stay available.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _profileService.deleteProfile(profile.id);
    final activeProfile = _profileService.activeProfile;
    setState(() {
      _profiles = _profileService.profiles;
      _activeProfileId = activeProfile.id;
      _settings = activeProfile.settings;
      if (_selectedProfileId == profile.id) {
        _selectedProfileId = null;
      }
    });
  }

  Future<void> _importDownloadedProfile(UserProfile profile) async {
    await _profileService.createProfile(profile);
    setState(() {
      _profiles = _profileService.profiles;
      _activeProfileId = profile.id;
      _settings = profile.settings;
      _selectedProfileId = profile.id;
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
/// APP SHELL 
/// This defines the high-level theme and switches between the
/// Profile Selection Screen and the main Home Page.

    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final seedColor = _seedColorFor(_settings.colourTheme);
    final textScale = _textScaleFor(_settings.fontSize);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Charlie Chat',
      theme: _buildTheme(seedColor, Brightness.light, _settings.highContrast),
      darkTheme: _buildTheme(seedColor, Brightness.dark, _settings.highContrast),
      themeMode: _settings.themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AuthGuard(
        child: PinLockGuard(
          child: _showWelcome || _selectedProfileId == null
              ? WelcomeScreen(
                  onContinue: () {
                    setState(() {
                      _showWelcome = false;
                    });
                  },
                  profiles: _profiles,
                  activeProfileId: _activeProfileId,
                  onProfileSelected: (id) => _selectProfile(id).then(
                    (ok) {
                      if (ok) setState(() => _showWelcome = false);
                    },
                  ),
                  onCreateProfile: _createNewProfile,
                  onDeleteProfile: _deleteProfile,
                  onDownloadedProfile: _importDownloadedProfile,
                )
              : HomePage(
                  key: ValueKey(_selectedProfileId),
                  initialSettings: _settings,
                  onSettingsChanged: _updateSettings,
                  onActiveProfileChanged: _activeProfileChanged,
                  onExitToProfiles: _showProfileHome,
                ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final ValueChanged<String> onActiveProfileChanged;
  final VoidCallback onExitToProfiles;

  const HomePage(
      {super.key,
      required this.initialSettings,
      required this.onSettingsChanged,
      required this.onActiveProfileChanged,
      required this.onExitToProfiles});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// TAB MODEL
/// Used to define the top navigation bar. 
/// Tabs can either be a custom "Board" or a system utility like "Settings".

enum TopTabType { category, board, favorites, settings, editor }

class TopTab {
  final String id;
  final String label;
  final IconData? icon;
  final String? iconAssetPath;
  final TopTabType type;
  final Board? board;
  final Board? parentBoard;

  TopTab({
    required this.id,
    required this.label,
    this.icon,
    this.iconAssetPath,
    required this.type,
    this.board,
    this.parentBoard,
  });

  TopTab copyWith({
    String? id,
    String? label,
    IconData? icon,
    String? iconAssetPath,
    TopTabType? type,
    Board? board,
    Board? parentBoard,
  }) =>
      TopTab(
        id: id ?? this.id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        iconAssetPath: iconAssetPath ?? this.iconAssetPath,
        type: type ?? this.type,
        board: board ?? this.board,
        parentBoard: parentBoard ?? this.parentBoard,
      );
}

class _HomePageState extends State<HomePage> {
  final List<SymbolTile> _phrase = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sentenceController = TextEditingController();
  late CrossPlatformTtsService _tts;
  String _selectedCategory = allCategories.isNotEmpty ? allCategories.first : 'All';
  bool _loading = true;
  bool _isLoadingActiveBoard = false;
  String? _boardLoadError;
  String? _missingBoardId;
  String? _missingBoardName;
  FavoritesService? _favoritesService;
  PhraseHistoryService? _phraseService;
  late ProfileService _profileService;
  late SymbolMetadataService _metadataService;
  List<UserProfile> _profiles = [];
  UserProfile? _activeProfile;
  AppSettings? _settings;
  List<Board> _boards = [];
  List<Board> _allBoards = [];
  bool _isLoadingFavorites = false;
  static final Map<String, String> _subjectVocabLessonIcons = {};

  /// Set of every bundled web asset (assets/**). Used to reject icon paths
  /// that don't exist in the bundle (e.g. stale 'assets/Default Tab Icons/...'
  /// references) before they trigger console 404s. null = not loaded yet.
  static Set<String>? _validIconAssets;
  List<TopTab> _tabs = [];
  TopTab? _activeTab;
  Board? _parentBoard;
  List<String> _availableLanguages = _fallbackLanguages;
  List<VoiceOption> _availableVoices = [];
  int _visibleBoardRows = 12;
  String? _visibleBoardId;
  AppMode _currentMode = AppMode.home;
  bool _isUpdatingText = false;
  final ExternalSymbolService _externalSymbolService = ExternalSymbolService();
  final List<TopTab> _navigationHistory = [];
  final GlobalKey _boardViewKey = GlobalKey();
  final AudioPlayer _customVoicePlayer = AudioPlayer();
  final ScrollController _boardScrollController = ScrollController();
  final ScrollController _boardHorizontalScrollController = ScrollController();
  double _gridZoom = 1.0;
  double _gridZoomStart = 1.0;
  final Map<String, ScrollController> _tabScrollControllers = {};
  final Map<String, GlobalKey> _tabActiveKeys = {};
  final Map<String, String> _iconPathCache = {};
  bool _showScrollToTop = false;

  List<Board> get _favouriteBoards {
    final favIds = _favoritesService?.favoriteBoards ?? <String>{};
    return _allBoards.where((b) => favIds.contains(b.id)).toList();
  }

  void _onBoardTap(Board board) {
    _openLinkedBoard(board.id);
  }

  // Sub-boards that are hidden from the top-level tab bar but shown as a second row when their parent is active.
  static const List<String> _subBoardNames = [];
  final Map<String, SymbolTile> _typedWordCache = {};
  // Lazily-built index of label -> tile across every board in every area
  // (not just the currently-loaded area's boards), so a typed word that
  // genuinely has a symbol elsewhere in the app (e.g. "help" on Common
  // Words) is still found while e.g. the Sentence Creator (Subject Vocab)
  // is active.
  Map<String, SymbolTile>? _globalWordIndex;
  Future<Map<String, SymbolTile>>? _globalWordIndexFuture;
  List<SymbolTile> _localAssetResults = [];
  String _lastAssetSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

/// MAIN INITIALIZATION
/// This is a multi-step process that sets up Audio (TTS), 
/// Storage (Profiles/Boards), and UI (Tabs) without blocking the user.

  Future<void> _initializeApp() async {
    try {
      _tts = CrossPlatformTtsService.instance;
      await _tts.initialize();
      _profileService = await ProfileService.init();
      _metadataService = await SymbolMetadataService.init();
      _phraseService = await PhraseHistoryService.init();
      _profiles = _profileService.profiles;
      _activeProfile = _profileService.activeProfile;
      _settings = _activeProfile?.settings ?? widget.initialSettings;
      
      // Initialize favorites service AFTER active profile is known
      _favoritesService = await FavoritesService.init(profileId: _activeProfile?.id ?? 'default');
      
      final boardService = await BoardService.getInstance(
        projectRoot: _settings?.projectRoot.isNotEmpty == true ? _settings!.projectRoot : null,
      );
      if (!mounted) return;
      boardService.setCurrentProfileId(_activeProfile?.id ?? 'default');

      if (_subjectVocabLessonIcons.isEmpty) await _loadSubjectVocabLessonIcons();
      await _loadValidIconAssets();

      // Tab orders now have a compiled fallback (see defaultTabOrders in
      // lib/data/tab_orders_data.dart) that's kept in sync with the curated
      // tab_orders.json, so there's no need to seed defaults here any more.
      // This used to hardcode its own copies of a couple of orders — those
      // had drifted out of date (e.g. missing 'My School Main' entirely) and,
      // because they were saved straight to this browser's local storage the
      // first time the app ran, permanently stuck once saved even after the
      // real default was fixed.

      // Self-heal: 'My School Main' is the My School landing board and must
      // always be first. Older builds seeded a tab order without it at all,
      // which — once persisted to a browser's local storage — otherwise
      // shadows the corrected compiled default forever.
      final mySchoolOrder = boardService.getTabOrder('My School');
      if (mySchoolOrder != null && !mySchoolOrder.contains('My School Main')) {
        await boardService.saveTabOrder(
            'My School', ['My School Main', ...mySchoolOrder]);
      }

      // Load the Common area tab list as placeholders, then fill the active
      // board. Only the selected board's tiles are loaded at startup.
      _currentMode = AppMode.home;
      await _loadBoards(area: 'Common');
      if (!mounted) return;

      _boardScrollController.addListener(() {
        // Requirement: Make the scroll to top button less sensitive
        final show = _boardScrollController.offset > 10;
        if (show != _showScrollToTop) {
          setState(() { _showScrollToTop = show; });
        }
      });

      _sentenceController.addListener(_onSentenceChanged);
    } catch (e) {
      debugPrint('Error during initialization: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
    // Load voices and configure TTS in the background to prevent startup lag
    _loadAvailableVoices().then((_) => _configureTts()).catchError((e) {
      debugPrint('Error loading voices: $e');
    });
  }

  AppMode _appModeForArea(String? area) {
    switch (area) {
      case 'Legends':
        return AppMode.legends;
      case 'Recipes':
        return AppMode.recipes;
      case 'My School':
        return AppMode.mySchool;
      case 'Sign':
        return AppMode.sign;
      case 'Subject Vocab':
        return AppMode.school;
      case 'Personal':
        return AppMode.personal;
      case 'Unassigned':
        return AppMode.unassigned;
      case 'Common':
      default:
        return AppMode.home;
    }
  }

  Future<void> _persistSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_mode', _currentMode.toString());
      if (_activeTab != null) {
        await prefs.setString('active_tab_id', _activeTab!.id);
      }
      if (_parentBoard != null) {
        await prefs.setString('active_parent_id', _parentBoard!.id);
      } else {
        await prefs.remove('active_parent_id');
      }
    } catch (e) {
      if (e.toString().contains('QuotaExceededError')) {
        await BoardService.instance?.freeWebStorage();
      }
      debugPrint('Error persisting session state: $e');
    }
  }

  Future<void> _loadBoards({String? area}) async {
    final service = await BoardService.getInstance();
    final loadArea = area;

    // 1. Load the area's board list WITHOUT waiting for tab-icon metadata.
    // The tab row renders immediately (names/tiers come from storage and the
    // compiled hierarchy — no asset parsing), and the landing board starts
    // loading right away instead of queuing behind icon fetches. Icons fill in
    // from the background pass in step 3.
    _boards = await service.listBoards(
        area: loadArea, includeTiles: false, awaitIcons: false);
    _buildTabs();
    unawaited(_loadFullActiveBoard());

    // 2. Background load for all boards (for unified favorites and global search).
    // This runs unawaited to avoid blocking the main UI thread.
    unawaited(service.listBoards(includeTiles: false, awaitIcons: false).then((all) {
      if (!mounted) return;
      setState(() {
        _allBoards = all;
      });
      if (_activeTab?.type == TopTabType.favorites) {
        _triggerFavoritesLoad();
      }
    }));

    // 3. Background pass that resolves any still-missing tab/tile icon
    // metadata for THIS area, then refreshes the tab rows so icons pop in as
    // soon as they land. Ignored when the user has switched areas meanwhile.
    unawaited(service
        .listBoards(area: loadArea, includeTiles: false, awaitIcons: true)
        .then((fresh) {
      if (!mounted || loadArea != _activeArea()) return;
      var changed = false;
      for (final fb in fresh) {
        final i = _boards.indexWhere((b) => b.id == fb.id);
        if (i < 0) continue;
        final b = _boards[i];
        final fbIcon = fb.iconAssetPath ?? '';
        final fbTileIcon = fb.tileIconAssetPath ?? '';
        if ((b.iconAssetPath ?? '') != fbIcon ||
            (b.tileIconAssetPath ?? '') != fbTileIcon) {
          b.iconAssetPath = fbIcon.isEmpty ? null : fb.iconAssetPath;
          b.tileIconAssetPath = fbTileIcon.isEmpty ? null : fb.tileIconAssetPath;
          changed = true;
          }
        }
        if (changed && mounted) {
          setState(() => _buildTabsInternal(_activeTab?.id));
        }
        unawaited(_preloadIconsForBoards(_boards));
      }));
  }

  void _triggerFavoritesLoad() async {
    if (_isLoadingFavorites || _allBoards.isEmpty) return;
    setState(() => _isLoadingFavorites = true);
    try {
      final service = await BoardService.getInstance();
      final favBoardIds = _favoritesService?.favoriteBoards ?? <String>{};
      final favTileIds = _favoritesService?.favorites ?? <String>{};
      
      // Load all boards that are favorited OR contain a favorite tile.
      final boardsToLoad = _allBoards.where((b) => 
        favBoardIds.contains(b.id) || 
        favTileIds.any((id) => id.startsWith(b.id + "_"))
      ).toList();

      for (final b in boardsToLoad) {
        // Skip if already fully loaded
        if (_allBoards.any((existing) => existing.id == b.id && existing.tiles.isNotEmpty)) continue;
        
        final full = await service.getBoard(b.id);
        if (full != null) {
          setState(() {
            final idx = _allBoards.indexWhere((existing) => existing.id == full.id);
            if (idx >= 0) _allBoards[idx] = full;
            
            // Also update the filtered current-area list if this board is in it
            final bIdx = _boards.indexWhere((existing) => existing.id == full.id);
            if (bIdx >= 0) _boards[bIdx] = full;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _loadFullActiveBoard() async {
    if (_activeTab?.type != TopTabType.board || _activeTab?.board == null) return;
    final service = await BoardService.getInstance();
    final targetTabId = _activeTab!.id;
    final targetBoardId = _activeTab!.board!.id;
    service.setPriorityBoardId(targetBoardId);
    if (mounted) setState(() => _isLoadingActiveBoard = true);
    final full = await service.getBoard(targetBoardId);
    if (!mounted) return;
    // Ignore the result if the user already navigated elsewhere while the
    // board was being fetched (area switches can overlap; the newer request
    // owns the spinner and the tab row).
    if (_activeTab?.id != targetTabId || _activeTab?.board?.id != targetBoardId) {
      if (_activeTab?.type != TopTabType.board && mounted) {
        setState(() => _isLoadingActiveBoard = false);
      }
      return;
    }
    if (full == null) {
      setState(() => _isLoadingActiveBoard = false);
      final missingBoard = _createAutoMissingBoard(
        targetBoardId,
        _activeTab!.board!.name,
        area: _activeTab!.board!.area,
      );
      await _upsertBoard(missingBoard);
      return;
    }
    setState(() {
      _isLoadingActiveBoard = false;
      _boardLoadError = null;
      _missingBoardId = null;
      _missingBoardName = null;
      final index = _boards.indexWhere((b) => b.id == full.id);
      if (index >= 0) {
        _boards[index] = full;
      } else {
        _boards.add(full);
      }
      _activeTab = TopTab(
        id: _activeTab!.id,
        label: _activeTab!.label,
        icon: _activeTab!.icon,
        iconAssetPath: _activeTab!.iconAssetPath,
        type: _activeTab!.type,
        board: full,
        parentBoard: _activeTab!.parentBoard,
      );
    });
  }

  String _sanitizeIconAssetPath(String path) {
    try {
      // Decode twice to undo accidental double-encoding (e.g. %2520 -> space).
      return Uri.decodeFull(Uri.decodeFull(path));
    } catch (_) {
      return path;
    }
  }

  String _bestBoardIconPath(String boardName, List<String> paths) {
    if (paths.isEmpty) return '';
    final lower = boardName.toLowerCase();
    // Prefer an exact file-name match
    for (final path in paths) {
      final fileName = p.basenameWithoutExtension(path).toLowerCase().trim();
      if (fileName == lower) return _sanitizeIconAssetPath(path);
    }
    // Otherwise prefer the shortest (least nested) path
    final sorted = List<String>.from(paths)..sort((a, b) => a.length.compareTo(b.length));
    return _sanitizeIconAssetPath(sorted.first);
  }

  Future<void> _loadSubjectVocabLessonIcons() async {
    if (_subjectVocabLessonIcons.isNotEmpty) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final path in manifest.listAssets()) {
        if (!path.toLowerCase().startsWith('assets/subject vocab/lessons/')) continue;
        if (!path.toLowerCase().endsWith('.png')) continue;
        _subjectVocabLessonIcons[p.basenameWithoutExtension(path).toLowerCase()] = path;
      }
    } catch (e) {
      debugPrint('Error loading Subject Vocab/Lessons icon manifest: $e');
    }
  }

  /// Loads the full set of bundled asset paths once. Icon mappings that point
  /// at files missing from the bundle are skipped so the UI falls back to a
  /// real bundled icon (or the default fallback) instead of firing 404s.
  Future<void> _loadValidIconAssets() async {
    if (_validIconAssets != null) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _validIconAssets = manifest
          .listAssets()
          .where((path) => path.startsWith('assets/') && path.endsWith('.png'))
          .toSet();
    } catch (e) {
      debugPrint('Error loading asset manifest for icon validation: $e');
      _validIconAssets = const {};
    }
  }

  /// Returns true if [path] is present in the bundled asset manifest. Until
  /// the manifest is loaded, unknown paths are assumed valid to preserve the
  /// previous behaviour.
  bool _isBundledIconAsset(String path) {
    final valid = _validIconAssets;
    if (valid == null) return true;
    try {
      return valid.contains(Uri.decodeFull(path));
    } catch (_) {
      return true;
    }
  }

  // Resolves and precaches icons for a board's children. Boards with many
  // children (e.g. Disney Stories has ~70 movies) used to do this as a
  // sequential await-per-child loop, which could take many seconds and
  // blocked navigation until every single icon had resolved. Now the work
  // for all children runs concurrently, and callers no longer need to await
  // this before showing the board — the icons simply pop in once ready via
  // the trailing setState.
  Future<void> _preResolveChildIcons(Board parent) async {
    final children = _boards.where((b) => b.parentBoardId == parent.id).toList();
    if (children.isEmpty) return;
    await Future.wait(children.map((child) async {
      try {
        await BoardService.instance?.preloadBoardIcon(child);
        if (!mounted) return;
        final path = _getBoardIconPath(child);
        if (path.startsWith('assets/')) {
          await precacheImage(
            AssetImage(path),
            context,
            size: const Size(36, 36),
          ).catchError((_) {});
        }
      } catch (_) {}
    }));
    if (mounted) setState(() {});
  }

  // Re-checks the icons behind the tab rows currently on screen and
  // repopulates any that have drifted. Tabs can be rebuilt from boards whose
  // stored iconAssetPath is empty or stale (area switches, hierarchy
  // navigation, refreshed server copies), which makes icons "revert". The
  // canonical compiled-index icon wins; boards the index has no icon for are
  // fetched asynchronously from the icon store/dev server.
  void _repopulateVisibleTabIcons() {
    final service = BoardService.current;
    if (service == null) return;
    var changed = false;
    final toLoad = <Board>[];
    final visitedIds = <String>{};
    void visit(Board? b) {
      if (b == null || !visitedIds.add(b.id)) return;
      final canonical = service.canonicalBoardIcon(b.id);
      final current = b.iconAssetPath;
      if (canonical != null && canonical.isNotEmpty && current != canonical) {
        b.iconAssetPath = canonical;
        _iconPathCache[b.id] = canonical;
        changed = true;
      } else if ((current == null || current.isEmpty) &&
          _iconPathCache[b.id] == null &&
          (canonical == null || canonical.isEmpty)) {
        toLoad.add(b);
      }
    }

    for (final tab in _tabs) {
      visit(tab.board);
    }
    // Visit the active board's lineage and the sub-tab rows that render for
    // each ancestor, so every icon used in the visible tab rows is checked.
    final visitedLineageIds = <String>{};
    Board? current = _activeTab?.board;
    while (current != null && current.parentBoardId != null) {
      if (!visitedLineageIds.add(current.id)) break;
      for (final sub in _subTabsForBoard(current)) {
        visit(sub.board);
      }
      final parent = _boards.cast<Board?>().firstWhere(
            (b) => b?.id == current!.parentBoardId,
            orElse: () => null,
          );
      if (parent == null) break;
      current = parent;
    }
    if (_activeTab?.board != null) {
      for (final sub in _subTabsForBoard(_activeTab!.board!)) {
        visit(sub.board);
      }
    }
    visit(_activeTab?.board);
    visit(_parentBoard);

    if (changed && mounted) {
      setState(() => _buildTabsInternal(_activeTab?.id));
    }
    if (toLoad.isNotEmpty) unawaited(_preloadIconsForBoards(toLoad));
  }

  Future<void> _preloadIconsForBoards(List<Board> boards) async {
    await Future.wait(boards.map((b) async {
      try {
        await BoardService.instance?.preloadBoardIcon(b);
      } catch (_) {}
    }));
    if (!mounted) return;
    if (boards.any((b) => b.iconAssetPath != null && b.iconAssetPath!.isNotEmpty)) {
      setState(() => _buildTabsInternal(_activeTab?.id));
    }
  }

  String _getBoardIconPath(Board board) {
    // Canonical icon from the compiled board index wins. This keeps tab icons
    // stable even when tabs are rebuilt from boards whose iconAssetPath is
    // empty/stale (function/area switches, hierarchy navigation, etc).
    final canonical = BoardService.current?.canonicalBoardIcon(board.id);
    if (canonical != null && canonical.isNotEmpty) return canonical;
    if (board.iconAssetPath != null && board.iconAssetPath!.isNotEmpty) {
      return board.iconAssetPath!;
    }
    final cached = _iconPathCache[board.id];
    if (cached != null) return cached;
    return _iconPathCache[board.id] = _resolveBoardIconPath(board);
  }

  String _resolveBoardIconPath(Board board) {
    final boardName = board.name;
    final searchName = boardName.toLowerCase().trim();

    final iconMappings = {
      // HOME mode icons
      'ANIMALS': 'assets/Default Tab Icons/animals.png',
      'JOBS and CAREERS': 'assets/Default Tab Icons/jobs and careers.png',
      'TIME': 'assets/Default Tab Icons/time.png',
      'MORE BOARDS': 'assets/BOARDS/More ++.png',
      'MORE WORDS': 'assets/BOARDS/More ++.png',
      
      // SCHOOL mode icons (subject vocab boards) - assets/symbols/Subjects
      'SENTENCE CREATOR': 'assets/Subject Vocab/sentence.png',
      'BETTER WORDS': 'assets/Subject Vocab/thesaurus.png',
      'Lessons': 'assets/Subject Vocab/timetable.png',
      'English': 'assets/Subject Vocab/Lessons/English.png',
      'Maths': 'assets/Subject Vocab/Lessons/Maths.png',
      'Science': 'assets/Subject Vocab/Lessons/Science.png',
      'Equipment For Science': 'assets/BOARDS/Science/Year 7/Science Equipment.png',
      'PEEP Keywords': 'assets/BOARDS/Keywords.png',
      'TFL': 'assets/Subject Vocab/Lessons/TFL.png',
      'Personal Development': 'assets/Subject Vocab/Lessons/PD.png',
      'PEEP': 'assets/Subject Vocab/Lessons/PEEP.png',
      'EPIC': 'assets/Subject Vocab/Lessons/EPIC.png',
      'PE': 'assets/Subject Vocab/Lessons/PE.png',
      'Physical Education': 'assets/Subject Vocab/Lessons/PE.png',
      'PD': 'assets/Subject Vocab/Lessons/PD.png',
      'Communication': 'assets/Subject Vocab/Lessons/EPIC.png',
      'Geography': 'assets/Subject Vocab/Lessons/PEEP.png',
      'History': 'assets/Subject Vocab/Lessons/PEEP.png',
      'IT': 'assets/Subject Vocab/Lessons/IT.png',
      'TFL / IT': 'assets/Subject Vocab/Lessons/TFL.png',
      'Art': 'assets/Subject Vocab/Lessons/Art.png',
      'Performing Arts': 'assets/Subject Vocab/Lessons/Performing Arts.png',
      'Sustainability': 'assets/Subject Vocab/Lessons/Sustainability.png',
      'Cooking': 'assets/Subject Vocab/Lessons/Cooking.png',
      'Resistant Materials': 'assets/Subject Vocab/Lessons/Resistant Materials and Construction.png',
      'Textiles': 'assets/Subject Vocab/Lessons/Textiles.png',
      'Religion and Worldviews': 'assets/Subject Vocab/Lessons/Religion and Worldviews.png',
      'Music': 'assets/Subject Vocab/Lessons/Music.png',
      'Horticulture': 'assets/Subject Vocab/Lessons/Horticulture.png',
      'Retail': 'assets/Subject Vocab/Lessons/Retail.png',
      'Photography': 'assets/Subject Vocab/Lessons/Photography.png',
      'Information Technology': 'assets/Subject Vocab/Lessons/IT.png',
      'Construction': 'assets/Subject Vocab/Lessons/Resistant Materials and Construction.png',
      'Engineering': 'assets/Subject Vocab/Lessons/Engineering.png',
      'Living Life Skills': 'assets/Subject Vocab/Lessons/Living Life Skills.png',
      'Prepare For Adulthood': 'assets/Subject Vocab/Lessons/Prepare For Adulthood.png',
      'Break and Lunch': 'assets/Subject Vocab/Lessons/Breaktime.png',
      'Tutor Time': 'assets/Subject Vocab/Lessons/Tutor Time.png',
      
      // SIGN mode icons
      'Sign': 'assets/Default Tab Icons/sign.png',
      'BSL': 'assets/Default Tab Icons/bsl.png',
      'Makaton': 'assets/Default Tab Icons/makaton.png',
      'A-Z Of Sign': 'assets/Default Tab Icons/a-z of sign.png',
      'Sign A-Z': 'assets/Default Tab Icons/sign a-z.png',
      'Manners and Greetings': 'assets/Default Tab Icons/manners and greetings.png',
      'Family and People': 'assets/Default Tab Icons/family and people.png',
      'Animals and Nature': 'assets/Default Tab Icons/animals and nature.png',
      'Transport and Vehicles': 'assets/Default Tab Icons/transport and vehicles.png',
      'Food and Drink': 'assets/Default Tab Icons/food and drink.png',
      'Home and Household': 'assets/Default Tab Icons/home and household.png',
      'Feelings and Health': 'assets/Default Tab Icons/feelings and health.png',
      'School and Instructions': 'assets/Default Tab Icons/school and instructions.png',
      'Descriptions and Attributes': 'assets/Default Tab Icons/descriptions and attributes.png',
      'Prepositions': 'assets/Default Tab Icons/prepositions.png',
      'Outside': 'assets/Default Tab Icons/outside.png',
      'Time and Days': 'assets/Default Tab Icons/time and days.png',
      'Questions': 'assets/Default Tab Icons/questions.png',
      'Letters': 'assets/Default Tab Icons/letters.png',
      'Numbers': 'assets/Default Tab Icons/numbers.png',
      'Personal Actions': 'assets/Default Tab Icons/personal actions.png',
      'Shared Activities': 'assets/Default Tab Icons/shared activities.png',
      'Leisure Activities and Interests': 'assets/Default Tab Icons/leisure activities and interests.png',
      'General Objects': 'assets/Default Tab Icons/general objects.png',
      'Clothing and Personal': 'assets/Default Tab Icons/clothes.png',
      'Personal Possessions': 'assets/Default Tab Icons/personal possessions.png',
      'Personal Hygiene': 'assets/Default Tab Icons/personal hygiene.png',
      'Gender and Sexuality': 'assets/Default Tab Icons/gender and sexuality.png',
      'Places': 'assets/Default Tab Icons/places.png',
      'Sport': 'assets/Default Tab Icons/sports.png',
      'Religion and Customs': 'assets/Default Tab Icons/religion and customs.png',
      'Other Countries': 'assets/Default Tab Icons/other countries.png',
      'Public Notices': 'assets/Default Tab Icons/public notices.png',
      'Money': 'assets/Default Tab Icons/money.png',
      'Computer Items': 'assets/Default Tab Icons/computer items.png',
      'Grammatical Elements': 'assets/Default Tab Icons/grammatical elements.png',
      'Quantity and Measurement': 'assets/Default Tab Icons/quantity and measurement.png',
      
      // SUB-BOARD icons (second tab row)
      'Sad': 'assets/BOARDS/Feelings/Sad.png',
      'Mad': 'assets/BOARDS/Feelings/Mad.png',
      'Scared': 'assets/BOARDS/Feelings/Scared.png',
      'Joyful': 'assets/BOARDS/Feelings/Joyful.png',
      'Strong': 'assets/BOARDS/Feelings/Strong.png',
      'Calm': 'assets/BOARDS/Feelings/Calm.png',
      'Shades Of Colours': 'assets/BOARDS/Shades Of Colours.png',
      'Adjectives': 'assets/BOARDS/English/Adjectives.png',
      'Phonics': 'assets/BOARDS/English/Phonics - Phase 2.png',
      'Phase 2 Phonics': 'assets/BOARDS/English/Phonics - Phase 2.png',
      'Phase 3 Phonics': 'assets/BOARDS/English/Phonics - Phase 3.png',
      'Phase 4 Phonics': 'assets/BOARDS/English/Phonics - Phase 4.png',
      'Phase 5 Phonics': 'assets/BOARDS/English/Phonics - Phase 5.png',
      'Phase 6 Phonics': 'assets/BOARDS/English/Phonics - Phase 6.png',
      'School People': 'assets/BOARDS/People At School.png',
      'Mammals': 'assets/BOARDS/Animals/Mammals.png',
      'Birds': 'assets/BOARDS/Animals/Birds.png',
      'Reptiles': 'assets/BOARDS/Animals/Reptiles.png',
      'Amphibians': 'assets/BOARDS/Animals/Amphibians.png',
      'Insects': 'assets/BOARDS/Animals/Insects.png',
      'Arachnids': 'assets/BOARDS/Animals/Arachnids.png',
      'Invertebrates': 'assets/BOARDS/Animals/Invertebrates.png',
      'Fish': 'assets/BOARDS/Animals/Fish.png',
      'Habitats': 'assets/BOARDS/Animals/Habitats.png',
      'Sealife': 'assets/BOARDS/Animals/Sealife.png',
      'Nature Vocabulary': 'assets/BOARDS/Animals/Animals.png',
      'Body Parts Of Animals': 'assets/BOARDS/Animals/Animal Body Parts.png',
      'Child Animals': 'assets/BOARDS/Animals/Child Animals.png',
      'Groups Of Animals': 'assets/BOARDS/Animals/Groups of Animals.png',
      'A (Sign)': 'assets/Common/Letters/a.png',
      'B (Sign)': 'assets/Common/Letters/b.png',
      'C (Sign)': 'assets/Common/Letters/c.png',
      'D (Sign)': 'assets/Common/Letters/d.png',
      'E (Sign)': 'assets/Common/Letters/e.png',
      'F (Sign)': 'assets/Common/Letters/f.png',
      'G (Sign)': 'assets/Common/Letters/g.png',
      'H (Sign)': 'assets/Common/Letters/h.png',
      'I (Sign)': 'assets/Common/Letters/i.png',
      'J (Sign)': 'assets/Common/Letters/j.png',
      'K (Sign)': 'assets/Common/Letters/k.png',
      'L (Sign)': 'assets/Common/Letters/l.png',
      'M (Sign)': 'assets/Common/Letters/m.png',
      'N (Sign)': 'assets/Common/Letters/n.png',
      'O (Sign)': 'assets/Common/Letters/o.png',
      'P (Sign)': 'assets/Common/Letters/p.png',
      'Q (Sign)': 'assets/Common/Letters/q.png',
      'R (Sign)': 'assets/Common/Letters/r.png',
      'S (Sign)': 'assets/Common/Letters/s.png',
      'T (Sign)': 'assets/Common/Letters/t.png',
      'U (Sign)': 'assets/Common/Letters/u.png',
      'V (Sign)': 'assets/Common/Letters/v.png',
      'W (Sign)': 'assets/Common/Letters/w.png',
      'X (Sign)': 'assets/Common/Letters/x.png',
      'Y (Sign)': 'assets/Common/Letters/y.png',
      'Z (Sign)': 'assets/Common/Letters/z.png',
      
      // MY SCHOOL mode icons
      'MY SCHOOL': 'assets/BOARDS/People At School.png',
      'Baycroft Expects': 'assets/BOARDS/Baycroft Expects.png',
      'Thinking Skills': 'assets/BOARDS/Thinking Skills.png',
      'When Things Go Wrong': 'assets/BOARDS/Words For When Things Go Wrong.png',
      'Blank Levels': 'assets/BOARDS/Blank Levels.png',
      'My School Lessons': 'assets/BOARDS/Lesson Vocabulary.png',
      'People at Baycroft': 'assets/BOARDS/People At School.png',

      // PERSONAL mode icons
      'PEOPLE AT HOME': 'assets/BOARDS/Home.png',
      'World Map': 'assets/Default Tab Icons/world map.png',
      'Internal Organs': 'assets/BOARDS/Body Parts.png',
      'Common Words': 'assets/Default Tab Icons/common words.png',
      'Small Words': 'assets/Default Tab Icons/small words.png',
      'Feelings': 'assets/Default Tab Icons/feelings.png',
      'Actions': 'assets/Default Tab Icons/actions.png',
      'People': 'assets/Default Tab Icons/people.png',
      'Colours': 'assets/Default Tab Icons/colours.png',
      'Body Parts': 'assets/Default Tab Icons/body parts.png',
      'Weather': 'assets/Default Tab Icons/weather.png',
      'Clothes': 'assets/Default Tab Icons/clothes.png',
      'Toys': 'assets/Default Tab Icons/toys.png',
      'Transport': 'assets/Default Tab Icons/transport.png',
    };

    // Subject Vocab "Lessons" folder icons get priority when the board area matches.
    if (board.area == 'Subject Vocab') {
      final lessonIcon = _subjectVocabLessonIcons[searchName] ??
          _subjectVocabLessonIcons[searchName.replaceAll(RegExp(r'[(){}\[\].,!?;:"/#@$%^&*]'), '').trim()];
      if (lessonIcon != null) return lessonIcon;
    }

    // Check if we have a specific mapping for this board name. Skip mappings
    // whose target file isn't bundled (e.g. stale 'assets/Default Tab Icons/'
    // paths) so the lookups below can find a real icon instead of 404ing.
    final upperBoardName = boardName.toUpperCase();
    for (final entry in iconMappings.entries) {
      if (entry.key.toUpperCase() == upperBoardName) {
        final mapped = _sanitizeIconAssetPath(entry.value);
        if (_isBundledIconAsset(mapped)) return mapped;
        break;
      }
    }

    final clean = searchName.replaceAll(RegExp(r'[(){}\[\].,!?;:"/#@$%^&*]'), '').trim();

    String? findKey(Map<String, List<String>> map, String query) {
      for (final key in map.keys) {
        if (key.toLowerCase() == query) return key;
      }
      return null;
    }

    // Try the symbol library first (non-BOARDS assets)
    final symbolKey = findKey(symbolIconAssetMap, searchName);
    if (symbolKey != null) {
      return _bestBoardIconPath(symbolKey, symbolIconAssetMap[symbolKey]!);
    }
    if (clean.isNotEmpty) {
      final cleanSymbolKey = findKey(symbolIconAssetMap, clean);
      if (cleanSymbolKey != null) {
        return _bestBoardIconPath(cleanSymbolKey, symbolIconAssetMap[cleanSymbolKey]!);
      }
    }

    String? bestSymbolKey;
    int bestSymbolScore = 0;
    for (final key in symbolIconAssetMap.keys) {
      final keyLower = key.toLowerCase();
      if (keyLower.contains(searchName) ||
          searchName.contains(keyLower) ||
          (clean.isNotEmpty && (keyLower.contains(clean) || clean.contains(keyLower)))) {
        if (key.length > bestSymbolScore) {
          bestSymbolScore = key.length;
          bestSymbolKey = key;
        }
      }
    }
    if (bestSymbolKey != null) {
      return _bestBoardIconPath(bestSymbolKey, symbolIconAssetMap[bestSymbolKey]!);
    }

    // Generated from assets/BOARDS - try exact, then closest filename match
    final boardKey = findKey(boardIconAssetMap, searchName);
    if (boardKey != null) {
      return _bestBoardIconPath(boardKey, boardIconAssetMap[boardKey]!);
    }
    if (clean.isNotEmpty) {
      final cleanBoardKey = findKey(boardIconAssetMap, clean);
      if (cleanBoardKey != null) {
        return _bestBoardIconPath(cleanBoardKey, boardIconAssetMap[cleanBoardKey]!);
      }
    }

    String? bestKey;
    int bestScore = 0;
    for (final key in boardIconAssetMap.keys) {
      final keyLower = key.toLowerCase();
      if (keyLower.contains(searchName) ||
          searchName.contains(keyLower) ||
          (clean.isNotEmpty && (keyLower.contains(clean) || clean.contains(keyLower)))) {
        if (key.length > bestScore) {
          bestScore = key.length;
          bestKey = key;
        }
      }
    }
    if (bestKey != null) {
      return _bestBoardIconPath(bestKey, boardIconAssetMap[bestKey]!);
    }

    // Specific icon path mappings for boards

    
    // Fallback to dynamic path construction — only if that file is actually
    // bundled; otherwise return empty so the caller shows its default icon
    // instead of issuing a 404 network request.
    final fileName = boardName.replaceAll(' ', ' ');
    final fallbackPath = _sanitizeIconAssetPath('assets/BOARDS/$fileName.png');
    return _isBundledIconAsset(fallbackPath) ? fallbackPath : '';
  }

  IconData _getBoardIconData(Board? board) {
    if (board == null) return Icons.grid_view;
    final name = board.name.toLowerCase();
    final area = board.area.toLowerCase();

    if (name.contains('animal') ||
        name.contains('mammal') ||
        name.contains('bird') ||
        name.contains('fish') ||
        name.contains('reptile') ||
        name.contains('insect') ||
        name.contains('amphibian') ||
        name.contains('spider') ||
        name.contains('nature')) {
      return Icons.pets;
    }

    if (name.contains('people') ||
        name.contains('person') ||
        name.contains('family') ||
        name.contains('jobs') ||
        name.contains('careers')) {
      return Icons.people;
    }

    if (name.contains('time') ||
        name.contains('month') ||
        name.contains('event') ||
        name.contains('season') ||
        name.contains('calendar')) {
      return Icons.access_time;
    }

    if (name.contains('sign') ||
        name.contains('bsl') ||
        name.contains('makaton') ||
        name.contains('alphabet') ||
        name.contains('phonics') ||
        name.contains('letters')) {
      return Icons.abc;
    }

    if (name.contains('food') ||
        name.contains('cooking') ||
        name.contains('drink') ||
        name.contains('meal') ||
        name.contains('eat')) {
      return Icons.restaurant;
    }

    if (name.contains('transport') ||
        name.contains('vehicle') ||
        name.contains('bus') ||
        name.contains('car') ||
        name.contains('travel')) {
      return Icons.directions_bus;
    }

    if (name.contains('place') ||
        name.contains('town') ||
        name.contains('country') ||
        name.contains('world') ||
        name.contains('map')) {
      return Icons.place;
    }

    if (name.contains('home') ||
        name.contains('house') ||
        name.contains('furniture') ||
        name.contains('appliance')) {
      return Icons.home;
    }

    if (name.contains('school') ||
        name.contains('lesson') ||
        name.contains('tutor') ||
        name.contains('subject') ||
        name.contains('class')) {
      return Icons.school;
    }

    if (name.contains('feel') ||
        name.contains('emotion') ||
        name.contains('health') ||
        name.contains('medical') ||
        name.contains('body')) {
      return Icons.favorite;
    }

    if (name.contains('colour') ||
        name.contains('color') ||
        name.contains('shade')) {
      return Icons.palette;
    }

    if (name.contains('number') ||
        name.contains('math') ||
        name.contains('quantity') ||
        name.contains('measure')) {
      return Icons.format_list_numbered;
    }

    if (name.contains('sport') ||
        name.contains('pe') ||
        name.contains('exercise') ||
        name.contains('game')) {
      return Icons.sports;
    }

    if (name.contains('clothes') ||
        name.contains('wear') ||
        name.contains('dress')) {
      return Icons.checkroom;
    }

    if (name.contains('money') ||
        name.contains('shop') ||
        name.contains('retail') ||
        name.contains('buy')) {
      return Icons.paid;
    }

    if (name.contains('weather') ||
        name.contains('sun') ||
        name.contains('rain') ||
        name.contains('snow')) {
      return Icons.wb_sunny;
    }

    if (name.contains('music') ||
        name.contains('song') ||
        name.contains('instrument')) {
      return Icons.music_note;
    }

    if (name.contains('art') ||
        name.contains('paint') ||
        name.contains('draw')) {
      return Icons.brush;
    }

    if (name.contains('religion') ||
        name.contains('worldviews') ||
        name.contains('community')) {
      return Icons.church;
    }

    if (name.contains('computer') ||
        name.contains('it') ||
        name.contains('technology') ||
        name.contains('equipment')) {
      return Icons.computer;
    }

    if (name.contains('garden') ||
        name.contains('plant') ||
        name.contains('tree')) {
      return Icons.park;
    }

    if (name.contains('toy') ||
        name.contains('play')) {
      return Icons.toys;
    }

    if (name.contains('question') ||
        name.contains('how') ||
        name.contains('why') ||
        name.contains('what')) {
      return Icons.help;
    }

    if (name.contains('action') ||
        name.contains('verb') ||
        name.contains('movement')) {
      return Icons.directions_run;
    }

    if (name.contains('disney') ||
        name.contains('marvel') ||
        name.contains('star wars') ||
        name.contains('story') ||
        name.contains('character')) {
      return Icons.movie;
    }

    if (area == 'sign') return Icons.sign_language;
    if (area == 'legends') return Icons.auto_stories;
    if (area == 'personal') return Icons.person;
    if (area == 'my school') return Icons.school;
    if (area == 'recipes') return Icons.restaurant;
    if (area == 'common') return Icons.dashboard;

    return Icons.grid_view;
  }

  static const _fallbackLanguages = [
    'en-GB', 'en-US', 'en-AU', 'en-IN',
    'fr-FR', 'de-DE', 'es-ES', 'it-IT',
    'nl-NL', 'pl-PL', 'pt-PT', 'sv-SE',
  ];

  static const _fallbackVoices = [
    VoiceOption(name: 'Default', locale: 'en-US'),
    VoiceOption(name: 'Samantha', locale: 'en-US'),
    VoiceOption(name: 'Daniel', locale: 'en-US'),
    VoiceOption(name: 'Sophie', locale: 'en-GB'),
    VoiceOption(name: 'George', locale: 'en-GB'),
    VoiceOption(name: 'Google US English', locale: 'en-US'),
    VoiceOption(name: 'Google UK English Female', locale: 'en-GB'),
    VoiceOption(name: 'Google UK English Male', locale: 'en-GB'),
  ];

  Future<void> _loadAvailableVoices() async {
    try {
      final languages = await _tts.getLanguages();
      final voices = await _tts.getVoices();
      setState(() {
        _availableLanguages = languages.isNotEmpty ? languages : _fallbackLanguages;
        final systemVoices = voices.map((v) {
          final name = v['name'] ?? 'Default';
          final locale = v['locale'] ?? '';
          return VoiceOption(name: name, locale: locale);
        }).toList();

        final sourceVoices = systemVoices.isNotEmpty ? systemVoices : _fallbackVoices;
        final seen = <String>{};
        _availableVoices = [];
        for (final voice in sourceVoices) {
          if (seen.add(voice.name)) {
            _availableVoices.add(voice);
          }
        }
      });
    } catch (_) {
      setState(() {
        _availableLanguages = _fallbackLanguages;
        _availableVoices = List.unmodifiable(_fallbackVoices);
      });
    }
  }

/// UI BUILDER: TABS
/// This generates the top navigation row. 
/// It combines custom boards with built-in screens like Settings.

  void _buildTabs() {
    final oldActiveId = _activeTab?.id;
    setState(() {
      _buildTabsInternal(oldActiveId);
    });
    // Tab icons can drift when tabs are rebuilt from boards whose stored icon
    // differs from the canonical index icon — re-check the visible rows.
    _repopulateVisibleTabIcons();
  }

  void _syncParentBoardForActiveTab() {
    if (_activeTab == null || _activeTab!.type != TopTabType.board) {
      _parentBoard = null;
      return;
    }
    _parentBoard = _activeTab!.parentBoard;
  }

  String _tabLabelForBoard(Board board) =>
      board.id.startsWith('link_') ? board.name.replaceAll(RegExp(r' \\(\\d+\\)$'), '') : board.name;

  void _buildTabsInternal([String? oldActiveId]) {
    final allTabs = <TopTab>[];
    
    // Boards that belong to Home mode (Common area) in AREA_COMMON.md order
    const commonTopLevelOrder = [
      'Common Words',
      'Small Words',
      'Letters',
      'Numbers',
      'Feelings',
      'Actions',
      'People',
      'Places',
      'Colours',
      'Prepositions',
      'Body Parts',
      'Jobs and Careers',
      'Animals',
      'Weather',
      'Time',
      'Clothes',
      'Toys',
      'Money',
      'Transport',
      'World Map',
    ];
    final commonOrder = {
      for (var i = 0;
          i < (BoardService.current?.getTabOrder('Common') ?? commonTopLevelOrder).length;
          i++)
        (BoardService.current?.getTabOrder('Common') ?? commonTopLevelOrder)[i]
            .toLowerCase(): i,
    };
    final homeBoardNames = hierarchyTopLevel('Common')..sort((a, b) {
      final aIdx = commonOrder[a.toLowerCase()] ?? 999;
      final bIdx = commonOrder[b.toLowerCase()] ?? 999;
      return aIdx.compareTo(bIdx);
    });
    // Boards that belong to Legends mode (saved order, then hierarchy)
    final legendsOrder = BoardService.current?.getTabOrder('Legends') ?? [];
    final legendsOrderMap = {
      for (int i = 0; i < legendsOrder.length; i++)
        legendsOrder[i].toLowerCase(): i
    };
    final legendsBoardNames = hierarchyTopLevel('Legends')..sort((a, b) {
      final aSaved = legendsOrderMap[a.toLowerCase()];
      final bSaved = legendsOrderMap[b.toLowerCase()];
      if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
      if (aSaved != null) return -1;
      if (bSaved != null) return 1;
      final aIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == a.toLowerCase());
      final bIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == b.toLowerCase());
      if (aIdx == -1) return 1;
      if (bIdx == -1) return -1;
      return aIdx.compareTo(bIdx);
    });
    // Boards that belong to School mode (saved order, then hierarchy)
    final schoolOrder = BoardService.current?.getTabOrder('Subject Vocab') ?? [];
    final schoolOrderMap = {
      for (int i = 0; i < schoolOrder.length; i++)
        schoolOrder[i].toLowerCase(): i
    };
    final schoolBoardNames = hierarchyTopLevel('Subject Vocab')..sort((a, b) {
      final aSaved = schoolOrderMap[a.toLowerCase()];
      final bSaved = schoolOrderMap[b.toLowerCase()];
      if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
      if (aSaved != null) return -1;
      if (bSaved != null) return 1;
      final aIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == a.toLowerCase());
      final bIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == b.toLowerCase());
      if (aIdx == -1) return 1;
      if (bIdx == -1) return -1;
      return aIdx.compareTo(bIdx);
    });
    // Boards that belong to My School mode (in order: main first)
    final mySchoolOrder = BoardService.current?.getTabOrder('My School') ?? [];
    final mySchoolOrderMap = {
      for (var i = 0; i < mySchoolOrder.length; i++)
        mySchoolOrder[i].toLowerCase(): i,
    };
    final mySchoolBoardNames = hierarchyTopLevel('My School')..sort((a, b) {
      final aSaved = mySchoolOrderMap[a.toLowerCase()];
      final bSaved = mySchoolOrderMap[b.toLowerCase()];
      if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
      if (aSaved != null) return -1;
      if (bSaved != null) return 1;
      final aIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == a.toLowerCase());
      final bIdx = runtimeBoardHierarchy
          .indexWhere((e) => e.name.toLowerCase() == b.toLowerCase());
      if (aIdx == -1) return 1;
      if (bIdx == -1) return -1;
      return aIdx.compareTo(bIdx);
    });

    
    // Build tabs based on current mode
    switch (_currentMode) {
      case AppMode.home:
        // Home mode: Show strictly defined common boards in order
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
            
        final addedHomeBoardIds = <String>{};
        for (final boardName in homeBoardNames) {
          // Look for board by name within the current area (case-insensitive)
          final board = _boardForTabName(boardName, _activeArea());
          if (board != null && !board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedHomeBoardIds.add(board.id);
          }
        }
        
        // Add any remaining boards that are in the Common area but were not in the explicit list.
        final addedHomeBoardNames = <String>{};
        for (final tab in allTabs) {
          addedHomeBoardNames.add(tab.label.toLowerCase());
        }
        for (final board in _boards) {
          if (board.area == 'Common' &&
              !board.isSubBoard &&
              !addedHomeBoardIds.contains(board.id) &&
              !addedHomeBoardNames.contains(board.name.toLowerCase())) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedHomeBoardIds.add(board.id);
            addedHomeBoardNames.add(board.name.toLowerCase());
          }
        }

        allTabs.add(TopTab(
            id: 'editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.legends:
        // Legends mode: Show the legend boards in the order defined by board_hierarchy.dart
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final addedLegendsBoardIds = <String>{};
        final addedLegendsBoardNames = <String>{};
        for (final boardName in legendsBoardNames) {
          final matches = _boards.where((b) => b.name.toLowerCase() == boardName.toLowerCase()).toList();
          final legendsMatches = matches.where((b) => b.area == 'Legends').toList();
          if (legendsMatches.isEmpty && matches.isNotEmpty) {
            // A board with this name exists but has been moved to another area.
            continue;
          }
          if (legendsMatches.isEmpty) continue;
          // Prefer profile-specific boards over prebuilt boards
          final nonPrebuilt = legendsMatches
              .where((b) => !b.id.startsWith('prebuilt_') && !b.id.startsWith('link_'));
          final board = nonPrebuilt.isNotEmpty ? nonPrebuilt.first : legendsMatches.first;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedLegendsBoardIds.add(board.id);
            addedLegendsBoardNames.add(board.name.toLowerCase());
          }
        }
        // Add any custom boards that are explicitly in the Legends area.
        for (final board in _boards) {
          if (board.area == 'Legends' &&
              !board.isSubBoard &&
              !addedLegendsBoardIds.contains(board.id) &&
              !addedLegendsBoardNames.contains(board.name.toLowerCase())) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedLegendsBoardIds.add(board.id);
            addedLegendsBoardNames.add(board.name.toLowerCase());
          }
        }
        allTabs.add(TopTab(
            id: 'legends_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.recipes:
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        // Build a name -> id map straight from the "Recipes" board's own
        // tiles. This is the exact same linkedBoardId tapping that tile
        // would open, so the tab bar can never disagree with the tile —
        // matching by name alone against the (possibly stale-cached, or
        // once-duplicated) board list could otherwise pick a different
        // board than the one the tile actually links to.
        final recipesLanding = _boards.cast<Board?>().firstWhere(
              (b) => b?.id == 'prebuilt_recipes',
              orElse: () => null,
            );
        final recipesTileIds = <String, String>{
          for (final tile in recipesLanding?.tiles ?? const <SymbolTile>[])
            if (tile.isBoardLink && tile.linkedBoardId.isNotEmpty)
              tile.label.toLowerCase(): tile.linkedBoardId,
        };
        final recipesOrder = BoardService.current?.getTabOrder('Recipes') ?? [];
        final recipesOrderMap = {
          for (int i = 0; i < recipesOrder.length; i++)
            recipesOrder[i].toLowerCase(): i
        };
        final recipesBoardNames = _boards
            .where((b) => b.area == 'Recipes' && !b.isSubBoard)
            .map((b) => b.name)
            .toSet()
            .toList()
          ..sort((a, b) {
            final aSaved = recipesOrderMap[a.toLowerCase()];
            final bSaved = recipesOrderMap[b.toLowerCase()];
            if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
            if (aSaved != null) return -1;
            if (bSaved != null) return 1;
            return a.toLowerCase().compareTo(b.toLowerCase());
          });
        final addedRecipesBoardIds = <String>{};
        for (final boardName in recipesBoardNames) {
          final tileId = recipesTileIds[boardName.toLowerCase()];
          Board? board;
          if (tileId != null) {
            board = _boards.cast<Board?>().firstWhere(
                  (b) => b?.id == tileId,
                  orElse: () => null,
                );
          }
          board ??= _boards.cast<Board?>().firstWhere(
                (b) =>
                    b?.name.toLowerCase() == boardName.toLowerCase() &&
                    b?.area == 'Recipes',
                orElse: () => null,
              );
          if (board == null || board.isSubBoard) continue;
          if (addedRecipesBoardIds.add(board.id)) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
          }
        }
        allTabs.add(TopTab(
            id: 'recipes_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.sign:
        // Sign mode: Category boards for BSL/Makaton
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final signOrder = BoardService.current?.getTabOrder('Sign') ?? [];
        final signOrderMap = {
          for (int i = 0; i < signOrder.length; i++)
            signOrder[i].toLowerCase(): i
        };
        final signBoardNames = hierarchyTopLevel('Sign')..sort((a, b) {
          final aSaved = signOrderMap[a.toLowerCase()];
          final bSaved = signOrderMap[b.toLowerCase()];
          if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
          if (aSaved != null) return -1;
          if (bSaved != null) return 1;
          final aIdx = runtimeBoardHierarchy
              .indexWhere((e) => e.name.toLowerCase() == a.toLowerCase());
          final bIdx = runtimeBoardHierarchy
              .indexWhere((e) => e.name.toLowerCase() == b.toLowerCase());
          if (aIdx == -1) return 1;
          if (bIdx == -1) return -1;
          return aIdx.compareTo(bIdx);
        });
        final addedSignBoardIds = <String>{};
        for (final boardName in signBoardNames) {
          final matches = _boards.where((b) => b.name.toLowerCase() == boardName.toLowerCase()).toList();
          final signMatches = matches.where((b) => b.area == 'Sign').toList();
          if (signMatches.isEmpty && matches.isNotEmpty) {
            // A board with this name exists but has been moved to another area.
            continue;
          }
          if (signMatches.isEmpty) continue;
          final board = signMatches.first;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSignBoardIds.add(board.id);
          }
        }
        // Add any custom boards that are explicitly in the Sign area.
        for (final board in _boards) {
          if (board.area == 'Sign' &&
              !board.isSubBoard &&
              !addedSignBoardIds.contains(board.id)) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSignBoardIds.add(board.id);
          }
        }
        allTabs.add(TopTab(
            id: 'sign_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;
      
      case AppMode.school:
        // School mode: Show Subject Vocabulary (as main), Lessons, Sentence Creator
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final addedSchoolBoardIds = <String>{};
        final addedSchoolBoardNames = <String>{};
        for (final boardName in schoolBoardNames) {
          // Look for board by name within the current area
          final board = _boardForTabName(boardName, _activeArea());
          
          if (board == null) continue;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: board.name.replaceFirst(' (Subject)', ''),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSchoolBoardIds.add(board.id);
            addedSchoolBoardNames.add(board.name.toLowerCase());
          }
        }
        for (final board in _boards) {
          if (board.area == 'Subject Vocab' &&
              !board.isSubBoard &&
              !addedSchoolBoardIds.contains(board.id) &&
              !addedSchoolBoardNames.contains(board.name.toLowerCase())) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSchoolBoardIds.add(board.id);
            addedSchoolBoardNames.add(board.name.toLowerCase());
          }
        }
        allTabs.add(TopTab(
            id: 'school_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.mySchool:
        // My School mode: Show school-specific boards in order
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final addedMySchoolBoardIds = <String>{};
        final addedMySchoolBoardNames = <String>{};
        for (final boardName in mySchoolBoardNames) {
          // Look for board by name within the current area
          final board = _boardForTabName(boardName, _activeArea());
          
          if (board == null) continue;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedMySchoolBoardIds.add(board.id);
            addedMySchoolBoardNames.add(board.name.toLowerCase());
          }
        }
        for (final board in _boards) {
          if (board.area == 'My School' &&
              !board.isSubBoard &&
              !addedMySchoolBoardIds.contains(board.id) &&
              !addedMySchoolBoardNames.contains(board.name.toLowerCase())) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedMySchoolBoardIds.add(board.id);
            addedMySchoolBoardNames.add(board.name.toLowerCase());
          }
        }
        // Never silently drop a hierarchically-expected My School tab just
        // because the board list is stale or still loading after an area
        // switch: inject a placeholder whose id comes from the compiled index
        // so tapping it opens the real board. This keeps all top-level My
        // School boards present no matter what state was cached previously.
        // Only create placeholders for boards that actually exist in _boards
        // (loaded from storage) — do NOT create phantom tabs for boards that
        // don't exist for the current profile (e.g. baycroft boards are invisible
        // to the default profile, so no placeholder should be shown).
        for (final boardName in mySchoolBoardNames) {
          final alreadyShown = _boardForTabName(boardName, 'My School') != null;
          if (alreadyShown) continue;
          final resolvedId = BoardService.current?.resolveBoardIdForName(boardName);
          if (resolvedId == null || addedMySchoolBoardIds.contains(resolvedId)) continue;
          // Only show the tab if the board actually exists in storage for this profile
          final existingBoards = _boards.where((b) => b.id == resolvedId);
          if (existingBoards.isEmpty) continue;
          final existingBoard = existingBoards.first;
          allTabs.add(TopTab(
              id: resolvedId,
              label: _tabLabelForBoard(existingBoard),
              iconAssetPath: _getBoardIconPath(existingBoard),
              type: TopTabType.board,
              board: existingBoard));
          addedMySchoolBoardIds.add(resolvedId);
        }
        allTabs.add(TopTab(
            id: 'my_school_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.personal:
        // Personal mode: Show personal boards
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final personalOrder = BoardService.current?.getTabOrder('Personal') ?? [];
        final personalOrderMap = {
          for (int i = 0; i < personalOrder.length; i++)
            personalOrder[i].toLowerCase(): i
        };
        final personalBoardNames = _boards
            .where((b) => b.area == 'Personal' && !b.isSubBoard)
            .map((b) => b.name)
            .toList()
          ..sort((a, b) {
            final aSaved = personalOrderMap[a.toLowerCase()];
            final bSaved = personalOrderMap[b.toLowerCase()];
            if (aSaved != null && bSaved != null) return aSaved.compareTo(bSaved);
            if (aSaved != null) return -1;
            if (bSaved != null) return 1;
            return a.toLowerCase().compareTo(b.toLowerCase());
          });
        for (final boardName in personalBoardNames) {
          final matches = _boards
              .where((b) =>
                  b.name.toLowerCase() == boardName.toLowerCase() &&
                  b.area == 'Personal')
              .toList();
          if (matches.isEmpty) continue;
          final board = matches.first;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
          }
        }
        allTabs.add(TopTab(
            id: 'personal_editor',
            label: 'New Board',
            icon: Icons.edit,
            type: TopTabType.editor));
        break;

      case AppMode.unassigned:
        // Admin-only: show Unassigned boards so they can be reviewed/deleted.
        for (final board in _boards) {
          if (board.area == 'Unassigned' && !board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
          }
        }
        break;
    }
    
    // Note: Settings moved to AppBar actions

    // 1. Keep Favorites first and Editor last, otherwise preserve the
    //    hierarchy order the tabs were built in (initialOrder).
    final initialOrder = {for (int i = 0; i < allTabs.length; i++) allTabs[i].id: i};
    allTabs.sort((a, b) {
      if (a.id == 'favorites') return -1;
      if (b.id == 'favorites') return 1;
      if (a.type == TopTabType.editor) return 1;
      if (b.type == TopTabType.editor) return -1;

      return (initialOrder[a.id] ?? 0).compareTo(initialOrder[b.id] ?? 0);
    });

    _tabs = allTabs;

    // Try to preserve current tab if it still exists in the new list
    final existingTab = _tabs.cast<TopTab?>().firstWhere(
          (t) => t?.id == oldActiveId,
          orElse: () => null,
        );

    TopTab? fallbackTab() {
      final startingBoardId = _activeProfile?.startingBoardId ?? '';
      TopTab? startingTab;
      if (startingBoardId.isNotEmpty) {
        startingTab = _tabs.cast<TopTab?>().firstWhere(
              (tab) => tab?.type == TopTabType.board && tab?.id == startingBoardId,
              orElse: () => null,
            );

        if (startingTab == null) {
          final board = _boards.cast<Board?>().firstWhere((b) => b?.id == startingBoardId, orElse: () => null);
          if (board != null) {
            final parent = board.parentBoardId != null && board.parentBoardId!.isNotEmpty
                ? _boards.cast<Board?>().firstWhere((b) => b?.id == board.parentBoardId, orElse: () => null)
                : null;
            startingTab = TopTab(
              id: board.id,
              label: _tabLabelForBoard(board),
              iconAssetPath: _getBoardIconPath(board),
              type: TopTabType.board,
              board: board,
              parentBoard: parent,
            );
          }
        }
      }

      // 1. Try starting tab
      if (startingTab != null) return startingTab;
      
      // 2. Try first board in current area
      // SPECIAL CASE: Sign mode defaults to 'Sign Main'
      if (_currentMode == AppMode.sign) {
          final signMain = _tabs.cast<TopTab?>().firstWhere(
              (tab) => tab?.type == TopTabType.board && tab?.label == 'Sign Main',
              orElse: () => null);
          if (signMain != null) return signMain;
      }
      
      final firstBoard = _tabs.cast<TopTab?>().firstWhere(
          (tab) => tab?.type == TopTabType.board,
          orElse: () => null);
      if (firstBoard != null) return firstBoard;
      
      // 3. Try Favorites
      final favorites = _tabs.cast<TopTab?>().firstWhere(
          (tab) => tab?.type == TopTabType.favorites,
          orElse: () => null);
      if (favorites != null) return favorites;
      
      // 4. Ultimate fallback
      return _tabs.isNotEmpty ? _tabs.first : null;
    }

    if (existingTab != null) {
      _activeTab = existingTab;
    } else if (oldActiveId != null && oldActiveId.isNotEmpty) {
      // Keep the requested board active even if it is an orphan sub-board,
      // so returning from the editor lands on the board that was just edited.
      final board = _boards.cast<Board?>().firstWhere((b) => b?.id == oldActiveId, orElse: () => null);
      if (board != null) {
        final parent = board.parentBoardId != null && board.parentBoardId!.isNotEmpty
            ? _boards.cast<Board?>().firstWhere((b) => b?.id == board.parentBoardId, orElse: () => null)
            : null;
        _activeTab = TopTab(
          id: board.id,
          label: _tabLabelForBoard(board),
          iconAssetPath: _getBoardIconPath(board),
          type: TopTabType.board,
          board: board,
          parentBoard: parent ?? _activeTab?.parentBoard,
        );
      } else {
        _activeTab = fallbackTab();
      }
    } else {
      _activeTab = fallbackTab();
    }

    _syncParentBoardForActiveTab();
  }

  /// Returns sub-board tabs for any parent board that links to sub-boards.
  /// Resolve a top-level tab board by name within [area], preferring a real
  /// board over a stale link board when several boards share the same name
  /// (e.g. an empty `link_prebuilt_*` board shadowing the real board).
  Board? _boardForTabName(String boardName, String area) {
    final matches = _boards
        .where((b) =>
            b.name.toLowerCase() == boardName.toLowerCase() && b.area == area)
        .toList();
    if (matches.isEmpty) return null;
    // Prefer profile-specific boards (e.g. baycroft_*) over prebuilt_ boards,
    // so the Baycroft profile sees its own populated boards instead of the
    // empty prebuilt shells that also exist in _boards.
    final nonPrebuilt = matches
        .where((b) => !b.id.startsWith('prebuilt_') && !b.id.startsWith('link_'));
    if (nonPrebuilt.isNotEmpty) {
      return nonPrebuilt.first;
    }
    return matches.firstWhere(
      (b) => !b.id.startsWith('link_'),
      orElse: () => matches.first,
    );
  }

  List<TopTab> _subTabsForBoard(Board? board) {
    if (board == null) return [];
    
    // Recursive logic to find all ancestors and show their immediate children
    // We want to build rows from Tier 1 down to the current board's children
    // If board is Tier 3, we show Row for Tier 2 children (of Tier 1), 
    // Tier 3 children (of Tier 2), and Tier 4 children (of Tier 3).
    // Actually, the request says: "being on any board that has boards underneath it, 
    // automatically shows those boards underneath it in the tabs at the top"
    // And mentions Phase 2 phonics (Tier 3) showing when Phonics (Tier 2) is open.
    
    // Find children of THIS board by stored parent relationship.
    // Board-link tiles no longer automatically generate sub-tabs.
    final rawChildren = _boards.where((b) => b.parentBoardId == board.id && b.isSubBoard).toList();
    // Dedup children by name, preferring profile-specific boards over prebuilt
    final childrenByName = <String, Board>{};
    for (final child in rawChildren) {
      final key = child.name.toLowerCase();
      final existing = childrenByName[key];
      if (existing == null) {
        childrenByName[key] = child;
      } else {
        // Prefer profile-specific (non-prebuilt) boards
        final childIsProfileSpecific = !child.id.startsWith('prebuilt_');
        final existingIsProfileSpecific = !existing.id.startsWith('prebuilt_');
        if (childIsProfileSpecific && !existingIsProfileSpecific) {
          childrenByName[key] = child;
        }
      }
    }
    final children = childrenByName.values.toList();

    // Small Words: keep Montessori-branded grammar boards plus plain Adjectives/Prepositions only.
    if (board.name.toLowerCase() == 'small words') {
      children.retainWhere((b) {
        final n = b.name.toLowerCase();
        return n.contains('(montessori)') || n == 'adjectives' || n == 'prepositions';
      });
    }

    final savedOrder = BoardService.current?.getTabOrder(board.id);
    if (savedOrder != null) {
      // When the user has explicitly configured this board's tabs, use that
      // exact list in that exact order. No automatic children or link boards
      // are added, and no reordering is applied.
      final childrenTabs = <TopTab>[];
      final seenIds = <String>{};
      final seenNames = <String>{};
      for (final name in savedOrder) {
        // Prefer a real board over an empty link board when several boards
        // share the same name, otherwise stale link boards can shadow the
        // real board and show an empty/wrong board. Fall back to the link
        // board when it is the only match for that name.
        final matching = _boards
            .where((b) => b.name.toLowerCase() == name.toLowerCase())
            .toList();
        Board? b;
        if (matching.isNotEmpty) {
          // Prefer profile-specific boards over prebuilt boards
          final nonPrebuilt = matching.where(
              (c) => !c.id.startsWith('prebuilt_') && !c.id.startsWith('link_'));
          if (nonPrebuilt.isNotEmpty) {
            b = nonPrebuilt.first;
          } else {
            b = matching.firstWhere(
              (candidate) => !candidate.id.startsWith('link_'),
              orElse: () => matching.first,
            );
          }
        }
        if (b != null && seenIds.add(b.id) && seenNames.add(b.name.toLowerCase())) {
          childrenTabs.add(TopTab(
            id: b.id,
            label: _tabLabelForBoard(b),
            iconAssetPath: _getBoardIconPath(b),
            type: TopTabType.board,
            board: b,
            parentBoard: board,
          ));
        }
      }

      // A stored order can be stale or incomplete (e.g. it was recorded before
      // a board restructure/rename, like People at Baycroft's sub-tabs). Never
      // silently drop a real child: append any children missing from the saved
      // order, keeping the saved prefix intact but guaranteeing everything that
      // lives under this board is reachable as a tab.
      final appended = <TopTab>[];
      for (final child in children) {
        if (seenIds.add(child.id) && seenNames.add(child.name.toLowerCase())) {
          appended.add(TopTab(
            id: child.id,
            label: _tabLabelForBoard(child),
            iconAssetPath: _getBoardIconPath(child),
            type: TopTabType.board,
            board: child,
            parentBoard: board,
          ));
        }
      }
      if (appended.isNotEmpty) childrenTabs.addAll(_sortedChildTabs(board, appended));
      return childrenTabs;
    }

    // No explicit tab order saved yet — fall back to the board's children.
    // Board-link tiles no longer auto-generate sub-tabs.
    final childrenTabs = <TopTab>[];
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final child in children) {
      if (seenIds.add(child.id) && seenNames.add(child.name.toLowerCase())) {
        childrenTabs.add(TopTab(
          id: child.id,
          label: _tabLabelForBoard(child),
          iconAssetPath: _getBoardIconPath(child),
          type: TopTabType.board,
          board: child,
          parentBoard: board,
        ));
      }
    }
    return _sortedChildTabs(board, childrenTabs);
  }

  // Sorts sub-board tabs by compiled hierarchy order, then board sortOrder,
  // then by label.
  List<TopTab> _sortedChildTabs(Board board, List<TopTab> childrenTabs) {
    // Sort by compiled hierarchy order, then board sortOrder, then by label
    childrenTabs.sort((a, b) {
      // SPECIAL CASE: A-Z Of Sign sub-tabs should ALWAYS be alphabetical
      if (board.name.toLowerCase() == 'a-z of sign' || board.id == 'prebuilt_a-z_of_sign') {
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      }

      // 1. Use the compiled hierarchy order for prebuilt boards.
      final aPrebuilt = a.board?.id.startsWith('prebuilt_') == true;
      final bPrebuilt = b.board?.id.startsWith('prebuilt_') == true;
      final aIndex = prebuiltBoardNames.indexOf(a.label);
      final bIndex = prebuiltBoardNames.indexOf(b.label);

      if (aPrebuilt && bPrebuilt) {
        if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
        if (aIndex >= 0) return -1;
        if (bIndex >= 0) return 1;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      }
      if (aPrebuilt) return -1;
      if (bPrebuilt) return 1;

      // 2. For user boards, respect manual sortOrder, then name.
      if (a.board != null && b.board != null) {
        if (a.board!.sortOrder != 0 && b.board!.sortOrder != 0) {
          return a.board!.sortOrder.compareTo(b.board!.sortOrder);
        }
        if (a.board!.sortOrder != 0) return -1;
        if (b.board!.sortOrder != 0) return 1;
      }

      // 3. Fallback to alphabetical label
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

    return childrenTabs;
  }

  Future<void> _configureTts() async {
    final settings = _settings ?? widget.initialSettings;
    debugPrint('Configuring TTS: Language=${settings.voiceLanguage}, Voice=${settings.voiceName}');
    await _tts.applySettings(
      language: settings.voiceLanguage,
      voiceName: settings.voiceName,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
      volume: settings.voiceVolume,
    );
  }

  Future<void> _activateProfile(String profileId) async {
    _navigationHistory.clear();
    final profile = _profiles.firstWhere(
      (profile) => profile.id == profileId,
      orElse: () => _profiles.isNotEmpty ? _profiles.first : UserProfile.defaultProfile(),
    );
    
    // Only the default profile can be entered without a password
    if (profile.id != 'default') {
      final authenticated = await _showLoginDialog(profile);
      if (!authenticated) return;
    }
    
    // IMPORTANT: Wait for the dialog to fully close before triggering state changes
    await Future.delayed(const Duration(milliseconds: 100));

    await _profileService.setActiveProfile(profile.id);
    
    final boardService = await BoardService.getInstance();
    // Inherit project root from the current session if the profile doesn't have one
    final currentProjectRoot = _settings?.projectRoot ?? '';
    if (profile.settings.projectRoot.isEmpty && currentProjectRoot.isNotEmpty) {
      boardService.setProjectRoot(currentProjectRoot);
    } else {
      boardService.setProjectRoot(profile.settings.projectRoot);
    }
    boardService.setCurrentProfileId(profile.id);

    // Re-initialize favourites service for the new profile
    _favoritesService = await FavoritesService.init(profileId: profile.id);

    if (profile.isAdmin) {
      EmptyBoardsService.instance.invalidate();
    }

    if (!mounted) return;

    // This triggers the HomePage ValueKey change and full state recreation
    widget.onActiveProfileChanged(profile.id);
    widget.onSettingsChanged(profile.settings);
    
    if (mounted) {
      setState(() {
        _activeProfile = profile;
        _settings = profile.settings;
      });
    }
  }

  Future<bool> _showLoginDialog(UserProfile profile) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => _LoginDialog(profile: profile, profileService: _profileService),
    );
    
    return result ?? false;
  }

  Future<void> _saveActiveProfile() async {
    if (_activeProfile == null) return;
    await _profileService.saveProfile(_activeProfile!);
  }

  Future<void> _createNewProfile() async {
    final profile = await NewProfileDialog.show(
        context, _activeProfile ?? UserProfile.defaultProfile());
    if (profile == null) return;

    await _profileService.createProfile(profile);
    _profiles = _profileService.profiles;
    await _profileService.setActiveProfile(profile.id);

    if (!mounted) return;
    widget.onActiveProfileChanged(profile.id);
    widget.onSettingsChanged(profile.settings);

    setState(() {
      _activeProfile = profile;
      _settings = profile.settings;
    });
  }

  Future<void> _saveHistory(String phrase) async {
    if (phrase.trim().isEmpty) return;
    await _phraseService?.addPhrase(phrase);
  }

  Future<void> _saveSentenceAsTxt() async {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No sentence to save.')));
      }
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'sentence_$timestamp.txt';
    if (kIsWeb) {
      await downloadBoardExportBytes(utf8.encode(text), fileName, 'text/plain');
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    }
  }

  Future<void> _exportBoardFromView() async {
    final board = _activeTab?.board;
    if (board == null) return;
    try {
      final captureKey = GlobalKey();
      final screenWidth = MediaQuery.of(context).size.width;

      final overlay = Overlay.of(context);
      OverlayEntry? entry;
      entry = OverlayEntry(builder: (ctx) {
        return Positioned(
          left: -10000,
          top: -10000,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: captureKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: screenWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_activeTab!.iconAssetPath != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Image.asset(_activeTab!.iconAssetPath!, width: 32, height: 32, errorBuilder: (_, __, ___) => Icon(_activeTab!.icon ?? Icons.dashboard, size: 32)),
                            )
                          else if (_activeTab!.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(_activeTab!.icon!, size: 32),
                            ),
                          Text(
                            _activeProfile?.isAdmin == true && _activeTab?.board != null
                                ? '${_activeTab!.label} (${_activeTab!.board!.id})'
                                : _activeTab!.label,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SymbolGrid(
                        symbols: _displaySymbols,
                        favoriteIds: _favoritesService?.favorites ?? {},
                        onTap: (_) {},
                        onLongPress: (_) {},
                        fixedRows: board.rows,
                        fixedColumns: board.columns,
                        adjustableLayout: board.adjustableLayout,
                        boxScale: board.boxScale,
                        highContrast: _settings?.highContrast ?? false,
                        viewOnly: true,
                        scrollable: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      });
      overlay.insert(entry);

      await Future.delayed(const Duration(milliseconds: 200));

      final boundary = captureKey.currentContext?.findRenderObject() as dynamic;
      if (boundary == null) {
        entry.remove();
        return;
      }
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      entry.remove();
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final fileName = BoardExportUtils.buildExportFileName(board.name, 'png');
      if (kIsWeb) {
        await downloadBoardExportBytes(bytes, fileName, 'image/png');
      } else {
        final selectedDir = await FilePicker.getDirectoryPath(dialogTitle: 'Choose where to save $fileName');
        if (selectedDir == null || selectedDir.isEmpty) return;
        final file = File(p.join(selectedDir, fileName));
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved screenshot to ${file.path}')));
        }
      }
    } catch (e) {
      debugPrint('Error exporting board from view: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export board: $e')));
      }
    }
  }

  String _boardWordList(Board board) {
    return board.tiles
        .where((t) => t.label.isNotEmpty)
        .map((t) => t.label)
        .join('\n');
  }

  Future<void> _downloadBoardJsonToBackup() async {
    final board = _activeTab?.board;
    if (board == null) return;
    try {
      final boardJson = board.toMap();
      final jsonString = JsonEncoder.withIndent('  ').convert(boardJson);
      final wordListName = '${board.name} - Word List';
      final wordList = _boardWordList(board);
      final boardFileName = '${board.id}.json';
      final wordFileName = '$wordListName.txt';
      final pngFileName = '${board.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim()}.png';

      List<int>? pngBytes;
      try {
        final captureKey = GlobalKey();
        final screenWidth = MediaQuery.of(context).size.width;
        final overlay = Overlay.of(context);
        OverlayEntry? entry;
        entry = OverlayEntry(builder: (ctx) {
          return Positioned(
            left: -10000, top: -10000,
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: captureKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: screenWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: buildBoardIconImage(
                                _activeTab!.iconAssetPath,
                                size: 32,
                                fallback: Icon(_activeTab!.icon ?? Icons.dashboard, size: 32),
                              ),
                            ),
                            Text(
                              _activeProfile?.isAdmin == true && _activeTab?.board != null
                                  ? '${_activeTab!.label} (${_activeTab!.board!.id})'
                                  : _activeTab!.label,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SymbolGrid(
                          symbols: _displaySymbols,
                          favoriteIds: _favoritesService?.favorites ?? {},
                          onTap: (_) {}, onLongPress: (_) {},
                          fixedRows: board.rows, fixedColumns: board.columns,
                          adjustableLayout: board.adjustableLayout,
                          boxScale: board.boxScale,
                          highContrast: _settings?.highContrast ?? false,
                          viewOnly: true, scrollable: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
        overlay.insert(entry);
        // Wait for the overlay to be laid out and painted before capturing.
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 500));
        final boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          if (image.width == 0 || image.height == 0) {
            debugPrint('PNG capture produced zero-size image');
          } else {
            final byteData = await image.toByteData(format: ImageByteFormat.png);
            if (byteData != null) {
              pngBytes = byteData.buffer.asUint8List();
            } else {
              debugPrint('PNG capture: toByteData returned null');
            }
          }
        } else {
          debugPrint('PNG capture: no RenderRepaintBoundary found');
        }
        entry.remove();
      } catch (e) {
        debugPrint('Error capturing board PNG: $e');
      }

      if (kIsWeb) {
        if (fsa.isSupported) {
          final dirHandle = await fsa.pickDirectory();
          if (dirHandle == null) return;
          final boardService = await BoardService.getInstance();
          final relativePath = await boardService.boardRelativePath(board);
          final filePath = relativePath.isEmpty ? 'lib/data/boards/$boardFileName' : 'lib/data/boards/$relativePath/$boardFileName';
          await fsa.writeTextToPath(dirHandle, filePath, jsonString);
          final wordFilePath = relativePath.isEmpty ? 'lib/data/boards/$wordFileName' : 'lib/data/boards/$relativePath/$wordFileName';
          await fsa.writeTextToPath(dirHandle, wordFilePath, wordList);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $filePath')));
        } else {
          await downloadBoardExportBytes(utf8.encode(jsonString), boardFileName, 'application/json');
          await downloadBoardExportBytes(utf8.encode(wordList), wordFileName, 'text/plain');
          if (pngBytes != null) await downloadBoardExportBytes(pngBytes, pngFileName, 'image/png');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded $boardFileName')));
        }
      } else {
        String? initialDir;
        final boardService = await BoardService.getInstance();
        final relativePath = await boardService.boardRelativePath(board);
        if (relativePath.isNotEmpty) {
          final candidate = p.join('C:\\Users\\Craig\\Downloads\\Charlie Chat', 'lib', 'data', 'boards', relativePath);
          if (Directory(candidate).existsSync()) initialDir = candidate;
        }
        final selectedDir = await FilePicker.getDirectoryPath(
          dialogTitle: 'Choose where to save ${board.name}',
          initialDirectory: initialDir,
        );
        if (selectedDir == null || selectedDir.isEmpty) return;

        final selDir = Directory(selectedDir);
        await selDir.create(recursive: true);
        await File(p.join(selectedDir, boardFileName)).writeAsString(jsonString);
        await File(p.join(selectedDir, wordFileName)).writeAsString(wordList);
        if (pngBytes != null) await File(p.join(selectedDir, pngFileName)).writeAsBytes(pngBytes);

        final now = DateTime.now();
        final dateStamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
        final backupDir = relativePath.isEmpty
            ? p.join('C:\\Users\\Craig\\Downloads\\Charlie Chat Notes', dateStamp, 'lib', 'data', 'boards')
            : p.join('C:\\Users\\Craig\\Downloads\\Charlie Chat Notes', dateStamp, 'lib', 'data', 'boards', relativePath);
        await Directory(backupDir).create(recursive: true);
        await File(p.join(backupDir, boardFileName)).writeAsString(jsonString);
        await File(p.join(backupDir, wordFileName)).writeAsString(wordList);
        if (pngBytes != null) await File(p.join(backupDir, pngFileName)).writeAsBytes(pngBytes);

        if (mounted) {
          final savedFiles = [
            boardFileName,
            wordFileName,
            if (pngBytes != null) pngFileName,
          ].join(', ');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved $savedFiles to $selectedDir\nBackup saved to $backupDir')));
        }
      }
    } catch (e) {
      debugPrint('Error downloading board JSON: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save board: $e')));
      }
    }
  }

/// This is the core speech function. It stops any current speech
/// and plays the new string based on the user's voice settings.

  String _buildSpeakableText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speakText(String text, {bool saveHistory = false, String? displayText}) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
    if (saveHistory) {
      await _saveHistory(displayText ?? text);
    }
  }

  @override
  void dispose() {
    _sentenceController.removeListener(_onSentenceChanged);
    _boardScrollController.dispose();
    _boardHorizontalScrollController.dispose();
    _searchController.dispose();
    _sentenceController.dispose();
    _customVoicePlayer.dispose();
    _tts.stop(); // Fire and forget
    super.dispose();
  }

/// GRID FILTERING 
/// This logic determines what symbols are shown in the main grid.
/// If a board is active, it shows only that board's tiles. 
/// Otherwise, it filters the master list by category/search.

  /// Search every board tile, static symbol, and local asset for [query].
  List<SymbolTile> _searchAllSymbols(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty || (q.length == 1 && !_isSearchableShortQuery(q))) return [];

    final isShortSearchable = q.length == 1;
    final normQuery = q.replaceAll(RegExp(r'[aeiouy]'), '*');
    final seen = <String>{};
    final result = <SymbolTile>[];
    
    void checkAndAdd(SymbolTile tile) {
      final label = tile.label.toLowerCase();
      
      // Use path + label for uniqueness instead of ID, which may have collisions 
      // due to legacy Rule #5 logic.
      final uniqueKey = '${tile.imageAsset}_${tile.label.toLowerCase()}';
      if (seen.contains(uniqueKey)) return;
      
      // 1. Direct match (exact for allowed single-character searches)
      if (isShortSearchable ? label == q : label.contains(q)) {
        result.add(tile);
        seen.add(uniqueKey);
        return;
      }
      
      // 2. Tag match
      if (_metadataService.matchesQuery(tile.imageAsset, q)) {
        result.add(tile);
        seen.add(uniqueKey);
        return;
      }
      
      // 3. Vowel-lenient match
      final normLabel = label.replaceAll(RegExp(r'[aeiouy]'), '*');
      if (normLabel.contains(normQuery)) {
        result.add(tile);
        seen.add(uniqueKey);
      }
    }

    for (final board in _boards) {
      for (final tile in board.tiles) {
        checkAndAdd(tile);
      }
    }
    for (final symbol in allSymbolTiles) {
      checkAndAdd(symbol);
    }
    for (final asset in _localAssetResults) {
      if (seen.add(asset.id)) result.add(asset);
    }
    return result;
  }

  bool _isSearchableShortQuery(String q) => const {'a', 'i', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}.contains(q);

  void _triggerAssetSearch(String query) {
    if (query.length < 2 || query == _lastAssetSearchQuery) return;
    _lastAssetSearchQuery = query;
    _externalSymbolService.searchAssets(query, limit: 60).then((assets) {
      if (!mounted || _lastAssetSearchQuery != query) return;
      setState(() {
        _localAssetResults = assets.map((a) => SymbolTile(
          id: 'asset_${a.imageUrl.hashCode}',
          label: a.label,
          category: 'Assets',
          imageAsset: a.imageUrl,
        )).toList();
      });
    });
  }

  bool _matchesFuzzy(SymbolTile tile, String query) {
    final q = query.toLowerCase().trim().replaceAll('.', '');
    if (q.isEmpty) return true;
    
    final l = tile.label.toLowerCase().replaceAll('.', '');
    
    // 1. Exact or dot-forgiven match
    if (l == q) return true;
    
    // 2. Abbreviation match (e.g., PD vs PD vs Personal Development)
    if (q == 'pd' && l.contains('personal development')) return true;
    if (l == 'pd' && q.contains('personal development')) return true;

    if (q.length == 1) {
      if (_isSearchableShortQuery(q)) {
        return l == q || _metadataService.matchesQuery(tile.imageAsset, q);
      }
      return true;
    }
    
    // 3. Suffix-forgiven match (ignore s, es, ing, ed)
    String normalize(String s) {
      if (s.length > 4 && s.endsWith('ing')) return s.substring(0, s.length - 3);
      if (s.length > 3 && s.endsWith('es')) return s.substring(0, s.length - 2);
      if (s.length > 3 && s.endsWith('ed')) return s.substring(0, s.length - 2);
      if (s.length > 2 && s.endsWith('s')) return s.substring(0, s.length - 1);
      return s;
    }
    
    if (normalize(l) == normalize(q)) return true;

    if (l.contains(q)) return true;

    // Tag match
    if (_metadataService.matchesQuery(tile.imageAsset, q)) return true;

    final normL = l.replaceAll(RegExp(r'[aeiouy]'), '*');
    final normQ = q.replaceAll(RegExp(r'[aeiouy]'), '*');
    return normL.contains(normQ);
  }

  List<SymbolTile> get _filteredSymbols {
    final search = _searchController.text.trim().toLowerCase();
    if (_activeTab?.type == TopTabType.board && _activeTab?.board != null) {
      final board = _activeTab!.board!;
      if (search.isEmpty || (search.length == 1 && !_isSearchableShortQuery(search))) {
        return board.tiles;
      }
      // Search across all boards, not only the current board.
      return _searchAllSymbols(search);
    }
    if (_activeTab?.type == TopTabType.favorites) {
      final favorites = _favoritesService?.favorites ?? <String>{};
      
      // Only show individual favorite tiles from all boards (no board links in main tile area)
      final boardFavTiles = <SymbolTile>[];
      
      for (final board in _allBoards) {
        for (final tile in board.tiles) {
          if (favorites.contains(tile.id) && _matchesFuzzy(tile, search)) {
            boardFavTiles.add(tile);
          }
        }
      }
      // Also include any static symbol tiles that are favourited
      final staticFavTiles = allSymbolTiles.where((symbol) {
        return favorites.contains(symbol.id) && _matchesFuzzy(symbol, search);
      }).toList();
      // Merge, deduplicating by id
      final seen = <String>{};
      final result = <SymbolTile>[];
      for (final t in [...boardFavTiles, ...staticFavTiles]) {
        if (seen.add(t.id)) result.add(t);
      }
      return result;
    }
    return allSymbolTiles.where((symbol) {
      final matchesCategory =
          _selectedCategory == 'All' || symbol.category == _selectedCategory;
      final matchesSearch = _matchesFuzzy(symbol, search);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<SymbolTile> get _displaySymbols {
    final filtered = _filteredSymbols;
    final search = _searchController.text.trim().toLowerCase();
    
    // Ensure minimum 4 tiles for favorites tab
    if (_activeTab?.type == TopTabType.favorites) {
      final result = List<SymbolTile>.from(filtered);
      while (result.length < 4) {
        result.add(SymbolTile(
          id: 'blank_${result.length}',
          label: '',
          imageAsset: '',
          emoji: '',
          category: '',
          bgColor: 'transparent',
          textColor: '#000000',
        ));
      }
      return result;
    }
    
    // Only apply layout truncation/expansion if we are viewing a specific board without search active
    if (_activeTab?.type == TopTabType.board && _activeTab?.board != null && (search.isEmpty || (search.length == 1 && !_isSearchableShortQuery(search)))) {
      final board = _activeTab!.board!;

      if (board.rows > 0 && board.columns > 0) {
        // Find the index of the last tile that has any content (label, image, or emoji)
        int lastContentIndex = -1;
        for (int i = filtered.length - 1; i >= 0; i--) {
          final t = filtered[i];
          if (t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty || t.linkedBoardId.isNotEmpty) {
            lastContentIndex = i;
            break;
          }
        }

        // Empty board: show at most one "Add" tile
        if (lastContentIndex == -1) {
          return filtered.isEmpty ? [] : filtered.sublist(0, 1);
        }

        final gridLimit = board.rows * board.columns;
        // Adjustable boards show up to the last filled tile plus one blank;
        // fixed boards show at least the full grid, expanding if content goes beyond it.
        final actualLimit = board.adjustableLayout
            ? (lastContentIndex + 2).clamp(1, filtered.length)
            : max(gridLimit, lastContentIndex + 1);

        // Reset pagination state when the active board changes.
        // Start with a small number of rows so large boards (e.g. Disney Stories)
        // render quickly, with a 'Show More' button to reveal the rest.
        if (_visibleBoardId != board.id) {
          _visibleBoardId = board.id;
          _visibleBoardRows = 3;
        }

        final contentRows = (actualLimit / board.columns).ceil();

        if (contentRows > 12) {
          final visibleTiles = (_visibleBoardRows * board.columns).clamp(0, filtered.length);
          final limit = min(visibleTiles, actualLimit);
          return filtered.sublist(0, limit);
        }

        return filtered.sublist(0, min(actualLimit, filtered.length));
      }
    }
    return filtered;
  }

  bool get _showMoreButton {
    if (_activeTab?.type != TopTabType.board || _activeTab?.board == null) return false;
    final board = _activeTab!.board!;
    final search = _searchController.text.trim().toLowerCase();
    if (search.isNotEmpty && (search.length > 1 || _isSearchableShortQuery(search))) return false;
    final filtered = _filteredSymbols;
    if (filtered.isEmpty) return false;
    final lastContent = filtered.lastIndexWhere((t) =>
        t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty || t.linkedBoardId.isNotEmpty);
    if (lastContent == -1) return false;
    final gridLimit = board.rows * board.columns;
    final actualLimit = board.adjustableLayout
        ? (lastContent + 2).clamp(1, filtered.length)
        : max(gridLimit, lastContent + 1);
    final contentRows = (actualLimit / board.columns).ceil();
    return contentRows > 12 && _visibleBoardRows < contentRows;
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _playCustomVoice(String path) async {
    await _tts.stop();
    try {
      if (path.startsWith('http') || path.startsWith('blob:') || path.startsWith('data:')) {
        await _customVoicePlayer.play(UrlSource(path));
      } else {
        await _customVoicePlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing custom voice: $e');
    }
  }

  Future<void> _speakSymbol(SymbolTile symbol, {bool ignoreSettings = false}) async {
    if (!ignoreSettings && (!symbol.speaks || (_settings?.readSentenceOnly ?? false))) return;
    if (symbol.customVoice.isNotEmpty) {
      await _playCustomVoice(symbol.customVoice);
    } else {
      await _speak(symbol.speechText);
    }
  }

  Widget _buildModeButton(AppMode mode, IconData icon, String label) {
    final isSelected = _currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FilledButton.tonal(
        onPressed: () {
          setState(() {
            _currentMode = mode;
            // Clear parent and active tab to ensure we don't carry over sub-boards from the old area
            _activeTab = null;
            _parentBoard = null;
            _navigationHistory.clear();
          });
_loadBoards(area: _activeArea());

          // Reset tab scroll position to the start
          for (final controller in _tabScrollControllers.values) {
            if (controller.hasClients) controller.jumpTo(0);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isSelected 
              ? Theme.of(context).colorScheme.onPrimary 
              : Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(40, 32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _onBoardScaleStart(ScaleStartDetails details) {
    _gridZoomStart = _gridZoom;
  }

  void _onBoardScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) return;
    final newZoom = (_gridZoomStart * details.scale).clamp(0.5, 2.0);
    if (newZoom != _gridZoom) {
      setState(() {
        _gridZoom = newZoom;
      });
    }
  }

  void _onBoardPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final bool ctrl = HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
      if (ctrl) {
        final step = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
        final newZoom = (_gridZoom * step).clamp(0.5, 2.0);
        if (newZoom != _gridZoom) {
          setState(() {
            _gridZoom = newZoom;
          });
        }
      }
    }
  }

  void _handleSymbolTap(SymbolTile symbol) {
    if (symbol.isBoardLink) {
      _openLinkedBoard(symbol.linkedBoardId);
      return;
    }
    if (symbol.isFullScreenImage && symbol.imageAsset.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FullScreenImageView(imagePath: symbol.imageAsset),
      ));
      return;
    }
    if (symbol.label.trim().isEmpty &&
        symbol.imageAsset.isEmpty &&
        symbol.emoji.isEmpty) {
      return;
    }
    _addToPhrase(symbol);
  }

  void _openLinkedBoard(String boardId) async {
    if (boardId.isEmpty || _boards.isEmpty) return;
    _pushHistory();
    Board? pending = _boards.cast<Board?>().firstWhere(
          (b) => b?.id == boardId,
          orElse: () => null,
        );
    // Placeholder tab entries have no tiles; load the real board before opening.
    if (pending == null || pending.tiles.isEmpty) {
      final full = await (await BoardService.getInstance()).getBoard(boardId);
      if (full != null) pending = full;
    }
    final board = pending ?? _createEmptySubboard(boardId);
    // Replace any stale/placeholder entry for this id (e.g. a ghost board
    // cached with a wrong area) with the freshly-resolved board so later
    // lookups by id (including the mode check just below) see the correct
    // area rather than leftover bad data.
    final existingBoardIndex = _boards.indexWhere((b) => b.id == board.id);
    if (existingBoardIndex >= 0) {
      _boards[existingBoardIndex] = board;
    } else {
      _boards.add(board);
    }
    if (!mounted) return;

    // Use the freshly-resolved board's own area directly rather than
    // re-looking it up in `_boards` — avoids picking up a stale/ghost
    // placeholder area for the same id.
    final targetMode = _appModeForArea(board.area);
    if (_currentMode != targetMode) {
      setState(() {
        _currentMode = targetMode;
        _activeTab = null;
        _parentBoard = null;
      });
      await _loadBoards(area: board.area);
      if (!mounted) return;
    }

    // Don't block showing the board on icon preloading — this can be slow
    // for boards with many children (e.g. Disney Stories). Icons pop in via
    // their own setState once ready.
    unawaited(_preResolveChildIcons(board));
    if (!mounted) return;
    setState(() {
      final boardIndex = _boards.indexWhere((b) => b.id == board.id);
      if (boardIndex >= 0) {
        _boards[boardIndex] = board;
      } else if (!_boards.any((b) => b.id == board.id)) {
        _boards.add(board);
      }
      _buildTabsInternal();

      // 1. Establish parent relationship
      Board? parent;
      if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
        parent = _boards
            .cast<Board?>()
            .firstWhere((b) => b?.id == board.parentBoardId, orElse: () => null);
      }

      // If moving to a sub-board from its direct parent
      if (parent == null && _activeTab?.board != null) {
        // Only treat current board as parent if the target is explicitly a sub-board or tertiary
        if (board.isSubBoard || board.isTertiaryBoard || _subBoardNames.any((n) => n.toUpperCase() == board.name.toUpperCase())) {
          parent = _activeTab!.board;
        }
      }

      // If the target board is NOT a sub-board and has no parent, clear parentBoard
      if (parent == null) {
        _parentBoard = null;
      }

      // 2. Find or create the tab, but always use the full board we just loaded.
      final existingIndex = _tabs.indexWhere((t) => t.id == board.id);
      TopTab? targetTab;
      if (existingIndex >= 0) {
        final existing = _tabs[existingIndex];
        parent = existing.parentBoard;
        targetTab = TopTab(
          id: existing.id,
          label: existing.label,
          icon: existing.icon,
          iconAssetPath: existing.iconAssetPath,
          type: existing.type,
          board: board,
          parentBoard: parent,
        );
        _tabs[existingIndex] = targetTab;
      } else {
        // Not a top tab, create orphan sub-tab
        targetTab = TopTab(
          id: board.id,
          label: _tabLabelForBoard(board),
          iconAssetPath: _getBoardIconPath(board),
          type: TopTabType.board,
          board: board,
          parentBoard: parent,
        );
      }

      _activeTab = targetTab;
      _parentBoard = parent;
      _selectedCategory = 'All';
      _persistSessionState();
    });
    _scrollActiveTabsIntoViewAfterFrame();
    _repopulateVisibleTabIcons();
  }

  Board _createAutoMissingBoard(String id, String name,
      {String? area, bool isSubBoard = false}) {
    return Board(
      id: id,
      name: name,
      area: area ?? hierarchyArea(name),
      rows: defaultBoardRows,
      columns: defaultBoardColumns,
      adjustableLayout: false,
      backgroundColor: defaultBoardColor,
      tiles: const [],
      isSubBoard: isSubBoard,
      tier: isSubBoard ? 2 : 1,
    );
  }

  Board _createEmptySubboard(String boardId) {
    final name = _boardNameFromId(boardId) ?? _titleCaseFromId(boardId);
    final board = _createAutoMissingBoard(
      boardId,
      name,
      area: hierarchyArea(name),
      isSubBoard: true,
    );
    if (!_boards.any((b) => b.id == boardId)) {
      _boards.add(board);
    }
    // Do NOT save this placeholder to storage/dev server: it is transient and
    // only exists until the real board loads. Persisting it here is what
    // overwrote populated board JSONs (e.g. People at Baycroft, Timetables,
    // 7EmS) with empty shells when getBoard failed or returned stale data.
    return board;
  }

  Board _createMissingBoardPlaceholder(String id, String name) {
    return Board(
      id: id,
      name: name,
      area: _activeArea(),
      rows: defaultBoardRows,
      columns: defaultBoardColumns,
      adjustableLayout: false,
      backgroundColor: defaultBoardColor,
      tiles: const [],
      isSubBoard: false,
    );
  }

  String? _boardNameFromId(String id) {
    for (final b in _boards) {
      if (b.id == id) return b.name;
    }
    return null;
  }

  String _titleCaseFromId(String id) {
    if (id.startsWith('prebuilt_')) {
      id = id.substring('prebuilt_'.length);
    }
    return id.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  void _goUpToParentBoard() {
    if (_parentBoard == null) return;
    _pushHistory();
    final board = _parentBoard!;

    // Determine the new parent for the board we are going back to
    final grandParent = _boards.cast<Board?>().firstWhere(
          (b) => b?.id == board.parentBoardId,
          orElse: () => null,
        );

    // Look for the board in top tabs first
    TopTab? tab;
    try {
      tab = _tabs.firstWhere((t) => t.id == board.id);
    } catch (_) {
      tab = TopTab(
        id: board.id,
        label: _tabLabelForBoard(board),
        iconAssetPath: _getBoardIconPath(board),
        type: TopTabType.board,
        board: board,
        parentBoard: grandParent,
      );
    }

    setState(() {
      _activeTab = tab;
      _selectedCategory = 'All';
      _parentBoard = tab?.parentBoard;
    });
    unawaited(_loadFullActiveBoard());
  }

  void _pushHistory() {
    if (_activeTab != null) {
      // Avoid pushing the same tab twice consecutively
      if (_navigationHistory.isNotEmpty && _navigationHistory.last.id == _activeTab!.id) {
        return;
      }
      _navigationHistory.add(_activeTab!);
      if (_navigationHistory.length > 30) {
        _navigationHistory.removeAt(0);
      }
    }
  }

  Future<void> _goBackInHistory() async {
    if (_navigationHistory.isEmpty) return;
    final prev = _navigationHistory.removeLast();
    final targetArea = prev.board?.area ?? _activeArea();
    final targetMode = _appModeForArea(targetArea);

    setState(() {
      _currentMode = targetMode;
      _activeTab = null;
      _parentBoard = null;
      _selectedCategory = prev.type == TopTabType.category ? prev.label : 'All';
    });

    await _loadBoards(area: targetArea);
    if (!mounted) return;

    setState(() {
      _activeTab = _tabs.firstWhere(
        (t) => t.id == prev.id,
        orElse: () => prev,
      );
    });
    _syncParentBoardForActiveTab();
    await _loadFullActiveBoard();
  }

/// PHRASE BUILDER
/// This is called whenever a symbol is tapped. It adds the symbol 
/// to the top horizontal list and updates the text field below it.

  bool _isPunctuation(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed.length > 1) return false;
    return !RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed);
  }

  static const Map<String, String> _silentPunctuation = {
    'fullstop': '.',
    'fullstop.': '.',
    'period': '.',
    'dot': '.',
    'comma': ',',
    'comma,': ',',
    'questionmark': '?',
    'questionmark?': '?',
    'question': '?',
    'exclamationmark': '!',
    'exclamationmark!': '!',
    'exclamation': '!',
    'apostrophe': "'",
    "apostrophe'": "'",
    'quotationmarks': '"',
    'quotationmark': '"',
    'quotemarks': '"',
    'quotes': '"',
    'quote': '"',
    'dash': '-',
    'hyphen': '-',
    'openbracketorparenthesis': '(',
    'openbracket': '(',
    'openbrackets': '(',
    'openparenthesis': '(',
    'openparentheses': '(',
    'openbracketorparenthesis(': '(',
    'closebracketorparenthesis': ')',
    'closebracket': ')',
    'closebrackets': ')',
    'closeparenthesis': ')',
    'closeparentheses': ')',
    'closebracketorparenthesis)': ')',
    'colon': ':',
    'colon:': ':',
    'semicolon': ';',
    'semicolon;': ';',
  };

  String? _punctuationForSilent(String label) {
    final key = label.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
    if (_silentPunctuation.containsKey(key)) return _silentPunctuation[key];
    final trimmed = label.trim();
    if (trimmed.isNotEmpty && trimmed.length == 1 && !RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) return trimmed;
    return null;
  }

  String _buildPhraseText() {
    final buffer = StringBuffer();
    for (int i = 0; i < _phrase.length; i++) {
      final symbol = _phrase[i];
      if (symbol.isSilent) {
        final punct = _punctuationForSilent(symbol.label);
        if (punct == null || punct.isEmpty) continue;
        buffer.write(punct);
      } else if (buffer.isEmpty || _isPunctuation(symbol.label)) {
        buffer.write(symbol.label.trim());
      } else {
        buffer.write(' ${symbol.label.trim()}');
      }
    }
    return buffer.toString();
  }

  void _addToPhrase(SymbolTile symbol) {
    setState(() {
      _phrase.add(symbol);
      _isUpdatingText = true;
      _sentenceController.text = _buildPhraseText();
      _isUpdatingText = false;
    });
    if (symbol.speaks && !(_settings?.readSentenceOnly ?? false) && !_isPunctuation(symbol.label)) {
      _speakSymbol(symbol);
    }
  }

  void _addTileToPhrase(SymbolTile symbol) {
    setState(() {
      _phrase.add(symbol);
    });
    if (symbol.speaks && !(_settings?.readSentenceOnly ?? false)) {
      _speakSymbol(symbol);
    }
  }

  void _removeFromPhrase(int index) {
    setState(() {
      _phrase.removeAt(index);
      _isUpdatingText = true;
      _sentenceController.text = _buildPhraseText();
      _isUpdatingText = false;
    });
  }

  void _clearPhrase() {
    setState(() {
      _phrase.clear();
      _isUpdatingText = true;
      _sentenceController.clear();
      _isUpdatingText = false;
    });
  }

  /// Builds (once, then caches) an index of every tile's label to that tile,
  /// scanning every board in every area — not just whatever's currently
  /// loaded into [_boards]. Used as a fallback so typed words still find a
  /// real, exact symbol even if it only exists on a board from a different
  /// area than the one currently active.
  Future<Map<String, SymbolTile>> _ensureGlobalWordIndex() async {
    if (_globalWordIndex != null) return _globalWordIndex!;
    if (_globalWordIndexFuture != null) return _globalWordIndexFuture!;
    final future = () async {
      final index = <String, SymbolTile>{};
      try {
        final service = await BoardService.getInstance();
        final allBoards = await service.listBoards(includeTiles: true);
        for (final board in allBoards) {
          for (final tile in board.tiles) {
            final label = tile.label.toLowerCase().trim();
            if (label.isEmpty) continue;
            final existing = index[label];
            // Prefer a tile that actually has an image over a label-only one.
            if (existing == null ||
                (existing.imageAsset.isEmpty && tile.imageAsset.isNotEmpty)) {
              index[label] = tile;
            }
          }
        }
      } catch (_) {
        // Leave whatever was gathered before the failure; better than nothing.
      }
      _globalWordIndex = index;
      return index;
    }();
    _globalWordIndexFuture = future;
    return future;
  }

  Future<SymbolTile?> _findSymbolForTypedWord(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return null;
    if (_typedWordCache.containsKey(lower)) {
      return _typedWordCache[lower];
    }
    for (final board in _boards) {
      for (final tile in board.tiles) {
        if (tile.label.toLowerCase() == lower) {
          _typedWordCache[lower] = tile;
          return tile;
        }
      }
    }
    for (final symbol in allSymbolTiles) {
      if (symbol.label.toLowerCase() == lower) {
        _typedWordCache[lower] = symbol;
        return symbol;
      }
    }
    final globalIndex = await _ensureGlobalWordIndex();
    final globalHit = globalIndex[lower];
    if (globalHit != null) {
      _typedWordCache[lower] = globalHit;
      return globalHit;
    }
    const suffixes = ['ies', 'es', 'ing', 'ed', 'er', 'est', 'ion', 'tion', 'ly', 's'];
    for (final suffix in suffixes) {
      if (lower.endsWith(suffix) && lower.length > suffix.length + 2) {
        final base = lower.substring(0, lower.length - suffix.length);
        final baseTile = _findExactSymbol(base) ?? globalIndex[base];
        if (baseTile != null) {
          _typedWordCache[lower] = baseTile;
          return baseTile;
        }
      }
    }
    return null;
  }

  SymbolTile? _findExactSymbol(String label) {
    for (final board in _boards) {
      for (final tile in board.tiles) {
        if (tile.label.toLowerCase() == label) return tile;
      }
    }
    for (final symbol in allSymbolTiles) {
      if (symbol.label.toLowerCase() == label) return symbol;
    }
    return null;
  }

  /// Whether [candidateLabel] is a genuine match for the typed [word], rather
  /// than just "the least-bad option a fuzzy/relevance search happened to
  /// return". Used to stop the sentence builder showing an unrelated picture
  /// (e.g. typing "help" resulting in "back") for words with no real symbol.
  bool _isPlausibleWordMatch(String candidateLabel, String word) {
    final c = candidateLabel.toLowerCase().trim();
    final w = word.toLowerCase().trim();
    if (c.isEmpty || w.isEmpty) return false;
    if (c == w) return true;
    String stripSuffix(String s) {
      const suffixes = ['ies', 'es', 'ing', 'ed', 'er', 'est', 'ion', 'tion', 'ly', 's'];
      for (final suf in suffixes) {
        if (s.length > suf.length + 2 && s.endsWith(suf)) {
          return s.substring(0, s.length - suf.length);
        }
      }
      return s;
    }
    if (stripSuffix(c) == stripSuffix(w)) return true;
    // Whole-word containment only (e.g. "help me" contains "help"), guarded
    // by a minimum length so short unrelated words can't coincidentally
    // "contain" each other.
    if (c.length >= 4 && w.contains(c)) return true;
    if (w.length >= 4 && c.contains(w)) return true;
    return false;
  }

  Future<void> _addTypedWordToPhrase(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return;
    final cached = _typedWordCache[lower];
    if (cached != null) {
      _addTileToPhrase(cached);
      return;
    }
    var symbol = await _findSymbolForTypedWord(word);
    if (symbol != null) {
      _addTileToPhrase(symbol);
      return;
    }
    // Only accept a fuzzy/relevance-search result if it's a genuine match for
    // the typed word — these searches always return their single best-ranked
    // result even when nothing actually matches well, which used to show an
    // unrelated picture (e.g. typing "help" showing "back") instead of just
    // falling back to plain text.
    final assetResults = await _externalSymbolService.searchAssets(word, limit: 1);
    if (assetResults.isNotEmpty && _isPlausibleWordMatch(assetResults.first.label, word)) {
      symbol = assetResults.first.toSymbolTile();
    }
    if (symbol == null) {
      final externalResults = await _externalSymbolService.searchAll(word, limit: 1);
      if (externalResults.isNotEmpty && _isPlausibleWordMatch(externalResults.first.label, word)) {
        symbol = externalResults.first.toSymbolTile();
      }
    }
    symbol ??= SymbolTile(
      id: 'typed_${lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      label: lower,
      category: 'Typed',
      imageAsset: '',
      emoji: '',
    );
    _typedWordCache[lower] = symbol;
    _addTileToPhrase(symbol);
  }

  void _onSentenceChanged() {
    if (_isUpdatingText) return;
    final text = _sentenceController.text;
    if (text.isEmpty) return;
    // Only process when the user has just typed a separator after a word.
    if (!text.endsWith(' ')) return;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return;
    final lastWord = words.last;
    if (lastWord.isEmpty) return;
    // Avoid adding the same word twice in a row.
    if (_phrase.isNotEmpty && _phrase.last.label.toLowerCase() == lastWord.toLowerCase()) {
      return;
    }
    _addTypedWordToPhrase(lastWord);
  }

  void _handleSymbolLongPress(SymbolTile symbol) {
    // Specialized menu for favorite board links on the Favorites board
    if (symbol.id.startsWith('fav_board_')) {
      final boardId = symbol.id.replaceFirst('fav_board_', '');
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Remove board from favorites'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _favoritesService?.toggleFavoriteBoard(boardId);
                  setState(() {}); // Refresh the favorites grid
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_favoritesService?.isFavorite(symbol.id) == true
                  ? Icons.favorite
                  : Icons.favorite_border, color: Colors.red),
              title: const Text('Toggle Favorite'),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleFavorite(symbol);
              },
            ),
            if (_activeProfile?.isAdmin == true) ...[
              ListTile(
                leading: const Icon(Icons.wallpaper_outlined, color: Colors.orange),
                title: const Text('Remove picture background'),
                subtitle: const Text('Makes only edge-connected white areas transparent'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _cleanSymbolImage(symbol, ImageCleanupMode.background);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_color_reset, color: Colors.orange),
                title: const Text('Remove all white from picture'),
                subtitle: const Text('Makes white and near-white pixels transparent everywhere'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _cleanSymbolImage(symbol, ImageCleanupMode.allWhite);
                },
              ),
            ],
            if (_activeTab?.type == TopTabType.board &&
                _activeTab?.board != null) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Tile'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final index = _activeTab!.board!.tiles.indexWhere((t) => t.id == symbol.id);
                  _openBoardEditor(
                      board: _activeTab!.board, index: index >= 0 ? index : null);
                },
              ),
              // Requirement: change the functionality of the merge tiles function. 
              // Instead of this showing as an option in Edit Board, it should show as an option 
              // when you click the three dots on an individual tile.
              ListTile(
                leading: const Icon(Icons.merge_type),
                title: const Text('Merge with empty tile'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // We jump into the editor at this tile's index and trigger the merge mode
                  final index = _activeTab!.board!.tiles.indexWhere((t) => t.id == symbol.id);
                  if (index >= 0) {
                     _openBoardEditorWithMerge(_activeTab!.board!, index);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cleanSymbolImage(
    SymbolTile symbol,
    ImageCleanupMode mode,
  ) async {
    if (symbol.imageAsset.isEmpty) return;
    final action = mode == ImageCleanupMode.background
        ? 'remove the picture background'
        : 'remove all white and near-white areas';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Picture?'),
        content: Text('This will $action. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Process'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final processedPath =
        await ImageCleanupService().cleanImage(symbol.imageAsset, mode);
    if (processedPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This picture could not be processed.')),
        );
      }
      return;
    }

    final board = _activeTab?.board;
    if (board != null) {
      final tileIndex = board.tiles.indexWhere((tile) => tile.id == symbol.id);
      if (tileIndex >= 0) {
        board.tiles[tileIndex].imageAsset = processedPath;
        await (await BoardService.getInstance()).saveBoard(board);
      }
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Picture updated.')),
    );
  }

  Future<void> _toggleFavorite(SymbolTile symbol) async {
    // Just toggle the favorite ID in SharedPreferences - this is instant
    await _favoritesService?.toggleFavorite(symbol.id);
    
    // Update UI immediately without slow board I/O
    setState(() {});
  }

  void _showWordEditMenu(SymbolTile symbol, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Speak this word'),
              onTap: () {
                Navigator.of(ctx).pop();
                _speakSymbol(symbol, ignoreSettings: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove from sentence'),
              onTap: () {
                Navigator.of(ctx).pop();
                _removeFromPhrase(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Toggle favorite'),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleFavorite(symbol);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsertBoard(Board board) async {
    try {
      debugPrint('Upserting board: ${board.name} (id: ${board.id})');
      final service = await BoardService.getInstance();
      await service.saveBoard(board).timeout(const Duration(seconds: 10));
      debugPrint('Board saved successfully');

      // Reload board from cache to ensure we have the latest version.
      // For web prebuilt boards this avoids loading the original source JSON
      // and discarding the edits we just saved.
      final reloadedBoard = await service.getBoard(board.id);
      if (reloadedBoard != null) {
        board = reloadedBoard;
      }
    } catch (e) {
      debugPrint('Error in _upsertBoard: $e');
    }

    var existingIndex = _boards.indexWhere((b) => b.id == board.id);
    if (existingIndex < 0) {
      existingIndex = _boards.indexWhere((b) =>
          b.name == board.name &&
          b.parentBoardId == board.parentBoardId &&
          b.area == board.area);
    }

    setState(() {
      if (existingIndex >= 0) {
        _boards[existingIndex] = board;
      } else {
        _boards.add(board);
      }

      AppMode targetMode = AppMode.home;
      final area = board.area;
      if (area == 'My School') {
        targetMode = AppMode.mySchool;
      } else if (area == 'Sign') {
        targetMode = AppMode.sign;
      } else if (area == 'Subject Vocab') {
        targetMode = AppMode.school;
      } else if (area == 'Personal') {
        targetMode = AppMode.personal;
      } else if (area == 'Legends') {
        targetMode = AppMode.legends;
      } else if (area == 'Recipes') {
        targetMode = AppMode.recipes;
      } else if (area == 'Unassigned') {
        targetMode = AppMode.unassigned;
      }
      _currentMode = targetMode;

      String targetTabId = board.id;
      if (board.isSubBoard &&
          board.parentBoardId != null &&
          board.parentBoardId!.isNotEmpty) {
        targetTabId = board.parentBoardId!;
        final parentBoard = _boards.firstWhere((b) => b.id == board.parentBoardId,
            orElse: () => board);
        _parentBoard = parentBoard;
      } else {
        _parentBoard = null;
      }

      _buildTabsInternal(targetTabId);

      _activeTab = _tabs.isNotEmpty
          ? _tabs.firstWhere(
              (tab) => tab.id == targetTabId,
              orElse: () => _tabs.firstWhere(
                (tab) => tab.type == TopTabType.board,
                orElse: () => _tabs.first,
              ),
            )
          : TopTab(
              id: board.id,
              label: _tabLabelForBoard(board),
              iconAssetPath: _getBoardIconPath(board),
              type: TopTabType.board,
              board: board,
              parentBoard: _parentBoard,
            );

      if (board.tier > 1 && _activeTab != null) {
        final subTabs = _subTabsForBoard(_parentBoard);
        final subTab = subTabs.firstWhere((t) => t.id == board.id,
            orElse: () => _activeTab!);
        _activeTab = subTab;
      }

      _selectedCategory = 'All';
      _persistSessionState();
    });
  }

  Future<void> _openBoardEditorWithMerge(Board board, int mergeIndex) async {
    await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Merge Tile')),
        body: BoardEditor(
          board: board,
          initialMergeIndex: mergeIndex,
          availableBoards: _boards,
          onSave: (savedBoard) async {
            await _upsertBoard(savedBoard);
            if (!mounted) return;
            Navigator.of(context).pop(savedBoard.id);
          },
        ),
      ),
    ));
    // _upsertBoard already updated the active tab when the merge was saved.
    if (!mounted) return;
  }

  String _activeArea() {
    switch (_currentMode) {
      case AppMode.home:
        return 'Common';
      case AppMode.legends:
        return 'Legends';
      case AppMode.recipes:
        return 'Recipes';
      case AppMode.school:
        return 'Subject Vocab';
      case AppMode.sign:
        return 'Sign';
      case AppMode.mySchool:
        return 'My School';
      case AppMode.personal:
        return 'Personal';
      case AppMode.unassigned:
        return 'Unassigned';
    }
  }

  Future<void> _openBoardEditor({
    Board? board,
    int? index,
    String? initialParentBoardId,
    int? initialTier,
    String? initialArea,
  }) async {
    final editingBoardId = board?.id;
    final savedBoardId = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(board == null ? 'New Board' : 'Edit Board')),
        body: BoardEditor(
          board: board,
          initialIndex: index,
          availableBoards: _boards,
          initialArea: board?.area ?? initialArea ?? _activeArea(),
          initialParentBoardId: board == null ? initialParentBoardId : null,
          initialTier: board == null ? (initialTier ?? 1) : board.tier,
          onSave: (savedBoard) async {
            await _upsertBoard(savedBoard);
            if (mounted) Navigator.of(context).pop(savedBoard.id);
          },
        ),
      ),
    ));

    // _upsertBoard already updated _boards and rebuilt the tabs when the
    // board was saved, so no need to reload the entire list again.
    if (!mounted) return;
    setState(() {
      _buildTabsInternal(savedBoardId ?? editingBoardId);
    });
  }

  Future<void> _openBoardSearch() async {
    final selectedBoardId = await showDialog<String>(
      context: context,
      builder: (_) => BoardSearchDialog(symbolService: _externalSymbolService),
    );
    if (selectedBoardId != null && selectedBoardId.isNotEmpty) {
      _openLinkedBoard(selectedBoardId);
    }
  }

  Future<void> _openSettings() async {
    final currentSettings = _settings ?? widget.initialSettings;
    final result = await Navigator.of(context).push<ProfileSettingsResult>(
      MaterialPageRoute(
        builder: (_) => SettingsShell(
          initialSettings: currentSettings,
          availableLanguages: _availableLanguages,
          availableVoices: _availableVoices,
          availableBoards: _boards,
          selectedPreferredSets: _activeProfile?.preferredSymbolSets ?? [],
          startingBoardId: _activeProfile?.startingBoardId ?? '',
          initialProfile: _activeProfile,
        ),
      ),
    );
    if (result != null) {
      widget.onSettingsChanged(result.settings);
      setState(() {
        _settings = result.settings;
        if (_activeProfile != null) {
          if (result.profile != null) {
            _activeProfile = result.profile!;
          } else {
            _activeProfile = _activeProfile!.copyWith(
              settings: result.settings,
              preferredSymbolSets: result.preferredSymbolSets,
              startingBoardId: result.startingBoardId,
            );
          }
        }
      });
      if (_activeProfile != null) {
        await _saveActiveProfile();
      }
      
      final boardService = await BoardService.getInstance();
      boardService.setProjectRoot(result.settings.projectRoot);
      await _loadBoards(area: _activeArea());

      if (result.navigateToBoardId != null) {
        _openLinkedBoard(result.navigateToBoardId!);
      }

      await _configureTts();
    } else {
      await _loadBoards(area: _activeArea());
    }
  }

  void _openSyncStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
    );
  }

  Future<void> _openEmptyBoardsList() async {
    final boardId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const EmptyBoardsScreen()),
    );
    if (boardId != null && boardId.isNotEmpty) {
      _openLinkedBoard(boardId);
    }
  }

  Future<void> _handleTabTap(TopTab tab) async {
    if (tab.id == _activeTab?.id) return;
    _pushHistory();
    if (_boardScrollController.hasClients) {
      _boardScrollController.jumpTo(0);
    }
    if (tab.type == TopTabType.category) {
      setState(() {
        _activeTab = tab;
        _selectedCategory = tab.label;
        _parentBoard = null;
      });
      _persistSessionState();
      _scrollActiveTabsIntoViewAfterFrame();
      return;
    }
    if (tab.type == TopTabType.board && tab.board != null) {
      final service = await BoardService.getInstance();
      _boardLoadError = null;
      _missingBoardId = null;
      _missingBoardName = null;
      final full = await service.getBoard(tab.board!.id);
      if (full == null) {
        final missingBoard = _createAutoMissingBoard(
          tab.board!.id,
          tab.board!.name,
          area: tab.board!.area,
        );
        await _upsertBoard(missingBoard);
        return;
      }

      // Link tabs (e.g. Characters under Common > People) should not open the
      // placeholder link board; they should load the original board in its own
      // area and select its real tab.
      if (full.linkedBoardId != null && full.linkedBoardId!.isNotEmpty) {
        final original = await service.getBoard(full.linkedBoardId!);
        if (original == null) return;
        if (original.area != _activeArea()) {
          await _loadBoards(area: original.area);
        }
        final target = _tabs.cast<TopTab?>().firstWhere(
              (t) => t?.board?.id == original.id,
              orElse: () => TopTab(
                id: original.id,
                label: original.name,
                iconAssetPath: _getBoardIconPath(original),
                type: TopTabType.board,
                board: original,
                parentBoard: null,
              ),
            )!;
        _handleTabTap(target);
        return;
      }

      if (!mounted) return;
      unawaited(_preResolveChildIcons(full));
      setState(() {
        _boardLoadError = null;
        _missingBoardId = null;
        _missingBoardName = null;
        final index = _boards.indexWhere((b) => b.id == full.id);
        if (index >= 0) _boards[index] = full;
        _activeTab = TopTab(
          id: tab.id,
          label: tab.label,
          icon: tab.icon,
          iconAssetPath: tab.iconAssetPath,
          type: tab.type,
          board: full,
          parentBoard: tab.parentBoard,
        );
        _selectedCategory = 'All';
        _parentBoard = tab.parentBoard;
      });
      _persistSessionState();
      _scrollActiveTabsIntoViewAfterFrame();
      return;
    }
    if (tab.type == TopTabType.favorites) {
      setState(() {
        _activeTab = tab;
        _selectedCategory = 'All';
        _parentBoard = null;
      });
      _persistSessionState();
      _scrollActiveTabsIntoViewAfterFrame();
      _triggerFavoritesLoad();
      return;
    }
    if (tab.type == TopTabType.settings) {
      _openSettings();
      return;
    }
    if (tab.type == TopTabType.editor) {
      final parent = tab.parentBoard;
      _openBoardEditor(
        initialParentBoardId: parent?.id,
        initialTier: parent == null ? 1 : (parent.tier < 5 ? parent.tier + 1 : 5),
        initialArea: parent?.area,
      );
      return;
    }
  }

  ImageProvider? _getProfileImageProvider(String img) {
    if (img.isEmpty || img == 'assets/symbols/baycroft.png') {
      return const AssetImage('assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png');
    }
    if (img.startsWith('data:')) return MemoryImage(base64Decode(img.split(',').last));
    if (img.startsWith('assets/')) return AssetImage(img);
    if (kIsWeb) return NetworkImage(img);
    return FileImage(File(img));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ResponsiveLayout(
      symbolSizeScale: widget.initialSettings.symbolSize,
      gridSpacingOverride: widget.initialSettings.gridSpacing,
      builder: (context, layout) => AacLayoutProvider(
        layout: layout,
        child: _buildBoardScaffold(context, layout),
      ),
    );
  }

  bool _isAncestor(String ancestorId, Board? child, [Set<String>? visited]) {
    if (child == null) return false;
    if (child.parentBoardId == ancestorId) return true;
    visited ??= <String>{};
    if (!visited.add(child.id)) return false; // cycle guard
    final parent = _boards.cast<Board?>().firstWhere((b) => b?.id == child.parentBoardId, orElse: () => null);
    return _isAncestor(ancestorId, parent, visited);
  }

  bool _isTabSelected(TopTab tab) {
    return _activeTab?.id == tab.id || _isAncestor(tab.id, _activeTab?.board);
  }

  void _scrollActiveTabsIntoView() {
    for (final key in _tabActiveKeys.values) {
      if (key.currentContext == null) continue;
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollActiveTabsIntoViewAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollActiveTabsIntoView();
    });
  }

  Future<void> _showTabContextMenu(TopTab tab) async {
    final isLink = tab.board!.id.startsWith('link_');
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tab options'),
        children: [
          if (isLink)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'relink'),
              child: const Text('Link to a different board'),
            ),
          if (!isLink)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'tier'),
              child: const Text('Create a new tier underneath'),
            ),
        ],
      ),
    );
    if (option == 'relink') {
      await _relinkTab(tab);
    } else if (option == 'tier') {
      await _showReorderTabsDialog(_subTabsForBoard(tab.board), rowParent: tab.board);
    }
  }

  Future<Board?> _relinkTab(TopTab tab) async {
    final service = await BoardService.getInstance();
    final allBoards = await service.listBoards(includeTiles: false);
    if (!mounted) return null;
    final currentTarget = tab.board!.linkedBoardId;
    final candidates = allBoards
        .where((b) =>
            !b.id.startsWith('link_') &&
            b.id != currentTarget &&
            b.id != tab.board!.id)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (candidates.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => const AlertDialog(
          content: Text('No other board available to link to.'),
        ),
      );
      return null;
    }
    final selectedId = await _pickExistingBoard(candidates);
    if (selectedId == null || !mounted) return null;
    final original = await service.getBoard(selectedId);
    if (original == null) return null;
    final fullBoard = await service.loadBoard(tab.board!.id) ?? tab.board!;
    fullBoard.name = original.name;
    fullBoard.linkedBoardId = original.id;
    fullBoard.iconAssetPath = original.iconAssetPath;
    fullBoard.tileIconAssetPath = original.tileIconAssetPath;
    await service.saveBoard(fullBoard);
    if (!mounted) return null;
    service.clearBoardCache(fullBoard.id);
    await _loadBoards();
    return fullBoard;
  }

  Future<void> _showReorderTabsDialog(List<TopTab> boardTabs, {Board? rowParent}) async {
    await showDialog<List<TopTab>>(
      context: context,
      builder: (ctx) => _ReorderTabsDialog(
        tabs: boardTabs,
        onDelete: _deleteTabFromReorderDialog,
        onAdd: (tabs) => _addExistingBoardToTabRow(tabs, parent: rowParent),
        onRelink: _relinkTab,
        onSaveComplete: _loadBoards,
      ),
    );
    // _saveOrder / reset already persisted and called onSaveComplete (_loadBoards).
  }

  Future<bool> _deleteTabFromReorderDialog(TopTab tab) async {
    final board = tab.board;
    if (board == null) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${tab.label}?'),
        content: const Text(
          'This will remove this board from the current tab row. It will not be deleted and can still be reached from linked tiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final service = await BoardService.getInstance();
    // Removing a tab just hides the board from all tab rows. The board is not
    // deleted and can still be opened from board-link tiles.
    board.parentBoardId = '__removed__';
    board.isSubBoard = true;
    board.isTertiaryBoard = false;
    // De-homed boards are hidden from every tab row but keep their area so
    // they stay reachable from board-link tiles.
    final fullBoard = await service.loadBoard(board.id) ?? board;
    fullBoard.isSubBoard = true;
    fullBoard.isTertiaryBoard = false;
    fullBoard.isQuaternaryBoard = false;
    fullBoard.isQuinaryBoard = false;
    fullBoard.parentBoardId = '__removed__';
    await service.saveBoard(fullBoard);
    service.clearBoardCache(board.id);
    await _loadBoards();
    return true;
  }

  Future<TopTab?> _addExistingBoardToTabRow(List<TopTab> currentTabs, {Board? parent}) async {
    final rowParent = parent ??
        currentTabs.cast<TopTab?>().firstWhere(
              (t) => t != null && t.parentBoard != null,
              orElse: () => null,
            )?.parentBoard;

    final service = await BoardService.getInstance();
    final allBoards = await service.listBoards(includeTiles: false);

    // Allow any board to be linked, except other link-boards and the row's parent.
    final candidates = allBoards
        .where((b) =>
            !b.id.startsWith('link_') &&
            (rowParent == null || b.id != rowParent.id) &&
            !currentTabs.any((t) =>
                t.id == b.id || t.board?.linkedBoardId == b.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final selectedId = await _pickExistingBoard(candidates);
    if (selectedId == null) return null;

    final original = await service.getBoard(selectedId);
    if (original == null) return null;

    final targetArea = rowParent?.area ?? _activeArea();
    final parentId = rowParent?.id;

    final isSub = rowParent != null;
    final tier = (rowParent?.tier ?? 1) + (isSub ? 1 : 0);

    // Create a link/placeholder tab board that points to the original.
    // The original is not moved; its parent, area, and tier stay as-is.
    final existingIds = <String>{for (final b in allBoards) b.id};
    String linkId;
    int n = 1;
    do {
      linkId = n == 1 ? 'link_${original.id}' : 'link_${original.id}_$n';
      n++;
    } while (existingIds.contains(linkId));

    final linkBoard = Board(
      id: linkId,
      name: original.name,
      area: targetArea,
      parentBoardId: parentId,
      linkedBoardId: original.id,
      rows: defaultBoardRows,
      columns: defaultBoardColumns,
      adjustableLayout: false,
      tiles: const [],
      boxScale: original.boxScale,
      tileHeight: original.tileHeight,
      tileWidth: original.tileWidth,
      backgroundColor: original.backgroundColor,
      isSubBoard: isSub,
      isTertiaryBoard: tier >= 3,
      isQuaternaryBoard: tier >= 4,
      isQuinaryBoard: tier >= 5,
      sortOrder: 0,
      tier: tier,
      iconAssetPath: original.iconAssetPath,
      version: original.version,
    );

    await service.saveBoard(linkBoard, recordSync: false);
    service.clearBoardCache(linkBoard.id);

    return TopTab(
      id: linkBoard.id,
      label: original.name,
      iconAssetPath: _getBoardIconPath(linkBoard),
      type: TopTabType.board,
      board: linkBoard,
      parentBoard: rowParent,
    );
  }

  Future<String?> _pickExistingBoard(List<Board> candidates) async {
    var query = '';
    return await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final displayed = candidates
              .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return AlertDialog(
            title: const Text('Add Existing Board'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search boards...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: displayed.isEmpty
                        ? const Center(child: Text('No matching boards.'))
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: displayed.length,
                            itemBuilder: (context, i) => ListTile(
                              title: Text(displayed[i].name),
                              onTap: () => Navigator.pop(ctx, displayed[i].id),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getTabRowKey(List<TopTab> tabs) {
    if (tabs.isEmpty) return 'top';
    // Top-level tabs don't have a parent board
    final firstWithParent = tabs.firstWhere((t) => t.parentBoard != null, orElse: () => tabs.first);
    if (firstWithParent.parentBoard == null) return 'top';
    return firstWithParent.parentBoard!.id;
  }

  Widget _buildTabBar(List<TopTab> tabs) {
    final reorderableTabs = tabs
        .where((t) => t.type == TopTabType.board && t.board != null && _boards.any((b) => b.id == t.board!.id))
        .toList();
    final editorIndex = tabs.indexWhere((t) => t.type == TopTabType.editor);
    final reorderIndex = editorIndex == -1 ? 0 : editorIndex;
    
    // Maintain scroll controllers per tab row so switching parents doesn't reuse
    // the same scroll offset (which makes tabs appear to jump to the start).
    final rowKey = _getTabRowKey(tabs);
    final controller = _tabScrollControllers.putIfAbsent(rowKey, () => ScrollController());
    final tabOrderKey = tabs.map((t) => t.id).join(',');
    final activeKey = _tabActiveKeys.putIfAbsent(rowKey, () => GlobalKey());

    final children = <Widget>[];
    for (int i = 0; i < tabs.length; i++) {
      if (i == reorderIndex) {
        children.add(_buildReorderTabButton(() => _showReorderTabsDialog(reorderableTabs)));
      }
      final tab = tabs[i];
      children.add(_buildTabButton(tab, i, tabs.length, activeKey: _isTabSelected(tab) ? activeKey : null));
    }
    if (reorderIndex == tabs.length) {
      children.add(_buildReorderTabButton(() => _showReorderTabsDialog(reorderableTabs)));
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          key: ValueKey(tabOrderKey),
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: children),
        ),
      ),
    );
  }

  Widget _buildReorderTabButton(VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: 'Order boards',
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(10),
            minimumSize: const Size(40, 40),
          ),
          onPressed: onPressed,
          child: const Icon(Icons.reorder, size: 18),
        ),
      ),
    );
  }

  Widget _buildTabButton(TopTab tab, int index, int total, {GlobalKey? activeKey}) {
    final selected = _isTabSelected(tab);
    final isFavorites = tab.type == TopTabType.favorites;
    final isEditor = tab.type == TopTabType.editor;
    final isUtilityTab = isFavorites || isEditor;
    Color backgroundColor;
    Color foregroundColor;
    if (isFavorites || isEditor) {
      backgroundColor = Colors.black;
      foregroundColor = Colors.white;
    } else if (selected) {
      backgroundColor = Colors.black;
      foregroundColor = Colors.white;
    } else {
      final double hue = (index * 360 / (total > 0 ? total : 1)) % 360;
      backgroundColor = HSVColor.fromAHSV(1.0, hue, 0.7, 0.95).toColor();
      foregroundColor = Colors.black;
    }
    return GestureDetector(
      onLongPress: () {
        if (tab.type == TopTabType.board && tab.board != null) {
          _showTabContextMenu(tab);
        } else {
          _refreshBoardCache(tab);
        }
      },
      child: Container(
        key: activeKey ?? ValueKey(tab.id),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tab.label,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: isUtilityTab
                ? const EdgeInsets.all(10)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: isUtilityTab ? const Size(40, 40) : null,
          ),
          onPressed: () => _handleTabTap(tab),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.iconAssetPath != null && tab.iconAssetPath!.isNotEmpty)
                buildBoardIconImage(
                  tab.iconAssetPath,
                  size: 18,
                  color: foregroundColor,
                  fallback: Icon(_getBoardIconData(tab.board), size: 18, color: foregroundColor),
                )
              else if (tab.icon != null)
                Icon(tab.icon, size: 18, color: foregroundColor)
              else
                Icon(_getBoardIconData(tab.board), size: 18, color: foregroundColor),
              if (!isUtilityTab) ...[
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  Future<void> _refreshBoardCache(TopTab tab) async {
    if (tab.board == null) return;
    final service = await BoardService.getInstance();
    service.clearBoardCache(tab.board!.id);
    final full = await service.getBoard(tab.board!.id);
    if (full == null) return;
    if (!mounted) return;
    setState(() {
      final index = _boards.indexWhere((b) => b.id == full.id);
      if (index >= 0) _boards[index] = full;
      if (_activeTab?.id == tab.id) {
        _activeTab = TopTab(
          id: tab.id,
          label: tab.label,
          icon: tab.icon,
          iconAssetPath: tab.iconAssetPath,
          type: tab.type,
          board: full,
          parentBoard: tab.parentBoard,
        );
      }
    });
  }

  List<List<TopTab>> _buildTabRows() {
    List<List<TopTab>> rows = [];

    // Admin-only Unassigned area: always show one tab row per tier (1-5),
    // even when a tier has no boards, so orphaned high-tier boards are still
    // reachable without a parent/hierarchy path.
    if (_currentMode == AppMode.unassigned) {
      final unassigned = _boards
          .where((b) => b.area == 'Unassigned' && !b.id.startsWith('link_'))
          .toList();
      for (int tier = 1; tier <= 5; tier++) {
        final tierBoards = unassigned
            .where((b) => b.tier == tier)
            .map((board) => TopTab(
                  id: board.id,
                  label: _tabLabelForBoard(board),
                  iconAssetPath: _getBoardIconPath(board),
                  type: TopTabType.board,
                  board: board,
                ))
            .toList();
        rows.add(tierBoards);
      }
      return rows;
    }

    rows.add(_tabs); // Top row: Main navigation

    // Use a Set to avoid duplicating the same row of sub-tabs
    final seenRowIds = <String>{};

    // Helper to add unique rows: Favorites, [boards], Editor
    void addRow(List<TopTab> row, Board parent) {
      final rowWithUtilities = <TopTab>[
        TopTab(
          id: 'nested_favorites_${parent.id}',
          label: 'Favorites',
          icon: Icons.favorite,
          type: TopTabType.favorites,
          parentBoard: parent,
        ),
        ...row,
        TopTab(
          id: 'nested_editor_${parent.id}',
          label: 'New Board',
          icon: Icons.edit,
          type: TopTabType.editor,
          parentBoard: parent,
        ),
      ];
      final rowId = rowWithUtilities.map((t) => t.id).join(',');
      if (seenRowIds.add(rowId)) {
        rows.add(rowWithUtilities);
      }
    }

    // Work out ancestors for the current active tab to show the path
    List<Board> lineage = [];
    Board? current = _activeTab?.board;
    final visitedLineageIds = <String>{};
    while (current != null && current.parentBoardId != null) {
       if (!visitedLineageIds.add(current.id)) break; // cycle guard
       final parent = _boards.cast<Board?>().firstWhere((b) => b?.id == current!.parentBoardId, orElse: () => null);
       if (parent != null) {
         lineage.insert(0, parent);
         current = parent;
       } else {
         break;
       }
    }

    // Add rows for each level of the lineage (parents of the active board).
    // This shows tabs for the active board's siblings at each parent level.
    for (final ancestor in lineage) {
      addRow(_subTabsForBoard(ancestor), ancestor);
    }

    // If the active board itself has children, show one more row for them.
    if (_activeTab?.board != null &&
        _boards.any((b) => b.parentBoardId == _activeTab!.board!.id)) {
      addRow(_subTabsForBoard(_activeTab!.board), _activeTab!.board!);
    }

    return rows;
  }

  Future<void> _showDeleteUnassignedDialog() async {
    final board = _activeTab?.board;
    if (board == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unassigned Board'),
        content: Text(
          'Are you sure you want to permanently delete "${board.name}"? '
          'This will remove its source JSON and its runtime hierarchy entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = await BoardService.getInstance();
      await service.deleteUnassignedBoardCompletely(board.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${board.name}" has been permanently deleted.')),
      );

      // Rebuild tabs so the deleted board is no longer listed.
      _buildTabs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildBoardLoadingPlaceholder(BuildContext context) {
    final name = _activeTab?.label ?? 'board';
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading $name...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while the board and its assets are prepared.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardScaffold(BuildContext context, AacLayout layout) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tabRows = _buildTabRows();
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/Logos and Profile Pics/charlie_chat_aac_logo.png',
            height: 40,
            fit: BoxFit.contain,
            cacheWidth: 100, // Optimize loading
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Logo error: $error');
              return const Icon(Icons.chat_bubble_outline, color: Colors.blue);
            },
          ),
        ),
        title: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeButton(AppMode.home, Icons.home, 'Common'),
                _buildModeButton(AppMode.school, Icons.school, 'Lesson Vocab'),
                _buildModeButton(AppMode.sign, Icons.sign_language, 'Sign'),
                _buildModeButton(AppMode.mySchool, Icons.school, 'My School'),
                _buildModeButton(AppMode.legends, Icons.auto_stories, 'Legends'),
                _buildModeButton(AppMode.recipes, Icons.restaurant, 'Recipes'),
                _buildModeButton(AppMode.personal, Icons.person, 'Personal'),
                if (_activeProfile?.isAdmin == true)
                  _buildModeButton(AppMode.unassigned, Icons.delete_outline, 'Unassigned'),
              ],
            ),
          ),
        ),
        actions: [
          if (_activeProfile?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.checklist_rtl),
              tooltip: 'Boards to finish',
              onPressed: _openEmptyBoardsList,
            ),
          if (_currentMode == AppMode.unassigned &&
              _activeProfile?.isAdmin == true &&
              _activeTab?.type == TopTabType.board)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Permanently delete this unassigned board',
              onPressed: _showDeleteUnassignedDialog,
            ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Profile home',
            onPressed: widget.onExitToProfiles,
          ),
          PopupMenuButton<String>(
            icon: _activeProfile?.settings.profileImage.isNotEmpty == true
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: _getProfileImageProvider(_activeProfile!.settings.profileImage),
                  )
                : Image.asset(
                    'assets/Logos and Profile Pics/charlie_chat_aac_default_profile.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.account_circle, size: 28),
                  ),
            tooltip: 'Select profile',
            onSelected: (value) {
              if (value == 'new_profile') {
                _createNewProfile();
              } else {
                _activateProfile(value);
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              for (final profile in _profiles) {
                items.add(PopupMenuItem(
                  value: profile.id,
                  child: Row(
                    children: [
                      if (_activeProfile?.id == profile.id)
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(profile.name)),
                    ],
                  ),
                ));
              }
              items.add(const PopupMenuDivider());
              items.add(const PopupMenuItem(
                value: 'new_profile',
                child: Text('Create New Profile'),
              ));
              return items;
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_queue),
            tooltip: 'Offline sync status',
            onPressed: _openSyncStatus,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: layout.isPhone ? 8 : 12,
                        vertical: layout.isPhone ? 6 : 10),
                    child: _buildSentenceBuilder(),
                  ),
                  if (_boardLoadError != null)
                    Container(
                      width: double.infinity,
                      color: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _boardLoadError!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_missingBoardId != null)
                            TextButton(
                              onPressed: () => _openBoardEditor(
                                board: _createMissingBoardPlaceholder(
                                  _missingBoardId!,
                                  _missingBoardName ?? _titleCaseFromId(_missingBoardId!),
                                ),
                              ),
                              child: const Text(
                                'Create this new board',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (_loading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: CustomScrollView(
                        controller: _boardScrollController,
                        slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...tabRows.map((row) => SizedBox(
                                height: layout.tabBarHeight,
                                child: row.isEmpty
                                    ? const SizedBox.shrink()
                                    : _buildTabBar(row),
                              )),
                              _buildResponsiveBody(context, layout),
                              if (_activeTab?.type == TopTabType.favorites) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Favourite Boards',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_favouriteBoards.isNotEmpty)
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      itemCount: _favouriteBoards.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final board = _favouriteBoards[index];
                                        return GestureDetector(
                                          onTap: () => _onBoardTap(board),
                                          child: Container(
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainer,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: (board.iconAssetPath?.isNotEmpty == true)
                                                      ? Image.asset(
                                                          board.iconAssetPath!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Icon(Icons.dashboard_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                                                        )
                                                      : Icon(Icons.dashboard_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                                                ),
                                                const SizedBox(height: 4),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: Text(
                                                    board.name,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Text(
                                      'Heart a board to add it here',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: layout.isPhone ? 8 : 12),
                            child: Column(
                              children: [
                                RepaintBoundary(
                                  key: _boardViewKey,
                                  child: _isLoadingActiveBoard
                                      ? _buildBoardLoadingPlaceholder(context)
                                      : Listener(
                                  onPointerSignal: _onBoardPointerSignal,
                                  child: GestureDetector(
                                    onScaleStart: _onBoardScaleStart,
                                    onScaleUpdate: _onBoardScaleUpdate,
                                    behavior: HitTestBehavior.translucent,
                                    child: SymbolGrid(
                                      symbols: _displaySymbols,
                                      favoriteIds: _favoritesService?.favorites ?? {},
                                      onTap: _handleSymbolTap,
                                      onLongPress: _handleSymbolLongPress,
                                      onAdd: (index) {
                                        if (_activeTab?.type == TopTabType.board && _activeTab?.board != null) {
                                          _openBoardEditor(board: _activeTab!.board, index: index);
                                        }
                                      },
                                      fixedRows: _activeTab?.board?.rows,
                                      fixedColumns: _activeTab?.board?.columns,
                                      adjustableLayout:
                                          _activeTab?.board?.adjustableLayout ?? true,
                                      boxScale: (_activeTab?.board?.boxScale ?? 1.0) * _gridZoom,
                                      highContrast: _settings?.highContrast ?? false,
                                      viewOnly: _activeTab?.type == TopTabType.board,
                                      scrollable: false,
                                      horizontalScroll: _activeTab?.board?.adjustableLayout == false,
                                      controller: _boardHorizontalScrollController,
                                    ),
                                  ),
                                ),
                              /*FIXME*/),
                              if (_showMoreButton)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _visibleBoardRows += 12;
                                      });
                                    },
                                    child: const Text('Show More'),
                                  ),
                                ),
                              _activeTab?.type == TopTabType.board && _activeTab?.board != null && _activeTab!.board!.adjustableLayout == false
                                  ? const SizedBox(height: 56)
                                  : const SizedBox(height: 240),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
      bottomNavigationBar: _buildHorizontalScrollBar(),
      floatingActionButton: _showScrollToTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.small(
                onPressed: () {
                  _boardScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.keyboard_arrow_up, size: 24),
              ),
            )
          : null,
    );
  }

  Widget _buildHorizontalScrollBar() {
    final activeBoard = _activeTab?.board;
    if (activeBoard == null || activeBoard.adjustableLayout) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _boardHorizontalScrollController,
      builder: (context, child) {
        if (!_boardHorizontalScrollController.hasClients) return const SizedBox.shrink();
        final max = _boardHorizontalScrollController.position.maxScrollExtent;
        if (max <= 0) return const SizedBox.shrink();
        final value = (_boardHorizontalScrollController.offset / max).clamp(0.0, 1.0);
        return Container(
          height: 32,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Slider(
            value: value,
            onChanged: (v) => _boardHorizontalScrollController.jumpTo(v * max),
            min: 0,
            max: 1,
          ),
        );
      },
    );
  }

  Widget _buildSentenceBuilder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_phrase.isNotEmpty)
                      SizedBox(
                        height: _settings?.sentenceSize == 'small' ? 40 : (_settings?.sentenceSize == 'large' ? 75 : 52),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final symbol = _phrase[index];
                            final showSymbol = _settings?.sentenceType != 'words' || symbol.isSilent;
                            final showLabel = _settings?.sentenceType != 'symbols' && !symbol.isSilent;
                            return Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (showSymbol && symbol.imageAsset.isNotEmpty)
                                        (symbol.imageAsset.startsWith('assets/')
                                            ? (symbol.imageAsset.endsWith('.svg')
                                                ? SvgPicture.asset(symbol.imageAsset, width: 24, height: 24)
                                                : Image.asset(symbol.imageAsset, width: 24, height: 24))
                                            : Image.network(symbol.imageAsset, width: 24, height: 24)),
                                      if (showLabel)
                                        Text(symbol.label, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showWordEditMenu(symbol, index),
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _phrase.length,
                        ),
                      ),
                    TextField(
                      controller: _sentenceController,
                      decoration: const InputDecoration(
                        hintText: 'Type or build a sentence',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        fontSize: _settings?.fontSize == 'small' ? 14 : (_settings?.fontSize == 'large' ? 22 : 18),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 28),
                    onPressed: () => _speakText(
                      _buildSpeakableText(_sentenceController.text),
                      saveHistory: true,
                      displayText: _sentenceController.text,
                    ),
                    tooltip: 'Speak sentence',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 28),
                    onPressed: _clearPhrase,
                    tooltip: 'Clear sentence',
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_alt, size: 28),
                    onPressed: _saveSentenceAsTxt,
                    tooltip: 'Save sentence as .txt',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveBody(BuildContext context, AacLayout layout) {
    final mainContent = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: layout.isPhone ? 8 : 12,
          vertical: layout.isPhone ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
/// EDITING CONTROLS
/// Only shows if the current tab is a custom board.

                    if (_activeTab?.type == TopTabType.board &&
                        _activeTab?.board != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeProfile?.isAdmin == true
                                ? 'Board: ${_activeTab!.label} (${_activeTab!.board!.id})'
                                : 'Board: ${_activeTab!.label}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_navigationHistory.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () { _goBackInHistory(); },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back'),
                                ),
                              if (_parentBoard != null)
                                OutlinedButton.icon(
                                  onPressed: _goUpToParentBoard,
                                  icon: const Icon(Icons.arrow_upward),
                                  label: const Text('Up'),
                                ),
                              OutlinedButton.icon(
                                onPressed: _openBoardSearch,
                                icon: const Icon(Icons.search),
                                label: const Text('Search For A Board'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                  side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_activeTab!.board!.tiles.where((t) => t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty).length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _favoritesService?.toggleFavoriteBoard(_activeTab!.board!.id);
                                  setState(() {});
                                },
                                icon: Icon(
                                  _favoritesService?.isFavoriteBoard(_activeTab!.board!.id) == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _favoritesService?.isFavoriteBoard(_activeTab!.board!.id) == true
                                      ? Colors.redAccent
                                      : null,
                                ),
                                label: const Text('Fave'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _exportBoardFromView,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Save PNG'),
                              ),
                              OutlinedButton(
                                onPressed: _downloadBoardJsonToBackup,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: const Size(40, 36),
                                ),
                                child: const Icon(Icons.download, size: 20),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openBoardEditor(board: _activeTab!.board),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Board'),
                              ),
                              if (_isLoadingActiveBoard)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
/// SEARCH BAR (Dynamic)

                    if (_activeTab?.type != TopTabType.board)
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search symbols (min. 2 letters)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _triggerAssetSearch(v.trim().toLowerCase());
                        },
                      ),
                    if (_activeTab?.type == TopTabType.board) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search all words (min. 2 letters)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _triggerAssetSearch(v.trim().toLowerCase());
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
    );

    // Always use top-tab layout — nav rail removed
    return mainContent;
  }
}

class _ReorderTabsDialog extends StatefulWidget {
  final List<TopTab> tabs;
  final Future<bool> Function(TopTab tab) onDelete;
  final Future<TopTab?> Function(List<TopTab> currentTabs) onAdd;
  final Future<Board?> Function(TopTab tab) onRelink;
  final Future<void> Function() onSaveComplete;
  const _ReorderTabsDialog({required this.tabs, required this.onDelete, required this.onAdd, required this.onRelink, required this.onSaveComplete});

  @override
  State<_ReorderTabsDialog> createState() => _ReorderTabsDialogState();
}

class _ReorderTabsDialogState extends State<_ReorderTabsDialog> {
  late List<TopTab> _localList;
  int? _editingIndex;
  final _editControllers = <int, TextEditingController>{};
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _localList = List.from(widget.tabs);
  }

  @override
  void dispose() {
    for (final c in _editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveOrder() async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final service = await BoardService.getInstance();
      String? orderKey;
      final names = <String>[];
      for (final tab in _localList) {
        if (tab.type == TopTabType.board && tab.board != null) {
          orderKey ??= tab.parentBoard?.id ?? tab.board!.area;
          names.add(tab.board!.name);
        }
      }
      if (orderKey != null && names.isNotEmpty) {
        await service.saveTabOrder(orderKey, names);
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Success! Order saved.';
        });
        // Clear message after 3s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = null);
        });
        // Trigger a reload of the UI tabs in the background
        await widget.onSaveComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Error saving order: $e';
        });
      }
    }
  }

  void _submitPosition(int fromIndex, String value) {
    final target = int.tryParse(value);
    if (target == null || target < 1 || target > _localList.length) {
      setState(() => _editingIndex = null);
      return;
    }
    final toIndex = target - 1;
    if (toIndex == fromIndex) {
      setState(() => _editingIndex = null);
      return;
    }
    setState(() {
      final item = _localList.removeAt(fromIndex);
      _localList.insert(toIndex, item);
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reorder Tabs'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (_isSaving) const LinearProgressIndicator(),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_statusMessage!, 
                    style: TextStyle(
                      color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )),
              ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _localList.length,
                itemBuilder: (context, index) {
                  final tab = _localList[index];
                  final isEditing = _editingIndex == index;
                  final controller = _editControllers.putIfAbsent(index, () => TextEditingController(text: '${index + 1}'));
                  if (isEditing) {
                    controller.text = '${index + 1}';
                    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                  }
                  return ListTile(
                    key: ValueKey(tab.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(tab.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEditing)
                          SizedBox(
                            width: 48,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                isDense: true,
                                border: UnderlineInputBorder(),
                              ),
                              onSubmitted: (v) => _submitPosition(index, v),
                              onTapOutside: (_) => setState(() => _editingIndex = null),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => setState(() => _editingIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        const SizedBox(width: 4),
                        if (tab.board?.id.startsWith('link_') ?? false)
                          IconButton(
                            icon: const Icon(Icons.link, color: Colors.blue),
                            tooltip: 'Relink to another board',
                            onPressed: () async {
                              final updated = await widget.onRelink(tab);
                              if (updated != null && mounted) {
                                setState(() => _localList[index] = _localList[index].copyWith(
                                      label: updated.name,
                                      board: updated,
                                    ));
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          tooltip: 'Remove from tab row',
                          onPressed: () async {
                            final removed = await widget.onDelete(tab);
                            if (removed && mounted) {
                              setState(() => _localList.removeAt(index));
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _localList.removeAt(oldIndex);
                    _localList.insert(newIndex, item);
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final added = await widget.onAdd(_localList);
            if (added != null && mounted) {
              setState(() => _localList.add(added));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Existing Board'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Order?'),
                content: const Text('This will clear custom sorting and return to the system hierarchy order. Are you sure?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
                ],
              ),
            );
            if (confirmed == true) {
              final service = await BoardService.getInstance();
              String? orderKey;
              for (final tab in _localList) {
                if (tab.board != null) {
                  orderKey ??= tab.parentBoard?.id ?? tab.board!.area;
                }
              }
              if (orderKey != null) {
                await service.clearTabOrder(orderKey);
              }
              if (mounted) {
                 setState(() => _statusMessage = 'Order reset to default.');
                 widget.onSaveComplete();
                 Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) navigator.pop();
                 });
              }
            }
          },
          child: const Text('Reset to Default', style: TextStyle(color: Colors.redAccent)),
        ),
        const SizedBox(width: 20),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _isSaving ? null : _saveOrder, child: const Text('Save Order')),
        FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    );
  }
}

class _LoginDialog extends StatefulWidget {
  final UserProfile profile;
  final ProfileService profileService;
  const _LoginDialog({required this.profile, required this.profileService});

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Note: We avoid disposing controllers here to prevent a race condition 
    // where the TextField rebuilds during the pop animation after the 
    // controller is already gone.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter password for ${widget.profile.name}'),
      content: TextField(
        controller: _passwordController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
        obscureText: true,
        onSubmitted: (_) => _handleLogin(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _handleLogin,
          child: const Text('Login'),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final authenticated = await widget.profileService.authenticate(
      widget.profile.username ?? widget.profile.name,
      _passwordController.text.trim(),
    );
    if (authenticated) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    }
  }
}
