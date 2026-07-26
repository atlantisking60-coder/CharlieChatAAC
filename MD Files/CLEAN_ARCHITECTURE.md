# Clean Architecture Guide

## Overview

Charlie Chat follows Clean Architecture principles to ensure maintainability, testability, and scalability. This document explains the architectural patterns and how they're implemented in the project.

---

## What is Clean Architecture?

Clean Architecture is a software design philosophy that separates concerns into distinct layers, making the application:
- **Testable** - Business logic can be tested without UI, database, or external dependencies
- **Independent** - UI can change without affecting business logic
- **Maintainable** - Clear separation of concerns makes code easier to understand and modify

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  (Widgets, Screens, ViewModels, State Management)           │
└─────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  (Use Cases, Entities, Repository Interfaces)               │
└─────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  (Repositories, Data Sources, Models, Services)             │
└─────────────────────────────────────────────────────────────┘
                              ↓ depends on
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                       │
│  (Storage, Network, Platform-specific code)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### 1. Presentation Layer

**Purpose:** Display data to the user and handle user interactions

**Components:**
- **Widgets:** Reusable UI components
- **Screens:** Full-screen pages
- **ViewModels:** Handle UI logic and state
- **Providers:** State management (Riverpod)

**Rules:**
- No business logic
- Only UI-related logic
- Communicates with Domain Layer via Use Cases
- Should be easily replaceable (e.g., switch from Material to Cupertino)

**Example:**
```dart
class BoardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    
    return boardsAsync.when(
      data: (boards) => BoardListView(boards: boards),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

---

### 2. Domain Layer

**Purpose:** Contains business logic and enterprise rules

**Components:**
- **Use Cases:** Application-specific business rules
- **Entities:** Core business objects
- **Repository Interfaces:** Abstractions for data access
- **Value Objects:** Immutable objects with no identity

**Rules:**
- No dependencies on external frameworks
- No UI or database logic
- Pure Dart code
- Testable in isolation

**Example:**
```dart
class GetBoardsUseCase {
  final BoardRepository _boardRepository;
  
  GetBoardsUseCase(this._boardRepository);
  
  Future<List<Board>> execute() {
    return _boardRepository.getBoards();
  }
}
```

---

### 3. Data Layer

**Purpose:** Provides data to the Domain Layer

**Components:**
- **Repositories:** Implement repository interfaces
- **Data Sources:** Where data comes from (local, remote)
- **Models:** Data transfer objects
- **Mappers:** Convert between models and entities

**Rules:**
- Implements Domain Layer interfaces
- Handles all data access logic
- No business logic
- Can use external libraries (HTTP, SQLite, etc.)

**Example:**
```dart
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _localDataSource;
  final BoardRemoteDataSource _remoteDataSource;
  
  BoardRepositoryImpl(this._localDataSource, this._remoteDataSource);
  
  @override
  Future<List<Board>> getBoards() async {
    try {
      return await _localDataSource.getBoards();
    } catch (e) {
      return await _remoteDataSource.getBoards();
    }
  }
}
```

---

### 4. Infrastructure Layer

**Purpose:** Provides technical capabilities

**Components:**
- **Storage:** File system, databases, SharedPreferences
- **Network:** HTTP clients, WebSocket
- **Platform:** Platform-specific code (Android, iOS, Web)

**Rules:**
- Lowest level of the architecture
- Can contain platform-specific code
- No business logic
- Exposed through Data Layer

---

## Dependency Rule

**The Dependency Rule:** Dependencies can only point inward.

```
Presentation → Domain → Data → Infrastructure
```

- Presentation depends on Domain
- Domain depends on nothing
- Data depends on Domain
- Infrastructure depends on Data

**Never:**
- Domain depending on Presentation
- Domain depending on Data
- Data depending on Presentation

---

## Implementation in Charlie Chat

### Current State

The project is currently in a **transition phase** from service-based architecture to Clean Architecture.

**Current Structure:**
```
lib/
├── data/
│   ├── models/
│   └── services/          # Mixed data and business logic
├── models/                # Domain entities
├── services/             # Business logic (needs refactoring)
├── widgets/              # Presentation layer
└── main.dart             # Entry point
```

**Target Structure:**
```
lib/
├── domain/               # NEW
│   ├── entities/
│   ├── usecases/
│   └── repositories/     # Interfaces
├── data/                 # RESTRUCTURED
│   ├── models/
│   ├── repositories/     # Implementations
│   ├── datasources/
│   └── services/
├── presentation/         # NEW
│   ├── pages/
│   ├── widgets/
│   ├── providers/
│   └── viewmodels/
├── core/                 # NEW
│   ├── constants/
│   ├── theme/
│   └── utils/
└── main.dart
```

---

## Migration Strategy

### Phase 1: Domain Layer (Current)

**Tasks:**
1. Create domain entities
2. Define repository interfaces
3. Create use cases

**Example:**
```dart
// domain/entities/board.dart
class Board {
  final String id;
  final String name;
  final List<SymbolTile> tiles;
  // ...
}

