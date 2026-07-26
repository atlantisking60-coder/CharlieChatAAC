// ignore_for_file: deprecated_member_use
// file_picker 12.x is still in beta and the static pickFiles API parameters
// (allowMultiple, withData, bytes) are deprecated without a stable replacement
// for multiple-file selection. These will be migrated when the package API
// stabilises.

import 'dart:async' show Timer;
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/rendering.dart';

import '../models/symbol_tile.dart';
import '../data/board_hierarchy.dart';
import '../services/board_ocr_service.dart';
import '../services/board_population_service.dart';
import '../services/board_service.dart';
import '../services/external_symbol_service.dart';
import '../services/board_archive_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../utils/board_export_utils.dart';
import '../utils/board_export_download.dart';
import 'external_symbol_search.dart';
import 'symbol_grid.dart';

final List<String> _dynamicColorOptions = [];

const String _placeholderImage = 'assets/symbols/needs symbol (placeholder).png';

const List<String> _colorOptions = [
  'transparent',
  '#000000', // Black
  '#FFFFFF', // White
  '#F5F5F5', // Light Gray
  '#9E9E9E', // Medium Gray
  '#616161', // Dark Gray
  // Red
  '#FFCDD2', // Light Red
  '#F44336', // Normal Red
  '#B71C1C', // Dark Red
  // Orange
  '#FFE0B2', // Light Orange
  '#FF9800', // Normal Orange
  '#E65100', // Dark Orange
  // Brown
  '#D7CCC8', // Light Brown
  '#A1887F', // Medium Brown
  '#795548', // Brown
  '#5D4037', // Deep Brown
  '#3E2723', // Dark Brown
  // Yellow
  '#FFF9C4', // Light Yellow
  '#FFEB3B', // Normal Yellow
  '#F57F17', // Dark Yellow
  // Green
  '#C8E6C9', // Light Green
  '#4CAF50', // Normal Green
  '#1B5E20', // Dark Green
  // Cyan
  '#B2EBF2', // Light Cyan
  '#00BCD4', // Normal Cyan
  '#006064', // Dark Cyan
  // Blue
  '#BBDEFB', // Light Blue
  '#2196F3', // Normal Blue
  '#0D47A1', // Dark Blue
  // Indigo
  '#C5CAE9', // Light Indigo
  '#3F51B5', // Normal Indigo
  '#1A237E', // Dark Indigo
  // Violet
  '#E1BEE7', // Light Violet
  '#9C27B0', // Normal Violet
  '#4A148C', // Dark Violet
  // Pink
  '#F8BBD0', // Light Pink
  '#E91E63', // Normal Pink
  '#880E4F', // Dark Pink
];

