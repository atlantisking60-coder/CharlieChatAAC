import '../models/symbol_tile.dart';

class ArchivedBoard {
  final String id;
  final String name;
  final String description;
  final String heading;
  final String author;
  final int downloadCount;
  final List<SymbolTile> tiles;
  final String backgroundColor;
  final int rows;
  final int columns;
  final double boxScale;
  final bool adjustableLayout;

  ArchivedBoard({
    required this.id,
    required this.name,
    required this.description,
    required this.heading,
    required this.author,
    required this.downloadCount,
    required this.tiles,
    required this.backgroundColor,
    required this.rows,
    required this.columns,
    required this.boxScale,
    required this.adjustableLayout,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'heading': heading,
        'author': author,
        'downloadCount': downloadCount,
        'tiles': tiles.map((t) => t.toMap()).toList(),
        'backgroundColor': backgroundColor,
        'rows': rows,
        'columns': columns,
        'boxScale': boxScale,
        'adjustableLayout': adjustableLayout,
      };

  factory ArchivedBoard.fromMap(Map<String, dynamic> m) => ArchivedBoard(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        heading: m['heading'] ?? 'Basics',
        author: m['author'] ?? 'Unknown',
        downloadCount: m['downloadCount'] ?? 0,
        tiles: (m['tiles'] as List<dynamic>?)
                ?.map((t) => SymbolTile.fromMap(t as Map<String, dynamic>))
                .toList() ??
            [],
        backgroundColor: m['backgroundColor'] ?? '#FFFFFF',
        rows: m['rows'] ?? 4,
        columns: m['columns'] ?? 4,
        boxScale: (m['boxScale'] is num) ? (m['boxScale'] as num).toDouble() : 1.0,
        adjustableLayout: m['adjustableLayout'] ?? false,
      );
}

class BoardArchiveService {
  Future<List<ArchivedBoard>> searchBoards(String query, {String? heading}) async {
    // Mock implementation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [];
  }

  Future<ArchivedBoard?> getBoard(String boardId) async {
    // Mock implementation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    return null;
  }

  Future<String> uploadBoard({
    required String name,
    required String description,
    required String heading,
    required List<SymbolTile> tiles,
    required String backgroundColor,
    required int rows,
    required int columns,
    required double boxScale,
    required bool adjustableLayout,
  }) async {
    // Mock implementation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Return a mock board ID
    return 'board_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> downloadBoard(String boardId) async {
    // Mock implementation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<String>> getHeadings() async {
    // Return available headings
    return [
      'Home',
      'School',
      'Sign',
      'My School',
      'Personal',
    ];
  }
}
