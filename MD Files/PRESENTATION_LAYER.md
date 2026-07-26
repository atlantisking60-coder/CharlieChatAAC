# Presentation Layer Documentation

## Overview

The Presentation Layer is responsible for displaying data to the user and handling user interactions. It contains UI components, state management, and navigation logic. This layer should be thin and delegate business logic to the Domain Layer.

---

## Structure

```
presentation/
├── pages/                # Full-screen pages
│   ├── home/
│   │   ├── home_page.dart
│   │   └── home_page_view.dart
│   ├── settings/
│   │   ├── settings_page.dart
│   │   └── settings_page_view.dart
│   ├── profile/
│   │   ├── profile_page.dart
│   │   └── profile_page_view.dart
│   ├── editor/
│   │   ├── board_editor_page.dart
│   │   └── board_editor_page_view.dart
│   └── welcome/
│       └── welcome_page.dart
├── widgets/              # Reusable widgets
│   ├── common/           # Common widgets
│   │   ├── app_bar.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   └── empty_state.dart
│   ├── board/            # Board-related widgets
│   │   ├── symbol_grid.dart
│   │   ├── symbol_tile.dart
│   │   └── board_header.dart
│   ├── symbol/           # Symbol-related widgets
│   │   ├── symbol_button.dart
│   │   └── symbol_image.dart
│   └── sentence/         # Sentence-related widgets
│       ├── sentence_panel.dart
│       └── phrase_panel.dart
├── providers/            # State management (Riverpod)
│   ├── board_provider.dart
│   ├── settings_provider.dart
│   ├── profile_provider.dart
│   ├── tts_provider.dart
│   └── sync_provider.dart
├── viewmodels/           # View models (MVVM pattern)
│   ├── board_viewmodel.dart
│   ├── settings_viewmodel.dart
│   └── profile_viewmodel.dart
└── routes/               # Route definitions
    └── app_router.dart
```

---

## Pages

Pages are full-screen widgets that represent a specific screen in the application.

### HomePage

```dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Charlie Chat - ${activeProfile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: boardsAsync.when(
        data: (boards) => BoardListView(boards: boards),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/editor'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### SettingsPage

```dart
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.watch(settingsProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(settings.themeMode.toString()),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (value) {
                if (value != null) {
                  settingsNotifier.updateThemeMode(value);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Voice Rate'),
            subtitle: Slider(
              value: settings.voiceRate,
              min: 0.1,
              max: 2.0,
              onChanged: (value) {
                settingsNotifier.updateVoiceRate(value);
              },
            ),
          ),
          ListTile(
            title: const Text('Voice Pitch'),
            subtitle: Slider(
              value: settings.voicePitch,
              min: 0.0,
              max: 2.0,
              onChanged: (value) {
                settingsNotifier.updateVoicePitch(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### ProfilePage

```dart
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: profilesAsync.when(
        data: (profiles) => ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final isActive = profile.id == activeProfileId;
            
            return ListTile(
              title: Text(profile.name),
              trailing: isActive ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(profileProvider.notifier).setActiveProfile(profile.id);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProfileDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Profile Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(profileProvider.notifier).createProfile(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
```

---

## Widgets

Widgets are reusable UI components.

### Common Widgets

#### LoadingIndicator

```dart
class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  const LoadingIndicator({this.message, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
```

#### ErrorWidget

```dart
class ErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  
  const ErrorWidget(this.error, {this.onRetry, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${error.toString()}'),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### EmptyState

```dart
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Board Widgets

#### SymbolGrid

```dart
class SymbolGrid extends StatelessWidget {
  final List<SymbolTile> tiles;
  final int columns;
  final Function(SymbolTile) onTileTap;
  
  const SymbolGrid({
    required this.tiles,
    required this.columns,
    required this.onTileTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return SymbolTileWidget(
          tile: tile,
          onTap: () => onTileTap(tile),
        );
      },
    );
  }
}
```

#### SymbolTileWidget

```dart
class SymbolTileWidget extends StatelessWidget {
  final SymbolTile tile;
  final VoidCallback onTap;
  
  const SymbolTileWidget({
    required this.tile,
    required this.onTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tile.bgColor != 'transparent' 
              ? Color(int.parse(tile.bgColor.replaceAll('#', '0xFF')))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tile.imageAsset.isNotEmpty)
              Image.asset(
                tile.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, color: Colors.grey[400]);
                },
              )
            else if (tile.emoji.isNotEmpty)
              Text(
                tile.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                tile.label,
                style: TextStyle(
                  color: tile.textColor != '#000000'
                      ? Color(int.parse(tile.textColor.replaceAll('#', '0xFF')))
                      : Colors.black,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Providers (Riverpod)

Providers manage state using Riverpod.

### BoardProvider

```dart
final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepositoryImpl(
    ref.watch(boardLocalDataSourceProvider),
    ref.watch(boardRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
  );
});

final boardsProvider = FutureProvider<List<Board>>((ref) async {
  final repository = ref.watch(boardRepositoryProvider);
  return await repository.getBoards();
});

final boardProvider = FutureProvider.family<Board?, String>((ref, id) async {
  final repository = ref.watch(boardRepositoryProvider);
  return await repository.getBoard(id);
});

final boardNotifierProvider = StateNotifierProvider<BoardNotifier, BoardState>((ref) {
  return BoardNotifier(ref.watch(boardRepositoryProvider));
});

class BoardNotifier extends StateNotifier<BoardState> {
  final BoardRepository _repository;
  
  BoardNotifier(this._repository) : super(BoardState.initial());
  
  Future<void> loadBoards() async {
    state = BoardState.loading();
    try {
      final boards = await _repository.getBoards();
      state = BoardState.loaded(boards);
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
  
  Future<void> saveBoard(Board board) async {
    try {
      await _repository.saveBoard(board);
      await loadBoards(); // Reload to reflect changes
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
  
  Future<void> deleteBoard(String id) async {
    try {
      await _repository.deleteBoard(id);
      await loadBoards();
    } catch (e) {
      state = BoardState.error(e.toString());
    }
  }
}

class BoardState {
  final bool isLoading;
  final List<Board>? boards;
  final String? error;
  
  BoardState.initial() : isLoading = false, boards = null, error = null;
  BoardState.loading() : isLoading = true, boards = null, error = null;
  BoardState.loaded(this.boards) : isLoading = false, error = null;
  BoardState.error(this.error) : isLoading = false, boards = null;
}
```

### SettingsProvider

```dart
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    ref.watch(settingsLocalDataSourceProvider),
  );
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;
  
  SettingsNotifier(this._repository) : super(const AppSettings(
    themeMode: ThemeMode.system,
    voiceRate: 0.5,
    voicePitch: 1.0,
    voiceVolume: 1.0,
  ));
  
  Future<void> loadSettings() async {
    final settings = await _repository.getSettings();
    state = settings;
  }
  
  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.saveSettings(state);
  }
  
  Future<void> updateVoiceRate(double rate) async {
    state = state.copyWith(voiceRate: rate);
    await _repository.saveSettings(state);
  }
  
  Future<void> updateVoicePitch(double pitch) async {
    state = state.copyWith(voicePitch: pitch);
    await _repository.saveSettings(state);
  }
  
  Future<void> updateVoiceVolume(double volume) async {
    state = state.copyWith(voiceVolume: volume);
    await _repository.saveSettings(state);
  }
  
  Future<void> updateVoiceLanguage(String language) async {
    state = state.copyWith(voiceLanguage: language);
    await _repository.saveSettings(state);
  }
  
  Future<void> updateVoiceName(String name) async {
    state = state.copyWith(voiceName: name);
    await _repository.saveSettings(state);
  }
}
```

### ProfileProvider

```dart
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileLocalDataSourceProvider),
  );
});

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getProfiles();
});

final activeProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getActiveProfile();
});

final activeProfileIdProvider = StateProvider<String>((ref) => '');

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  
  ProfileNotifier(this._repository) : super(ProfileState.initial());
  
  Future<void> loadProfiles() async {
    state = ProfileState.loading();
    try {
      final profiles = await _repository.getProfiles();
      state = ProfileState.loaded(profiles);
    } catch (e) {
      state = ProfileState.error(e.toString());
    }
  }
  
  Future<void> createProfile(String name) async {
    try {
      await _repository.createProfile(name);
      await loadProfiles();
    } catch (e) {
      state = ProfileState.error(e.toString());
    }
  }
  
  Future<void> setActiveProfile(String id) async {
    try {
      await _repository.setActiveProfile(id);
      await loadProfiles();
    } catch (e) {
      state = ProfileState.error(e.toString());
    }
  }
  
  Future<void> deleteProfile(String id) async {
    try {
      await _repository.deleteProfile(id);
      await loadProfiles();
    } catch (e) {
      state = ProfileState.error(e.toString());
    }
  }
}

class ProfileState {
  final bool isLoading;
  final List<UserProfile>? profiles;
  final String? error;
  
  ProfileState.initial() : isLoading = false, profiles = null, error = null;
  ProfileState.loading() : isLoading = true, profiles = null, error = null;
  ProfileState.loaded(this.profiles) : isLoading = false, error = null;
  ProfileState.error(this.error) : isLoading = false, profiles = null;
}
```

### TTSProvider

```dart
final ttsRepositoryProvider = Provider<TTSRepository>((ref) {
  return TTSRepositoryImpl(
    ref.watch(ttsServiceProvider),
  );
});

final ttsProvider = StateNotifierProvider<TTSNotifier, TTSState>((ref) {
  return TTSNotifier(ref.watch(ttsRepositoryProvider));
});

class TTSNotifier extends StateNotifier<TTSState> {
  final TTSRepository _repository;
  
  TTSNotifier(this._repository) : super(TTSState.initial());
  
  Future<void> speak(String text) async {
    state = TTSState.speaking();
    try {
      await _repository.speak(text);
      state = TTSState.idle();
    } catch (e) {
      state = TTSState.error(e.toString());
    }
  }
  
  Future<void> stop() async {
    try {
      await _repository.stop();
      state = TTSState.idle();
    } catch (e) {
      state = TTSState.error(e.toString());
    }
  }
  