Color _colorFromHex(String hex, [Color fallback = Colors.transparent]) {
  if (hex == 'transparent') return Colors.transparent;
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length == 6 || cleaned.length == 8) {
    try {
      return Color(
          int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}

String _normalizeColor(String value, {String emptyDefault = 'transparent'}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return emptyDefault;
  final lower = trimmed.toLowerCase();
  if (lower == 'transparent') return 'transparent';
  if (trimmed.startsWith('#')) return trimmed;
  return '#$trimmed';
}

class BoardEditor extends StatefulWidget {
  final Board? board;
  final SymbolTile? initialSymbol;
  final int? initialIndex;
  final int? initialMergeIndex;
  final String initialArea;
  final String? initialParentBoardId;
  final int initialTier;
  final Future<void> Function(Board) onSave;

  const BoardEditor(
      {super.key, this.board, this.initialSymbol, this.initialIndex, this.initialMergeIndex, this.initialArea = 'Common', this.initialParentBoardId, this.initialTier = 1, required this.onSave});

  @override
  State<BoardEditor> createState() => _BoardEditorState();
}

class _BoardEditorState extends State<BoardEditor> {
  static const _populationService = BoardPopulationService();
  final _ocrService = BoardOcrService();
  final _externalSymbolService = ExternalSymbolService();
  final GlobalKey _boardScreenshotKey = GlobalKey();
  late Board board;
  late final TextEditingController _nameController;
  late final TextEditingController _rowsController;
  late final TextEditingController _columnsController;
  bool _mergeTilesEnabled = false;
  List<Board> _availableBoards = [];
  bool _isPopulating = false;
  bool _isSaving = false;
  double _populateProgress = 0.0;
  UserProfile? _activeProfile;
  int? _mergeSourceIndex;
  Timer? _resizeTimer;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    board = widget.board ??
        Board(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: 'New Board',
            area: widget.initialArea,
            parentBoardId: widget.initialParentBoardId,
            tier: widget.initialTier,
            rows: defaultBoardRows,
            columns: defaultBoardColumns,
            adjustableLayout: false,
            backgroundColor: defaultBoardColor,
            boxScale: 1.0,
            tiles: []);
    _nameController = TextEditingController(text: board.name);
    _rowsController = TextEditingController(text: board.rows.toString());
    _columnsController = TextEditingController(text: board.columns.toString());
    
    // Ensure tier is initialized and legacy flags are in sync
    if (board.tier == 1 && (board.isSubBoard || board.isTertiaryBoard || board.isQuaternaryBoard || board.isQuinaryBoard)) {
      board.tier = board.isQuinaryBoard
          ? 5
          : board.isQuaternaryBoard
              ? 4
              : board.isTertiaryBoard
                  ? 3
                  : 2;
    }
    board.isSubBoard = board.tier > 1;
    board.isTertiaryBoard = board.tier > 2;
    board.isQuaternaryBoard = board.tier > 3;
    board.isQuinaryBoard = board.tier > 4;

    _ensureTileCapacity(board.tiles.length);
    if (board.tiles.any((t) => t.colSpan > 1 || t.rowSpan > 1)) {
      _mergeTilesEnabled = true;
    }
    if (widget.initialSymbol != null) {
      _applyInitialSymbol(widget.initialSymbol!);
    }
    if (widget.initialMergeIndex != null) {
      _mergeSourceIndex = widget.initialMergeIndex;
    }
    _ensureTileCapacity(board.tiles.length);
    _loadAvailableBoards();

    if (widget.initialIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editTile(widget.initialIndex!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _columnsController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadCustomColors();
    final profileService = await ProfileService.init();
    setState(() {
      _activeProfile = profileService.activeProfile;
    });
  }

  Future<void> _loadCustomColors() async {
    final service = await SettingsService.init();
    final custom = service.getCustomColors();
    if (custom.isNotEmpty) {
      setState(() {
        _dynamicColorOptions.clear();
        _dynamicColorOptions.addAll(custom);
      });
    }
  }

  Future<void> _saveCustomColors() async {
    final service = await SettingsService.init();
    await service.saveCustomColors(_dynamicColorOptions);
  }

  void _applyInitialSymbol(SymbolTile symbol) {
    final index = board.tiles
        .indexWhere((tile) => tile.imageAsset.isEmpty && tile.label.isEmpty);
    final targetIndex = index >= 0 ? index : 0;
    setState(() {
      final tile = board.tiles[targetIndex];
      tile.label = symbol.label;
      tile.imageAsset = symbol.imageAsset;
      tile.category = symbol.category;
      tile.tileSize = symbol.tileSize;
      tile.bgColor = symbol.bgColor;
      tile.textColor = symbol.textColor;
      tile.isBoardLink = false;
      tile.linkedBoardId = '';
    });
  }

  /// [chooseFromOptions] controls behaviour:
  ///   false (default) — "guess" mode: always auto-picks the best match,
  ///                     never shows a popup, never keeps the current image.
  ///   true  — "choose" mode: always shows the selection popup so the user
  ///                     can pick from up to 9 candidates.
  Future<void> _autoFindTileImage(int index, {bool chooseFromOptions = false}) async {
    final tile = board.tiles[index];
    if (tile.label.isEmpty) return;

    setState(() => _isPopulating = true);
    try {
      // Strip text in brackets (e.g. "ng (phonics)" -> "ng")
      final rawLabel = tile.label.trim();
      final searchLabel = rawLabel.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ').trim();
      final query = searchLabel.toLowerCase();
      if (query.isEmpty) return;

      final results = await _externalSymbolService.searchAll(query, limit: 10, preferredSets: _activeProfile?.preferredSymbolSets);
      // Always skip the current image so we never "keep" what's already there.
      final candidates = results.where((r) => r.imageUrl != tile.imageAsset).toList();

      if (candidates.isEmpty) return;

      if (!chooseFromOptions) {
        // GUESS mode: auto-apply the first (best) match.
        final best = candidates.first;
        setState(() {
          board.tiles[index] = tile.copyWith(imageAsset: best.imageUrl, category: best.source);
        });
        final service = await BoardService.getInstance();
        await service.saveBoard(board);
      } else {
        // CHOOSE mode: show the selection popup.
        if (!mounted) return;
        final selected = await showDialog<ExternalSymbol>(
          context: context,
          builder: (ctx) => _SymbolSelectionDialog(
            symbols: candidates.take(9).toList(),
            title: 'Choose picture for "$rawLabel"',
          ),
        );
        if (selected != null) {
          setState(() {
            board.tiles[index] = tile.copyWith(imageAsset: selected.imageUrl, category: selected.source);
          });
          final service = await BoardService.getInstance();
          await service.saveBoard(board);
        }
      }
    } catch (e) {
      debugPrint('Error auto-finding image: $e');
    } finally {
      setState(() => _isPopulating = false);
    }
  }

  Future<void> _loadAvailableBoards() async {
    final service = await BoardService.getInstance();
    final boards = await service.listBoards();
    if (!mounted) return;
    setState(() {
      _availableBoards = boards.where((b) => b.id != board.id).toList();
    });
  }

  Future<String?> _createNewBoardFromDialog() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Board'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Board Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty) return null;

    // Generate board ID with appropriate prefix.
    // Admin-created boards use prebuilt_ (available to all users).
    // User-created boards use {username}_ (personal).
    final service = await BoardService.getInstance();
    final String boardId;
    if (service.isAdmin) {
      boardId = adminBoardId(name);
    } else {
      boardId = userBoardId(service.rawProfileId, name);
    }

    final newBoard = Board(
      id: boardId,
      name: name,
      area: board.area, // Inherit area
      rows: defaultBoardRows,
      columns: defaultBoardColumns,
      tiles: [],
      isSubBoard: true,
      parentBoardId: board.id,
      tier: board.tier + 1, // Correctly set next tier level
    );
    for (var i = 0; i < newBoard.rows * newBoard.columns; i++) {
      newBoard.tiles.add(SymbolTile(
        id: 'tile_$i',
        label: '',
        category: 'Custom',
        imageAsset: '',
        bgColor: 'transparent',
        textColor: '#000000',
      ));
    }
    await service.saveBoard(newBoard);
    await _loadAvailableBoards();
    return newBoard.id;
  }

  Future<void> importPictureFolder({bool fullScreen = false}) async {
    List<SymbolTile> newTiles = [];
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importing pictures...'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    try {
      if (kIsWeb) {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          dialogTitle: 'Select picture files',
          allowMultiple: true,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          for (final f in result.files) {
            try {
              final tile = await _tileFromPlatformFile(f,
                  fullScreen: fullScreen, boardId: board.id, skipOnlineSearch: true);
              newTiles.add(tile);
            } catch (e) {
              debugPrint('Error processing file ${f.name}: $e');
            }
          }
        }
      } else {
        final directoryPath = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select picture folder',
        );
        if (directoryPath != null) {
          final directory = Directory(directoryPath);
          final files = directory
              .listSync()
              .whereType<File>()
              .where((file) => _isImagePath(file.path))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
          for (final f in files) {
            try {
              final tile = await _tileFromFile(f, fullScreen: fullScreen, boardId: board.id);
              newTiles.add(tile);
            } catch (e) {
              debugPrint('Error processing file ${f.path}: $e');
            }
          }
        } else {
          final pickResult = await FilePicker.pickFiles(
            dialogTitle: 'Select pictures for board',
            type: FileType.image,
            allowMultiple: true,
            withData: true,
          );
          if (pickResult != null && pickResult.files.isNotEmpty) {
            for (final f in pickResult.files) {
              try {
                final tile = await _tileFromPlatformFile(f,
                    fullScreen: fullScreen, boardId: board.id, skipOnlineSearch: true);
                newTiles.add(tile);
              } catch (e) {
                debugPrint('Error processing file ${f.name}: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in importPictureFolder: $e');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
    if (newTiles.isNotEmpty) {
      _populateBoard(newTiles);
      final service = await BoardService.getInstance();
      await service.saveBoard(board);
    }
  }

  Future<void> _createFromImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() {
      _isPopulating = true;
      _populateProgress = 0.1;
    });

    try {
      // Pass the symbol service to the OCR service to allow for library matching
      final result = await _ocrService.processScreenshot(image, symbolService: _externalSymbolService);
      
      if (result != null) {
        setState(() {
          board.rows = result.rows;
          board.columns = result.columns;
          board.adjustableLayout = false;
          board.tiles = result.tiles;
        });
        
        final service = await BoardService.getInstance();
        await service.saveBoard(board);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not recognize a board grid in this image.'))
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating board from image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      setState(() {
        _isPopulating = false;
        _populateProgress = 0.0;
      });
    }
  }

  Future<bool> _isImageBroken(String path) async {
    if (path.isEmpty) return true;
    if (path.startsWith('assets/')) {
      try {
        await rootBundle.load(path);
        return false;
      } catch (_) {
        return true;
      }
    }
    if (path.startsWith('http')) {
      try {
        final response = await http.head(Uri.parse(path)).timeout(const Duration(seconds: 2));
        return response.statusCode != 200;
      } catch (_) {
        return true;
      }
    }
    if (!kIsWeb) return !await File(path).exists();
    return false;
  }

  Future<void> _fillPictures() async {
    setState(() {
      _isPopulating = true;
      _populateProgress = 0.0;
    });
    try {
      final total = board.tiles.length;
      for (int i = 0; i < total; i++) {
        final tile = board.tiles[i];
        if (tile.label.isNotEmpty) {
          final isBroken = await _isImageBroken(tile.imageAsset);
          if (tile.imageAsset.isEmpty || isBroken) {
            final query = tile.label.trim().toLowerCase();
            final results = await _externalSymbolService.searchAll(query, limit: 1, preferredSets: _activeProfile?.preferredSymbolSets);
            if (results.isNotEmpty) {
              setState(() {
                board.tiles[i] = tile.copyWith(imageAsset: results.first.imageUrl, category: results.first.source);
              });
            } else {
              setState(() {
                board.tiles[i] = tile.copyWith(imageAsset: _placeholderImage);
              });
            }
          }
        }
        setState(() {
          _populateProgress = (i + 1) / total;
        });
      }
      final service = await BoardService.getInstance();
      await service.saveBoard(board);
    } catch (e) {
      debugPrint('Error filling pictures: $e');
    } finally {
      setState(() {
        _isPopulating = false;
        _populateProgress = 0.0;
      });
    }
  }

  Future<void> _populateFromWordList() async {
    final controller = TextEditingController();
    final words = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Word List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'One word per line',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_populationService.parseWordList(controller.text)),
            child: const Text('Populate'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (words == null || words.isEmpty) return;
    setState(() {
      _isPopulating = true;
      _populateProgress = 0.0;
    });
    final tiles = <SymbolTile>[];
    for (int i = 0; i < words.length; i++) {
      final tile = await _tileFromWordWithSymbol(words[i]);
      tiles.add(tile);
      setState(() {
        _populateProgress = (i + 1) / words.length;
      });
    }
    _populateBoard(tiles);
    final service = await BoardService.getInstance();
    await service.saveBoard(board);
    setState(() {
      _isPopulating = false;
      _populateProgress = 0.0;
    });
  }

  Future<void> _populateWithAi() async {
    final titleController = TextEditingController(text: _nameController.text);
    final contextController = TextEditingController();
    var generatedTitle = '';
    final words = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Fill'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Board title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contextController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Context clues',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              generatedTitle = titleController.text.trim();
              Navigator.of(ctx).pop(_populationService.suggestWords(
                title: titleController.text,
                context: contextController.text,
                maxCount: _targetTileCount,
              ));
            },
            child: const Text('Populate'),
          ),
        ],
      ),
    );
    titleController.dispose();
    contextController.dispose();
    if (words == null || words.isEmpty) return;
    if (_nameController.text.trim().isEmpty && generatedTitle.isNotEmpty) {
      _nameController.text = generatedTitle;
      board.name = _nameController.text;
    }
    setState(() {
      _isPopulating = true;
      _populateProgress = 0.0;
    });
    final tiles = <SymbolTile>[];
    for (int i = 0; i < words.length; i++) {
      final tile = await _tileFromWordWithSymbol(words[i]);
      tiles.add(tile);
      setState(() {
        _populateProgress = (i + 1) / words.length;
      });
    }
    _populateBoard(tiles);
    final service = await BoardService.getInstance();
    await service.saveBoard(board);
    setState(() {
      _isPopulating = false;
      _populateProgress = 0.0;
    });
  }

  int get _targetTileCount {
    if (!board.adjustableLayout) return board.rows * board.columns;
    if (board.tiles.isEmpty) return defaultBoardRows * defaultBoardColumns;
    if (board.tiles.length > defaultBoardRows * defaultBoardColumns) return defaultBoardRows * defaultBoardColumns;
    return board.tiles.length;
  }

  void _populateBoard(List<SymbolTile> tiles) {
    if (tiles.isEmpty) return;
    setState(() {
      var tileIndex = 0;
      for (var i = 0; i < board.tiles.length && tileIndex < tiles.length; i++) {
        if (board.tiles[i].label.isEmpty && board.tiles[i].imageAsset.isEmpty && board.tiles[i].emoji.isEmpty) {
          board.tiles[i] = tiles[tileIndex];
          tileIndex++;
        }
      }
      while (tileIndex < tiles.length) {
        board.tiles.add(tiles[tileIndex]);
        tileIndex++;
      }
      _ensureTileCapacity(board.tiles.length);
    });
  }

  Future<void> _importBoardFromJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String raw;
      if (kIsWeb) {
        if (file.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not read file.')),
            );
          }
          return;
        }
        raw = String.fromCharCodes(file.bytes!);
      } else {
        if (file.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not read file path.')),
            );
          }
          return;
        }
        raw = await File(file.path!).readAsString();
      }
      final m = json.decode(raw) as Map<String, dynamic>;
      final service = await BoardService.getInstance();
      final imported = service.boardFromJson(m);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import from JSON'),
          content: Text(
            'This will replace the current board "${board.name}" with the '
            'board from the JSON file ("${imported.name}"). Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() {
        // Requirement: Do NOT change the area or board name already selected in the app
        board
          ..rows = imported.rows
          ..columns = imported.columns
          ..adjustableLayout = imported.adjustableLayout
          ..backgroundColor = imported.backgroundColor
          ..isSubBoard = imported.isSubBoard
          ..isTertiaryBoard = imported.isTertiaryBoard
          ..isQuaternaryBoard = imported.isQuaternaryBoard
          ..isQuinaryBoard = imported.isQuinaryBoard
          ..sortOrder = imported.sortOrder
          ..tier = imported.tier
          ..parentBoardId = imported.parentBoardId
          ..boxScale = imported.boxScale
          ..tileHeight = imported.tileHeight
          ..tileWidth = imported.tileWidth
          ..tiles = List<SymbolTile>.from(imported.tiles);
        _rowsController.text = board.rows.toString();
        _columnsController.text = board.columns.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${imported.name}" (${imported.tiles.length} tiles)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import JSON: $e')),
        );
      }
    }
  }

  bool _isBlankTile(SymbolTile tile) =>
      tile.label.isEmpty && tile.imageAsset.isEmpty && tile.emoji.isEmpty;

  void _ensureTileCapacity(int count) {
    if (!board.adjustableLayout) {
      final target = board.rows * board.columns;
      if (board.tiles.length < target) {
        board.tiles.addAll(List.generate(
          target - board.tiles.length,
          (i) => _blankTile(board.tiles.length + i),
        ));
      } else if (board.tiles.length > target) {
        // User said: "show all rows and columns regardless of if they are populated"
        // But if they shrink it manually we should respect that.
        // This method is mainly to ensure we have ENOUGH slots.
      }
      return;
    }
    // Trim trailing blank tiles so we don't keep multiple empty placeholders.
    while (board.tiles.isNotEmpty && _isBlankTile(board.tiles.last)) {
      board.tiles.removeLast();
    }
    // Ensure exactly one trailing empty tile for adding new content.
    if (board.tiles.isEmpty || !_isBlankTile(board.tiles.last)) {
      board.tiles.add(_blankTile(board.tiles.length));
    }
  }

  SymbolTile _blankTile(int index) {
    return SymbolTile(
      id: 'tile_$index',
      label: '',
      category: 'Custom',
      imageAsset: '',
      emoji: '',
      bgColor: 'transparent',
      textColor: '#000000',
      tileSize: 1.0,
      colSpan: 1,
      rowSpan: 1,
    );
  }

  SymbolTile _tileFromWord(String word) {
    final lowerWord = word.trim().toLowerCase();
    return SymbolTile(
      id: 'tile_${DateTime.now().microsecondsSinceEpoch}_${lowerWord.hashCode}',
      label: lowerWord,
      category: 'Custom',
      imageAsset: _findAssetForWordSync(lowerWord),
      emoji: '',
      bgColor: 'transparent',
      textColor: '#000000',
    );
  }

  String _findAssetForWordSync(String word) {
    final assetPaths = [
      'assets/symbols/1. Main Boards/$word.png',
      'assets/symbols/$word.png',
    ];
    for (final path in assetPaths) {
      return path;
    }
    return '';
  }

  Future<SymbolTile> _tileFromWordWithSymbol(String word) async {
    final tile = _tileFromWord(word);
    final assetPath = await _findAssetForWord(word);
    if (assetPath.isNotEmpty) {
      tile.imageAsset = assetPath;
      return tile;
    }
    final symbols = await _externalSymbolService.searchAll(word, limit: 1);
    if (symbols.isNotEmpty) {
      tile.imageAsset = symbols.first.imageUrl;
    } else {
      tile.imageAsset = _placeholderImage;
    }
    return tile;
  }

  Future<String> _findAssetForWord(String word) async {
    if (word.trim().isEmpty) return '';
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetList = manifest.listAssets();
      final normalized = word.trim().toLowerCase();
      final slug = normalized.replaceAll(' ', '-');
      final slugUnderscore = normalized.replaceAll(' ', '_');
      final alphanumeric = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'];
      for (final assetPath in assetList) {
        if (!assetPath.startsWith('assets/')) continue;
        final ext = assetPath.toLowerCase();
        if (!imageExtensions.any((e) => ext.endsWith(e))) continue;
        final basename = assetPath.split('/').last.toLowerCase();
        final nameWithoutExt = basename.replaceAll(RegExp(r'\.(png|jpg|jpeg|gif|webp|svg)$'), '');
        final assetAlphanumeric = nameWithoutExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (nameWithoutExt == normalized || nameWithoutExt == slug || nameWithoutExt == slugUnderscore || assetAlphanumeric == alphanumeric) return assetPath;
      }
    } catch (e) {
      debugPrint('Error finding asset for word "$word": $e');
    }
    return '';
  }

  Future<void> _exportBoardScreenshot(String format) async {
    try {
      final resolvedFormat = format.isEmpty ? await _pickExportFormat() : format;
      if (resolvedFormat == null || resolvedFormat.isEmpty) return;

      final fileName = BoardExportUtils.buildExportFileName(board.name, resolvedFormat);
      final bytes = await _captureBoardScreenshot(resolvedFormat);
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to capture the board screenshot.')));
        return;
      }

      if (kIsWeb) {
        await downloadBoardExportBytes(bytes, fileName, BoardExportUtils.mimeTypeForFormat(resolvedFormat));
      } else {
        final selectedDir = await FilePicker.getDirectoryPath(dialogTitle: 'Choose where to save $fileName');
        if (selectedDir == null || selectedDir.isEmpty) return;
        final file = File(p.join(selectedDir, fileName));
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved screenshot to ${file.path}')));
      }
    } catch (e) {
      debugPrint('Error exporting board screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export board screenshot: $e')));
      }
    }
  }

  Future<String?> _pickExportFormat() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Board Screenshot'),
        content: const Text('Choose a file format for this board screenshot.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('png'), child: const Text('PNG')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('jpg'), child: const Text('JPG')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('pdf'), child: const Text('PDF')),
        ],
      ),
    );
  }

  Future<List<int>?> _captureBoardScreenshot(String format) async {
    final renderRepaintBoundary = await _captureBoardWidgetAsImage(format);
    if (renderRepaintBoundary == null) return null;
    return renderRepaintBoundary;
  }

  Future<List<int>?> _captureBoardWidgetAsImage(String format) async {
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
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(Icons.dashboard, size: 32),
                          ),
                          Text(
                            board.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SymbolGrid(
                        symbols: board.tiles,
                        favoriteIds: const {},
                        onTap: (_) {},
                        onLongPress: (_) {},
                        fixedRows: board.rows,
                        fixedColumns: board.columns,
                        adjustableLayout: board.adjustableLayout,
                        boxScale: board.boxScale,
                        highContrast: false,
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

      final repaintBoundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (repaintBoundary == null) {
        entry.remove();
        return null;
      }
      final image = await repaintBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      entry.remove();
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Board screenshot capture failed: $e');
      return null;
    }
  }

  void _showTileMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit tile'),
              onTap: () {
                Navigator.of(ctx).pop();
                editTile(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Auto find picture - guess'),
              onTap: () {
                Navigator.of(ctx).pop();
                _autoFindTileImage(index, chooseFromOptions: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Auto find picture - choose from options'),
              onTap: () {
                Navigator.of(ctx).pop();
                _autoFindTileImage(index, chooseFromOptions: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Merge with empty tile'),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _mergeSourceIndex = index;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tap an adjacent empty tile to merge.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete tile'),
              onTap: () async {
                Navigator.of(ctx).pop();
                setState(() {
                  board.tiles[index] = _blankTile(index);
                });
                final service = await BoardService.getInstance();
                await service.saveBoard(board);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<SymbolTile> _tileFromFile(File file,
      {bool fullScreen = false, required String boardId}) async {
    final label = _labelFromPath(file.path);
    final persistedPath = await _persistImportedImage(file, boardId: boardId);
    return SymbolTile(
      id: 'tile_${DateTime.now().microsecondsSinceEpoch}_${label.hashCode}',
      label: label,
      category: 'Custom',
      imageAsset: persistedPath.isNotEmpty ? _convertToAssetPath(persistedPath) : '',
      emoji: '',
      bgColor: fullScreen ? '#FFCDD2' : 'transparent',
      textColor: '#000000',
      isFullScreenImage: fullScreen,
    );
  }

  Future<SymbolTile> _tileFromPlatformFile(PlatformFile file,
      {bool fullScreen = false,
      required String boardId,
      bool skipOnlineSearch = false}) async {
    final sourceName = file.name.isNotEmpty ? file.name : (file.path ?? '');
    final label = _labelFromPath(sourceName);
    var imagePath = '';
    if (kIsWeb) {
      if (file.name.isNotEmpty && file.bytes != null) {
        _mirrorImageToProject(file.name, file.bytes!);
        imagePath = 'data:image/png;base64,${base64Encode(file.bytes!)}';
      }
    } else {
      if (file.path != null && file.path!.isNotEmpty) {
        imagePath = file.path!;
      } else if (file.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.bytes!);
        imagePath = tempFile.path;
      }
    }
    String persistedPath = '';
    if (imagePath.isNotEmpty) {
      if (!kIsWeb) {
        final localFile = File(imagePath);
        if (await localFile.exists()) {
          persistedPath = await _persistImportedImage(localFile, boardId: boardId);
        } else {
          persistedPath = imagePath;
        }
      } else {
        persistedPath = imagePath;
      }
    }
    return SymbolTile(
      id: 'tile_${DateTime.now().microsecondsSinceEpoch}_${label.hashCode}',
      label: label,
      category: 'Custom',
      imageAsset: persistedPath.isNotEmpty ? _convertToAssetPath(persistedPath) : '',
      emoji: '',
      bgColor: fullScreen ? '#FFCDD2' : 'transparent',
      textColor: '#000000',
      isFullScreenImage: fullScreen,
    );
  }

  Future<String> _persistImportedImage(File sourceFile,
      {required String boardId}) async {
    final sourcePath = sourceFile.path.replaceAll('\\', '/');
    if (sourcePath.startsWith('assets/') ||
        sourcePath.startsWith('http://') ||
        sourcePath.startsWith('https://') ||
        sourcePath.startsWith('blob:') ||
        sourcePath.startsWith('data:')) {
      return sourcePath;
    }
    if (!await sourceFile.exists()) return sourcePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${appDir.path}/custom_tiles/$boardId');
      await storageDir.create(recursive: true);
      final originalName = sourceFile.uri.pathSegments.isNotEmpty
          ? sourceFile.uri.pathSegments.last
          : 'image';
      final safeName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
      final destination = File('${storageDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName');
      await sourceFile.copy(destination.path);
      return destination.path;
    } catch (e) {
      debugPrint('Error persisting imported image: $e');
      return sourcePath;
    }
  }

  Future<String> _persistVoiceFile(String sourcePath,
      {required String boardId}) async {
    final normalized = sourcePath.replaceAll('\\', '/');
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:') ||
        normalized.contains('/custom_tiles/')) {
      return sourcePath;
    }
    if (kIsWeb && normalized.startsWith('blob:')) {
      try {
        final bytes = await XFile(normalized).readAsBytes();
        final lower = sourcePath.toLowerCase();
        final mime = lower.endsWith('.wav') ? 'audio/wav' : 'audio/webm';
        return 'data:$mime;base64,${base64Encode(bytes)}';
      } catch (e) {
        debugPrint('Error converting blob voice to data URL: $e');
      }
      return sourcePath;
    }
    if (normalized.startsWith('assets/')) {
      return sourcePath;
    }
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return sourcePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${appDir.path}/custom_tiles/$boardId/voices');
      await storageDir.create(recursive: true);
      final lower = sourcePath.toLowerCase();
      final ext = lower.endsWith('.wav') ? '.wav' : (lower.endsWith('.m4a') ? '.m4a' : '.aac');
      final destination = File('${storageDir.path}/voice_${DateTime.now().microsecondsSinceEpoch}$ext');
      await sourceFile.copy(destination.path);
      return destination.path;
    } catch (e) {
      debugPrint('Error persisting voice file: $e');
      return sourcePath;
    }
  }

  Future<String?> _mirrorImageToProject(String filename, List<int> bytes) async {
    try {
      final uri = Uri.parse('http://localhost:8787/saveImage');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'filename': filename,
          'data': base64Encode(bytes),
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['path'] as String?;
      }
    } catch (e) {
      debugPrint('Error mirroring image to project: $e');
    }
    return null;
  }

  String _convertToAssetPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final hasDrive = normalized.contains(':');
    final isRelative = !hasDrive && !normalized.startsWith('/');
    if (isRelative) {
      if (normalized.startsWith('assets/')) return normalized;
      if (kIsWeb && !normalized.startsWith('http') && !normalized.startsWith('blob:') && !normalized.startsWith('data:')) {
        if (normalized.startsWith('symbols/')) return 'assets/$normalized';
        if (!normalized.startsWith('assets/')) return 'assets/symbols/Custom/$normalized';
      }
    }
    return normalized;
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.webp') || lower.endsWith('.svg');
  }

  String _labelFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final filename = normalized.split('/').last;
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    return base.replaceAll(RegExp(r'[_-]+'), ' ').trim().toLowerCase();
  }

  List<String> get _allColorOptions {
    final combined = <String>{'transparent', ..._colorOptions, ..._dynamicColorOptions};
    final sorted = combined.toList();
    sorted.sort((a, b) {
      if (a == 'transparent') return -1;
      if (b == 'transparent') return 1;
      if (a == '#000000') return -1;
      if (b == '#000000') return 1;
      if (a == '#FFFFFF') return -1;
      if (b == '#FFFFFF') return 1;
      final colorA = _colorFromHex(a);
      final colorB = _colorFromHex(b);
      final hslA = HSLColor.fromColor(colorA);
      final hslB = HSLColor.fromColor(colorB);
      final bool isNeutralA = hslA.saturation < 0.15;
      final bool isNeutralB = hslB.saturation < 0.15;
      if (isNeutralA && !isNeutralB) return -1;
      if (!isNeutralA && isNeutralB) return 1;
      if (isNeutralA && isNeutralB) return hslB.lightness.compareTo(hslA.lightness);
      if ((hslA.hue - hslB.hue).abs() > 2) return hslA.hue.compareTo(hslB.hue);
      return hslB.lightness.compareTo(hslA.lightness);
    });
    return sorted;
  }

  void _showColorPickerDialog(TextEditingController controller, StateSetter setDialogState) {
    Color pickerColor = _colorFromHex(controller.text, Colors.blue);
    final TextEditingController hexInputController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                  hexInputController.text = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
                },
                pickerAreaHeightPercent: 0.8,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hexInputController,
                decoration: const InputDecoration(labelText: 'Color Hex (#RRGGBB)', prefixText: '#'),
                onChanged: (value) {
                  final hex = value.startsWith('#') ? value : '#$value';
                  if (hex.length == 7 || hex.length == 9) {
                    final newColor = _colorFromHex(hex);
                    if (newColor != Colors.transparent || hex.toLowerCase() == 'transparent') {
                      setDialogState(() => pickerColor = newColor);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final hex = hexInputController.text.toUpperCase();
              if (!_allColorOptions.contains(hex)) {
                setState(() => _dynamicColorOptions.add(hex));
                _saveCustomColors();
              }
              setDialogState(() => controller.text = hex);
              Navigator.of(ctx).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(TextEditingController controller, StateSetter setDialogState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._allColorOptions.map((colorHex) {
          final color = _colorFromHex(colorHex, colorHex == 'transparent' ? Colors.transparent : Colors.white);
          final selected = controller.text.toUpperCase() == colorHex;
          return GestureDetector(
            onTap: () => setDialogState(() => controller.text = colorHex),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: selected ? Colors.black : Colors.grey, width: selected ? 2 : 1),
              ),
              child: colorHex == 'transparent' ? const Center(child: Icon(Icons.close, size: 16, color: Colors.grey)) : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showColorPickerDialog(controller, setDialogState),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey, width: 1)),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ],
    );
  }

  void editTile(int index) async {
    if (_availableBoards.isEmpty) await _loadAvailableBoards();
    if (!mounted) return;
    final tile = board.tiles[index];
    final bool wasBlank = tile.label.isEmpty && tile.imageAsset.isEmpty;
    final labelCtl = TextEditingController(text: tile.label);
    final bgCtl = TextEditingController(text: _normalizeColor(tile.bgColor));
    final txtCtl = TextEditingController(text: _normalizeColor(tile.textColor, emptyDefault: '#000000'));
    final sizeCtl = TextEditingController(text: tile.tileSize.toString());
    final colSpanCtl = TextEditingController(text: tile.colSpan.toString());
    final rowSpanCtl = TextEditingController(text: tile.rowSpan.toString());
    var isBoardLink = tile.isBoardLink;
    var isFullScreenImage = tile.isFullScreenImage;
    var linkedBoardId = tile.linkedBoardId;
    String tileType = isBoardLink ? 'link_to_board' : (isFullScreenImage ? 'open_picture' : 'normal_word');
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool imageExplicitlyRemoved = false;
          bool imageUpdated = false;
          return AlertDialog(
            title: const Text('Edit Tile'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelCtl, 
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Label'), 
                      onChanged: (_) => setDialogState(() {})
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tile type'),
                      initialValue: tileType,
                      items: const [
                        DropdownMenuItem(value: 'normal_word', child: Text('Normal word')),
                        DropdownMenuItem(value: 'link_to_board', child: Text('Link to board')),
                        DropdownMenuItem(value: 'open_picture', child: Text('Open picture in full screen')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          tileType = v;
                          isBoardLink = v == 'link_to_board';
                          isFullScreenImage = v == 'open_picture';
                          if (!isBoardLink) linkedBoardId = '';
                          if (v == 'link_to_board') {
                            labelCtl.text = _toTitleCase(labelCtl.text);
                          } else if (v == 'normal_word') {
                            labelCtl.text = labelCtl.text.toLowerCase();
                          }
                        });
                      },
                    ),
                    if (isBoardLink) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDialog<String?>(
                            context: context,
                            builder: (ctx) => _BoardSelectionDialog(boards: _availableBoards, initialSelectedId: linkedBoardId, initialQuery: labelCtl.text.trim(), title: 'Select Destination Board'),
                          );
                          if (selected == 'CREATE_NEW') {
                            final newId = await _createNewBoardFromDialog();
                            if (newId != null) setDialogState(() { linkedBoardId = newId; if (labelCtl.text.trim().isEmpty) labelCtl.text = _boardNameForId(newId) ?? ''; });
                          } else if (selected != 'DIALOG_DISMISSED') {
                            setDialogState(() { linkedBoardId = (selected == 'NONE' ? '' : selected) ?? ''; final boardName = _boardNameForId(linkedBoardId); if (boardName != null && labelCtl.text.trim().isEmpty) labelCtl.text = boardName; });
                          }
                        },
                        icon: const Icon(Icons.link_rounded),
                        label: Text(linkedBoardId.isEmpty ? 'Select Destination Board' : 'Linked to: ${_boardNameForId(linkedBoardId)}'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
                      ),
                    ],
                    if (_mergeTilesEnabled) ...[
                      const SizedBox(height: 12),
                      const Text('Merge Tiles (Specialist)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(controller: colSpanCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width (Columns)', hintText: '1', border: OutlineInputBorder()), onChanged: (v) => setDialogState(() {}))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: rowSpanCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (Rows)', hintText: '1', border: OutlineInputBorder()), onChanged: (v) => setDialogState(() {}))),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    const Text('Background color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildColorRow(bgCtl, setDialogState),
                    const SizedBox(height: 8),
                    TextField(controller: bgCtl, decoration: const InputDecoration(labelText: 'Background (#RRGGBB)'), onChanged: (_) => setDialogState(() {})),
                    const SizedBox(height: 16),
                    const Text('Text color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildColorRow(txtCtl, setDialogState),
                    const SizedBox(height: 8),
                    TextField(controller: txtCtl, decoration: const InputDecoration(labelText: 'Text color (#RRGGBB)'), onChanged: (_) => setDialogState(() {})),
                    const SizedBox(height: 16),
                    TextField(controller: sizeCtl, decoration: const InputDecoration(labelText: 'Size (1.0)')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () async {
                        final SymbolTile? selected = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExternalSymbolSearchScreen(onAdd: (s) {}, initialLabel: labelCtl.text.trim(), preferredSets: _activeProfile?.preferredSymbolSets)));
                        if (selected != null) {
                          final resolvedAsset = await _resolveExternalImageAsset(selected.imageAsset, label: selected.label);
                          setDialogState(() {
                            imageUpdated = true;
                            if (labelCtl.text.trim().isEmpty) labelCtl.text = selected.label.toLowerCase();
                            tile.label = labelCtl.text.toLowerCase();
                            tile.imageAsset = resolvedAsset;
                            tile.category = selected.category;
                          });
                          final service = await BoardService.getInstance();
                          await service.saveBoard(board);
                        }
                      }, icon: const Icon(Icons.search, size: 16), label: const Text('Online Search', overflow: TextOverflow.ellipsis))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: () async {
                        try {
                          final picker = ImagePicker();
                          final res = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (res != null) {
                            String imagePath = res.path;
                            
                            // Requirement: If the user uploads an image that already exists in our Assets Library, 
                            // the app should use the existing Image.
                            final existingAsset = await _externalSymbolService.findExistingAssetByFilename(res.name);
                            if (existingAsset != null) {
                              imagePath = existingAsset;
                            } else {
                              if (kIsWeb) {
                                final bytes = await res.readAsBytes();
                                final savedPath = await _mirrorImageToProject(res.name, bytes);
                                imagePath = savedPath ?? 'data:image/png;base64,${base64Encode(bytes)}';
                              } else if (imagePath.isNotEmpty) {
                                imagePath = await _persistImportedImage(File(imagePath), boardId: board.id);
                              }
                            }
                            setDialogState(() { imageUpdated = true; tile.imageAsset = imagePath; isBoardLink = false; linkedBoardId = ''; if (labelCtl.text.trim().isEmpty) labelCtl.text = _labelFromPath(res.name); });
                          }
                        } catch (e) { debugPrint('Error picking image: $e'); }
                      }, child: const Text('Upload Image'))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: () async {
                        try {
                          final picker = ImagePicker();
                          final res = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                          if (res != null) {
                            String imagePath = res.path;
                            
                            // Requirement: If the user uploads an image that already exists in our Assets Library, 
                            // the app should use the existing Image.
                            final existingAsset = await _externalSymbolService.findExistingAssetByFilename(res.name);
                            if (existingAsset != null) {
                              imagePath = existingAsset;
                            } else {
                              if (kIsWeb) {
                                final bytes = await res.readAsBytes();
                                final savedPath = await _mirrorImageToProject(res.name, bytes);
                                imagePath = savedPath ?? 'data:image/png;base64,${base64Encode(bytes)}';
                              } else if (imagePath.isNotEmpty) {
                                imagePath = await _persistImportedImage(File(imagePath), boardId: board.id);
                              }
                            }
                            setDialogState(() { imageUpdated = true; tile.imageAsset = imagePath; isBoardLink = false; linkedBoardId = ''; if (labelCtl.text.trim().isEmpty) labelCtl.text = _labelFromPath(res.name); });
                          }
                        } catch (e) { debugPrint('Error taking photo: $e'); }
                      }, child: const Text('Take Photo'))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: tile.imageAsset.isNotEmpty ? () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenImageView(imagePath: tile.imageAsset))); } : null, icon: const Icon(Icons.fullscreen, size: 16), label: const Text('View Full Image', overflow: TextOverflow.ellipsis))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton.icon(onPressed: () async { _showRecordDialog(tile, setDialogState); }, icon: const Icon(Icons.mic, size: 16), label: const Text('Record', overflow: TextOverflow.ellipsis))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: () { setDialogState(() { tile.imageAsset = ''; imageExplicitlyRemoved = true; imageUpdated = true; }); }, style: ElevatedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Remove current image'))),
                    ]),
                    const SizedBox(height: 12),
                    Center(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Live Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(width: 120.0 * (double.tryParse(colSpanCtl.text) ?? 1.0).clamp(1.0, 3.0), height: 120.0 * (double.tryParse(rowSpanCtl.text) ?? 1.0).clamp(1.0, 3.0), child: Material(elevation: 4, shadowColor: Colors.black26, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias, color: _colorFromHex(bgCtl.text, Colors.transparent), child: _buildTileContent(SymbolTile(id: 'preview', label: labelCtl.text, category: tile.category, imageAsset: tile.imageAsset, emoji: tile.emoji, isBoardLink: isBoardLink, isFullScreenImage: isFullScreenImage, linkedBoardId: linkedBoardId, tileSize: double.tryParse(sizeCtl.text) ?? 1.0, colSpan: int.tryParse(colSpanCtl.text) ?? 1, rowSpan: int.tryParse(rowSpanCtl.text) ?? 1, bgColor: bgCtl.text, textColor: txtCtl.text), _colorFromHex(bgCtl.text, Colors.transparent), _colorFromHex(txtCtl.text, Colors.black)))),
                    ]))),
                    const SizedBox(height: 12),
                    if (tile.customVoice.isNotEmpty) Row(children: [ Expanded(child: ElevatedButton.icon(onPressed: () async { final player = AudioPlayer(); await player.play(DeviceFileSource(tile.customVoice)); }, icon: const Icon(Icons.play_arrow), label: const Text('Play Recording'))), const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: () { setDialogState(() { tile.customVoice = ''; }); }, icon: const Icon(Icons.delete), label: const Text('Delete')))]) else const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () { setState(() { board.tiles[index] = _blankTile(index); }); Navigator.of(ctx).pop(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () async {
                final newLabel = labelCtl.text.trim();
                var newImageAsset = tile.imageAsset;
                if (wasBlank && newLabel.isNotEmpty && newImageAsset.isEmpty && !imageExplicitlyRemoved && !imageUpdated) {
                  final autoTile = await _tileFromWordWithSymbol(newLabel);
                  newImageAsset = autoTile.imageAsset;
                }
                if (kIsWeb && newImageAsset.startsWith('blob:') && ExternalSymbolService.getPersistentPath(newImageAsset) == null) newImageAsset = '';
                final newRowSpan = int.tryParse(rowSpanCtl.text) ?? 1;
                setState(() {
                  tile.label = newLabel;
                  tile.imageAsset = newImageAsset;
                  tile.bgColor = _normalizeColor(bgCtl.text);
                  tile.textColor = _normalizeColor(txtCtl.text, emptyDefault: '#000000');
                  tile.tileSize = double.tryParse(sizeCtl.text) ?? 1.0;
                  tile.colSpan = int.tryParse(colSpanCtl.text) ?? 1;
                  tile.rowSpan = newRowSpan;
                  tile.isBoardLink = isBoardLink;
                  tile.isFullScreenImage = isFullScreenImage;
                  tile.linkedBoardId = linkedBoardId;
                  if (isBoardLink) { tile.bgColor = '#000000'; tile.textColor = '#FFFFFF'; }
                  else if (isFullScreenImage) { tile.bgColor = '#FFCDD2'; tile.textColor = '#000000'; }

                  // Requirement: if a tile is resized to be taller, make all tiles on that row be resized to that same size too.
                  // We synchronize rowSpan for the entire row to maintain a consistent grid height.
                  if (board.columns > 0) {
                    final rowIndex = index ~/ board.columns;
                    final startOfRow = rowIndex * board.columns;
                    final endOfRow = (rowIndex + 1) * board.columns;
                    for (int i = startOfRow; i < endOfRow; i++) {
                      if (i < board.tiles.length) {
                        board.tiles[i].rowSpan = newRowSpan;
                      }
                    }
                  }
                });
                final service = await BoardService.getInstance();
                await service.saveBoard(board);
                if (mounted) Navigator.of(ctx).pop();
                setState(() => _ensureTileCapacity(board.tiles.length));
              }, child: const Text('Save')),
            ],
          );
        },
      ),
    );
  }

  Future<String> _resolveExternalImageAsset(String imageUrl, {String? label}) async {
    if (imageUrl.isEmpty) return '';
    final shouldPersist = (_activeProfile?.id == 'admin' || _activeProfile?.id == 'default');
    if (!shouldPersist || imageUrl.startsWith('assets/') || imageUrl.startsWith('blob:') || imageUrl.startsWith('data:')) {
      return imageUrl;
    }

    try {
      final filename = '${(label ?? 'external').replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_').trim()}_${DateTime.now().microsecondsSinceEpoch}${_extensionFromUrl(imageUrl)}';
      final imageBytes = (await http.get(Uri.parse(imageUrl))).bodyBytes;
      
      // Mirror to project for backup, but always return a path symbol_grid can load.
      // Asset paths from runtime saves aren't in the Flutter asset bundle, so
      // we must return a network URL (native) or base64 data URI (web) instead.
      if (kIsWeb && Uri.base.host == 'localhost') {
        await _mirrorImageToProject(filename, imageBytes);
      }

      if (kIsWeb) {
        return 'data:image/png;base64,${base64Encode(imageBytes)}';
      }
      await _mirrorImageToProject(filename, imageBytes);
    } catch (e) {
      debugPrint('Unable to persist external image for admin/default profile: $e');
    }
    return imageUrl;
  }

  String _extensionFromUrl(String url) {
    final clean = url.split('?').first;
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex <= 0) return '.png';
    return clean.substring(dotIndex);
  }

  Future<void> _showRecordDialog(SymbolTile tile, StateSetter setDialogState) async {
    final recordedPath = await showDialog<String>(
      context: context,
      builder: (ctx) => _RecordDialog(
        initialPath: tile.customVoice,
        onPathChanged: (_) {},
      ),
    );
    if (recordedPath != null) {
      if (recordedPath.isEmpty) {
        setDialogState(() => tile.customVoice = '');
      } else {
        final persistentPath = await _persistVoiceFile(recordedPath, boardId: board.id);
        setDialogState(() => tile.customVoice = persistentPath);
      }
    }
  }

  String? _boardNameForId(String id) {
    for (final b in _availableBoards) {
      if (b.id == id) {
        return b.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final boardBg = board.backgroundColor == 'transparent' ? Colors.transparent : _colorFromHex(board.backgroundColor, Colors.transparent);
    return Container(
      color: boardBg,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Board name'), onChanged: (v) => board.name = v)),
              const SizedBox(width: 8),
              SizedBox(width: 160, child: DropdownButtonFormField<String>(key: ValueKey('area-${board.area}'), initialValue: board.area, decoration: const InputDecoration(labelText: 'Area'), isExpanded: true, items: const [DropdownMenuItem(value: 'Common', child: Text('Common')), DropdownMenuItem(value: 'Subject Vocab', child: Text('Subject Vocab')), DropdownMenuItem(value: 'My School', child: Text('My School')), DropdownMenuItem(value: 'Sign', child: Text('Sign')), DropdownMenuItem(value: 'Personal', child: Text('Personal'))], onChanged: (value) { if (value != null) setState(() => board.area = value); })),
            ]),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                PopupMenuButton<String>(tooltip: 'Populate board', onSelected: (value) {
                  if (value == 'pictures') { importPictureFolder(fullScreen: false); }
                  else if (value == 'pictures_full') { importPictureFolder(fullScreen: true); }
                  else if (value == 'words') { _populateFromWordList(); }
                  else if (value == 'ai') { _populateWithAi(); }
                  else if (value == 'screenshot') { _createFromImage(); }
                  else if (value == 'import_json') { _importBoardFromJson(); }
                }, itemBuilder: (context) => const [PopupMenuItem(value: 'pictures', child: Text('Picture Folder')), PopupMenuItem(value: 'pictures_full', child: Text('Picture Folder (View full size)')), PopupMenuItem(value: 'words', child: Text('Word List')), PopupMenuItem(value: 'ai', child: Text('AI Fill')), PopupMenuItem(value: 'screenshot', child: Text('Create From Image')), PopupMenuItem(value: 'import_json', child: Text('Import JSON'))], child: IgnorePointer(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome), label: const Text('Populate')))),
                ElevatedButton.icon(onPressed: _alphabetiseTiles, icon: const Icon(Icons.sort_by_alpha), label: const Text('Alphabetise')),
                ElevatedButton.icon(onPressed: _isPopulating ? null : _fillPictures, icon: _isPopulating ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image_search), label: const Text('Fill Pics')),
                ElevatedButton.icon(onPressed: () => _shareToArchive(), icon: const Icon(Icons.share), label: const Text('Share to Archive')),
                ElevatedButton.icon(onPressed: () async {
                  final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Start Again'), content: const Text('This will erase all words currently on this board. Are you sure?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm'))]));
                  if (confirmed == true) {
                    setState(() {
                      _mergeTilesEnabled = false;
                      board.tiles.clear();
                      _ensureTileCapacity(0);
                    });
                    final service = await BoardService.getInstance();
                    await service.saveBoard(board);
                  }
                }, icon: const Icon(Icons.refresh), label: const Text('Start Again')),
                ElevatedButton.icon(onPressed: () async {
                  final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Board'), content: const Text('Are you sure you want to permanently delete this board? This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete'))]));
                  if (confirmed == true) { final service = await BoardService.getInstance(); await service.deleteBoard(board.id); if (!context.mounted) return; Navigator.of(context).pop(); }
                }, icon: const Icon(Icons.delete, color: Colors.white), label: const Text('Delete Board'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaving ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          debugPrint('Save Board button clicked');
                          setState(() => _isSaving = true);
                          try {
                            board.name = _nameController.text;
                            final rows = int.tryParse(_rowsController.text) ?? board.rows;
                            final cols = int.tryParse(_columnsController.text) ?? board.columns;
                            if (rows != board.rows || cols != board.columns) _resizeBoard(rows, cols);
                            
                            // 5s timeout to prevent being stuck forever if something hangs
                            await widget.onSave(board).timeout(
                                  const Duration(seconds: 5),
                                  onTimeout: () => debugPrint('Save timed out'),
                                );
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Board'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(margin: EdgeInsets.zero, color: Colors.transparent, elevation: 0, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Board layout', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Adjustable layout'), subtitle: const Text('Reflows tiles when the device rotates or the window changes size.'), value: board.adjustableLayout, onChanged: (v) {
                setState(() {
                  board.adjustableLayout = v;
                  _ensureTileCapacity(board.tiles.length);
                });
              }),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Board Hierarchy Tier',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: board.tier,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Main board (Tier 1)')),
                  DropdownMenuItem(value: 2, child: Text('Sub-board (Tier 2)')),
                  DropdownMenuItem(value: 3, child: Text('Tertiary board (Tier 3)')),
                  DropdownMenuItem(value: 4, child: Text('Quaternary board (Tier 4)')),
                  DropdownMenuItem(value: 5, child: Text('Quinary board (Tier 5)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      board.tier = v;
                      // Keep legacy flags in sync for compatibility
                      board.isSubBoard = v > 1;
                      board.isTertiaryBoard = v > 2;
                      board.isQuaternaryBoard = v > 3;
                      board.isQuinaryBoard = v > 4;
                    });
                  }
                },
              ),
              if (board.tier > 1) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () async {
                  final selected = await showDialog<String?>(context: context, builder: (ctx) => _BoardSelectionDialog(boards: _availableBoards, initialSelectedId: board.parentBoardId, title: 'Select Parent Board'));
                  if (selected != 'DIALOG_DISMISSED') setState(() => board.parentBoardId = (selected == 'NONE' ? null : selected));
                }, icon: const Icon(Icons.account_tree_outlined), label: Text(board.parentBoardId == null || board.parentBoardId!.isEmpty ? 'Set Parent board (tab placement)' : 'Parent: ${_boardNameForId(board.parentBoardId!)}'), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft)),
              ],
              const Divider(),
              const Text('Convert all tiles to:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), hint: const Text('Select tile type'), items: const [DropdownMenuItem(value: 'normal_word', child: Text('Normal word')), DropdownMenuItem(value: 'link_to_board', child: Text('Link to board')), DropdownMenuItem(value: 'open_picture', child: Text('Open picture in full screen'))], onChanged: (v) { if (v != null) _convertAllTiles(v); }),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(enabled: !board.adjustableLayout, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rows'), controller: _rowsController, onSubmitted: (_) => _applySizeChange(), onChanged: (value) {
                  _resizeTimer?.cancel();
                  _resizeTimer = Timer(const Duration(seconds: 10), _applySizeChange);
                })),
                const SizedBox(width: 12),
                Expanded(child: TextField(enabled: !board.adjustableLayout, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Columns'), controller: _columnsController, onSubmitted: (_) => _applySizeChange(), onChanged: (value) {
                  _resizeTimer?.cancel();
                  _resizeTimer = Timer(const Duration(seconds: 10), _applySizeChange);
                })),
              ]),
            ]))),
            const SizedBox(height: 12),
            if (_isPopulating) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(children: [LinearProgressIndicator(value: _populateProgress), const SizedBox(height: 4), Text('Processing... ${(_populateProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12))])),
            LayoutBuilder(builder: (context, constraints) {
              final layout = _editorGridLayoutFor(constraints);
              return RepaintBoundary(
                key: _boardScreenshotKey,
                child: DropTarget(onDragDone: (details) async {
                if (kIsWeb) return;
                for (final file in details.files) {
                  final path = file.path.replaceAll('\x00', '').trim();
                  if (path.isNotEmpty && _isImagePath(path)) {
                    final emptyIndex = board.tiles.indexWhere((tile) => tile.label.isEmpty && tile.imageAsset.isEmpty && tile.emoji.isEmpty);
                    if (emptyIndex != -1) {
                      final fileName = path.split(Platform.pathSeparator).last.replaceAll('\x00', '').trim();
                      final label = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
                      String tileImage = '';
                      if (kIsWeb) {
                        final bytes = await file.readAsBytes();
                        tileImage = 'data:image/png;base64,${base64Encode(bytes)}';
                      } else {
                        final persisted = await _persistImportedImage(File(path), boardId: board.id);
                        tileImage = persisted.isNotEmpty ? _convertToAssetPath(persisted) : '';
                      }
                      setState(() { board.tiles[emptyIndex] = SymbolTile(id: 'tile_$emptyIndex', label: label, category: 'Custom', imageAsset: tileImage, bgColor: 'transparent', textColor: '#000000', tileSize: 1.0); _ensureTileCapacity(board.tiles.length); });
                      final service = await BoardService.getInstance(); await service.saveBoard(board);
                    }
                  }
                }
              }, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: SingleChildScrollView(child: (() {
                final coveredCells = _computeCoveredCells(board.tiles, layout.columns);
                final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
                final columns = layout.columns;
                final spacing = 10.0;
                final childWidth = (maxWidth - (columns + 1) * spacing) / columns;
                final numRows = (board.tiles.length / columns).ceil();
                final List<Widget> positionedTiles = [];
                for (int r = 0; r < numRows; r++) {
                  for (int c = 0; c < columns; c++) {
                  final index = r * columns + c;
                  if (index >= board.tiles.length || coveredCells.contains(index)) continue;
                  final t = board.tiles[index];
                  final isBlank = t.label.isEmpty && t.imageAsset.isEmpty && t.emoji.isEmpty;
                  Color bg = t.bgColor == 'transparent' ? Colors.transparent : _colorFromHex(t.bgColor, Colors.transparent);
                  Color txt = t.textColor == 'transparent' ? Colors.transparent : _colorFromHex(t.textColor, Colors.black);
                  final tileWidth = childWidth * t.colSpan + spacing * (t.colSpan - 1);
                  final tileHeight = childWidth * t.rowSpan + spacing * (t.rowSpan - 1);
                   final tileChild = GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {
                      if (_mergeSourceIndex != null) {
                        _handleMergeClick(_mergeSourceIndex!, index);
                      } else {
                        editTile(index);
                      }
                    }, child: Container(width: tileWidth, height: tileHeight, decoration: (_mergeSourceIndex == index) ? BoxDecoration(border: Border.all(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(16)) : null, child: Stack(children: [_buildTileContent(t, bg, txt), if (!isBlank) Positioned(top: 0, right: 0, child: IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () => _showTileMenu(index)))])));
                    final feedback = Material(elevation: 8, borderRadius: BorderRadius.circular(16), child: SizedBox(width: tileWidth, height: tileHeight, child: _buildTileContent(t, bg, txt)));
                    final childWhenDragging = Opacity(opacity: 0.3, child: SizedBox(width: tileWidth, height: tileHeight, child: _buildTileContent(t, bg, txt)));
                    final bool isDesktop = (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
                    final tileWidget = DragTarget<int>(onWillAcceptWithDetails: (details) => details.data != index, onAcceptWithDetails: (details) async {
                      final draggedIndex = details.data;
                      if (draggedIndex != index) { setState(() { final draggedTile = board.tiles[draggedIndex]; board.tiles[draggedIndex] = board.tiles[index]; board.tiles[index] = draggedTile; }); try { final service = await BoardService.getInstance(); await service.saveBoard(board); } catch (e) { debugPrint('Error saving board after swap: $e'); } }
                    }, builder: (context, candidateData, rejectedData) {
                      final active = candidateData.isNotEmpty;
                      final wrapped = active ? Container(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).primaryColor, width: 2), borderRadius: BorderRadius.circular(16),), child: tileChild) : tileChild;
                      if (isDesktop) return Draggable<int>(data: index, feedback: feedback, childWhenDragging: childWhenDragging, onDragStarted: () => setState(() => _isDragging = true), onDragEnd: (_) => setState(() => _isDragging = false), child: wrapped);
                      return LongPressDraggable<int>(data: index, dragAnchorStrategy: pointerDragAnchorStrategy, feedback: feedback, childWhenDragging: childWhenDragging, onDragStarted: () => setState(() => _isDragging = true), onDragEnd: (_) => setState(() => _isDragging = false), child: wrapped);
                    });
                    positionedTiles.add(Positioned(
                      left: spacing + c * (childWidth + spacing),
                      top: r * (childWidth + spacing),
                      width: tileWidth,
                      height: tileHeight,
                      child: tileWidget,
                    ));
                  }
                }
                if (_isDragging) {
                  for (int r = 0; r < numRows; r++) {
                    for (int c = 0; c <= columns; c++) {
                      final insertIndex = (r * columns + c).clamp(0, board.tiles.length);
                      final left = spacing + c * (childWidth + spacing) - spacing / 2;
                      positionedTiles.add(Positioned(
                        left: left,
                        top: r * (childWidth + spacing),
                        width: spacing,
                        height: childWidth,
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (details) => details.data != insertIndex,
                          onAcceptWithDetails: (details) async {
                            final draggedIdx = details.data;
                            final adjusted = draggedIdx < insertIndex ? insertIndex - 1 : insertIndex;
                            setState(() {
                              final draggedTile = board.tiles.removeAt(draggedIdx);
                              board.tiles.insert(adjusted.clamp(0, board.tiles.length), draggedTile);
                            });
                            try { final service = await BoardService.getInstance(); await service.saveBoard(board); } catch (e) { debugPrint('Error saving board after reorder: $e'); }
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isActive = candidateData.isNotEmpty;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: isActive ? 8 : 4,
                              decoration: BoxDecoration(
                                color: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.6) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        ),
                      ));
                    }
                  }
                }
                final totalHeight = numRows * (childWidth + spacing);
                return SizedBox(
                  height: totalHeight,
                  child: Stack(children: positionedTiles),
                );
              })()))));
            }),
          ],
        ),
      ),
    );
  }

  void _handleMergeClick(int sourceIndex, int targetIndex) {
    if (sourceIndex == targetIndex) {
      setState(() => _mergeSourceIndex = null);
      return;
    }
    
    final targetTile = board.tiles[targetIndex];
    final isTargetBlank = targetTile.label.isEmpty && targetTile.imageAsset.isEmpty && targetTile.emoji.isEmpty;
    
    if (!isTargetBlank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target tile must be empty.')),
      );
      setState(() => _mergeSourceIndex = null);
      return;
    }

    // Check adjacency
    final row1 = sourceIndex ~/ board.columns;
    final col1 = sourceIndex % board.columns;
    final row2 = targetIndex ~/ board.columns;
    final col2 = targetIndex % board.columns;
    
    final isAdjacent = (row1 == row2 && (col1 - col2).abs() == 1) || (col1 == col2 && (row1 - row2).abs() == 1);
    
    if (!isAdjacent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target tile must be adjacent (above, below, left, or right).')),
      );
      setState(() => _mergeSourceIndex = null);
      return;
    }

    setState(() {
      final sourceTile = board.tiles[sourceIndex];
      if (row1 == row2) {
        // Horizontal merge
        sourceTile.colSpan += 1;
      } else {
        // Vertical merge
        sourceTile.rowSpan += 1;
      }
      // "Delete" the target tile to make it part of the span (it will be overlapped)
      board.tiles[targetIndex] = _blankTile(targetIndex);
      _mergeSourceIndex = null;
    });
    
    BoardService.getInstance().then((s) => s.saveBoard(board));
  }

  static Set<int> _computeCoveredCells(List<SymbolTile> tiles, int columns) {
    final covered = <int>{};
    for (int i = 0; i < tiles.length; i++) {
      final t = tiles[i];
      final row = i ~/ columns;
      final col = i % columns;
      for (int dr = 0; dr < t.rowSpan; dr++) {
        for (int dc = 0; dc < t.colSpan; dc++) {
          final coveredRow = row + dr;
          final coveredCol = col + dc;
          final coveredIndex = coveredRow * columns + coveredCol;
          if (coveredIndex != i && coveredIndex < tiles.length) {
            covered.add(coveredIndex);
          }
        }
      }
    }
    return covered;
  }

  void _applySizeChange() async {
    _resizeTimer?.cancel();
    _resizeTimer = null;

    final rows = int.tryParse(_rowsController.text) ?? board.rows;
    final columns = int.tryParse(_columnsController.text) ?? board.columns;

    if (rows == board.rows && columns == board.columns) return;

    if (rows < board.rows || columns < board.columns) {
      final newCount = rows * columns;
      int lastContentIdx = -1;
      for (int i = 0; i < board.tiles.length; i++) {
        if (board.tiles[i].label.isNotEmpty || board.tiles[i].imageAsset.isNotEmpty) {
          lastContentIdx = i;
        }
      }
      if (lastContentIdx >= newCount) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Shrink Board?'),
            content: const Text('Reducing board dimensions will hide some existing tiles from view. They will not be deleted, just hidden. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK'))
            ],
          ),
        );
        if (confirmed != true) {
          _rowsController.text = board.rows.toString();
          _columnsController.text = board.columns.toString();
          return;
        }
      }
    }
    _resizeBoard(rows, columns);
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _alphabetiseTiles() {
    final filled = board.tiles.where((t) => t.label.isNotEmpty || t.imageAsset.isNotEmpty).toList();
    final empty = board.tiles.where((t) => t.label.isEmpty && t.imageAsset.isNotEmpty).toList();
    filled.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    setState(() {
      board.tiles = [...filled, ...empty];
    });
  }

  void _resizeBoard(int newRows, int newCols) {
    final oldTiles = board.tiles;
    final newCount = newRows * newCols;
    setState(() {
      board.rows = newRows;
      board.columns = newCols;
      board.tiles = List.generate(newCount, (i) {
        return i < oldTiles.length ? oldTiles[i] : _blankTile(i);
      });
    });
  }

  void _convertAllTiles(String type) {
    setState(() {
      for (final tile in board.tiles) {
        switch (type) {
          case 'normal_word':
            tile.isBoardLink = false;
            tile.isFullScreenImage = false;
            tile.linkedBoardId = '';
            tile.bgColor = 'transparent';
            tile.textColor = '#000000';
            break;
          case 'link_to_board':
            tile.isBoardLink = true;
            tile.isFullScreenImage = false;
            tile.bgColor = '#000000';
            tile.textColor = '#FFFFFF';
            break;
          case 'open_picture':
            tile.isBoardLink = false;
            tile.isFullScreenImage = true;
            tile.bgColor = '#FFCDD2';
            tile.textColor = '#000000';
            break;
        }
      }
    });
  }

  Widget _buildTileContent(SymbolTile t, Color bg, Color txt) {
    final isBlank = t.label.isEmpty && t.imageAsset.isEmpty && t.emoji.isEmpty;
    Widget symbolImage;
    if (t.isBoardLink && t.imageAsset.isEmpty) {
      symbolImage = Icon(Icons.folder, size: 64 * t.tileSize * board.boxScale, color: txt);
    } else if (t.imageAsset.isNotEmpty) {
      if (t.imageAsset.startsWith('http')) {
        if (t.imageAsset.toLowerCase().endsWith('.svg')) {
          symbolImage = SvgPicture.network(t.imageAsset, width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale, fit: BoxFit.contain);
        } else {
          symbolImage = Image.network(t.imageAsset, width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale, fit: BoxFit.contain);
        }
      } else if (t.imageAsset.startsWith('assets/')) {
        if (t.imageAsset.toLowerCase().endsWith('.svg')) {
          symbolImage = SvgPicture.asset(t.imageAsset, width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale);
        } else {
          symbolImage = Image.asset(t.imageAsset, width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale, fit: BoxFit.contain);
        }
      } else if (kIsWeb) {
        symbolImage = Image.network(t.imageAsset, width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, size: 64 * t.tileSize * board.boxScale, color: txt));
      } else {
        symbolImage = Image.file(File(t.imageAsset), width: 64 * t.tileSize * board.boxScale, height: 64 * t.tileSize * board.boxScale, fit: BoxFit.contain);
      }
    } else if (t.emoji.isNotEmpty) {
      symbolImage = Text(t.emoji, style: TextStyle(fontSize: 48 * t.tileSize * board.boxScale));
    } else {
      symbolImage = Icon(Icons.add, size: 64 * t.tileSize * board.boxScale, color: Colors.grey.withValues(alpha: 0.5));
    }
    return Container(decoration: BoxDecoration(color: isBlank ? Colors.transparent : bg, border: isBlank ? Border.all(color: Colors.grey.withValues(alpha: 0.3)) : null, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(8), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Expanded(child: SizedBox(width: double.infinity, child: FittedBox(fit: BoxFit.contain, child: symbolImage))), const SizedBox(height: 4), Text(t.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: txt, fontSize: max(14, 12 * t.tileSize * board.boxScale), fontWeight: FontWeight.w600))]));
  }

  Future<void> _shareToArchive() async {
    final descriptionController = TextEditingController();
    final headingController = TextEditingController(text: 'Basics');
    final archiveService = BoardArchiveService();
    final headings = await archiveService.getHeadings();
    if (!mounted) return;
    await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Share Board to Archive'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [TextField(controller: TextEditingController(text: board.name), decoration: const InputDecoration(labelText: 'Board Name'), readOnly: true), const SizedBox(height: 12), TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3), const SizedBox(height: 12), const Text('Heading', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), DropdownButtonFormField<String>(initialValue: headingController.text, decoration: const InputDecoration(labelText: 'Select Heading'), items: headings.map((heading) => DropdownMenuItem(value: heading, child: Text(heading))).toList(), onChanged: (value) => headingController.text = value ?? 'Home')])), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () async { try { final boardId = await archiveService.uploadBoard(name: board.name, description: descriptionController.text, heading: headingController.text, tiles: board.tiles, backgroundColor: board.backgroundColor, rows: board.rows, columns: board.columns, boxScale: board.boxScale, adjustableLayout: board.adjustableLayout); if (ctx.mounted) { Navigator.of(ctx).pop(true); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Board shared successfully! ID: $boardId'))); } } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error sharing board: $e'))); } }, child: const Text('Share'))]));
    descriptionController.dispose();
    headingController.dispose();
  }

  _EditorGridLayout _editorGridLayoutFor(BoxConstraints constraints) {
    if (!board.adjustableLayout) return _EditorGridLayout(columns: board.columns.clamp(1, 12), childAspectRatio: 1.0);
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
    final targetTileExtent = (118.0 * board.boxScale).clamp(82.0, 180.0);
    var columns = (width / targetTileExtent).floor().clamp(2, 10);
    if (columns < 6) columns = 6;
    return _EditorGridLayout(columns: columns, childAspectRatio: 1.0);
  }
}

