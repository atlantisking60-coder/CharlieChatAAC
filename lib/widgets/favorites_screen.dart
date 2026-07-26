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

  const FavoritesScreen({
    super.key,
    required this.favoriteTiles,
    required this.favoriteIds,
    required this.onTap,
    required this.onToggleFavorite,
  });

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
      body: favoriteTiles.isEmpty
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
                      symbols: favoriteTiles,
                      favoriteIds: favoriteIds,
                      onTap: onTap,
                      onLongPress: onToggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