  Future<void> setVoice(String voiceName, String locale) async {
    try {
      await _repository.setVoice(voiceName, locale: locale);
    } catch (e) {
      state = TTSState.error(e.toString());
    }
  }
  
  Future<void> loadVoices() async {
    try {
      final voices = await _repository.getVoices();
      state = TTSState.voicesLoaded(voices);
    } catch (e) {
      state = TTSState.error(e.toString());
    }
  }
}

class TTSState {
  final bool isSpeaking;
  final List<VoiceOption>? voices;
  final String? error;
  
  TTSState.initial() : isSpeaking = false, voices = null, error = null;
  TTSState.idle() : isSpeaking = false, voices = null, error = null;
  TTSState.speaking() : isSpeaking = true, voices = null, error = null;
  TTSState.voicesLoaded(this.voices) : isSpeaking = false, error = null;
  TTSState.error(this.error) : isSpeaking = false, voices = null;
}
```

---

## ViewModels (MVVM)

ViewModels handle UI logic and coordinate between providers and widgets.

### BoardViewModel

```dart
class BoardViewModel extends ChangeNotifier {
  final BoardRepository _repository;
  
  List<Board> _boards = [];
  bool _isLoading = false;
  String? _error;
  
  BoardViewModel(this._repository) {
    loadBoards();
  }
  
  List<Board> get boards => _boards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadBoards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _boards = await _repository.getBoards();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> saveBoard(Board board) async {
    try {
      await _repository.saveBoard(board);
      await loadBoards();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteBoard(String id) async {
    try {
      await _repository.deleteBoard(id);
      await loadBoards();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

---

## Navigation (go_router)

### AppRouter

```dart
final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) {
        final boardId = state.uri.queryParameters['boardId'];
        return BoardEditorPage(boardId: boardId);
      },
    ),
    GoRoute(
      path: '/board/:id',
      name: 'board',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailPage(boardId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);
```

### Navigation Usage

```dart
// Navigate to a route
context.go('/settings');

// Navigate with parameters
context.go('/board/$boardId');

// Navigate with query parameters
context.go('/editor?boardId=$boardId');

// Navigate and replace
context.go('/profile');

// Go back
context.pop();
```

---

## Responsive Design

Implement responsive layouts based on screen size.

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1024) {
          return tablet;
        } else {
          return desktop;
        }
      },
    );
  }
}
```

---

## Best Practices

### 1. Keep Widgets Stateless When Possible

❌ **Bad:**
```dart
class BoardWidget extends StatefulWidget {
  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  List<Board> boards = [];
  
  @override
  void initState() {
    super.initState();
    _loadBoards();
  }
  
  void _loadBoards() async {
    boards = await repository.getBoards();
    setState(() {});
  }
}
```

✅ **Good:**
```dart
class BoardWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    
    return boardsAsync.when(
      data: (boards) => BoardListView(boards: boards),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### 2. Separate UI from Business Logic

❌ **Bad:**
```dart
class BoardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Business logic in widget
        final repository = BoardRepositoryImpl();
        repository.saveBoard(board);
      },
      child: Text('Save'),
    );
  }
}
```

✅ **Good:**
```dart
class BoardWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Delegate to provider
        ref.read(boardNotifierProvider.notifier).saveBoard(board);
      },
      child: Text('Save'),
    );
  }
}
```

### 3. Use Const Widgets

❌ **Bad:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

✅ **Good:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}
```

### 4. Handle Loading and Error States

❌ **Bad:**
```dart
class BoardWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    return BoardListView(boards: boardsAsync.value!); // Crashes on loading/error
  }
}
```

✅ **Good:**
```dart
class BoardWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    
    return boardsAsync.when(
      data: (boards) => BoardListView(boards: boards),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

---

## Testing Presentation Layer

Test widgets and providers.

### Widget Tests

```dart
testWidgets('HomePage displays loading indicator initially', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        boardsProvider.overrideWith((ref) => AsyncValue.loading()),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('HomePage displays boards when loaded', (tester) async {
  final testBoards = [
    Board(id: '1', name: 'Test', rows: 6, columns: 5, tiles: [],
          createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        boardsProvider.overrideWith((ref) => AsyncValue.data(testBoards)),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
  
  expect(find.text('Test'), findsOneWidget);
});
```

### Provider Tests

```dart
test('SettingsNotifier updates voice rate', () async {
  final mockRepository = MockSettingsRepository();
  final notifier = SettingsNotifier(mockRepository);
  
  await notifier.updateVoiceRate(0.8);
  
  expect(notifier.state.voiceRate, 0.8);
  verify(mockRepository.saveSettings(any)).called(1);
});
```

---

## Summary

The Presentation Layer provides:

1. **UI Components** - Reusable widgets for consistent design
2. **State Management** - Riverpod providers for reactive state
3. **Navigation** - go_router for declarative routing
4. **Responsive Design** - Adaptive layouts for different screen sizes
5. **Separation of Concerns** - UI logic separate from business logic

This layer ensures a clean, maintainable UI that delegates business logic to the Domain Layer.

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [DATA_LAYER.md](DATA_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
