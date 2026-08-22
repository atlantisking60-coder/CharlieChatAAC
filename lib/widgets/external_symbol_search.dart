import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/symbol_tile.dart';
import '../services/board_service.dart';
import '../services/external_symbol_service.dart';
import '../services/profile_service.dart';
import 'symbol_grid.dart';

class ExternalSymbolSearchScreen extends StatefulWidget {
  final void Function(SymbolTile symbol) onAdd;
  final String? initialLabel;
  final List<String>? preferredSets;

  const ExternalSymbolSearchScreen({super.key, required this.onAdd, this.initialLabel, this.preferredSets});

  @override
  State<ExternalSymbolSearchScreen> createState() => _ExternalSymbolSearchScreenState();
}

class _ExternalSymbolSearchScreenState extends State<ExternalSymbolSearchScreen> {
  final _queryController = TextEditingController();
  final _providerScrollController = ScrollController();
  final _service = ExternalSymbolService();
  final _providers = [
    'All Libraries',
    'Assets',
    'ARASAAC',
    'OpenSymbols',
    'GlobalSymbols',
    'Mulberry',
    'Sclera',
    'Widgit',
    'Makaton',
    'Snap Core',
    'Tobii Dynavox'
  ];
  String _selectedProvider = 'Assets';
  bool _loading = false;
  String? _error;
  List<ExternalSymbol> _results = [];
  int _currentLimit = 30;
  bool _hasMore = true;
  Timer? _debounce;
  bool _isAdmin = false;
  ExternalSymbol? _mergeSource;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    final initialLabel = widget.initialLabel;
    if (initialLabel != null && initialLabel.isNotEmpty) {
      _queryController.text = initialLabel;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _providerScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final profileService = await ProfileService.init();
    setState(() {
      _isAdmin = profileService.activeProfile.isAdmin;
    });
  }

