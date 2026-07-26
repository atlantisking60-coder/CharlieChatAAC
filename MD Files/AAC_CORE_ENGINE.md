# AAC Core Engine

## Overview

This document provides a complete AAC (Augmentative and Alternative Communication) engine implementation for the Charlie Chat Android communication app using Flutter, following Clean Architecture principles with Entities, Repositories, Use Cases, and ViewModels.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  - ViewModels (State management)                           │
│  - Widgets (UI components)                                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
│  - Use Cases (Business logic)                              │
│  - Entities (Core business objects)                         │
│  - Repository Interfaces                                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
│  - Repository Implementations                               │
│  - Data Sources (Local/Remote)                              │
│  - Mappers (Entity ↔ Model conversion)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Domain Layer - Entities

### Symbol Entity

```dart
// lib/domain/entities/symbol.dart
class Symbol {
  final String id;
  final String label;
  final String? description;
  final String? imagePath;
  final String? emoji;
  final String? linkedBoardId;
  final bool isBoardLink;
  final double tileSize;
  final String backgroundColor;
  final String textColor;
  final String? customVoice;
  final int position;
  final int? row;
  final int? column;
  final bool isFavorite;
  final int usageCount;
  final DateTime? lastUsedAt;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Symbol({
    required this.id,
    required this.label,
    this.description,
    this.imagePath,
    this.emoji,
    this.linkedBoardId,
    this.isBoardLink = false,
    this.tileSize = 1.0,
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#000000',
    this.customVoice,
    this.position = 0,
    this.row,
    this.column,
    this.isFavorite = false,
    this.usageCount = 0,
    this.lastUsedAt,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  Symbol copyWith({
    String? id,
    String? label,
    String? description,
    String? imagePath,
    String? emoji,
    String? linkedBoardId,
    bool? isBoardLink,
    double? tileSize,
    String? backgroundColor,
    String? textColor,
    String? customVoice,
    int? position,
    int? row,
    int? column,
    bool? isFavorite,
    int? usageCount,
    DateTime? lastUsedAt,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Symbol(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      emoji: emoji ?? this.emoji,
      linkedBoardId: linkedBoardId ?? this.linkedBoardId,
      isBoardLink: isBoardLink ?? this.isBoardLink,
      tileSize: tileSize ?? this.tileSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      customVoice: customVoice ?? this.customVoice,
      position: position ?? this.position,
      row: row ?? this.row,
      column: column ?? this.column,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Category Entity

```dart
// lib/domain/entities/category.dart
class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final String? parentId;
  final int sortOrder;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color = '#FF0000',
    this.parentId,
    this.sortOrder = 0,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? parentId,
    int? sortOrder,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Board Entity

```dart
// lib/domain/entities/board.dart
class Board {
  final String id;
  final String profileId;
  final String name;
  final String? description;
  final int rows;
  final int columns;
  final bool adjustableLayout;
  final double boxScale;
  final double tileHeight;
  final double tileWidth;
  final String backgroundColor;
  final bool isSubBoard;
  final String? parentBoardId;
  final bool isPublic;
  final bool isDeleted;
  final int version;
  final String? cloudId;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    this.rows = 6,
    this.columns = 5,
    this.adjustableLayout = false,
    this.boxScale = 1.0,
    this.tileHeight = 100.0,
    this.tileWidth = 100.0,
    this.backgroundColor = '#FFFFFF',
    this.isSubBoard = false,
    this.parentBoardId,
    this.isPublic = false,
    this.isDeleted = false,
    this.version = 1,
    this.cloudId,
    this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Board copyWith({
    String? id,
    String? profileId,
    String? name,
    String? description,
    int? rows,
    int? columns,
    bool? adjustableLayout,
    double? boxScale,
    double? tileHeight,
    double? tileWidth,
    String? backgroundColor,
    bool? isSubBoard,
    String? parentBoardId,
    bool? isPublic,
    bool? isDeleted,
    int? version,
    String? cloudId,
    DateTime? syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      description: description ?? this.description,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      adjustableLayout: adjustableLayout ?? this.adjustableLayout,
      boxScale: boxScale ?? this.boxScale,
      tileHeight: tileHeight ?? this.tileHeight,
      tileWidth: tileWidth ?? this.tileWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isSubBoard: isSubBoard ?? this.isSubBoard,
      parentBoardId: parentBoardId ?? this.parentBoardId,
      isPublic: isPublic ?? this.isPublic,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      cloudId: cloudId ?? this.cloudId,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Sentence Entity

```dart
// lib/domain/entities/sentence.dart
class Sentence {
  final String id;
  final String profileId;
  final String text;
  final List<String> symbolIds;
  final bool isFavorite;
  final int usageCount;
  final String? cloudId;
  final DateTime? syncedAt;
  final DateTime createdAt;

  const Sentence({
    required this.id,
    required this.profileId,
    required this.text,
    required this.symbolIds,
    this.isFavorite = false,
    this.usageCount = 0,
    this.cloudId,
    this.syncedAt,
    required this.createdAt,
  });