class _SymbolSelectionDialog extends StatelessWidget {
  final List<ExternalSymbol> symbols;
  final String title;
  const _SymbolSelectionDialog({required this.symbols, required this.title});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text(title), content: SizedBox(width: double.maxFinite, child: GridView.builder(shrinkWrap: true, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8), itemCount: symbols.length, itemBuilder: (ctx, i) {
      final s = symbols[i];
      final isAsset = s.imageUrl.startsWith('assets/');
      final isSvg = s.imageUrl.toLowerCase().endsWith('.svg');
      Widget image;
      if (isAsset) {
        image = isSvg ? SvgPicture.asset(s.imageUrl, fit: BoxFit.contain) : Image.asset(s.imageUrl, fit: BoxFit.contain);
      } else {
        image = isSvg ? SvgPicture.network(s.imageUrl, fit: BoxFit.contain) : Image.network(s.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
      }
      return InkWell(onTap: () => Navigator.of(ctx).pop(s), child: Column(children: [Expanded(child: image), Text(s.source, style: const TextStyle(fontSize: 10))]));
    })), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))]);
  }
}

class _EditorGridLayout {
  final int columns;
  final double childAspectRatio;
  const _EditorGridLayout({required this.columns, required this.childAspectRatio});
}

class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  const FullScreenImageView({super.key, required this.imagePath});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Image')), 
      body: SizedBox.expand(
        child: Center(
          child: Hero(
            tag: imagePath,
            child: imagePath.startsWith('http') 
              ? (imagePath.toLowerCase().endsWith('.svg') ? SvgPicture.network(imagePath, fit: BoxFit.contain) : Image.network(imagePath, fit: BoxFit.contain)) 
              : (imagePath.startsWith('assets/') ? (imagePath.toLowerCase().endsWith('.svg') ? SvgPicture.asset(imagePath, fit: BoxFit.contain) : Image.asset(imagePath, fit: BoxFit.contain)) : (kIsWeb ? Image.network(imagePath, fit: BoxFit.contain) : Image.file(File(imagePath), fit: BoxFit.contain))),
          ),
        ),
      ),
    );
  }
}