  Future<void> _showAssetMenu(ExternalSymbol symbol) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.merge_type, color: Colors.blue),
              title: const Text('Merge with another picture'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _mergeSource = symbol;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Now select the picture you want to keep.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete from project assets'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteAsset(symbol);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers_clear, color: Colors.orange),
              title: const Text('Remove white background'),
              onTap: () {
                Navigator.pop(ctx);
                _removeBackground(symbol);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeBackground(ExternalSymbol symbol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Background?'),
        content: const Text('This will attempt to make the white background transparent. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Process')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        final success = await _service.removeWhiteBackground(symbol.imageUrl);
        if (success) {
           // We need to bust the image cache to see changes
           PaintingBinding.instance.imageCache.clear();
           PaintingBinding.instance.imageCache.clearLiveImages();
           
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Background removed successfully.')),
             );
           }
        }
      } catch (e) {
        debugPrint('Remove background error: $e');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmMerge(ExternalSymbol source, ExternalSymbol target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge Pictures?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will replace all usages of the first picture with the second one and delete the first file.'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                   SizedBox(width: 60, height: 60, child: Image.network(source.imageUrl, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))),
                   const Text('OLD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
                const Icon(Icons.arrow_forward),
                Column(children: [
                   SizedBox(width: 60, height: 60, child: Image.network(target.imageUrl, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))),
                   const Text('KEEP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                ]),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        final boardService = await BoardService.getInstance();
        await boardService.mergeAssets(source.imageUrl, target.imageUrl);
        setState(() {
          _results.removeWhere((r) => r.imageUrl == source.imageUrl);
          _mergeSource = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Merge successful. All boards updated.')),
          );
        }
      } catch (e) {
        debugPrint('Merge error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Merge failed: $e')),
          );
        }
      } finally {
        setState(() => _loading = false);
      }
    } else {
      setState(() => _mergeSource = null);
    }
  }

  Future<void> _deleteAsset(ExternalSymbol symbol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: Text('Are you sure you want to permanently delete "${symbol.label}" from the project assets? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final boardService = await BoardService.getInstance();
      await boardService.deleteAssetGlobally(symbol.imageUrl);
      
      setState(() {
        _results.removeWhere((r) => r.imageUrl == symbol.imageUrl);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted globally from all boards.')),
        );
      }
    }
  }

  Future<List<ExternalSymbol>> _searchMultiple(
    List<String> queries,
    Future<List<ExternalSymbol>> Function(String) searcher,
  ) async {
    final seenUrls = <String>{};
    final combined = <ExternalSymbol>[];
    for (final q in queries) {
      try {
        final results = await searcher(q);
        for (final r in results) {
          if (seenUrls.add(r.imageUrl)) combined.add(r);
        }
      } catch (_) {}
    }
    return combined;
  }

  Future<void> _search({bool loadMore = false}) async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    if (_selectedProvider == 'Mulberry' || _selectedProvider == 'Sclera') {
      _openWebSearch(query);
      return;
    }

    if (!loadMore) {
      setState(() {
        _loading = true;
        _error = null;
        _results = [];
        _currentLimit = 30;
        _hasMore = true;
      });
    } else {
      setState(() {
        _loading = true;
      });
    }

    try {
      List<ExternalSymbol> results;
      if (_selectedProvider == 'All Libraries') {
        results = await _service.searchAll(query, limit: _currentLimit, preferredSets: widget.preferredSets);
      } else if (_selectedProvider == 'Assets') {
        results = await _service.searchAssets(query, limit: _currentLimit);
      } else {
        // Single-provider searches also use synonyms
        final alts = _service.expandedQueries(query);
        final queries = [query, ...alts];
        if (_selectedProvider == 'ARASAAC') {
          results = await _searchMultiple(queries, (q) => _service.searchArasaac(q, limit: _currentLimit));
        } else if (_selectedProvider == 'OpenSymbols') {
          results = await _searchMultiple(queries, (q) => _service.searchOpenSymbols(q, limit: _currentLimit));
        } else if (_selectedProvider == 'GlobalSymbols') {
          results = await _searchMultiple(queries, (q) => _service.searchGlobalSymbols(q, limit: _currentLimit));
        } else if (_selectedProvider == 'Widgit') {
          results = await _searchMultiple(queries, (q) => _service.searchWidgit(q, limit: _currentLimit));
        } else if (_selectedProvider == 'Makaton') {
          results = await _searchMultiple(queries, (q) => _service.searchOpenSymbols(q, limit: _currentLimit, repo: 'makaton'));
        } else if (_selectedProvider == 'Snap Core') {
          results = await _searchMultiple(queries, (q) => _service.searchOpenSymbols(q, limit: _currentLimit, repo: 'snap-core'));
        } else if (_selectedProvider == 'Tobii Dynavox') {
          results = await _searchMultiple(queries, (q) => _service.searchOpenSymbols(q, limit: _currentLimit, repo: 'tobii-dynavox'));
        } else {
          results = [];
        }
      }
      
      // Filter out NSFW words unless the query itself is one of those exact words
      const blockedWords = {'penis', 'vagina', 'breasts'};
      final qLower = query.toLowerCase();
      final queryIsBlocked = blockedWords.contains(qLower);
      if (!queryIsBlocked) {
        results = results.where((s) {
          final label = s.label.toLowerCase();
          return !blockedWords.any((w) => label.contains(w));
        }).toList();
      }

      results = _service.sortByRelevance(results, query, preferredSets: widget.preferredSets);
      setState(() {
        _results = results;
        _hasMore = results.length >= _currentLimit;
      });
    } catch (exception) {
      setState(() {
        _error = exception.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    _currentLimit += 30;
    await _search(loadMore: true);
  }

  Future<void> _openWebSearch(String query) async {
    final link = _service.libraryLinks.firstWhere(
      (link) => link.name.toLowerCase().contains(_selectedProvider.toLowerCase()),
      orElse: () => _service.libraryLinks.first,
    );

    final uri = link.uriForQuery(query);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open external search.')),
        );
      }
    }
  }

  bool _isIntegratedProvider(String provider) {
    return provider == 'All Libraries' ||
        provider == 'Assets' ||
        provider == 'ARASAAC' ||
        provider == 'OpenSymbols' ||
        provider == 'GlobalSymbols' ||
        provider == 'Widgit';
  }

  @override
  Widget build(BuildContext context) {
    final isIntegrated = _isIntegratedProvider(_selectedProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search online symbols'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SingleChildScrollView(
              controller: _providerScrollController,
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  _providerScrollController.jumpTo(
                    _providerScrollController.position.pixels - details.delta.dx,
                  );
                },
                child: Row(
                  children: _providers.map((provider) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(provider),
                      selected: _selectedProvider == provider,
                      onSelected: (_) {
                        setState(() {
                          _selectedProvider = provider;
                          _results = [];
                          _error = null;
                        });
                        final query = _queryController.text.trim();
                        if (query.length >= 2 && _isIntegratedProvider(provider)) {
                          _search();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search for $_selectedProvider ...',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final query = value.trim();
                      if (query.length >= 2 && isIntegrated) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () => _search());
                      }
                    },
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isIntegrated)
              const Text('Tap a symbol to select it for your board.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            if (_error != null && _results.isEmpty)
              Expanded(
                child: Center(
                  child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                ),
              )
            else if (isIntegrated)
              Expanded(
                child: Column(
                  children: [
                    if (_mergeSource != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.merge_type, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Merging mode: Tap the image you want to KEEP.')),
                            TextButton(
                              onPressed: () => setState(() => _mergeSource = null),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    if (_loading && _results.isEmpty)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else
                      Expanded(
                        child: _results.isEmpty
                            ? Center(child: _loading ? const CircularProgressIndicator() : const Text('Enter a term above to find integrated symbols.'))
                            : SymbolGrid(
                              symbols: _results.map((result) => result.toSymbolTile()).toList(),
                              favoriteIds: const {},
                              onTap: (symbol) {
                                if (_mergeSource != null) {
                                  try {
                                    final target = _results.firstWhere((r) => r.imageUrl == symbol.imageAsset);
                                    if (target.imageUrl != _mergeSource!.imageUrl) {
                                      _confirmMerge(_mergeSource!, target);
                                    }
                                  } catch (_) {}
                                } else {
                                  Navigator.of(context).pop(symbol);
                                }
                              },
                              onLongPress: (symbol) {
                                if (_isAdmin) {
                                  try {
                                    final ext = _results.firstWhere((r) => r.imageUrl == symbol.imageAsset);
                                    if (ext.source == 'Assets') {
                                      _showAssetMenu(ext);
                                    }
                                  } catch (_) {}
                                }
                              },
                            ),
                    ),
                    if (_loading && _results.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_results.isNotEmpty && _hasMore)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _loadMore,
                          child: const Text('Load More'),
                        ),
                      ),
                    if (_error != null && _results.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('$_selectedProvider does not have a public search API.', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Searching will open a browser window.', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
