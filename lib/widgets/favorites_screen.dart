import 'dart:math';

import 'package:flutter/material.dart';

import '../models/symbol_tile.dart';
import 'symbol_grid.dart';

typedef SymbolTapCallback = void Function(SymbolTile symbol);
typedef SymbolFavoriteToggle = void Function(SymbolTile symbol);

class FavoritesScreen extends StatelessWidget {
  final List<SymbolTile> favoriteTiles;
  final Set<String> favoriteIds;
  final SymbolTapCallback onTap;
  final SymbolFavoriteToggle onToggleFavorite;

  // Ensure we always show at least 4 tiles (padding with blank tiles if needed).
  FavoritesScreen({
    super.key,
    required this.favoriteTiles,
    required this.favoriteIds,
    required this.onTap,
    required this.onToggleFavorite,
  }) : _paddedTiles = _padTiles(favoriteTiles);

  List<SymbolTile> _padTiles(List<SymbolTile> tiles) {
    final result = List<SymbolTile>.from(tiles);
    while (result.length < 4) {
      result.add(_blankTile());
    }
    return result;
  }

  SymbolTile _blankTile() {
    return SymbolTile(
      label: '',
      imageAsset: '',
      emoji: '',
      type: TileType.blank,
    );
  }

  List<SymbolTile> get paddedTiles => _paddedTiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: paddedTiles.isEmpty
          ? const Center(child: Text('No favorites yet. Long-press a symbol to add it.'))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Tap a symbol to add it to your phrase. Long-press to remove from favorites.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: SymbolGrid(
                      symbols: paddedTiles,
                      favoriteIds: favoriteIds,
                      onTap: onTap,
                      onLongPress: (symbol) {
                        // Show confirmation dialog before removing from favorites
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove from Favorites'),
                            content: Text('Remove "${symbol.label}" from your favorites?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  onToggleFavorite(symbol);
                                },
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
