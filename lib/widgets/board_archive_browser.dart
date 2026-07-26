import 'package:flutter/material.dart';

import '../services/board_archive_service.dart';

class BoardArchiveBrowser extends StatefulWidget {
  final Function(ArchivedBoard) onAddBoard;

  const BoardArchiveBrowser({super.key, required this.onAddBoard});

  @override
  State<BoardArchiveBrowser> createState() => _BoardArchiveBrowserState();
}

class _BoardArchiveBrowserState extends State<BoardArchiveBrowser> {
  final BoardArchiveService _archiveService = BoardArchiveService();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedHeading;
  List<ArchivedBoard> _boards = [];
  bool _isLoading = false;
  List<String> _headings = [];

  @override
  void initState() {
    super.initState();
    _loadHeadings();
    _searchBoards();
  }

  Future<void> _loadHeadings() async {
    final headings = await _archiveService.getHeadings();
    if (mounted) {
      setState(() {
        _headings = headings;
      });
    }
  }

  Future<void> _searchBoards() async {
    setState(() {
      _isLoading = true;
    });

    final boards = await _archiveService.searchBoards(
      _searchController.text,
      heading: _selectedHeading,
    );

    if (mounted) {
      setState(() {
        _boards = boards;
        _isLoading = false;
      });
    }
  }

  void _addBoard(ArchivedBoard board) {
    widget.onAddBoard(board);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Archive'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search boards',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchBoards();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _searchBoards(),
                ),
                const SizedBox(height: 8),
                if (_headings.isNotEmpty)
                  DropdownButton<String>(
                    hint: const Text('Filter by heading'),
                    value: _selectedHeading,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Headings'),
                      ),
                      ..._headings.map((heading) {
                        return DropdownMenuItem(
                          value: heading,
                          child: Text(heading),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedHeading = value;
                      });
                      _searchBoards();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _boards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No boards found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term or heading',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _boards.length,
                  itemBuilder: (context, index) {
                    final board = _boards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(board.tiles.length.toString()),
                        ),
                        title: Text(board.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(board.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(board.heading),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  board.author,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.download, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${board.downloadCount}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _addBoard(board),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