// domain/repositories/board_repository.dart
abstract class BoardRepository {
  Future<List<Board>> getBoards();
  Future<Board?> getBoard(String id);
  Future<void> saveBoard(Board board);
}

// domain/usecases/get_boards_usecase.dart
class GetBoardsUseCase {
  final BoardRepository _repository;
  
  GetBoardsUseCase(this._repository);
  
  Future<List<Board>> call() => _repository.getBoards();
}
```

### Phase 2: Data Layer

**Tasks:**
1. Implement repository interfaces
2. Create data sources
3. Add mappers

**Example:**
```dart
// data/repositories/board_repository_impl.dart
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _local;
  final BoardRemoteDataSource _remote;
  
  BoardRepositoryImpl(this._local, this._remote);
  
  @override
  Future<List<Board>> getBoards() async {
    final boardModels = await _local.getBoards();
    return boardModels.map((model) => BoardMapper.toEntity(model)).toList();
  }
}
```

### Phase 3: Presentation Layer

**Tasks:**
1. Create providers
2. Implement view models
3. Refactor widgets

**Example:**
```dart
// presentation/providers/board_provider.dart
final boardsProvider = FutureProvider<List<Board>>((ref) async {
  final getBoards = ref.watch(getBoardsUseCaseProvider);
  return getBoards();
});
```

### Phase 4: Dependency Injection

**Tasks:**
1. Add GetIt
2. Configure service locator
3. Wire up dependencies

**Example:**
```dart
// core/di/di_config.dart
final getIt = GetIt.instance;

void setupDI() {
  // Repositories
  getIt.registerLazySingleton<BoardRepository>(
    () => BoardRepositoryImpl(
      getIt<BoardLocalDataSource>(),
      getIt<BoardRemoteDataSource>(),
    ),
  );
  
  // Use Cases
  getIt.registerFactory<GetBoardsUseCase>(
    () => GetBoardsUseCase(getIt<BoardRepository>()),
  );
}
```

---

## Benefits of Clean Architecture

### 1. Testability

Each layer can be tested in isolation:

```dart
test('GetBoardsUseCase returns boards', () async {
  // Arrange
  final mockRepository = MockBoardRepository();
  final useCase = GetBoardsUseCase(mockRepository);
  
  when(mockRepository.getBoards()).thenAnswer((_) async => [testBoard]);
  
  // Act
  final result = await useCase();
  
  // Assert
  expect(result.length, 1);
});
```

### 2. Maintainability

Changes in one layer don't affect others:
- Change database → only Data Layer affected
- Change UI framework → only Presentation Layer affected
- Change business rules → only Domain Layer affected

### 3. Scalability

Easy to add new features:
- New data source → implement repository interface
- New use case → add to Domain Layer
- New screen → add to Presentation Layer

### 4. Collaboration

Teams can work independently:
- UI team → Presentation Layer
- Backend team → Data Layer
- Business logic team → Domain Layer

---

## Best Practices

### 1. Keep Layers Separate

❌ **Bad:**
```dart
class BoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final boards = SharedPreferences.getInstance() // Direct access!
      .then((prefs) => prefs.getString('boards'));
    // ...
  }
}
```

✅ **Good:**
```dart
class BoardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardsProvider);
    // ...
  }
}
```

### 2. Use Interfaces

❌ **Bad:**
```dart
class BoardService {
  Future<List<Board>> getBoards() {
    return File('boards.json').readAsString();
  }
}
```

✅ **Good:**
```dart
abstract class BoardRepository {
  Future<List<Board>> getBoards();
}

