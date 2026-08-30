import 'package:flutter/material.dart';

import '../data/board_index.dart';
import '../services/board_search_service.dart';
import '../services/external_symbol_service.dart';

/// Popup dialog that lets the user search for a *board* (rather than a word
/// or symbol). Matches are ranked by board name first, then fuzzy name
/// match, then word synonyms, then by boards whose own tiles resemble the
/// query (e.g. searching "rock" also finds a "Musical Genres" board that
/// contains a "rock" tile). Returns the selected board's id via
/// `Navigator.pop`, or null if dismissed.
class BoardSearchDialog extends StatefulWidget {
  final ExternalSymbolService symbolService;
  static const int maxResults = 12;

  const BoardSearchDialog({super.key, required this.symbolService});

  @override
  State<BoardSearchDialog> createState() => _BoardSearchDialogState();
}

class _BoardSearchDialogState extends State<BoardSearchDialog> {
  final _controller = TextEditingController();
  List<BoardIndexEntry> _results = [];
  bool _isSearching = false;
  int _requestId = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final id = ++_requestId;
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    searchBoards(query, symbolService: widget.symbolService, limit: BoardSearchDialog.maxResults)
        .then((results) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search For A Board'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search boards (min. 2 letters)...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: _buildResults(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.text.trim().length < 2) {
      return const Center(
        child: Text('Type at least 2 letters to search for a board.', textAlign: TextAlign.center),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No matching boards found.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final board = _results[index];
        final icon = board.iconAssetPath;
        return ListTile(
          leading: (icon != null && icon.isNotEmpty && icon.startsWith('assets/'))
              ? Image.asset(icon, width: 32, height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.dashboard_outlined))
              : const Icon(Icons.dashboard_outlined),
          title: Text(board.name),
          subtitle: Text(board.area),
          onTap: () => Navigator.of(context).pop(board.id),
        );
      },
    );
  }
}
