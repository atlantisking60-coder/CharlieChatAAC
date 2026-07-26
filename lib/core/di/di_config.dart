import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/board_service.dart';
import '../../services/profile_service.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';
import '../../services/cross_platform_tts_service.dart';
import '../../services/favorites_service.dart';
import '../../services/phrase_service.dart';

/// Dependency Injection Configuration
/// 
/// This file sets up the GetIt service locator with all dependencies.
/// Services are registered as singletons to maintain state across the app.
/// 
/// Usage:
/// ```dart
/// final boardService = getIt<BoardService>();
/// ```
final getIt = GetIt.instance;

/// Initialize all dependencies
/// 
/// Call this in main.dart before runApp()
Future<void> setupDI() async {
  // Ensure all async singletons are ready
  await _registerAsyncDependencies();
  
  // Register synchronous dependencies
  _registerSyncDependencies();
}

void _registerSyncDependencies() {
  // Cross-platform TTS Service (singleton)
  getIt.registerSingleton<CrossPlatformTtsService>(
    CrossPlatformTtsService.instance,
  );
  
  // Connectivity (singleton)
  getIt.registerSingleton<Connectivity>(
    Connectivity(),
  );
}

Future<void> _registerAsyncDependencies() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  
  // Application Documents Directory
  final appDocDir = await getApplicationDocumentsDirectory();
  getIt.registerSingleton<String>(appDocDir.path);
  
  // Board Service (uses getInstance)
  final boardService = await BoardService.getInstance();
  getIt.registerSingleton<BoardService>(boardService);
  
  // Profile Service (uses init)
  final profileService = await ProfileService.init();
  getIt.registerSingleton<ProfileService>(profileService);
  
  // Settings Service (uses init)
  final settingsService = await SettingsService.init();
  getIt.registerSingleton<SettingsService>(settingsService);
  
  // Sync Service (uses init)
  final syncService = await SyncService.init();
  getIt.registerSingleton<SyncService>(syncService);
  
  // Favorites Service (uses init)
  final favoritesService = await FavoritesService.init();
  getIt.registerSingleton<FavoritesService>(favoritesService);
  
  // Phrase History Service (uses init)
  final phraseService = await PhraseHistoryService.init();
  getIt.registerSingleton<PhraseHistoryService>(phraseService);
}

/// Reset all dependencies (useful for testing)
/// 
/// WARNING: This should only be used in tests
Future<void> resetDI() async {
  await getIt.reset();
}