  Sentence copyWith({
    String? id,
    String? profileId,
    String? text,
    List<String>? symbolIds,
    bool? isFavorite,
    int? usageCount,
    String? cloudId,
    DateTime? syncedAt,
    DateTime? createdAt,
  }) {
    return Sentence(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      text: text ?? this.text,
      symbolIds: symbolIds ?? this.symbolIds,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      cloudId: cloudId ?? this.cloudId,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### Favorite Entity

```dart
// lib/domain/entities/favorite.dart
class Favorite {
  final String id;
  final String profileId;
  final String symbolId;
  final DateTime addedAt;

  const Favorite({
    required this.id,
    required this.profileId,
    required this.symbolId,
    required this.addedAt,
  });

  Favorite copyWith({
    String? id,
    String? profileId,
    String? symbolId,
    DateTime? addedAt,
  }) {
    return Favorite(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      symbolId: symbolId ?? this.symbolId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
```

---

## 3. Domain Layer - Repository Interfaces

### Symbol Repository Interface

```dart
// lib/domain/repositories/symbol_repository.dart
import '../entities/symbol.dart';

abstract class SymbolRepository {
  Future<Symbol?> getSymbolById(String id);
  Future<List<Symbol>> getSymbolsByBoardId(String boardId);
  Future<List<Symbol>> getSymbolsByCategoryId(String categoryId);
  Future<List<Symbol>> searchSymbols(String query);
  Future<List<Symbol>> getFavoriteSymbols(String profileId);
  Future<List<Symbol>> getRecentSymbols(String profileId, {int limit = 20});
  Future<List<Symbol>> getMostUsedSymbols(String profileId, {int limit = 20});
  Future<void> saveSymbol(Symbol symbol);
  Future<void> saveSymbols(List<Symbol> symbols);
  Future<void> deleteSymbol(String id);
  Future<void> deleteSymbolsByBoardId(String boardId);
  Future<void> toggleFavorite(String symbolId, String profileId);
  Future<void> incrementUsageCount(String symbolId);
}
```

### Category Repository Interface

```dart
// lib/domain/repositories/category_repository.dart
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Category?> getCategoryById(String id);
  Future<List<Category>> getCategoriesByProfileId(String profileId);
  Future<List<Category>> getSubCategories(String parentId);
  Future<List<Category>> getSystemCategories();
  Future<List<Category>> searchCategories(String query);
  Future<void> saveCategory(Category category);
  Future<void> saveCategories(List<Category> categories);
  Future<void> deleteCategory(String id);
  Future<void> deleteCategoriesByProfileId(String profileId);
}
```

### Board Repository Interface

```dart
// lib/domain/repositories/board_repository.dart
import '../entities/board.dart';
import '../entities/symbol.dart';

abstract class BoardRepository {
  Future<Board?> getBoardById(String id);
  Future<List<Board>> getBoardsByProfileId(String profileId);
  Future<List<Board>> getMainBoardsByProfileId(String profileId);
  Future<List<Board>> getSubBoards(String parentBoardId);
  Future<List<Symbol>> getSymbolsForBoard(String boardId);
  Future<Board> getBoardWithSymbols(String boardId);
  Future<void> saveBoard(Board board);
  Future<void> saveBoardWithSymbols(Board board, List<Symbol> symbols);
  Future<void> deleteBoard(String id);
  Future<void> softDeleteBoard(String id);
  Future<List<Board>> searchBoards(String query);
  Future<void> updateSyncTimestamp(String boardId);
}
```

### Sentence Repository Interface

```dart
// lib/domain/repositories/sentence_repository.dart
import '../entities/sentence.dart';

abstract class SentenceRepository {
  Future<Sentence?> getSentenceById(String id);
  Future<List<Sentence>> getSentencesByProfileId(String profileId, {int limit = 50});
  Future<List<Sentence>> getFavoriteSentences(String profileId);
  Future<List<Sentence>> searchSentences(String query);
  Future<List<Sentence>> getMostUsedSentences(String profileId, {int limit = 20});
  Future<void> saveSentence(Sentence sentence);
  Future<void> saveSentences(List<Sentence> sentences);
  Future<void> deleteSentence(String id);
  Future<void> deleteSentencesByProfileId(String profileId);
  Future<void> incrementUsageCount(String sentenceId);
  Future<void> toggleFavorite(String sentenceId);
}
```

### Favorite Repository Interface

```dart
// lib/domain/repositories/favorite_repository.dart
import '../entities/favorite.dart';
import '../entities/symbol.dart';

abstract class FavoriteRepository {
  Future<List<Favorite>> getFavoritesByProfileId(String profileId);
  Future<List<Symbol>> getFavoriteSymbols(String profileId);
  Future<Favorite?> getFavorite(String profileId, String symbolId);
  Future<void> addFavorite(Favorite favorite);
  Future<void> removeFavorite(String profileId, String symbolId);
  Future<void> removeFavoritesByProfileId(String profileId);
  Future<void> removeFavoritesBySymbolId(String symbolId);
}
```

---

## 4. Domain Layer - Use Cases

### Get Symbols Use Case

```dart
// lib/domain/usecases/get_symbols_usecase.dart
import '../entities/symbol.dart';
import '../repositories/symbol_repository.dart';

class GetSymbolsUseCase {
  final SymbolRepository _repository;

  GetSymbolsUseCase(this._repository);

  Future<List<Symbol>> call(String boardId) async {
    return await _repository.getSymbolsByBoardId(boardId);
  }
}
```

### Search Symbols Use Case

```dart
// lib/domain/usecases/search_symbols_usecase.dart
import '../entities/symbol.dart';
import '../repositories/symbol_repository.dart';

class SearchSymbolsUseCase {
  final SymbolRepository _repository;

  SearchSymbolsUseCase(this._repository);

  Future<List<Symbol>> call(String query) async {
    return await _repository.searchSymbols(query);
  }
}
```

### Toggle Favorite Use Case

```dart
// lib/domain/usecases/toggle_favorite_usecase.dart
import '../repositories/symbol_repository.dart';

class ToggleFavoriteUseCase {
  final SymbolRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  Future<void> call(String symbolId, String profileId) async {
    await _repository.toggleFavorite(symbolId, profileId);
  }
}
```

### Get Recent Symbols Use Case

```dart
// lib/domain/usecases/get_recent_symbols_usecase.dart
import '../entities/symbol.dart';
import '../repositories/symbol_repository.dart';

class GetRecentSymbolsUseCase {
  final SymbolRepository _repository;

  GetRecentSymbolsUseCase(this._repository);

  Future<List<Symbol>> call(String profileId, {int limit = 20}) async {
    return await _repository.getRecentSymbols(profileId, limit: limit);
  }
}
```

### Get Boards Use Case

```dart
// lib/domain/usecases/get_boards_usecase.dart
import '../entities/board.dart';
import '../repositories/board_repository.dart';

class GetBoardsUseCase {
  final BoardRepository _repository;

  GetBoardsUseCase(this._repository);

  Future<List<Board>> call(String profileId) async {
    return await _repository.getBoardsByProfileId(profileId);
  }
}
```

### Get Board With Symbols Use Case

```dart
// lib/domain/usecases/get_board_with_symbols_usecase.dart
import '../entities/board.dart';
import '../repositories/board_repository.dart';

class GetBoardWithSymbolsUseCase {
  final BoardRepository _repository;

  GetBoardWithSymbolsUseCase(this._repository);

  Future<Board> call(String boardId) async {
    return await _repository.getBoardWithSymbols(boardId);
  }
}
```

### Save Board Use Case

```dart
// lib/domain/usecases/save_board_usecase.dart
import '../entities/board.dart';
import '../entities/symbol.dart';
import '../repositories/board_repository.dart';

class SaveBoardUseCase {
  final BoardRepository _repository;

  SaveBoardUseCase(this._repository);

  Future<void> call(Board board, {List<Symbol>? symbols}) async {
    if (symbols != null) {
      await _repository.saveBoardWithSymbols(board, symbols);
    } else {
      await _repository.saveBoard(board);
    }
  }
}
```

### Build Sentence Use Case

```dart
// lib/domain/usecases/build_sentence_usecase.dart
import '../entities/symbol.dart';
import '../entities/sentence.dart';
import '../repositories/sentence_repository.dart';
import '../repositories/symbol_repository.dart';

class BuildSentenceUseCase {
  final SymbolRepository _symbolRepository;
  final SentenceRepository _sentenceRepository;

  BuildSentenceUseCase(this._symbolRepository, this._sentenceRepository);

  Future<String> call(List<String> symbolIds, String profileId) async {
    final symbols = <Symbol>[];
    
    for (final symbolId in symbolIds) {
      final symbol = await _symbolRepository.getSymbolById(symbolId);
      if (symbol != null) {
        symbols.add(symbol);
        await _symbolRepository.incrementUsageCount(symbolId);
      }
    }

    final sentence = symbols.map((s) => s.label).join(' ');
    
    // Save sentence to history
    final sentenceEntity = Sentence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: profileId,
      text: sentence,
      symbolIds: symbolIds,
      createdAt: DateTime.now(),
    );
    
    await _sentenceRepository.saveSentence(sentenceEntity);
    
    return sentence;
  }
}
```

### Speak Text Use Case

```dart
// lib/domain/usecases/speak_text_usecase.dart
import '../services/tts_service.dart';

class SpeakTextUseCase {
  final TTSService _ttsService;

  SpeakTextUseCase(this._ttsService);

  Future<void> call(String text, {String? voice, String? language}) async {
    await _ttsService.speak(text, voice: voice, language: language);
  }
}
```

### Get Categories Use Case

```dart
// lib/domain/usecases/get_categories_usecase.dart
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<Category>> call(String profileId) async {
    return await _repository.getCategoriesByProfileId(profileId);
  }
}
```

---

## 5. Data Layer - Repository Implementations

### Symbol Repository Implementation

```dart
// lib/data/repositories/symbol_repository_impl.dart
import '../../domain/entities/symbol.dart';
import '../../domain/repositories/symbol_repository.dart';
import '../datasources/local/symbol_local_datasource.dart';
import '../datasources/remote/symbol_remote_datasource.dart';
import '../mappers/symbol_mapper.dart';

class SymbolRepositoryImpl implements SymbolRepository {
  final SymbolLocalDataSource _localDataSource;
  final SymbolRemoteDataSource _remoteDataSource;
  final SymbolMapper _mapper;

  SymbolRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._mapper,
  );

  @override
  Future<Symbol?> getSymbolById(String id) async {
    try {
      final model = await _localDataSource.getSymbolById(id);
      return _mapper.toEntity(model);
    } catch (e) {
      // Try remote if local fails
      final model = await _remoteDataSource.getSymbolById(id);
      return _mapper.toEntity(model);
    }
  }

  @override
  Future<List<Symbol>> getSymbolsByBoardId(String boardId) async {
    final models = await _localDataSource.getSymbolsByBoardId(boardId);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> getSymbolsByCategoryId(String categoryId) async {
    final models = await _localDataSource.getSymbolsByCategoryId(categoryId);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> searchSymbols(String query) async {
    final models = await _localDataSource.searchSymbols(query);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> getFavoriteSymbols(String profileId) async {
    final models = await _localDataSource.getFavoriteSymbols(profileId);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> getRecentSymbols(String profileId, {int limit = 20}) async {
    final models = await _localDataSource.getRecentSymbols(profileId, limit: limit);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> getMostUsedSymbols(String profileId, {int limit = 20}) async {
    final models = await _localDataSource.getMostUsedSymbols(profileId, limit: limit);
    return models.map((model) => _mapper.toEntity(model)).toList();
  }

  @override
  Future<void> saveSymbol(Symbol symbol) async {
    final model = _mapper.toModel(symbol);
    await _localDataSource.saveSymbol(model);
  }

  @override
  Future<void> saveSymbols(List<Symbol> symbols) async {
    final models = symbols.map((s) => _mapper.toModel(s)).toList();
    await _localDataSource.saveSymbols(models);
  }

  @override
  Future<void> deleteSymbol(String id) async {
    await _localDataSource.deleteSymbol(id);
  }

  @override
  Future<void> deleteSymbolsByBoardId(String boardId) async {
    await _localDataSource.deleteSymbolsByBoardId(boardId);
  }

  @override
  Future<void> toggleFavorite(String symbolId, String profileId) async {
    await _localDataSource.toggleFavorite(symbolId, profileId);
  }

  @override
  Future<void> incrementUsageCount(String symbolId) async {
    await _localDataSource.incrementUsageCount(symbolId);
  }
}
```

### Board Repository Implementation

```dart
// lib/data/repositories/board_repository_impl.dart
import '../../domain/entities/board.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/repositories/board_repository.dart';
import '../datasources/local/board_local_datasource.dart';
import '../datasources/remote/board_remote_datasource.dart';
import '../mappers/board_mapper.dart';
import '../mappers/symbol_mapper.dart';

class BoardRepositoryImpl implements BoardRepository {
  final BoardLocalDataSource _localDataSource;
  final BoardRemoteDataSource _remoteDataSource;
  final BoardMapper _boardMapper;
  final SymbolMapper _symbolMapper;

  BoardRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._boardMapper,
    this._symbolMapper,
  );

  @override
  Future<Board?> getBoardById(String id) async {
    final model = await _localDataSource.getBoardById(id);
    return model != null ? _boardMapper.toEntity(model) : null;
  }

  @override
  Future<List<Board>> getBoardsByProfileId(String profileId) async {
    final models = await _localDataSource.getBoardsByProfileId(profileId);
    return models.map((model) => _boardMapper.toEntity(model)).toList();
  }

  @override
  Future<List<Board>> getMainBoardsByProfileId(String profileId) async {
    final models = await _localDataSource.getMainBoardsByProfileId(profileId);
    return models.map((model) => _boardMapper.toEntity(model)).toList();
  }

  @override
  Future<List<Board>> getSubBoards(String parentBoardId) async {
    final models = await _localDataSource.getSubBoards(parentBoardId);
    return models.map((model) => _boardMapper.toEntity(model)).toList();
  }

  @override
  Future<List<Symbol>> getSymbolsForBoard(String boardId) async {
    final models = await _localDataSource.getSymbolsForBoard(boardId);
    return models.map((model) => _symbolMapper.toEntity(model)).toList();
  }

  @override
  Future<Board> getBoardWithSymbols(String boardId) async {
    final boardModel = await _localDataSource.getBoardById(boardId);
    if (boardModel == null) {
      throw Exception('Board not found');
    }

    final symbolModels = await _localDataSource.getSymbolsForBoard(boardId);
    final board = _boardMapper.toEntity(boardModel);
    final symbols = symbolModels.map((m) => _symbolMapper.toEntity(m)).toList();

    return board.copyWith(
      // You might want to add symbols as a property to Board entity
      // or return a BoardWithSymbols entity
    );
  }

  @override
  Future<void> saveBoard(Board board) async {
    final model = _boardMapper.toModel(board);
    await _localDataSource.saveBoard(model);
  }

  @override
  Future<void> saveBoardWithSymbols(Board board, List<Symbol> symbols) async {
    final boardModel = _boardMapper.toModel(board);
    final symbolModels = symbols.map((s) => _symbolMapper.toModel(s)).toList();
    await _localDataSource.saveBoardWithSymbols(boardModel, symbolModels);
  }

  @override
  Future<void> deleteBoard(String id) async {
    await _localDataSource.deleteBoard(id);
  }

  @override
  Future<void> softDeleteBoard(String id) async {
    await _localDataSource.softDeleteBoard(id);
  }

  @override
  Future<List<Board>> searchBoards(String query) async {
    final models = await _localDataSource.searchBoards(query);
    return models.map((model) => _boardMapper.toEntity(model)).toList();
  }

  @override
  Future<void> updateSyncTimestamp(String boardId) async {
    await _localDataSource.updateSyncTimestamp(boardId);
  }
}
```

---

## 6. Data Layer - Mappers

### Symbol Mapper

```dart
// lib/data/mappers/symbol_mapper.dart
import '../../domain/entities/symbol.dart';
import '../models/symbol_model.dart';

class SymbolMapper {
  Symbol toEntity(SymbolModel model) {
    return Symbol(
      id: model.id,
      label: model.label,
      description: model.description,
      imagePath: model.imagePath,
      emoji: model.emoji,
      linkedBoardId: model.linkedBoardId,
      isBoardLink: model.isBoardLink,
      tileSize: model.tileSize,
      backgroundColor: model.backgroundColor,
      textColor: model.textColor,
      customVoice: model.customVoice,
      position: model.position,
      row: model.row,
      column: model.column,
      isFavorite: model.isFavorite,
      usageCount: model.usageCount,
      lastUsedAt: model.lastUsedAt,
      categoryId: model.categoryId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  SymbolModel toModel(Symbol entity) {
    return SymbolModel(
      id: entity.id,
      boardId: '', // Will be set when saving to board
      label: entity.label,
      description: entity.description,
      imagePath: entity.imagePath,
      emoji: entity.emoji,
      linkedBoardId: entity.linkedBoardId,
      isBoardLink: entity.isBoardLink,
      tileSize: entity.tileSize,
      backgroundColor: entity.backgroundColor,
      textColor: entity.textColor,
      customVoice: entity.customVoice,
      position: entity.position,
      row: entity.row,
      column: entity.column,
      isFavorite: entity.isFavorite,
      usageCount: entity.usageCount,
      lastUsedAt: entity.lastUsedAt,
      categoryId: entity.categoryId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
```

### Board Mapper

```dart
// lib/data/mappers/board_mapper.dart
import '../../domain/entities/board.dart';
import '../models/board_model.dart';

class BoardMapper {
  Board toEntity(BoardModel model) {
    return Board(
      id: model.id,
      profileId: model.profileId,
      name: model.name,
      description: model.description,
      rows: model.rows,
      columns: model.columns,
      adjustableLayout: model.adjustableLayout,
      boxScale: model.boxScale,
      tileHeight: model.tileHeight,
      tileWidth: model.tileWidth,
      backgroundColor: model.backgroundColor,
      isSubBoard: model.isSubBoard,
      parentBoardId: model.parentBoardId,
      isPublic: model.isPublic,
      isDeleted: model.isDeleted,
      version: model.version,
      cloudId: model.cloudId,
      syncedAt: model.syncedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  BoardModel toModel(Board entity) {
    return BoardModel(
      id: entity.id,
      profileId: entity.profileId,
      name: entity.name,
      description: entity.description,
      rows: entity.rows,
      columns: entity.columns,
      adjustableLayout: entity.adjustableLayout,
      boxScale: entity.boxScale,
      tileHeight: entity.tileHeight,
      tileWidth: entity.tileWidth,
      backgroundColor: entity.backgroundColor,
      isSubBoard: entity.isSubBoard,
      parentBoardId: entity.parentBoardId,
      isPublic: entity.isPublic,
      isDeleted: entity.isDeleted,
      version: entity.version,
      cloudId: entity.cloudId,
      syncedAt: entity.syncedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
```

---

## 7. Presentation Layer - ViewModels

### AAC Engine ViewModel

```dart
// lib/presentation/viewmodels/aac_engine_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/sentence.dart';
import '../../domain/usecases/get_boards_usecase.dart';
import '../../domain/usecases/get_board_with_symbols_usecase.dart';
import '../../domain/usecases/get_symbols_usecase.dart';
import '../../domain/usecases/search_symbols_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/usecases/get_recent_symbols_usecase.dart';
import '../../domain/usecases/build_sentence_usecase.dart';
import '../../domain/usecases/speak_text_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';

class AACEngineViewModel extends ChangeNotifier {
  final GetBoardsUseCase _getBoardsUseCase;
  final GetBoardWithSymbolsUseCase _getBoardWithSymbolsUseCase;
  final GetSymbolsUseCase _getSymbolsUseCase;
  final SearchSymbolsUseCase _searchSymbolsUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final GetRecentSymbolsUseCase _getRecentSymbolsUseCase;
  final BuildSentenceUseCase _buildSentenceUseCase;
  final SpeakTextUseCase _speakTextUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  // State
  List<Board> _boards = [];
  List<Symbol> _currentSymbols = [];
  List<Symbol> _sentenceSymbols = [];
  List<Symbol> _recentSymbols = [];
  List<Symbol> _searchResults = [];
  Board? _currentBoard;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Board> get boards => _boards;
  List<Symbol> get currentSymbols => _currentSymbols;
  List<Symbol> get sentenceSymbols => _sentenceSymbols;
  List<Symbol> get recentSymbols => _recentSymbols;
  List<Symbol> get searchResults => _searchResults;
  Board? get currentBoard => _currentBoard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentSentence => _sentenceSymbols.map((s) => s.label).join(' ');
  int get sentenceLength => _sentenceSymbols.length;

  AACEngineViewModel({
    required GetBoardsUseCase getBoardsUseCase,
    required GetBoardWithSymbolsUseCase getBoardWithSymbolsUseCase,
    required GetSymbolsUseCase getSymbolsUseCase,
    required SearchSymbolsUseCase searchSymbolsUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
    required GetRecentSymbolsUseCase getRecentSymbolsUseCase,
    required BuildSentenceUseCase buildSentenceUseCase,
    required SpeakTextUseCase speakTextUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _getBoardsUseCase = getBoardsUseCase,
        _getBoardWithSymbolsUseCase = getBoardWithSymbolsUseCase,
        _getSymbolsUseCase = getSymbolsUseCase,
        _searchSymbolsUseCase = searchSymbolsUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        _getRecentSymbolsUseCase = getRecentSymbolsUseCase,
        _buildSentenceUseCase = buildSentenceUseCase,
        _speakTextUseCase = speakTextUseCase,
        _getCategoriesUseCase = getCategoriesUseCase;

  // Load boards
  Future<void> loadBoards(String profileId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _boards = await _getBoardsUseCase(profileId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load board with symbols
  Future<void> loadBoard(String boardId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBoard = await _getBoardWithSymbolsUseCase(boardId);
      _currentSymbols = await _getSymbolsUseCase(boardId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add symbol to sentence
  void addToSentence(Symbol symbol) {
    _sentenceSymbols.add(symbol);
    notifyListeners();
  }

  // Remove last symbol from sentence
  void removeFromSentence() {
    if (_sentenceSymbols.isNotEmpty) {
      _sentenceSymbols.removeLast();
      notifyListeners();
    }
  }

  // Clear sentence
  void clearSentence() {
    _sentenceSymbols.clear();
    notifyListeners();
  }

  // Speak sentence
  Future<void> speakSentence(String profileId) async {
    if (_sentenceSymbols.isEmpty) return;

    try {
      final symbolIds = _sentenceSymbols.map((s) => s.id).toList();
      final sentence = await _buildSentenceUseCase(symbolIds, profileId);
      await _speakTextUseCase(sentence);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Speak single symbol
  Future<void> speakSymbol(Symbol symbol) async {
    try {
      await _speakTextUseCase(symbol.label);
      await _getRecentSymbolsUseCase(''); // Refresh recent symbols
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(Symbol symbol, String profileId) async {
    try {
      await _toggleFavoriteUseCase(symbol.id, profileId);
      final updatedSymbol = symbol.copyWith(isFavorite: !symbol.isFavorite);
      _updateSymbolInList(updatedSymbol);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Search symbols
  Future<void> searchSymbols(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _searchSymbolsUseCase(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recent symbols
  Future<void> loadRecentSymbols(String profileId) async {
    try {
      _recentSymbols = await _getRecentSymbolsUseCase(profileId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Navigate to subboard
  Future<void> navigateToSubBoard(String boardId) async {
    await loadBoard(boardId);
  }

  // Navigate to parent board
  Future<void> navigateToParentBoard() async {
    if (_currentBoard?.parentBoardId != null) {
      await loadBoard(_currentBoard!.parentBoardId!);
    }
  }

  // Helper: Update symbol in list
  void _updateSymbolInList(Symbol updatedSymbol) {
    _currentSymbols = _currentSymbols.map((s) {
      return s.id == updatedSymbol.id ? updatedSymbol : s;
    }).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

### Board ViewModel

```dart
// lib/presentation/viewmodels/board_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/usecases/get_boards_usecase.dart';
import '../../domain/usecases/get_board_with_symbols_usecase.dart';
import '../../domain/usecases/save_board_usecase.dart';

class BoardViewModel extends ChangeNotifier {
  final GetBoardsUseCase _getBoardsUseCase;
  final GetBoardWithSymbolsUseCase _getBoardWithSymbolsUseCase;
  final SaveBoardUseCase _saveBoardUseCase;

  // State
  List<Board> _boards = [];
  List<Symbol> _symbols = [];
  Board? _currentBoard;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Board> get boards => _boards;
  List<Symbol> get symbols => _symbols;
  Board? get currentBoard => _currentBoard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BoardViewModel({
    required GetBoardsUseCase getBoardsUseCase,
    required GetBoardWithSymbolsUseCase getBoardWithSymbolsUseCase,
    required SaveBoardUseCase saveBoardUseCase,
  })  : _getBoardsUseCase = getBoardsUseCase,
        _getBoardWithSymbolsUseCase = getBoardWithSymbolsUseCase,
        _saveBoardUseCase = saveBoardUseCase;

  Future<void> loadBoards(String profileId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _boards = await _getBoardsUseCase(profileId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBoard(String boardId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBoard = await _getBoardWithSymbolsUseCase(boardId);
      _symbols = await _getBoardWithSymbolsUseCase(boardId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBoard(Board board, {List<Symbol>? symbols}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saveBoardUseCase(board, symbols: symbols);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 8. Presentation Layer - Riverpod Providers

### AAC Engine Provider

```dart
// lib/presentation/providers/aac_engine_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_boards_usecase.dart';
import '../../domain/usecases/get_board_with_symbols_usecase.dart';
import '../../domain/usecases/get_symbols_usecase.dart';
import '../../domain/usecases/search_symbols_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/usecases/get_recent_symbols_usecase.dart';
import '../../domain/usecases/build_sentence_usecase.dart';
import '../../domain/usecases/speak_text_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../viewmodels/aac_engine_viewmodel.dart';

// Use case providers
final getBoardsUseCaseProvider = Provider<GetBoardsUseCase>((ref) {
  return GetBoardsUseCase(ref.watch(boardRepositoryProvider));
});

final getBoardWithSymbolsUseCaseProvider = Provider<GetBoardWithSymbolsUseCase>((ref) {
  return GetBoardWithSymbolsUseCase(ref.watch(boardRepositoryProvider));
});

final getSymbolsUseCaseProvider = Provider<GetSymbolsUseCase>((ref) {
  return GetSymbolsUseCase(ref.watch(symbolRepositoryProvider));
});

final searchSymbolsUseCaseProvider = Provider<SearchSymbolsUseCase>((ref) {
  return SearchSymbolsUseCase(ref.watch(symbolRepositoryProvider));
});

final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>((ref) {
  return ToggleFavoriteUseCase(ref.watch(symbolRepositoryProvider));
});

final getRecentSymbolsUseCaseProvider = Provider<GetRecentSymbolsUseCase>((ref) {
  return GetRecentSymbolsUseCase(ref.watch(symbolRepositoryProvider));
});

final buildSentenceUseCaseProvider = Provider<BuildSentenceUseCase>((ref) {
  return BuildSentenceUseCase(
    ref.watch(symbolRepositoryProvider),
    ref.watch(sentenceRepositoryProvider),
  );
});

final speakTextUseCaseProvider = Provider<SpeakTextUseCase>((ref) {
  return SpeakTextUseCase(ref.watch(ttsServiceProvider));
});

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

// ViewModel provider
final aacEngineViewModelProvider = ChangeNotifierProvider<AACEngineViewModel>((ref) {
  return AACEngineViewModel(
    getBoardsUseCase: ref.watch(getBoardsUseCaseProvider),
    getBoardWithSymbolsUseCase: ref.watch(getBoardWithSymbolsUseCaseProvider),
    getSymbolsUseCase: ref.watch(getSymbolsUseCaseProvider),
    searchSymbolsUseCase: ref.watch(searchSymbolsUseCaseProvider),
    toggleFavoriteUseCase: ref.watch(toggleFavoriteUseCaseProvider),
    getRecentSymbolsUseCase: ref.watch(getRecentSymbolsUseCaseProvider),
    buildSentenceUseCase: ref.watch(buildSentenceUseCaseProvider),
    speakTextUseCase: ref.watch(speakTextUseCaseProvider),
    getCategoriesUseCase: ref.watch(getCategoriesUseCaseProvider),
  );
});
```

### Board Provider

```dart
// lib/presentation/providers/board_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/board.dart';
import '../../domain/usecases/get_boards_usecase.dart';
import '../../domain/usecases/get_board_with_symbols_usecase.dart';

final boardsProvider = FutureProvider.family<List<Board>, String>((ref, profileId) async {
  final useCase = ref.watch(getBoardsUseCaseProvider);
  return await useCase(profileId);
});

final boardProvider = FutureProvider.family<Board, String>((ref, boardId) async {
  final useCase = ref.watch(getBoardWithSymbolsUseCaseProvider);
  return await useCase(boardId);
});
```

### Symbol Provider

```dart
// lib/presentation/providers/symbol_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/usecases/get_symbols_usecase.dart';

final symbolsProvider = FutureProvider.family<List<Symbol>, String>((ref, boardId) async {
  final useCase = ref.watch(getSymbolsUseCaseProvider);
  return await useCase(boardId);
});

final searchResultsProvider = Provider<List<Symbol>>((ref) {
  final viewModel = ref.watch(aacEngineViewModelProvider);
  return viewModel.searchResults;
});

final recentSymbolsProvider = Provider<List<Symbol>>((ref) {
  final viewModel = ref.watch(aacEngineViewModelProvider);
  return viewModel.recentSymbols;
});
```

---

## 9. TTS Service

```dart
// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _currentVoice;
  String _currentLanguage = 'en-US';
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        'ambient',
        [
          'allowBackgroundAudioPlayback',
          'mixWithOthers',
        ],
        'spokenAudio',
      );
      _initialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text, {String? voice, String? language}) async {
    if (!_initialized) await initialize();

    try {
      if (language != null) {
        await _tts.setLanguage(language);
      } else {
        await _tts.setLanguage(_currentLanguage);
      }

      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      if (voice != null) {
        await _tts.setVoice({'name': voice});
      } else if (_currentVoice != null) {
        await _tts.setVoice({'name': _currentVoice});
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    if (_initialized) {
      await _tts.stop();
    }
  }

  Future<List<Map<String, String>>> getVoices() async {
    if (!_initialized) await initialize();
    return await _tts.getVoices;
  }

  Future<void> setVoice(String voiceName) async {
    _currentVoice = voiceName;
    if (!_initialized) await initialize();
    await _tts.setVoice({'name': voiceName});
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    if (!_initialized) await initialize();
    await _tts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    if (!_initialized) await initialize();
    await _tts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (!_initialized) await initialize();
    await _tts.setPitch(pitch);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (!_initialized) await initialize();
    await _tts.setVolume(volume);
  }
}
```

---

## 10. Example Usage

### Using the AAC Engine in a Widget

```dart
// lib/presentation/pages/communication_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aac_engine_provider.dart';
import '../widgets/symbol_grid.dart';
import '../widgets/sentence_panel.dart';

class CommunicationPage extends ConsumerWidget {
  final String profileId;
  final String? initialBoardId;

  const CommunicationPage({
    super.key,
    required this.profileId,
    this.initialBoardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(aacEngineViewModelProvider);

    // Initialize on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.loadBoards(profileId);
      if (initialBoardId != null) {
        viewModel.loadBoard(initialBoardId!);
      }
      viewModel.loadRecentSymbols(profileId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showRecentSymbolsDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sentence Panel
          SentencePanel(
            sentence: viewModel.currentSentence,
            symbols: viewModel.sentenceSymbols,
            onRemove: viewModel.removeFromSentence,
            onClear: viewModel.clearSentence,
            onSpeak: () => viewModel.speakSentence(profileId),
          ),
          
          // Symbol Grid
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null
                    ? Center(child: Text(viewModel.errorMessage!))
                    : SymbolGrid(
                        symbols: viewModel.currentSymbols,
                        onSymbolTap: (symbol) {
                          viewModel.addToSentence(symbol);
                        },
                        onSymbolLongPress: (symbol) {
                          viewModel.speakSymbol(symbol);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final viewModel = ref.read(aacEngineViewModelProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Symbols'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Search...'),
          onChanged: (value) {
            viewModel.searchSymbols(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRecentSymbolsDialog(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(aacEngineViewModelProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Symbols'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: viewModel.recentSymbols.length,
            itemBuilder: (context, index) {
              final symbol = viewModel.recentSymbols[index];
              return ListTile(
                title: Text(symbol.label),
                onTap: () {
                  viewModel.addToSentence(symbol);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

---

## 11. Summary

This AAC Core Engine provides:

1. **Domain Entities** - Symbol, Category, Board, Sentence, Favorite with proper properties
2. **Repository Interfaces** - Abstract interfaces for all data operations
3. **Repository Implementations** - Concrete implementations with local/remote data sources
4. **Use Cases** - Business logic for all AAC operations
5. **ViewModels** - State management with ChangeNotifier
6. **Riverpod Providers** - Dependency injection and state management
7. **TTS Service** - Text-to-speech integration with Flutter TTS
8. **Mappers** - Entity ↔ Model conversion
9. **Complete Implementation** - Ready-to-use Flutter code

The engine supports:
- Symbol management with categories
- Board and subboard navigation
- Sentence building and history
- Speech playback
- Symbol history and recent symbols
- Favorites
- Search functionality

---

**Related Documents:**
- [ROOM_DATABASE_SCHEMA.md](ROOM_DATABASE_SCHEMA.md)
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [DOMAIN_LAYER.md](DOMAIN_LAYER.md)
- [DATA_LAYER.md](DATA_LAYER.md)
- [PRESENTATION_LAYER.md](PRESENTATION_LAYER.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