class _RecordDialog extends StatefulWidget {
  final String initialPath;
  final ValueChanged<String> onPathChanged;
  const _RecordDialog({required this.initialPath, required this.onPathChanged});
  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _isRecording = false;
  String _recordedPath = '';
  bool _isPlaying = false;
  @override
  void initState() {
    super.initState();
    _recordedPath = widget.initialPath;
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }
  @override
  void dispose() { _recorder.dispose(); _player.dispose(); super.dispose(); }
  Future<void> _start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record voice.')),
          );
        }
        return;
      }
      
      String path;
      RecordConfig config;
      if (kIsWeb) {
        config = const RecordConfig(encoder: AudioEncoder.opus);
        // On Web, we don't pass a path to start(); it returns a blob URL in stop()
        await _recorder.start(config, path: '');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final customDir = Directory('${directory.path}/custom_audio');
        if (!await customDir.exists()) await customDir.create(recursive: true);
        
        path = '${customDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        config = const RecordConfig(encoder: AudioEncoder.aacLc);
        await _recorder.start(config, path: path);
      }

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stop() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedPath = path;
        });
        widget.onPathChanged(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }
  Future<void> _play() async {
    if (_recordedPath.isEmpty) return;
    try {
      if (_isPlaying) {
        await _player.stop();
      } else {
        if (_recordedPath.startsWith('http') || _recordedPath.startsWith('blob:') || _recordedPath.startsWith('data:')) {
          await _player.play(UrlSource(_recordedPath));
        } else {
          await _player.play(DeviceFileSource(_recordedPath));
        }
      }
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }
  void _startAgain() { setState(() { _recordedPath = ''; _isRecording = false; }); widget.onPathChanged(''); }
  @override
  Widget build(BuildContext context) { return AlertDialog(title: const Text('Custom Voice'), content: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: _isRecording ? null : _start, icon: const Icon(Icons.mic), label: const Text('Record')), ElevatedButton.icon(onPressed: _isRecording ? _stop : null, icon: const Icon(Icons.stop), label: const Text('Stop'))]), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(onPressed: _recordedPath.isNotEmpty && !_isRecording ? _play : null, icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow), label: Text(_isPlaying ? 'Stop' : 'Play')), ElevatedButton.icon(onPressed: _recordedPath.isNotEmpty && !_isRecording ? _startAgain : null, icon: const Icon(Icons.refresh), label: const Text('Start Again'))]), const SizedBox(height: 16), Text(_isRecording ? 'Recording...' : (_recordedPath.isNotEmpty ? 'Recording ready' : 'Press Record to start'), style: Theme.of(context).textTheme.bodyMedium)]), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')), FilledButton(onPressed: _recordedPath.isNotEmpty ? () => Navigator.of(context).pop(_recordedPath) : null, child: const Text('Done'))]); }
}

