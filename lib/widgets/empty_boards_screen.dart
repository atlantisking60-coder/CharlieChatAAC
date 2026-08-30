import 'package:flutter/material.dart';

import '../services/board_service.dart';
import '../services/empty_boards_service.dart';

/// Admin "to-do list" of boards with 3 or fewer populated tiles.
///
/// Tapping a board pops this screen and returns its id so the caller can
/// navigate straight to it. Each row also has a "mark complete" action for
/// boards that are intentionally sparse, and a "delete" action that permanently
/// removes the board without affecting same-name boards in other areas.
class EmptyBoardsScreen extends StatefulWidget {
  const EmptyBoardsScreen({super.key});

  @override
  State<EmptyBoardsScreen> createState() => _EmptyBoardsScreenState();
}

class _EmptyBoardsScreenState extends State<EmptyBoardsScreen> {
  bool _loading = true;
  List<EmptyBoardEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final entries = await EmptyBoardsService.instance.getList(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _markComplete(EmptyBoardEntry entry) async {
    await EmptyBoardsService.instance.markComplete(entry.id);
    if (!mounted) return;
    setState(() {
      _entries = _entries.where((e) => e.id != entry.id).toList();
    });
  }

  Future<void> _deleteBoard(EmptyBoardEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete board?'),
        content: Text(
          '"${entry.name}" (${entry.area}) will be completely removed, '
          'including its source JSON file and any hierarchy entry. '
          'This cannot be undone.\n\n'
          'Boards with the same or a similar name in other areas will NOT be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = await BoardService.getInstance();
      await service.deleteBoardCompletelyById(entry.id);
      if (!mounted) return;
      setState(() {
        _entries = _entries.where((e) => e.id != entry.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${entry.name}" has been permanently deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boards To Finish'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescan all boards',
            onPressed: _loading ? null : () => _load(forceRefresh: true),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No boards with 3 tiles or fewer. Nice work!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return ListTile(
                      title: Text(entry.name),
                      subtitle: Text(
                          '${entry.tileCount} tile${entry.tileCount == 1 ? '' : 's'} used'),
                      onTap: () => Navigator.of(context).pop(entry.id),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Mark as intentionally complete',
                            onPressed: () => _markComplete(entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Permanently delete this board',
                            onPressed: () => _deleteBoard(entry),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
