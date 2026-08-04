import 'dart:ui';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import 'data/board_hierarchy.dart';
import 'models/symbol_tile.dart';
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
import 'widgets/board_editor.dart';
import 'widgets/welcome_screen.dart';
import 'widgets/auth_guard.dart';
import 'utils/board_export_utils.dart';
import 'utils/board_export_download.dart';
import 'widgets/pin_lock_guard.dart';
import 'utils/responsive_layout.dart';

const int defaultBoardRows = 6;
const int defaultBoardColumns = 5;

enum AppMode {
  home,
  legends,
  recipes,
  sign,
  school,
  mySchool,
  personal,
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

  Future<void> _selectProfile(String profileId) async {
    await _profileService.setActiveProfile(profileId);
    final profile = _profileService.activeProfile;
    setState(() {
      _activeProfileId = profile.id;
      _selectedProfileId = profile.id;
      _settings = profile.settings;
    });
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
    final nameController = TextEditingController();
    final newName = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('New Profile'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (newName == null || newName.isEmpty) return;

    final activeProfile = _profileService.activeProfile;
    final profile = UserProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: newName,
      settings: activeProfile.settings,
      tabOrder: activeProfile.tabOrder,
      preferredSymbolSets: activeProfile.preferredSymbolSets,
      startingBoardId: activeProfile.startingBoardId,
    );
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
                  onProfileSelected: (id) {
                    _selectProfile(id);
                    setState(() => _showWelcome = false);
                  },
                  onCreateProfile: _createNewProfile,
                  onDeleteProfile: _deleteProfile,
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
  List<TopTab> _tabs = [];
  TopTab? _activeTab;
  Board? _parentBoard;
  List<String> _availableLanguages = _fallbackLanguages;
  List<VoiceOption> _availableVoices = [];
  bool _showAllBoardSymbols = false;
  AppMode _currentMode = AppMode.home;
  bool _isUpdatingText = false;
  final ExternalSymbolService _externalSymbolService = ExternalSymbolService();
  final List<TopTab> _navigationHistory = [];
  final GlobalKey _boardViewKey = GlobalKey();
  final AudioPlayer _customVoicePlayer = AudioPlayer();
  final ScrollController _boardScrollController = ScrollController();
  final Map<int, ScrollController> _tabScrollControllers = {};
  bool _showScrollToTop = false;

  // Sub-boards that are hidden from the top-level tab bar but shown as a second row when their parent is active.
  static const List<String> _subBoardNames = [];
  final Map<String, SymbolTile> _typedWordCache = {};
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
      _favoritesService = await FavoritesService.init();
      _phraseService = await PhraseHistoryService.init();
      _profiles = _profileService.profiles;
      _activeProfile = _profileService.activeProfile;
      _settings = _activeProfile?.settings ?? widget.initialSettings;
      
      final boardService = await BoardService.getInstance(
        projectRoot: _settings?.projectRoot.isNotEmpty == true ? _settings!.projectRoot : null,
      );
      if (!mounted) return;
      boardService.setCurrentProfileId(_activeProfile?.id ?? 'default');

      // Default sub-tab order for Common > Time > Events and Occasions.
      if (boardService.getTabOrder('prebuilt_events_and_occasions') == null) {
        await boardService.saveTabOrder('prebuilt_events_and_occasions', [
          'Passover Keywords',
          'Easter Keywords',
          'Halloween Keywords',
          'Bonfire Night Keywords',
          'Christmas Keywords',
          'Special Days',
        ]);
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

  AppMode _getModeForBoard(String boardId) {
    final board = _boards.cast<Board?>().firstWhere((b) => b?.id == boardId, orElse: () => null);
    if (board == null) return AppMode.home;
    final area = board.area;
    if (area == 'Legends') return AppMode.legends;
    if (area == 'Recipes') return AppMode.recipes;
    if (area == 'My School') return AppMode.mySchool;
    if (area == 'Sign') return AppMode.sign;
    if (area == 'Subject Vocab') return AppMode.school;
    if (area == 'Personal') return AppMode.personal;
    return AppMode.home;
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
      debugPrint('Error persisting session state: $e');
    }
  }

  Future<void> _loadBoards({String? area}) async {
    final service = await BoardService.getInstance();
    _boards = await service.listBoards(area: area, includeTiles: false);
    _buildTabs();
    await _loadFullActiveBoard();
  }

  Future<void> _loadFullActiveBoard() async {
    if (_activeTab?.type != TopTabType.board || _activeTab?.board == null) return;
    final service = await BoardService.getInstance();
    service.setPriorityBoardId(_activeTab!.board!.id);
    if (mounted) setState(() => _isLoadingActiveBoard = true);
    final full = await service.getBoard(_activeTab!.board!.id);
    if (!mounted) return;
    if (full == null) {
      setState(() => _isLoadingActiveBoard = false);
      final missingBoard = _createAutoMissingBoard(
        _activeTab!.board!.id,
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
      if (index >= 0) _boards[index] = full;
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

  Future<void> _loadInitialBoard() async {
    final service = await BoardService.getInstance();
    final commonWordsId = prebuiltBoardId('Common Words');
    service.setPriorityBoardId(commonWordsId);
    final board = await service.getBoard(commonWordsId);
    _boards = board != null ? [board] : [];
  }

  Future<void> _loadRemainingCommonBoards() async {
    final service = await BoardService.getInstance();
    final commonWordsId = prebuiltBoardId('Common Words');
    final common = await service.listBoards(area: 'Common', includeTiles: false);
    final fullCommonWords = _boards.cast<Board?>().firstWhere(
          (b) => b?.id == commonWordsId,
          orElse: () => null,
        );
    _boards = common;
    if (fullCommonWords != null) {
      final idx = _boards.indexWhere((b) => b.id == commonWordsId);
      if (idx >= 0) _boards[idx] = fullCommonWords;
    }
    if (mounted) _buildTabs();
    await _loadFullActiveBoard();
  }

  Future<void> _loadRemainingAreaBoards() async {
    final service = await BoardService.getInstance();
    final commonWordsId = prebuiltBoardId('Common Words');
    final all = await service.listBoards(includeTiles: false);
    final fullCommonWords = _boards.cast<Board?>().firstWhere(
          (b) => b?.id == commonWordsId,
          orElse: () => null,
        );
    _boards = all;
    if (fullCommonWords != null) {
      final idx = _boards.indexWhere((b) => b.id == commonWordsId);
      if (idx >= 0) _boards[idx] = fullCommonWords;
    }
    if (mounted) _buildTabs();
    await _loadFullActiveBoard();
  }

  /// Fire-and-forget migration: for every tile on every board whose label
  /// differs from the image filename, adds the label as a search tag.
  /// Runs once at startup so existing boards get tagged automatically.
  void _migrateTileLabelsToImageTags() async {
    try {
      final meta = await SymbolMetadataService.init();
      final boardService = await BoardService.getInstance();
      final boards = await boardService.listBoards();
      final updates = <String, List<String>>{};
      for (final board in boards) {
        for (final tile in board.tiles) {
          if (tile.isBoardLink || tile.imageAsset.isEmpty || tile.label.isEmpty) continue;
          final imageFilename = p.basenameWithoutExtension(tile.imageAsset).toLowerCase();
          final tileLabel = tile.label.toLowerCase();
          if (imageFilename == tileLabel) continue;
          final assetId = tile.imageAsset.hashCode.toString();
          updates.putIfAbsent(assetId, () => []).add(tileLabel);
        }
      }
      await meta.batchAddTags(updates);
      debugPrint('Migration: synced tile labels to image tags for ${boards.length} boards');
    } catch (e) {
      debugPrint('Error during tile-label-to-image-tag migration: $e');
    }
  }

  String _sanitizeIconAssetPath(String path) {
    try {
      // Decode twice to undo accidental double-encoding (e.g. %2520 -> space).
      return Uri.decodeFull(Uri.decodeFull(path));
    } catch (_) {
      return path;
    }
  }

  String _getBoardIconPath(Board board) {
    if (board.iconAssetPath != null && board.iconAssetPath!.isNotEmpty) {
      return board.iconAssetPath!;
    }
    
    final boardName = board.name;
    // Specific icon path mappings for boards
    final iconMappings = {
      // HOME mode icons
      'ANIMALS': 'assets/BOARDS/Animals/Animals.png',
      'JOBS and CAREERS': 'assets/BOARDS/Jobs.png',
      'TIME': 'assets/BOARDS/Time, Months, Events/Time.png',
      'MORE BOARDS': 'assets/BOARDS/More ++.png',
      'MORE WORDS': 'assets/BOARDS/More ++.png',
      
      // SCHOOL mode icons (subject vocab boards) - assets/symbols/Subjects
      'SENTENCE CREATOR': 'assets/symbols/Subjects/English.png',
      'BETTER WORDS': 'assets/symbols/Subjects/English.png',
      'Lessons': 'assets/symbols/Subjects/Tutor Time.png',
      'English': 'assets/symbols/Subjects/English.png',
      'Maths': 'assets/symbols/Subjects/Maths.png',
      'Science': 'assets/symbols/Subjects/Science.png',
      'TFL': 'assets/symbols/Subjects/TFL.png',
      'Personal Development': 'assets/symbols/Subjects/P.D.png',
      'PEEP': 'assets/symbols/Subjects/PEEP.png',
      'EPIC': 'assets/symbols/Subjects/EPIC.png',
      'P.E.': 'assets/symbols/Subjects/P.E.png',
      'Art': 'assets/symbols/Subjects/Art.png',
      'Performing Arts': 'assets/symbols/Subjects/Performing Arts.png',
      'Sustainability': 'assets/symbols/Subjects/Sustainability.png',
      'Cooking': 'assets/symbols/Subjects/Cooking.png',
      'Resistant Materials': 'assets/symbols/Subjects/Resistant Materials and Construction.png',
      'Textiles': 'assets/symbols/Subjects/Textiles.png',
      'Religion and Worldviews': 'assets/symbols/Subjects/Religion and Worldviews.png',
      'Music': 'assets/symbols/Subjects/Music.png',
      'Horticulture': 'assets/symbols/Subjects/Horticulture.png',
      'Retail': 'assets/symbols/Subjects/Retail.png',
      'Photography': 'assets/symbols/Subjects/Photography.png',
      'Information Technology': 'assets/symbols/Subjects/I.T.png',
      'Construction': 'assets/symbols/Subjects/Resistant Materials and Construction.png',
      'Engineering': 'assets/symbols/Subjects/Engineering.png',
      'Living Life Skills': 'assets/symbols/Subjects/Living Life Skills.png',
      'Prepare For Adulthood': 'assets/symbols/Subjects/Prepare For Adulthood.png',
      'Break and Lunch': 'assets/symbols/Subjects/Breaktime.png',
      'Tutor Time': 'assets/symbols/Subjects/Tutor Time.png',
      
      // SIGN mode icons
      'Sign': 'assets/BOARDS/Signs.png',
      'BSL': 'assets/BOARDS/Signs.png',
      'Makaton': 'assets/BOARDS/Signs.png',
      'A-Z Of Sign': 'assets/BOARDS/Letters.png',
      'Sign A-Z': 'assets/BOARDS/Letters.png',
      'Manners and Greetings': 'assets/BOARDS/People.png',
      'Family and People': 'assets/BOARDS/Family Tree.png',
      'Animals and Nature': 'assets/BOARDS/Animals/Animals.png',
      'Transport and Vehicles': 'assets/BOARDS/Transport.png',
      'Food and Drink': 'assets/BOARDS/Cooking and Food/Food.png',
      'Home and Household': 'assets/BOARDS/Home.png',
      'Feelings and Health': 'assets/BOARDS/Feelings.png',
      'School and Instructions': 'assets/BOARDS/People At School.png',
      'Descriptions and Attributes': 'assets/BOARDS/English/Adjectives.png',
      'Prepositions': 'assets/BOARDS/Prepositions.png',
      'Outside': 'assets/BOARDS/Town.png',
      'Time and Days': 'assets/BOARDS/Time, Months, Events/Time.png',
      'Questions': 'assets/BOARDS/English/How.png',
      'Letters': 'assets/BOARDS/Letters.png',
      'Numbers': 'assets/BOARDS/Numbers.png',
      'Personal Actions': 'assets/BOARDS/Actions.png',
      'Shared Activities': 'assets/BOARDS/People and Places.png',
      'Leisure Activities and Interests': 'assets/BOARDS/Sports, Activities and P.E/Sports.png',
      'General Objects': 'assets/BOARDS/Furniture.png',
      'Clothing and Personal': 'assets/BOARDS/Clothes.png',
      'Personal Possessions': 'assets/BOARDS/Toys.png',
      'Personal Hygiene': 'assets/BOARDS/Medical.png',
      'Gender and Sexuality': 'assets/BOARDS/People.png',
      'Places': 'assets/BOARDS/Places.png',
      'Sport': 'assets/BOARDS/Sports, Activities and P.E/Sports.png',
      'Religion and Customs': 'assets/BOARDS/Religion and Worldviews/Community.png',
      'Other Countries': 'assets/BOARDS/Countryside.png',
      'Public Notices': 'assets/BOARDS/Signs.png',
      'Money': 'assets/BOARDS/Money UK.png',
      'Computer Items': 'assets/BOARDS/Class Equipment.png',
      'Grammatical Elements': 'assets/BOARDS/Small Words.png',
      'Quantity and Measurement': 'assets/BOARDS/Numbers.png',
      
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
      'A (Sign)': 'assets/symbols/1. Main Boards/Alphabet/a.png',
      'B (Sign)': 'assets/symbols/1. Main Boards/Alphabet/b.png',
      'C (Sign)': 'assets/symbols/1. Main Boards/Alphabet/c.png',
      'D (Sign)': 'assets/symbols/1. Main Boards/Alphabet/d.png',
      'E (Sign)': 'assets/symbols/1. Main Boards/Alphabet/e.png',
      'F (Sign)': 'assets/symbols/1. Main Boards/Alphabet/f.png',
      'G (Sign)': 'assets/symbols/1. Main Boards/Alphabet/g.png',
      'H (Sign)': 'assets/symbols/1. Main Boards/Alphabet/h.png',
      'I (Sign)': 'assets/symbols/1. Main Boards/Alphabet/i.png',
      'J (Sign)': 'assets/symbols/1. Main Boards/Alphabet/j.png',
      'K (Sign)': 'assets/symbols/1. Main Boards/Alphabet/k.png',
      'L (Sign)': 'assets/symbols/1. Main Boards/Alphabet/l.png',
      'M (Sign)': 'assets/symbols/1. Main Boards/Alphabet/m.png',
      'N (Sign)': 'assets/symbols/1. Main Boards/Alphabet/n.png',
      'O (Sign)': 'assets/symbols/1. Main Boards/Alphabet/o.png',
      'P (Sign)': 'assets/symbols/1. Main Boards/Alphabet/p.png',
      'Q (Sign)': 'assets/symbols/1. Main Boards/Alphabet/q.png',
      'R (Sign)': 'assets/symbols/1. Main Boards/Alphabet/r.png',
      'S (Sign)': 'assets/symbols/1. Main Boards/Alphabet/s.png',
      'T (Sign)': 'assets/symbols/1. Main Boards/Alphabet/t.png',
      'U (Sign)': 'assets/symbols/1. Main Boards/Alphabet/u.png',
      'V (Sign)': 'assets/symbols/1. Main Boards/Alphabet/v.png',
      'W (Sign)': 'assets/symbols/1. Main Boards/Alphabet/w.png',
      'X (Sign)': 'assets/symbols/1. Main Boards/Alphabet/x.png',
      'Y (Sign)': 'assets/symbols/1. Main Boards/Alphabet/y.png',
      'Z (Sign)': 'assets/symbols/1. Main Boards/Alphabet/z.png',
      
      // MY SCHOOL mode icons
      'MY SCHOOL': 'assets/BOARDS/People At School.png',
      'Baycroft Expects': 'assets/BOARDS/Baycroft Expects.png',
      'Thinking Skills': 'assets/BOARDS/Thinking Skills.png',
      'When Things Go Wrong': 'assets/BOARDS/Words For When Things Go Wrong.png',
      'Blank Levels': 'assets/BOARDS/Blank Levels.png',
      'My School Lessons': 'assets/BOARDS/Lesson Vocabulary.png',
      'People At School': 'assets/BOARDS/People At School.png',

      // PERSONAL mode icons
      'PEOPLE AT HOME': 'assets/BOARDS/Home.png',
      'World Map': 'assets/BOARDS/Places.png',
      'Internal Organs': 'assets/BOARDS/Body Parts.png',
    };

    // Check if we have a specific mapping for this board name
    final upperBoardName = boardName.toUpperCase();
    for (final entry in iconMappings.entries) {
      if (entry.key.toUpperCase() == upperBoardName) {
        return _sanitizeIconAssetPath(entry.value);
      }
    }
    
    // Fallback to dynamic path construction
    final fileName = boardName.replaceAll(' ', ' ');
    return _sanitizeIconAssetPath('assets/BOARDS/$fileName.png');
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
    // Boards that belong to Legends mode (in exact order)
    final legendsBoardNames = ['Legends'];
    // Boards that belong to School mode (in order: main first)
    final schoolBoardNames = ['Subject Vocab'];
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
          final board = _boards.cast<Board?>().firstWhere(
            (b) => b?.name.toLowerCase() == boardName.toLowerCase() && b?.area == _activeArea(),
            orElse: () => null,
          );
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
        // Legends mode: Show the legend boards in the exact requested order
        allTabs.add(TopTab(
            id: 'favorites',
            label: 'Favorites',
            icon: Icons.favorite,
            type: TopTabType.favorites));
        final addedLegendsBoardIds = <String>{};
        for (final boardName in legendsBoardNames) {
          final board = _boards.cast<Board?>().firstWhere(
            (b) => b?.name.toLowerCase() == boardName.toLowerCase() && b?.area == _activeArea(),
            orElse: () => null,
          );
          if (board != null && !board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedLegendsBoardIds.add(board.id);
          }
        }
        // Add any remaining boards explicitly in the Legends area
        for (final board in _boards) {
          if (board.area == 'Legends' &&
              !board.isSubBoard &&
              !addedLegendsBoardIds.contains(board.id)) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedLegendsBoardIds.add(board.id);
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
        final addedRecipesBoardIds = <String>{};
        for (final board in _boards) {
          if (board.area == 'Recipes' && !board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedRecipesBoardIds.add(board.id);
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
        final signBoardNames = hierarchyTopLevel('Sign')..sort((a, b) {
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
        for (final boardName in schoolBoardNames) {
          // Look for board by name within the current area
          final boardMatch = _boards.cast<Board?>().firstWhere(
            (b) => b?.name.toLowerCase() == boardName.toLowerCase() && b?.area == _activeArea(),
            orElse: () => null,
          );
          
          if (boardMatch == null) continue;
          final board = boardMatch;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: board.name.replaceFirst(' (Subject)', ''),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSchoolBoardIds.add(board.id);
          }
        }
        for (final board in _boards) {
          if (board.area == 'Subject Vocab' &&
              !board.isSubBoard &&
              !addedSchoolBoardIds.contains(board.id)) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedSchoolBoardIds.add(board.id);
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
        for (final boardName in mySchoolBoardNames) {
          // Look for board by name within the current area
          final boardMatch = _boards.cast<Board?>().firstWhere(
            (b) => b?.name.toLowerCase() == boardName.toLowerCase() && b?.area == _activeArea(),
            orElse: () => null,
          );
          
          if (boardMatch == null) continue;
          final board = boardMatch;
          if (!board.isSubBoard) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedMySchoolBoardIds.add(board.id);
          }
        }
        for (final board in _boards) {
          if (board.area == 'My School' &&
              !board.isSubBoard &&
              !addedMySchoolBoardIds.contains(board.id)) {
            allTabs.add(TopTab(
                id: board.id,
                label: _tabLabelForBoard(board),
                iconAssetPath: _getBoardIconPath(board),
                type: TopTabType.board,
                board: board));
            addedMySchoolBoardIds.add(board.id);
          }
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
        for (final board in _boards) {
          if (board.area == 'Personal' && !board.isSubBoard) {
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

  static const Set<String> _animalSubBoards = {};

  /// Returns sub-board tabs for any parent board that links to sub-boards.
  List<TopTab> _subTabsForBoard(Board? board) {
    if (board == null) return [];
    
    // Recursive logic to find all ancestors and show their immediate children
    // We want to build rows from Tier 1 down to the current board's children
    // If board is Tier 3, we show Row for Tier 2 children (of Tier 1), 
    // Tier 3 children (of Tier 2), and Tier 4 children (of Tier 3).
    // Actually, the request says: "being on any board that has boards underneath it, 
    // automatically shows those boards underneath it in the tabs at the top"
    // And mentions Phase 2 phonics (Tier 3) showing when Phonics (Tier 2) is open.
    
    // Find children of THIS board
    final children = _boards.where((b) => b.parentBoardId == board.id).toList();
    
    // Also include linked boards that are marked as sub-boards in the tiles
    final linkedSubBoardIds = <String>{};
    for (final tile in board.tiles) {
      if (tile.isBoardLink && tile.linkedBoardId.isNotEmpty) {
        final linked = _boards.cast<Board?>().firstWhere((b) => b?.id == tile.linkedBoardId, orElse: () => null);
        if (linked != null && linked.tier > board.tier) {
          linkedSubBoardIds.add(linked.id);
        }
      }
    }
    
    // Animal special case — only for the Animals parent board itself
    if (board.name.toUpperCase() == 'ANIMALS') {
      // Animal sub-boards are referenced by name, not by stored board IDs.
      for (final animalName in _animalSubBoards) {
        final matched = _boards.cast<Board?>().firstWhere((b) => b?.name.toUpperCase() == animalName.toUpperCase() && b?.area == board.area, orElse: () => null);
        if (matched != null) linkedSubBoardIds.add(matched.id);
      }
    }

    final childrenTabs = <TopTab>[];
    final seenIds = <String>{};
    
    for (final child in children) {
      if (seenIds.add(child.id)) {
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
    
    for (final linkedId in linkedSubBoardIds) {
      final b = _boards.cast<Board?>().firstWhere((b) => b?.id == linkedId, orElse: () => null);
      if (b != null && seenIds.add(b.id)) {
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

    // Sort by saved parent tab order, then board sortOrder, then by label
    final savedOrder = BoardService.current?.getTabOrder(board.id) ?? [];
    final orderMap = <String, int>{
      for (var i = 0; i < savedOrder.length; i++) savedOrder[i].toLowerCase(): i,
    };
    childrenTabs.sort((a, b) {
      // SPECIAL CASE: A-Z Of Sign sub-tabs should ALWAYS be alphabetical
      if (board.name.toLowerCase() == 'a-z of sign' || board.id == 'prebuilt_a-z_of_sign') {
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      }

      // 0. Check explicit tab order saved via Edit Tab Order
      if (savedOrder.isNotEmpty) {
        final aName = a.board?.name.toLowerCase() ?? a.label.toLowerCase();
        final bName = b.board?.name.toLowerCase() ?? b.label.toLowerCase();
        final aIdx = orderMap[aName];
        final bIdx = orderMap[bName];
        if (aIdx != null && bIdx != null) return aIdx.compareTo(bIdx);
        if (aIdx != null) return -1;
        if (bIdx != null) return 1;
      }

      // 1. Check manual sortOrder (only applies if both have boards)
      if (a.board != null && b.board != null) {
        if (a.board!.sortOrder != 0 && b.board!.sortOrder != 0) {
          return a.board!.sortOrder.compareTo(b.board!.sortOrder);
        }
        if (a.board!.sortOrder != 0) return -1;
        if (b.board!.sortOrder != 0) return 1;
      }

      // 2. Check prebuilt hierarchy order (Authoritative sequence for system boards and shortcuts)
      final aIndex = prebuiltBoardNames.indexOf(a.label);
      final bIndex = prebuiltBoardNames.indexOf(b.label);
      
      if (aIndex >= 0 && bIndex >= 0) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex >= 0) return -1;
      if (bIndex >= 0) return 1;

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
    
    // Check if profile requires authentication
    if (profile.username != null && profile.password != null) {
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
    final nameController = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(nameController.text.trim());
              },
              child: const Text('Create')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;

    final profile = UserProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: newName,
      settings: _activeProfile?.settings ?? const AppSettings(),
      tabOrder: _activeProfile?.tabOrder ?? [],
      preferredSymbolSets: _activeProfile?.preferredSymbolSets ?? [],
      startingBoardId: _activeProfile?.startingBoardId ?? '',
    );
    await _profileService.createProfile(profile);
    _profiles = _profileService.profiles;
    await _activateProfile(profile.id);
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
                            _activeTab!.label,
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
                        Row(children: [
                          Text(board.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        ]),
                        const SizedBox(height: 20),
                        SymbolGrid(
                          symbols: board.tiles,
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
        await Future.delayed(const Duration(milliseconds: 200));
        final boundary = captureKey.currentContext?.findRenderObject();
        if (boundary != null) {
          final image = await (boundary as dynamic).toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ImageByteFormat.png);
          if (byteData != null) pngBytes = byteData.buffer.asUint8List();
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

  Future<void> _speakText(String text, {bool saveHistory = false}) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
    if (saveHistory) {
      await _saveHistory(text);
    }
  }

  @override
  void dispose() {
    _sentenceController.removeListener(_onSentenceChanged);
    _boardScrollController.dispose();
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
    
    // 2. Abbreviation match (e.g., PD vs P.D. vs Personal Development)
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
      // Collect tiles from all boards that are favourited
      final boardFavTiles = <SymbolTile>[];
      for (final board in _boards) {
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
    
    // Only apply layout truncation/expansion if we are viewing a specific board without search active
    if (_activeTab?.type == TopTabType.board && _activeTab?.board != null && (search.isEmpty || (search.length == 1 && !_isSearchableShortQuery(search)))) {
      final board = _activeTab!.board!;

      if (board.adjustableLayout) {
        // Requirement: ensure that it always includes the very last tile on the board, and finishes there.
        // It should not cut tiles off, nor should I any more extra blank tiles than is needed.
        
        // Find the index of the last tile that has any content (label, image, or emoji)
        int lastContentIndex = -1;
        for (int i = filtered.length - 1; i >= 0; i--) {
          final t = filtered[i];
          if (t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty || t.linkedBoardId.isNotEmpty) {
            lastContentIndex = i;
            break;
          }
        }
        
        // We show all tiles up to the last filled one, plus exactly ONE blank space at the end
        // for adding new content.
        if (lastContentIndex == -1) {
          // Board is completely empty, just show one "Add" tile
          return filtered.isEmpty ? [] : filtered.sublist(0, 1);
        }
        
        final displayCount = (lastContentIndex + 2).clamp(1, filtered.length);
        return filtered.sublist(0, displayCount);
      }

      if (!board.adjustableLayout && board.rows > 0 && board.columns > 0) {
        final gridLimit = board.rows * board.columns;
        
        // Find the index of the last tile that has any content
        int lastContentIndex = -1;
        for (int i = filtered.length - 1; i >= 0; i--) {
          final t = filtered[i];
          if (t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty || t.linkedBoardId.isNotEmpty) {
            lastContentIndex = i;
            break;
          }
        }
        
        // Show at least the grid size, but expand if there's content beyond it
        final actualLimit = max(gridLimit, lastContentIndex + 1);

        if (!_showAllBoardSymbols && filtered.length > actualLimit) {
          return filtered.sublist(0, actualLimit);
        }
      }
    }
    return filtered;
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
    if (!_boards.any((b) => b.id == boardId)) {
      _boards.add(board);
    }
    if (!mounted) return;

    final targetMode = _getModeForBoard(board.id);
    if (_currentMode != targetMode) {
      setState(() {
        _currentMode = targetMode;
        _activeTab = null;
        _parentBoard = null;
      });
      await _loadBoards(area: board.area);
      if (!mounted) return;
    }

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

      // 2. Find or create the tab
      TopTab? targetTab;
      try {
        targetTab = _tabs.firstWhere((t) => t.id == board.id);
        // If found in top tabs, it shouldn't have a parent that forces sub-tabs
        parent = targetTab.parentBoard;
      } catch (_) {
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
      _showAllBoardSymbols = false;
      _persistSessionState();
    });
  }

  Board _createAutoMissingBoard(String id, String name,
      {String? area, bool isSubBoard = false}) {
    final tile = SymbolTile(
      id: '${id}_empty',
      label: name,
      category: 'Custom',
      imageAsset: 'assets/Empty Board.png',
      isBoardLink: false,
      bgColor: '#000000',
      textColor: '#FFFFFF',
    );
    return Board(
      id: id,
      name: name,
      area: area ?? hierarchyArea(name),
      rows: 1,
      columns: 1,
      adjustableLayout: false,
      backgroundColor: defaultBoardColor,
      tiles: [tile],
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
    BoardService.getInstance().then((s) => s.saveBoard(board));
    return board;
  }

  Board _createMissingBoardPlaceholder(String id, String name) {
    return Board(
      id: id,
      name: name,
      area: _activeArea(),
      rows: defaultBoardRows,
      columns: defaultBoardColumns,
      adjustableLayout: true,
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

  void _goBackInHistory() {
    if (_navigationHistory.isEmpty) return;
    setState(() {
      final prev = _navigationHistory.removeLast();
      _activeTab = prev;
      _parentBoard = prev.parentBoard;
      _selectedCategory = prev.type == TopTabType.category ? prev.label : 'All';
    });
  }

/// PHRASE BUILDER
/// This is called whenever a symbol is tapped. It adds the symbol 
/// to the top horizontal list and updates the text field below it.

  void _addToPhrase(SymbolTile symbol) {
    setState(() {
      _phrase.add(symbol);
      _isUpdatingText = true;
      final current = _sentenceController.text.trim();
      _sentenceController.text =
          current.isEmpty ? symbol.label : '$current ${symbol.label}';
      _isUpdatingText = false;
    });
    if (symbol.speaks && !(_settings?.readSentenceOnly ?? false)) {
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
      _sentenceController.text = _phrase.map((s) => s.label).join(' ');
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

  SymbolTile? _findSymbolForTypedWord(String word) {
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
    const suffixes = ['ies', 'es', 'ing', 'ed', 'er', 'est', 'ion', 'tion', 'ly', 's'];
    for (final suffix in suffixes) {
      if (lower.endsWith(suffix) && lower.length > suffix.length + 2) {
        final base = lower.substring(0, lower.length - suffix.length);
        final baseTile = _findExactSymbol(base);
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

  Future<void> _addTypedWordToPhrase(String word) async {
    final lower = word.toLowerCase().trim();
    if (lower.isEmpty) return;
    final cached = _typedWordCache[lower];
    if (cached != null) {
      _addTileToPhrase(cached);
      return;
    }
    var symbol = _findSymbolForTypedWord(word);
    if (symbol != null) {
      _addTileToPhrase(symbol);
      return;
    }
    final assetResults = await _externalSymbolService.searchAssets(word, limit: 1);
    if (assetResults.isNotEmpty) {
      symbol = assetResults.first.toSymbolTile();
    }
    if (symbol == null) {
      final externalResults = await _externalSymbolService.searchAll(word, limit: 1);
      if (externalResults.isNotEmpty) {
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
    final service = await BoardService.getInstance();
    final isFavorite = _favoritesService?.isFavorite(symbol.id) ?? false;
    
    // Toggle the favorite ID
    await _favoritesService?.toggleFavorite(symbol.id);
    
    // Also add/remove from the Favorites board
    final favoritesBoardId = prebuiltBoardId('Favorites');
    Board? favoritesBoard = await service.loadBoard(favoritesBoardId);
    
    if (!isFavorite) {
      // Adding to favorites - add to Favorites board
      favoritesBoard ??= Board(
        id: favoritesBoardId,
        name: 'Favorites',
        rows: defaultBoardRows,
        columns: defaultBoardColumns,
        tiles: [],
        isSubBoard: true,
      );
      
      // Add the tile to the favorites board if not already there
      final tileExists = favoritesBoard.tiles.any((t) => t.id == symbol.id);
      if (!tileExists) {
        favoritesBoard.tiles.add(symbol);
        await service.saveBoard(favoritesBoard);
      }
    } else {
      // Removing from favorites - remove from Favorites board
      if (favoritesBoard != null) {
        favoritesBoard.tiles.removeWhere((t) => t.id == symbol.id);
        await service.saveBoard(favoritesBoard);
      }
    }
    
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
    final savedBoardId = await Navigator.of(context).push<String>(MaterialPageRoute(
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
        ),
      ),
    );
    if (result != null) {
      widget.onSettingsChanged(result.settings);
      setState(() {
        _settings = result.settings;
        if (_activeProfile != null) {
          _activeProfile = _activeProfile!.copyWith(
            settings: result.settings,
            preferredSymbolSets: result.preferredSymbolSets,
            startingBoardId: result.startingBoardId,
          );
        }
      });
      if (_activeProfile != null) {
        await _saveActiveProfile();
      }
      
      final boardService = await BoardService.getInstance();
      boardService.setProjectRoot(result.settings.projectRoot);
      await _loadBoards();

      if (result.navigateToBoardId != null) {
        _openLinkedBoard(result.navigateToBoardId!);
      }

      await _configureTts();
    } else {
      await _loadBoards();
    }
  }

  void _openSyncStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
    );
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
        _showAllBoardSymbols = false;
        _parentBoard = tab.parentBoard;
      });
      _persistSessionState();
      return;
    }
    if (tab.type == TopTabType.favorites) {
      setState(() {
        _activeTab = tab;
        _selectedCategory = 'All';
        _showAllBoardSymbols = false;
        _parentBoard = null;
      });
      _persistSessionState();
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

  bool _isAncestor(String ancestorId, Board? child) {
    if (child == null) return false;
    if (child.parentBoardId == ancestorId) return true;
    final parent = _boards.cast<Board?>().firstWhere((b) => b?.id == child.parentBoardId, orElse: () => null);
    return _isAncestor(ancestorId, parent);
  }

  Future<void> _showReorderTabsDialog(List<TopTab> boardTabs, {Board? rowParent}) async {
    await showDialog<List<TopTab>>(
      context: context,
      builder: (ctx) => _ReorderTabsDialog(
        tabs: boardTabs,
        onDelete: _deleteTabFromReorderDialog,
        onAdd: (tabs) => _addExistingBoardToTabRow(tabs, parent: rowParent),
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
    if (board.parentBoardId != null && board.parentBoardId!.isNotEmpty) {
      // Promote out of the current tab row
      final newParentId = tab.parentBoard?.parentBoardId;
      board.parentBoardId = newParentId ?? '';
      if (newParentId != null && newParentId.isNotEmpty) {
        final newParent = _boards.cast<Board?>().firstWhere(
              (b) => b?.id == newParentId,
              orElse: () => null,
            );
        board.isSubBoard = true;
        board.isTertiaryBoard = newParent?.isSubBoard ?? false;
      } else {
        board.isSubBoard = false;
        board.isTertiaryBoard = false;
      }
    } else {
      // Top-level tab: hide from the top tab bar without deleting
      board.isSubBoard = true;
    }
    // Load the full board (with tiles) before saving, otherwise the tile-less
    // placeholder used in the tab list would overwrite the board with no tiles.
    final fullBoard = await service.loadBoard(board.id) ?? board;
    fullBoard.isSubBoard = board.isSubBoard;
    fullBoard.isTertiaryBoard = board.isTertiaryBoard;
    fullBoard.parentBoardId = board.parentBoardId;
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
            (rowParent == null || b.id != rowParent.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final selectedId = await _pickExistingBoard(candidates);
    if (selectedId == null) return null;

    final original = await service.getBoard(selectedId);
    if (original == null) return null;

    final targetArea = rowParent?.area ?? _activeArea();
    final parentId = rowParent?.id;

    // Find a unique internal id and name for the new secondary tab.
    final existingIds = <String>{for (final b in allBoards) b.id};
    final existingNames = <String>{for (final b in allBoards) b.name.toLowerCase()};

    String linkId;
    String linkName;
    int n = 1;
    do {
      linkName = n == 1 ? original.name : '${original.name} ($n)';
      linkId = n == 1 ? 'link_${original.id}' : 'link_${original.id}_$n';
      n++;
    } while (existingIds.contains(linkId));

    final isSub = rowParent != null;
    final tier = (rowParent?.tier ?? 1) + (isSub ? 1 : 0);

    final linkBoard = Board(
      id: linkId,
      name: linkName,
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
      label: linkName,
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

  int _getCurrentRowLevel(List<TopTab> tabs) {
    if (tabs.isEmpty) return 0;
    // Top-level tabs don't have a parent board
    final firstWithParent = tabs.firstWhere((t) => t.parentBoard != null, orElse: () => tabs.first);
    if (firstWithParent.parentBoard == null) return 0;
    return firstWithParent.parentBoard!.tier;
  }

  Widget _buildTabBar(List<TopTab> tabs) {
    final reorderableTabs = tabs
        .where((t) => t.type == TopTabType.board && t.board != null && _boards.any((b) => b.id == t.board!.id))
        .toList();
    final editorIndex = tabs.indexWhere((t) => t.type == TopTabType.editor);
    final reorderIndex = editorIndex == -1 ? 0 : editorIndex;
    
    // Maintain scroll controllers for each tab row level
    final rowLevel = _getCurrentRowLevel(tabs);
    final controller = _tabScrollControllers.putIfAbsent(rowLevel, () => ScrollController());

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: tabs.length + 1,
        itemBuilder: (context, index) {
          if (index == reorderIndex) {
            return _buildReorderTabButton(() => _showReorderTabsDialog(reorderableTabs));
          }
          final tabIndex = index < reorderIndex ? index : index - 1;
          final tab = tabs[tabIndex];
          return _buildTabButton(tab, tabIndex, tabs.length);
        },
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

  Widget _buildTabButton(TopTab tab, int index, int total) {
    final selected = _activeTab?.id == tab.id || _isAncestor(tab.id, _activeTab?.board);
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
        if (tab.type == TopTabType.board && tab.board != null && !tab.board!.id.startsWith('link_')) {
          _showReorderTabsDialog(_subTabsForBoard(tab.board), rowParent: tab.board);
        } else {
          _refreshBoardCache(tab);
        }
      },
      child: Container(
        key: ValueKey(tab.id),
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
              if (tab.iconAssetPath != null)
                Image.asset(
                  tab.iconAssetPath!,
                  width: 18,
                  height: 18,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.grid_view, size: 18);
                  },
                )
              else if (tab.icon != null)
                Icon(tab.icon, size: 18),
              if (!isUtilityTab) ...[
                const SizedBox(width: 6),
                Text(tab.label, style: const TextStyle(fontSize: 13)),
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
    while (current != null && current.parentBoardId != null) {
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
              ],
            ),
          ),
        ),
        actions: [
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
                    child: CustomScrollView(
                      controller: _boardScrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...tabRows.map((row) => SizedBox(
                                height: layout.tabBarHeight,
                                child: _buildTabBar(row),
                              )),
                              _buildResponsiveBody(context, layout),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              RepaintBoundary(
                                key: _boardViewKey,
                                child: _isLoadingActiveBoard
                                    ? _buildBoardLoadingPlaceholder(context)
                                    : SymbolGrid(
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
                                  boxScale: _activeTab?.board?.boxScale ?? 1.0,
                                  highContrast: _settings?.highContrast ?? false,
                                  viewOnly: _activeTab?.type == TopTabType.board,
                                  scrollable: false,
                                ),
                              ),
                              if (_activeTab?.type == TopTabType.board && _activeTab?.board != null &&
                                  !_activeTab!.board!.adjustableLayout &&
                                  _activeTab!.board!.rows >= 10 &&
                                  _filteredSymbols.length > (_activeTab!.board!.rows * _activeTab!.board!.columns) &&
                                  !_showAllBoardSymbols)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAllBoardSymbols = true;
                                      });
                                    },
                                    child: const Text('Show More'),
                                  ),
                                ),
                              const SizedBox(height: 240),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _showScrollToTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
                            final showSymbol = _settings?.sentenceType != 'words';
                            final showLabel = _settings?.sentenceType != 'symbols';
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
                    onPressed: () => _speakText(_sentenceController.text, saveHistory: true),
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
                            'Board: ${_activeTab!.label}',
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
                                  onPressed: _goBackInHistory,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back'),
                                ),
                              if (_parentBoard != null)
                                OutlinedButton.icon(
                                  onPressed: _goUpToParentBoard,
                                  icon: const Icon(Icons.arrow_upward),
                                  label: const Text('Up'),
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
                                onPressed: _exportBoardFromView,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Export Board'),
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
  final Future<void> Function() onSaveComplete;
  const _ReorderTabsDialog({required this.tabs, required this.onDelete, required this.onAdd, required this.onSaveComplete});

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
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final item = _localList.removeAt(oldIndex);
                    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                    _localList.insert(insertIndex, item);
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
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
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
      title: Text('Login to ${widget.profile.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            onSubmitted: (_) => _handleLogin(),
          ),
        ],
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
      _usernameController.text.trim(),
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
