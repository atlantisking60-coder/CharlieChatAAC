import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/settings_service.dart';
import '../../../services/board_service.dart';
import '../../../services/external_symbol_service.dart';
import '../../../services/image_cleanup_service.dart';
import '../../../services/symbol_metadata_service.dart';
import '../../../data/symbol_data.dart';
import '../settings_widgets.dart';

class _ResponsiveSymbolGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const _ResponsiveSymbolGridDelegate({required this.maxCrossAxisCount})
      : super(crossAxisCount: maxCrossAxisCount, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.82);

  final int maxCrossAxisCount;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisCount = (constraints.crossAxisExtent / 140).floor().clamp(2, maxCrossAxisCount);
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: 140,
      crossAxisStride: 140,
      childMainAxisExtent: 140,
      childCrossAxisExtent: 140,
      reverseCrossAxis: false,
    );
  }
}

class EditSymbolsSection extends StatefulWidget {
  const EditSymbolsSection({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<EditSymbolsSection> createState() => _EditSymbolsSectionState();
}

class _EditSymbolsSectionState extends State<EditSymbolsSection> {
  final _externalSymbolService = ExternalSymbolService();
  late SymbolMetadataService _metadataService;
  List<SymbolTileInfo> _allSymbols = [];
  List<SymbolTileInfo> _filteredSymbols = [];
  bool _loading = true;
  String _query = '';
  int _visibleSymbolCount = 150;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _metadataService = await SymbolMetadataService.init();
    await _loadSymbols();
  }

  Future<void> _loadSymbols() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // 1. Get all assets (limited to a reasonable amount for initial load, 
      // but searching will trigger deeper scans in the service if needed)
      final assetResults = await _externalSymbolService.searchAssets('', limit: 1000);
      final assetTiles = assetResults.map((s) => SymbolTileInfo(
        id: s.id,
        label: s.label,
        imageUrl: s.imageUrl,
        source: s.source,
      )).toList();

      // 2. Get all hardcoded symbols
      final hardcodedTiles = allSymbolTiles.map((s) => SymbolTileInfo(
        id: s.id,
        label: s.label,
        imageUrl: s.imageAsset,
        source: 'Built-in',
      )).toList();

      // 3. Get all symbols currently on boards
      final boardService = await BoardService.getInstance();
      final boards = await boardService.listBoards();
      final boardTiles = <SymbolTileInfo>[];
      for (final b in boards) {
        for (final t in b.tiles) {
          if (t.label.isNotEmpty || t.imageAsset.isNotEmpty) {
            boardTiles.add(SymbolTileInfo(
              id: t.id,
              label: t.label,
              imageUrl: t.imageAsset,
              source: 'Board: ${b.name}',
            ));
          }
        }
      }

      // Merge and deduplicate by ID
      final seen = <String>{};
      _allSymbols = [...boardTiles, ...assetTiles, ...hardcodedTiles].where((s) => seen.add(s.id)).toList();
      
      _filterSymbols();
    } catch (e) {
      debugPrint('Error loading symbols for tagging: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterSymbols() {
    _visibleSymbolCount = 150;
    if (_query.isEmpty) {
      _filteredSymbols = _allSymbols;
    } else {
      final q = _query.toLowerCase();
      _filteredSymbols = _allSymbols.where((s) {
        final labelMatch = s.label.toLowerCase().contains(q);
        final tagMatch = _metadataService.matchesQuery(s.id, q);
        return labelMatch || tagMatch;
      }).toList();
    }
    if (mounted) setState(() {});
  }

  Widget _buildSymbolImage(String path, {double size = 64}) {
    if (path.isEmpty) return Icon(Icons.image, size: size, color: Colors.grey);
    
    if (path.startsWith('http')) {
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(path, width: size, height: size, fit: BoxFit.contain);
      }
      return Image.network(path, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size));
    }
    