class _BoardSelectionDialog extends StatefulWidget {
  final List<Board> boards;
  final String? initialSelectedId;
  final String initialQuery;
  final String title;
  const _BoardSelectionDialog({required this.boards, this.initialSelectedId, this.initialQuery = '', this.title = 'Select Board'});
  @override
  State<_BoardSelectionDialog> createState() => _BoardSelectionDialogState();
}

class _BoardSelectionDialogState extends State<_BoardSelectionDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController.text = _query;
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  bool _matchesFuzzy(String label, String query) {
    if (query.isEmpty) return true;
    final l = label.toLowerCase();
    final q = query.toLowerCase();
    if (l.contains(q)) return true;
    final normL = l.replaceAll(RegExp(r'[aeiouy]'), '*');
    final normQ = q.replaceAll(RegExp(r'[aeiouy]'), '*');
    return normL.contains(normQ);
  }
  @override
  Widget build(BuildContext context) {
    final filtered = widget.boards.where((b) => _matchesFuzzy(b.name, _query)).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return AlertDialog(title: Text(widget.title), content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search boards...', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (v) => setState(() => _query = v)), const SizedBox(height: 12), Expanded(child: ListView(shrinkWrap: true, children: [ListTile(title: const Text('None', style: TextStyle(color: Colors.redAccent)), leading: const Icon(Icons.block, color: Colors.redAccent), onTap: () => Navigator.of(context).pop('NONE')), ListTile(title: const Text('Create New Board', style: TextStyle(color: Colors.blue)), leading: const Icon(Icons.add_circle_outline, color: Colors.blue), onTap: () => Navigator.of(context).pop('CREATE_NEW')), const Divider(), ...filtered.map((board) { final isSelected = board.id == widget.initialSelectedId; return ListTile(title: Text(board.name), trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null, onTap: () => Navigator.of(context).pop(board.id), selected: isSelected); })]))])), actions: [TextButton(onPressed: () => Navigator.of(context).pop('DIALOG_DISMISSED'), child: const Text('Cancel'))]);
  }
}