class BoardRepositoryImpl implements BoardRepository {
  final BoardDataSource _dataSource;
  
  @override
  Future<List<Board>> getBoards() => _dataSource.getBoards();
}
```

### 3. Dependency Inversion

❌ **Bad:**
```dart
class BoardService {
  final File _file = File('boards.json'); // Concrete dependency
}
```

✅ **Good:**
```dart
class BoardService {
  final BoardDataSource _dataSource; // Abstract dependency
  
  BoardService(this._dataSource);
}
```

---

## Common Patterns

### Repository Pattern

Separates data access logic from business logic:

```dart
// Domain Layer
abstract class BoardRepository {
  Future<List<Board>> getBoards();
  Future<void> saveBoard(Board board);
}

// Data Layer
class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _local;
  final BoardRemoteDataSource _remote;
  
  @override
  Future<List<Board>> getBoards() async {
    try {
      return await _local.getBoards();
    } catch (e) {
      return await _remote.getBoards();
    }
  }
}
```

### Use Case Pattern

Encapsulates a single business action:

```dart
class GetBoardsUseCase {
  final BoardRepository _repository;
  
  GetBoardsUseCase(this._repository);
  
  Future<List<Board>> call() => _repository.getBoards();
}

// Usage
final boards = await getBoardsUseCase();
```

### Factory Pattern

Creates objects without specifying exact class:

```dart
abstract class BoardFactory {
  Board createBoard(String name);
}

class DefaultBoardFactory implements BoardFactory {
  @override
  Board createBoard(String name) {
    return Board(id: generateId(), name: name, tiles: []);
  }
}
```

---

## Testing Strategy

### Unit Tests

Test each layer independently:

```dart
// Domain Layer Tests
test('GetBoardsUseCase returns boards', () async {
  final mockRepo = MockBoardRepository();
  final useCase = GetBoardsUseCase(mockRepo);
  when(mockRepo.getBoards()).thenAnswer((_) async => [testBoard]);
  
  final result = await useCase();
  expect(result.length, 1);
});

// Data Layer Tests
test('BoardRepositoryImpl returns boards from local source', () async {
  final mockLocal = MockBoardLocalDataSource();
  final repo = BoardRepositoryImpl(mockLocal, MockBoardRemoteDataSource());
  when(mockLocal.getBoards()).thenAnswer((_) async => [boardModel]);
  
  final result = await repo.getBoards();
  expect(result.length, 1);
});
```

### Integration Tests

Test layer interactions:

```dart
test('BoardScreen displays boards from repository', () async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        boardRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(home: BoardScreen()),
    ),
  );
  
  expect(find.text('Test Board'), findsOneWidget);
});
```

---

## Summary

Clean Architecture provides a robust foundation for Charlie Chat by:

1. **Separating concerns** into distinct layers
2. **Making the code testable** at every level
3. **Allowing independent development** of layers
4. **Enabling easy maintenance** and feature additions
5. **Supporting multiple platforms** through abstraction

The migration to Clean Architecture is ongoing. See individual layer documentation for implementation details.

---

**Related Documents:**
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)
- [CROSS_PLATFORM_ARCHITECTURE.md](CROSS_PLATFORM_ARCHITECTURE.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
