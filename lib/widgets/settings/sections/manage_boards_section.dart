import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;
import '../../../models/symbol_tile.dart';
import '../../../services/board_service.dart';
import '../../../services/filesystem_access.dart' as fsa;
import '../../../services/settings_service.dart';
import '../../external_symbol_search.dart';
import '../../symbol_grid.dart';
import '../settings_widgets.dart';

class ManageBoardsSection extends StatefulWidget {
  const ManageBoardsSection({super.key, required this.settings, required this.onChanged, this.onNavigate});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final ValueChanged<String>? onNavigate;

  @override
  State<ManageBoardsSection> createState() => _ManageBoardsSectionState();
}

class BoardShortcut {
  final String targetId;
  final String label;
  final String parentBoardId;
  BoardShortcut(this.targetId, this.label, this.parentBoardId);
}

class _ManageBoardsSectionState extends State<ManageBoardsSection> {
  List<Board> _allBoardsPool = [];
  List<dynamic> _hierarchyItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() => _loading = true);
    final service = await BoardService.getInstance();
    _allBoardsPool = await service.listBoards();
    if (mounted) {
      setState(() {
        _hierarchyItems = _sortItemsHierarchically(_allBoardsPool);
        _loading = false;
      });
    }
  }

  String _boardWordList(Board board) {
    return board.tiles
        .where((t) => t.label.isNotEmpty)
        .map((t) => t.label)
        .join('\n');
  }

  Future<void> _backupAllBoards() async {
    try {
      final service = await BoardService.getInstance();
      final boards = await service.listBoards();

      if (kIsWeb) {
        if (!fsa.isSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File System Access API is not supported in this browser. Use Chrome.')),
            );
          }
          return;
        }
        final dirHandle = await fsa.pickDirectory();
        if (dirHandle == null) return;
        int count = 0;
        for (final board in boards) {
          final relativePath = await service.boardRelativePath(board);
          final filePath = 'lib/data/boards/$relativePath/${board.id}.json';
          final jsonString = JsonEncoder.withIndent('  ').convert(board.toMap());
          await fsa.writeTextToPath(dirHandle, filePath, jsonString);
          final wordListName = '${board.name} - Word List';
          await fsa.writeTextToPath(dirHandle, 'lib/data/boards/$relativePath/$wordListName.txt', _boardWordList(board));
          count++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backed up $count boards')),
          );
        }
      } else {
        final selectedDir = await FilePicker.getDirectoryPath(
          dialogTitle: 'Choose where to back up all boards',
        );
        if (selectedDir == null || selectedDir.isEmpty) return;
        int count = 0;
        for (final board in boards) {
          final relativePath = await service.boardRelativePath(board);
          final boardDir = Directory(p.join(selectedDir, 'lib', 'data', 'boards', relativePath));
          await boardDir.create(recursive: true);
          final jsonString = JsonEncoder.withIndent('  ').convert(board.toMap());
          await File(p.join(boardDir.path, '${board.id}.json')).writeAsString(jsonString);
          final wordListName = '${board.name} - Word List';
          await File(p.join(boardDir.path, '$wordListName.txt')).writeAsString(_boardWordList(board));
          final pngBytes = await _captureBoardPng(board);
          if (pngBytes != null) {
            final pngFileName = '${board.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim()}.png';
            await File(p.join(boardDir.path, pngFileName)).writeAsBytes(pngBytes);
          }
          count++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backed up $count boards to $selectedDir')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error backing up boards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<List<int>?> _captureBoardPng(Board board) async {
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
                      Text(board.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 20),
                      SymbolGrid(
                        symbols: board.tiles,
                        favoriteIds: const {},
                        onTap: (_) {}, onLongPress: (_) {},
                        fixedRows: board.rows, fixedColumns: board.columns,
                        adjustableLayout: board.adjustableLayout,
                        boxScale: board.boxScale,
                        highContrast: widget.settings.highContrast,
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
      await Future.delayed(const Duration(milliseconds: 300));
      final boundary = captureKey.currentContext?.findRenderObject();
      if (boundary == null) { entry.remove(); return null; }
      final image = await (boundary as dynamic).toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      entry.remove();
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing board PNG: $e');
      return null;
    }
  }

  Future<void> _renumberAllBoards() async {
    final service = await BoardService.getInstance();
    final list = await service.listBoards();
    
    final areas = ['Common', 'Subject Vocab', 'Sign', 'My School', 'Personal'];
    for (final area in areas) {
      final roots = list.where((b) => b.area == area && !b.isSubBoard && !b.isTertiaryBoard).toList();
      for (int i = 0; i < roots.length; i++) {
        roots[i].sortOrder = (i + 1) * 10;
        await service.saveBoard(roots[i]);
        await _renumberChildren(roots[i], service, list);
      }
    }
    _loadBoards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All board positions have been synchronized.')),
      );
    }
  }

  Future<void> _renumberChildren(Board parent, BoardService service, List<Board> pool) async {
    final children = pool.where((b) => b.parentBoardId == parent.id).toList();
    for (int i = 0; i < children.length; i++) {
      children[i].sortOrder = (i + 1) * 10;
      await service.saveBoard(children[i]);
      await _renumberChildren(children[i], service, pool);
    }
  }

  List<dynamic> _sortItemsHierarchically(List<Board> all) {
    final areas = ['Common', 'Subject Vocab', 'Sign', 'My School', 'Personal'];
    final boardsByArea = <String, List<Board>>{};
    for (final area in areas) {
      boardsByArea[area] = [];
    }

    for (final b in all) {
      final area = areas.contains(b.area) ? b.area : 'Common';
      boardsByArea[area]!.add(b);
    }

    final result = <dynamic>[];
    for (final area in areas) {
      final areaBoards = boardsByArea[area]!;
      if (areaBoards.isEmpty) continue;

      if (area == 'Common') {
        result.addAll(_sortCommonArea(areaBoards, all));
      } else if (area == 'Subject Vocab') {
        result.addAll(_sortSubjectVocabArea(areaBoards, all));
      } else if (area == 'Sign') {
        result.addAll(_sortSignArea(areaBoards, all));
      } else if (area == 'My School') {
        result.addAll(_sortMySchoolArea(areaBoards, all));
      } else {
        result.addAll(_sortGenericArea(areaBoards, all));
      }
    }
    return result;
  }

  List<dynamic> _sortCommonArea(List<Board> areaBoards, List<Board> allPool) {
    final order = [
      'Common Words', 'Letters', 'Numbers', 'Feelings', 'Colours', 'Prepositions',
      'People', 'Animals', 'Actions', 'Places', 'Jobs & Careers', 'Weather',
      'Body Parts', 'Time', 'Clothes', 'Toys'
    ];
    return _sortWithOrder(areaBoards, allPool, order);
  }

  List<dynamic> _sortSubjectVocabArea(List<Board> areaBoards, List<Board> allPool) {
    final order = ['Lessons', 'Sentence Creator'];
    return _sortWithOrder(areaBoards, allPool, order);
  }

  List<dynamic> _sortSignArea(List<Board> areaBoards, List<Board> allPool) {
    final order = ['Sign Main', 'A-Z Of Sign'];
    return _sortWithOrder(areaBoards, allPool, order);
  }

  List<dynamic> _sortMySchoolArea(List<Board> areaBoards, List<Board> allPool) {
    final order = ['My School Main', 'People At School', 'Baycroft Expects', 'Thinking Skills', 'When Things Go Wrong', 'Blank Levels', 'My School Lessons', 'Better Words (Thesaurus)'];
    return _sortWithOrder(areaBoards, allPool, order);
  }

  List<dynamic> _sortGenericArea(List<Board> areaBoards, List<Board> allPool) {
    return _sortWithOrder(areaBoards, allPool, []);
  }

  List<dynamic> _sortWithOrder(List<Board> areaBoards, List<Board> allPool, List<String> order) {
    final result = <dynamic>[];
    final remaining = List<Board>.from(areaBoards);

    for (final name in order) {
      final matches = remaining.where((b) => b.name.toLowerCase() == name.toLowerCase() && b.sortOrder == 0).toList();
      for (final root in matches) {
        remaining.remove(root);
        result.add(root);
        _addItemsRecursive(root, allPool, result, <String>{root.id});
      }
    }

    final roots = remaining.where((b) => !b.isSubBoard && !b.isTertiaryBoard).toList();
    roots.sort((a, b) {
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    
    for (final root in roots) {
      remaining.remove(root);
      result.add(root);
      _addItemsRecursive(root, allPool, result, <String>{root.id});
    }

    remaining.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final b in remaining) {
       result.add(b);
       _addItemsRecursive(b, allPool, result, <String>{b.id});
    }

    return result;
  }

  void _addItemsRecursive(Board parent, List<Board> allPool, List<dynamic> result, Set<String> visited) {
    final children = allPool.where((b) => b.parentBoardId == parent.id).toList();
    
    final shortcuts = <BoardShortcut>[];
    for (final tile in parent.tiles) {
      if (tile.isBoardLink && tile.linkedBoardId.isNotEmpty) {
        final target = allPool.cast<Board?>().firstWhere((b) => b?.id == tile.linkedBoardId, orElse: () => null);
        if (target != null && target.tier > parent.tier && target.parentBoardId != parent.id) {
          shortcuts.add(BoardShortcut(target.id, target.name, parent.id));
        }
      }
    }

    final combined = <dynamic>[...children, ...shortcuts];
    combined.sort((a, b) {
      final orderA = (a is Board) ? a.sortOrder : 0;
      final orderB = (b is Board) ? b.sortOrder : 0;
      if (orderA != 0 && orderB != 0) return orderA.compareTo(orderB);
      if (orderA != 0) return -1;
      if (orderB != 0) return 1;
      
      final labelA = (a is Board) ? a.name : (a as BoardShortcut).label;
      final labelB = (b is Board) ? b.name : (b as BoardShortcut).label;

      final prebuiltOrder = prebuiltBoardNames;
      final aIndex = prebuiltOrder.indexOf(labelA);
      final bIndex = prebuiltOrder.indexOf(labelB);
      if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
      if (aIndex >= 0) return -1;
      if (bIndex >= 0) return 1;

      return labelA.toLowerCase().compareTo(labelB.toLowerCase());
    });

    for (final item in combined) {
      if (item is Board) {
        if (visited.add(item.id)) {
          result.add(item);
          _addItemsRecursive(item, allPool, result, visited);
        }
      } else {
        result.add(item);
      }
    }
  }

  String _getBoardPath(Board board) {
    final List<String> parts = [board.name];
    Board? current = board;
    while (current != null && (current.isSubBoard || current.isTertiaryBoard) && current.parentBoardId != null) {
      final parentId = current.parentBoardId;
      final parent = _allBoardsPool.cast<Board?>().firstWhere((b) => b?.id == parentId, orElse: () => null);
      if (parent != null) {
        parts.insert(0, parent.name);
        current = parent;
      } else {
        break;
      }
    }
    parts.insert(0, board.area);
    return parts.join(' > ');
  }

  String _getBoardIconPath(Board board) {
    if (board.iconAssetPath != null && board.iconAssetPath!.isNotEmpty) return board.iconAssetPath!;
    final iconMappings = {
      'ANIMALS': 'assets/symbols/BOARDS/Animals/Animals.png',
      'JOBS & CAREERS': 'assets/symbols/BOARDS/Jobs.png',
      'TIME': 'assets/symbols/BOARDS/Time, Months, Events/Time.png',
      'MORE BOARDS': 'assets/symbols/BOARDS/More ++.png',
      'MORE WORDS': 'assets/symbols/BOARDS/More ++.png',
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
      'Resistant Materials': 'assets/symbols/Subjects/Resistant Materials & Construction.png',
      'Textiles': 'assets/symbols/Subjects/Textiles.png',
      'Religion & Worldviews': 'assets/symbols/Subjects/Religion & Worldviews.png',
      'Music': 'assets/symbols/Subjects/Music.png',
      'Horticulture': 'assets/symbols/Subjects/Horticulture.png',
      'Retail': 'assets/symbols/Subjects/Retail.png',
      'Photography': 'assets/symbols/Subjects/Photography.png',
      'Information Technology': 'assets/symbols/Subjects/I.T.png',
      'Construction': 'assets/symbols/Subjects/Resistant Materials & Construction.png',
      'Engineering': 'assets/symbols/Subjects/Engineering.png',
      'Living Life Skills': 'assets/symbols/Subjects/Living Life Skills.png',
      'Prepare For Adulthood': 'assets/symbols/Subjects/Prepare For Adulthood.png',
      'Break & Lunch': 'assets/symbols/Subjects/Breaktime.png',
      'Tutor Time': 'assets/symbols/Subjects/Tutor Time.png',
      'Sign': 'assets/symbols/BOARDS/Signs.png',
      'A-Z Of Sign': 'assets/symbols/BOARDS/Letters.png',
      'Manners & Greetings': 'assets/symbols/BOARDS/People.png',
      'Family & People': 'assets/symbols/BOARDS/Family Tree.png',
      'Transport & Vehicles': 'assets/symbols/BOARDS/Transport.png',
      'Food & Drink': 'assets/symbols/BOARDS/Cooking & Food/Food.png',
      'Home & Household': 'assets/symbols/BOARDS/Home.png',
      'Feelings & Health': 'assets/symbols/BOARDS/Feelings.png',
      'School & Instructions': 'assets/symbols/BOARDS/People At School.png',
      'Descriptions & Attributes': 'assets/symbols/BOARDS/English/Adjectives.png',
      'Prepositions': 'assets/symbols/BOARDS/Prepositions.png',
      'Outside': 'assets/symbols/BOARDS/Town.png',
      'Questions': 'assets/symbols/BOARDS/English/How.png',
      'Letters': 'assets/symbols/BOARDS/Letters.png',
      'Numbers': 'assets/symbols/BOARDS/Numbers.png',
      'Personal Actions': 'assets/symbols/BOARDS/Actions.png',
      'Shared Activities': 'assets/symbols/BOARDS/People & Places.png',
      'Leisure Activities & Interests': 'assets/symbols/BOARDS/Sports, Activities & P.E/Sports.png',
      'General Objects': 'assets/symbols/BOARDS/Furniture.png',
      'Clothing & Personal': 'assets/symbols/BOARDS/Clothes.png',
      'Personal Possessions': 'assets/symbols/BOARDS/Toys.png',
      'Personal Hygiene': 'assets/symbols/BOARDS/Medical.png',
      'Gender & Sexuality': 'assets/symbols/BOARDS/People.png',
      'Places': 'assets/symbols/BOARDS/Places.png',
      'Sport': 'assets/symbols/BOARDS/Sports, Activities & P.E/Sports.png',
      'Religion & Customs': 'assets/symbols/BOARDS/Religion & Worldviews/Community.png',
      'Other Countries': 'assets/symbols/BOARDS/Countryside.png',
      'Public Notices': 'assets/symbols/BOARDS/Signs.png',
      'Money': 'assets/symbols/BOARDS/Money UK.png',
      'Computer Items': 'assets/symbols/BOARDS/Class Equipment.png',
      'Grammatical Elements': 'assets/symbols/BOARDS/Small Words.png',
      'Quantity & Measurement': 'assets/symbols/BOARDS/Numbers.png',
      'Sad': 'assets/symbols/BOARDS/Feelings/Sad.png',
      'Mad': 'assets/symbols/BOARDS/Feelings/Mad.png',
      'Scared': 'assets/symbols/BOARDS/Feelings/Scared.png',
      'Joyful': 'assets/symbols/BOARDS/Feelings/Joyful.png',
      'Strong': 'assets/symbols/BOARDS/Feelings/Strong.png',
      'Calm': 'assets/symbols/BOARDS/Feelings/Calm.png',
      'Shades Of Colours': 'assets/symbols/BOARDS/Shades Of Colours.png',
      'Adjectives': 'assets/symbols/BOARDS/English/Adjectives.png',
      'Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 2.png',
      'Phase 2 Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 2.png',
      'Phase 3 Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 3.png',
      'Phase 4 Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 4.png',
      'Phase 5 Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 5.png',
      'Phase 6 Phonics': 'assets/symbols/BOARDS/English/Phonics - Phase 6.png',
      'School People': 'assets/symbols/BOARDS/People At School.png',
      'Characters': 'assets/symbols/BOARDS/English/Characters.png',
      'Mammals': 'assets/symbols/BOARDS/Animals/Mammals.png',
      'Birds': 'assets/symbols/BOARDS/Animals/Birds.png',
      'Reptiles': 'assets/symbols/BOARDS/Animals/Reptiles.png',
      'Amphibians': 'assets/symbols/BOARDS/Animals/Amphibians.png',
      'Insects': 'assets/symbols/BOARDS/Animals/Insects.png',
      'Arachnids': 'assets/symbols/BOARDS/Animals/Arachnids.png',
      'Invertebrates': 'assets/symbols/BOARDS/Animals/Invertebrates.png',
      'Fish': 'assets/symbols/BOARDS/Animals/Fish.png',
      'Habitats': 'assets/symbols/BOARDS/Animals/Habitats.png',
      'Sealife': 'assets/symbols/BOARDS/Animals/Sealife.png',
      'Nature Vocabulary': 'assets/symbols/BOARDS/Animals/Animals.png',
      'Body Parts Of Animals': 'assets/symbols/BOARDS/Animals/Animal Body Parts.png',
      'Child Animals': 'assets/symbols/BOARDS/Animals/Child Animals.png',
      'Groups Of Animals': 'assets/symbols/BOARDS/Animals/Groups of Animals.png',
      'MY SCHOOL': 'assets/symbols/BOARDS/People At School.png',
      'People At School': 'assets/symbols/BOARDS/People At School.png',
      'Baycroft Expects': 'assets/symbols/BOARDS/Baycroft Expects.png',
      'Thinking Skills': 'assets/symbols/BOARDS/Thinking Skills.png',
      'When Things Go Wrong': 'assets/symbols/BOARDS/Words For When Things Go Wrong.png',
      'Blank Levels': 'assets/symbols/BOARDS/Blank Levels.png',
      'My School Lessons': 'assets/symbols/BOARDS/Lesson Vocabulary.png',
      'PEOPLE AT HOME': 'assets/symbols/BOARDS/Home.png',
    };
    final upper = board.name.toUpperCase();
    for (final entry in iconMappings.entries) {
      if (entry.key.toUpperCase() == upper) return entry.value;
    }
    return 'assets/symbols/BOARDS/${board.name.replaceAll(' ', ' ')}.png';
  }

  Future<void> _deleteBoard(Board board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${board.name}?'),
        content: const Text('This will permanently remove this board and all its tiles. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final service = await BoardService.getInstance();
      await service.deleteBoard(board.id);
      _loadBoards();
    }
  }

  Future<void> _moveBoard(Board board) async {
    String selectedArea = board.area;
    bool isSubBoard = board.isSubBoard;
    bool isTertiaryBoard = board.isTertiaryBoard;
    String? selectedParentId = board.parentBoardId;
    int sortOrder = board.sortOrder;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDiagState) => AlertDialog(
          title: Text('Move ${board.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedArea,
                  decoration: const InputDecoration(labelText: 'Target Area'),
                  items: const [
                    DropdownMenuItem(value: 'Common', child: Text('Common')),
                    DropdownMenuItem(value: 'Subject Vocab', child: Text('Subject Vocab')),
                    DropdownMenuItem(value: 'Sign', child: Text('Sign')),
                    DropdownMenuItem(value: 'My School', child: Text('My School')),
                    DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  ],
                  onChanged: (v) => setDiagState(() => selectedArea = v!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Sub-board?'),
                  value: isSubBoard,
                  onChanged: (v) => setDiagState(() {
                    isSubBoard = v;
                    if (!v) isTertiaryBoard = false;
                  }),
                ),
                SwitchListTile(
                  title: const Text('Is Tertiary?'),
                  value: isTertiaryBoard,
                  onChanged: (v) => setDiagState(() {
                    isTertiaryBoard = v;
                    if (v) isSubBoard = true;
                  }),
                ),
                if (isSubBoard || isTertiaryBoard) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDialog<String?>(
                        context: context,
                        builder: (ctx) => _BoardSelectionDialog(
                          boards: _allBoardsPool,
                          initialSelectedId: selectedParentId,
                          title: 'Select Parent Board',
                        ),
                      );
                      if (selected != 'DIALOG_DISMISSED') {
                        setDiagState(() => selectedParentId = (selected == 'NONE' ? null : selected));
                      }
                    },
                    icon: const Icon(Icons.account_tree_outlined),
                    label: Text(
                      selectedParentId == null || selectedParentId!.isEmpty
                          ? 'Select Parent Board'
                          : 'Parent: ${_allBoardsPool.cast<Board?>().firstWhere((b) => b?.id == selectedParentId, orElse: () => null)?.name ?? 'Unknown'}',
                    ),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), alignment: Alignment.centerLeft),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: sortOrder.toString(),
                  decoration: const InputDecoration(labelText: 'Sort Order (Position)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => sortOrder = int.tryParse(v) ?? sortOrder,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Move')),
          ],
        ),
      ),
    );

    if (result == true) {
      board.area = selectedArea;
      board.isSubBoard = isSubBoard;
      board.isTertiaryBoard = isTertiaryBoard;
      board.parentBoardId = (isSubBoard || isTertiaryBoard) ? selectedParentId : null;
      board.sortOrder = sortOrder;
      final service = await BoardService.getInstance();
      await service.saveBoard(board);
      _loadBoards();
    }
  }

  void _reorderGroup(Board board) async {
    final bool isRoot = !board.isSubBoard && !board.isTertiaryBoard;
    List<Board> siblings;
    if (isRoot) {
      siblings = _allBoardsPool.where((b) => b.area == board.area && !b.isSubBoard && !b.isTertiaryBoard).toList();
    } else {
      siblings = _allBoardsPool.where((b) => b.parentBoardId == board.parentBoardId).toList();
    }
    
    siblings.sort((a, b) {
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final result = await showDialog<List<Board>>(
      context: context,
      builder: (ctx) => _ReorderBoardsDialog(boards: siblings),
    );

    if (result != null) {
      final service = await BoardService.getInstance();
      for (int i = 0; i < result.length; i++) {
        result[i].sortOrder = (i + 1) * 10;
        await service.saveBoard(result[i]);
      }
      _loadBoards();
    }
  }

  (int, int) _getBoardPosition(Board board) {
    final bool isRoot = !board.isSubBoard && !board.isTertiaryBoard;
    List<Board> siblings;
    if (isRoot) {
      siblings = _allBoardsPool.where((b) => b.area == board.area && !b.isSubBoard && !b.isTertiaryBoard).toList();
    } else {
      siblings = _allBoardsPool.where((b) => b.parentBoardId == board.parentBoardId).toList();
    }
    siblings.sort((a, b) {
      if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final index = siblings.indexWhere((b) => b.id == board.id);
    return (index + 1, siblings.length);
  }

  Widget _buildPreview(Board board) {
    final filledTiles = board.tiles.where((t) => t.label.isNotEmpty || t.imageAsset.isNotEmpty || t.emoji.isNotEmpty).toList();
    if (filledTiles.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Empty Board', style: TextStyle(fontStyle: FontStyle.italic)));
    return Container(
      width: 280, padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: filledTiles.length.clamp(0, 12),
        itemBuilder: (context, i) => Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)), child: _buildTileImage(filledTiles[i].imageAsset, size: 40)),
      ),
    );
  }

  Widget _buildTileImage(String path, {double size = 32}) {
    if (path.isEmpty) return Icon(Icons.image, size: size * 0.6, color: Colors.grey);
    if (path.startsWith('http')) return Image.network(path, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size * 0.6));
    if (path.startsWith('assets/')) {
      if (path.toLowerCase().endsWith('.svg')) return SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain);
      return Image.asset(path, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size * 0.6));
    }
    return Image.network(path, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size * 0.6));
  }

  Widget _buildShortcutCard(BoardShortcut shortcut, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant, width: 1)), child: Icon(Icons.shortcut_rounded, size: 20, color: cs.secondary)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Shortcut: ${shortcut.label}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurfaceVariant)), const SizedBox(height: 2), Text('Link to board in another area', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontStyle: FontStyle.italic))])),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBoardIcon(Board board) async {
    final result = await Navigator.of(context).push<SymbolTile>(MaterialPageRoute(builder: (_) => ExternalSymbolSearchScreen(onAdd: (s) {}, initialLabel: board.name)));
    if (result != null && mounted) {
      final service = await BoardService.getInstance();
      setState(() { board.iconAssetPath = result.imageAsset; });
      await service.saveBoard(board);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Icon updated for ${board.name}.')));
    }
  }

  void _openBoard(Board board) async {
    if (kIsWeb) { web.window.open(web.window.location.href, '_blank'); }
    else { widget.onNavigate?.call(board.id); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SettingsSectionHeader(icon: Icons.grid_view_rounded, title: 'Manage Boards', subtitle: 'Organize, move, and delete boards across your app areas.')),
          ],
        ),
        Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _backupAllBoards, icon: const Icon(Icons.backup_rounded), label: const Text('Backup All Boards')))),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (_hierarchyItems.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No boards found.')))
        else ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _hierarchyItems.length,
          itemBuilder: (context, index) {
            final item = _hierarchyItems[index];
            if (item is BoardShortcut) return _buildShortcutCard(item, cs);
            final board = item as Board;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _pickBoardIcon(board), borderRadius: BorderRadius.circular(8),
                      child: Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant, width: 1)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(board.iconAssetPath ?? _getBoardIconPath(board), errorBuilder: (_, __, ___) => Icon(board.isSubBoard || board.isTertiaryBoard ? Icons.folder_open : Icons.grid_view, size: 20, color: cs.primary)))),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) {
                            final pos = _getBoardPosition(board);
                            return Tooltip(richMessage: WidgetSpan(child: _buildPreview(board)), decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.primary.withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)]), child: Text('${board.name} (${pos.$1}/${pos.$2})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)));
                          }),
                          const SizedBox(height: 2),
                          Text(_getBoardPath(board), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.open_in_new_rounded, size: 20), tooltip: 'Open board', onPressed: () => _openBoard(board), color: cs.tertiary),
                    IconButton(icon: const Icon(Icons.reorder_rounded, size: 20), tooltip: 'Reorder siblings', onPressed: () => _reorderGroup(board), color: cs.secondary),
                    IconButton(icon: const Icon(Icons.drive_file_move_outlined, size: 20), tooltip: 'Move board', onPressed: () => _moveBoard(board), color: cs.primary),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 20), tooltip: 'Delete board', onPressed: () => _deleteBoard(board), color: Colors.redAccent),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BoardSelectionDialog extends StatefulWidget {
  final List<Board> boards;
  final String? initialSelectedId;
  final String title;
  const _BoardSelectionDialog({required this.boards, this.initialSelectedId, this.title = 'Select Board'});
  @override
  State<_BoardSelectionDialog> createState() => _BoardSelectionDialogState();
}