    if (path.startsWith('assets/')) {
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain);
      }
      return Image.asset(path, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size));
    }

    if (kIsWeb) {
      return Image.network(path, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size));
    }

    return Image.file(File(path), width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size));
  }

  void _editTags(SymbolTileInfo symbol) async {
    final currentTags = _metadataService.getTags(symbol.id);
    final controller = TextEditingController(text: currentTags.join(', '));

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Tags: ${symbol.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSymbolImage(symbol.imageUrl, size: 100),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'e.g. food, snack, fruit',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text('ID: ${symbol.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cleanSymbolImage(symbol, ImageCleanupMode.background);
            },
            child: const Text('Remove Background'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cleanSymbolImage(symbol, ImageCleanupMode.allWhite);
            },
            child: const Text('Remove All White'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final tags = result.split(',').map((t) => t.trim()).toList();
      await _metadataService.setTags(symbol.id, tags);
      _filterSymbols(); // Refresh list to show tags
    }
  }

  Future<void> _cleanSymbolImage(
    SymbolTileInfo symbol,
    ImageCleanupMode mode,
  ) async {
    if (symbol.imageUrl.isEmpty) return;
    final processedPath =
        await ImageCleanupService().cleanImage(symbol.imageUrl, mode);
    if (processedPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This picture could not be processed.')),
        );
      }
      return;
    }

    final boardService = await BoardService.getInstance();
    final boards = await boardService.listBoards();
    var updatedTiles = 0;
    for (final board in boards) {
      var changed = false;
      for (final tile in board.tiles) {
        if (tile.imageAsset == symbol.imageUrl) {
          tile.imageAsset = processedPath;
          changed = true;
          updatedTiles++;
        }
      }
      if (changed) await boardService.saveBoard(board);
    }

    if (!mounted) return;
    await _loadSymbols();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedTiles == 0
              ? 'Processed a copy. Add the symbol to a board to use it.'
              : 'Updated $updatedTiles board ${updatedTiles == 1 ? 'tile' : 'tiles'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.edit_note_rounded,
          title: 'Edit Symbols',
          subtitle: 'Add tags to any symbol to make it easier to find in searches.',
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: TextField(
            onChanged: (v) {
              _query = v;
              _filterSymbols();
            },
            decoration: InputDecoration(
              hintText: 'Search symbols to tag...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
            ),
          ),
        ),

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (_filteredSymbols.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No symbols found matching your search.')))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const _ResponsiveSymbolGridDelegate(maxCrossAxisCount: 6),
            itemCount: _filteredSymbols.length.clamp(0, _visibleSymbolCount),
            itemBuilder: (context, index) {
              final symbol = _filteredSymbols[index];
              final tags = _metadataService.getTags(symbol.id);
              
              return InkWell(
                onTap: () => _editTags(symbol),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: tags.isNotEmpty ? cs.primary : cs.outlineVariant,
                      width: tags.isNotEmpty ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: tags.isNotEmpty ? cs.primary.withValues(alpha: 0.05) : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _buildSymbolImage(symbol.imageUrl, size: 52),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: Column(
                          children: [
                            Text(
                              symbol.label.isEmpty ? '[No Label]' : symbol.label,
                              style: TextStyle(
                                fontSize: 10.5, 
                                fontWeight: tags.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tags.isNotEmpty)
                              Text(
                                tags.join(', '),
                                style: TextStyle(fontSize: 8.5, color: cs.primary, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                symbol.source,
                                style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        if (_filteredSymbols.length > _visibleSymbolCount)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _visibleSymbolCount = (_visibleSymbolCount + 75).clamp(0, _filteredSymbols.length);
                  });
                },
                child: Text(_visibleSymbolCount >= _filteredSymbols.length ? 'Showing all results' : 'Show more'),
              ),
            ),
          ),
      ],
    );
  }
}

class SymbolTileInfo {
  final String id;
  final String label;
  final String imageUrl;
  final String source;

  SymbolTileInfo({required this.id, required this.label, required this.imageUrl, required this.source});
}