class _BoardSelectionDialogState extends State<_BoardSelectionDialog> {
  final _searchController = TextEditingController();
  String _query = '';
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search boards...', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (v) => setState(() => _query = v)), const SizedBox(height: 12), Expanded(child: ListView(shrinkWrap: true, children: [ListTile(title: const Text('None', style: TextStyle(color: Colors.redAccent)), leading: const Icon(Icons.block, color: Colors.redAccent), onTap: () => Navigator.of(context).pop('NONE')), const Divider(), ...filtered.map((board) { final isSelected = board.id == widget.initialSelectedId; return ListTile(title: Text(board.name), trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null, onTap: () => Navigator.of(context).pop(board.id), selected: isSelected); })]))])),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop('DIALOG_DISMISSED'), child: const Text('Cancel'))],
    );
  }
}

class _ReorderBoardsDialog extends StatefulWidget {
  final List<Board> boards;
  const _ReorderBoardsDialog({required this.boards});
  @override
  State<_ReorderBoardsDialog> createState() => _ReorderBoardsDialogState();
}

class _ReorderBoardsDialogState extends State<_ReorderBoardsDialog> {
  late List<Board> _localList;
  int? _editingIndex;
  final _editControllers = <int, TextEditingController>{};
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _localList = List.from(widget.boards);
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
      int currentOrder = 1;
      for (final board in _localList) {
        board.sortOrder = currentOrder++;
        await service.saveBoard(board);
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Success! Order saved.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = null);
        });
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
      title: const Text('Reorder Boards'),
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
                  final b = _localList[index];
                  final isEditing = _editingIndex == index;
                  final controller = _editControllers.putIfAbsent(index, () => TextEditingController(text: '${index + 1}'));
                  if (isEditing) {
                    controller.text = '${index + 1}';
                    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                  }
                  return ListTile(
                    key: ValueKey(b.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(b.name),
                    trailing: isEditing
                        ? SizedBox(
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
                        : GestureDetector(
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
        TextButton(
          onPressed: () async {
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
              for (final board in _localList) {
                board.sortOrder = 0;
                await service.saveBoard(board);
              }
              if (mounted) {
                 setState(() => _statusMessage = 'Order reset to default.');
                 Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) Navigator.pop(context, _localList);
                 });
              }
            }
          },
          child: const Text('Reset to Default', style: TextStyle(color: Colors.redAccent)),
        ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _isSaving ? null : _saveOrder, child: const Text('Save Order')),
        FilledButton.tonal(onPressed: () => Navigator.pop(context, _localList), child: const Text('Done')),
      ],
    );
  }
}
