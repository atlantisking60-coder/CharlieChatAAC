import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/symbol_tile.dart';
import '../utils/responsive_layout.dart';

typedef SymbolTapCallback = void Function(SymbolTile symbol);
typedef SymbolFavoriteToggle = void Function(SymbolTile symbol);
typedef SymbolAddCallback = void Function(int index);

class SymbolGrid extends StatelessWidget {
  final List<SymbolTile> symbols;
  final Set<String> favoriteIds;
  final SymbolTapCallback onTap;
  final SymbolFavoriteToggle onLongPress;
  final SymbolAddCallback? onAdd;
  final int? fixedRows;
  final int? fixedColumns;
  final bool adjustableLayout;
  final double boxScale;
  final bool highContrast;
  final bool viewOnly;
  final bool scrollable;
  final bool horizontalScroll;
  final ScrollController? controller;

  const SymbolGrid({
    super.key,
    required this.symbols,
    required this.favoriteIds,
    required this.onTap,
    required this.onLongPress,
    this.onAdd,
    this.fixedRows,
    this.fixedColumns,
    this.adjustableLayout = true,
    this.boxScale = 1.0,
    this.highContrast = false,
    this.viewOnly = false,
    this.scrollable = true,
    this.horizontalScroll = false,
    this.controller,
  });

  static final Set<String> _precachedImages = <String>{};

  /// Pre-load the visible board's PNG assets before the grid is painted,
  /// giving the user's chosen board priority in the image cache.
  void _precacheImages(BuildContext context) {
    for (final symbol in symbols) {
      final asset = symbol.imageAsset;
      if (asset.isEmpty) continue;
      if (!asset.startsWith('assets/')) continue;
      if (asset.toLowerCase().endsWith('.svg')) continue;
      if (!_precachedImages.add(asset)) continue;
      unawaited(precacheImage(AssetImage(asset), context));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (symbols.isEmpty) {
      return const Center(child: Text('No symbols found.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _gridLayoutFor(context, constraints, symbols.length);
        final responsive = AacLayoutProvider.maybeOf(context);
        final spacing = responsive?.gridSpacing ?? 10.0;
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final targetTileExtent = (118.0 * boxScale).clamp(82.0, 180.0);
        var childWidth = (maxWidth - (layout.columns + 1) * spacing) / layout.columns;
        if (horizontalScroll && childWidth < targetTileExtent && layout.columns > 5) {
          childWidth = targetTileExtent;
        }
        final totalWidth = layout.columns * childWidth + (layout.columns + 1) * spacing;
        final imageHeight = childWidth - 16;
        final double labelWidth =
            (childWidth - 16).clamp(0.0, double.infinity).toDouble();
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        final maxLabelHeight = symbols.fold<double>(0, (maxHeight, symbol) {
          final painter = TextPainter(
            text: TextSpan(
              text: symbol.label,
              style: TextStyle(
                fontSize: max(14, 12 * symbol.tileSize * boxScale),
                fontWeight: FontWeight.w600,
              ),
            ),
            textAlign: TextAlign.center,
            textDirection: textDirection,
            textScaler: textScaler,
            maxLines: 2,
            ellipsis: '…',
          )..layout(maxWidth: labelWidth);
          return max(maxHeight, painter.height);
        });
        final baseTileHeight = imageHeight + maxLabelHeight + 44;

        final coveredCells = _computeCoveredCells(symbols, layout.columns);
        final List<Widget> positionedTiles = [];
        for (int index = 0; index < symbols.length; index++) {
          if (coveredCells.contains(index)) continue;
          final symbol = symbols[index];
          final row = index ~/ layout.columns;
          final col = index % layout.columns;
          
          final isFavorite = favoriteIds.contains(symbol.id);
          final isBlank = symbol.label.trim().isEmpty && symbol.imageAsset.isEmpty && symbol.emoji.isEmpty;

          Color bg;
          if (symbol.bgColor == 'transparent') {
            bg = Colors.transparent;
          } else if (symbol.bgColor.isNotEmpty && symbol.bgColor.startsWith('#')) {
            try {
              bg = Color(int.parse(symbol.bgColor.replaceFirst('#', '0xFF')));
            } catch (_) {
              bg = Colors.transparent;
            }
          } else {
            bg = Colors.transparent;
          }

          if (symbol.label.toLowerCase().contains('(phonics)') && bg == Colors.transparent) {
            bg = const Color(0xFF7C7B7B);
          }

          Color textCol;
          if (symbol.textColor.isNotEmpty && symbol.textColor != 'transparent' && symbol.textColor.startsWith('#')) {
            try {
              textCol = Color(int.parse(symbol.textColor.replaceFirst('#', '0xFF')));
            } catch (_) {
              textCol = highContrast ? Colors.white : Theme.of(context).colorScheme.onSurface;
            }
          } else {
            textCol = highContrast ? Colors.white : Theme.of(context).colorScheme.onSurface;
          }

          Widget tileChild;
          if (isBlank) {
            if (viewOnly) {
              tileChild = const SizedBox.shrink();
            } else {
              tileChild = Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onAdd?.call(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: highContrast ? Colors.white : Colors.grey.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Center(
                      child: Icon(Icons.add, color: highContrast ? Colors.white : Colors.grey),
                    ),
                  ),
                ),
              );
            }
          } else {
            final imageAsset = symbol.imageAsset;
            Widget symbolImage;
            if (symbol.isBoardLink && imageAsset.isEmpty) {
              symbolImage = Icon(Icons.folder, size: 54 * symbol.tileSize * boxScale, color: textCol);
            } else if (imageAsset.startsWith('http')) {
              if (imageAsset.toLowerCase().endsWith('.svg')) {
                symbolImage = SvgPicture.network(imageAsset, width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain);
              } else {
                symbolImage = Image.network(imageAsset, width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain);
              }
            } else if (imageAsset.startsWith('assets/')) {
              if (imageAsset.toLowerCase().endsWith('.svg')) {
                symbolImage = SvgPicture.asset(imageAsset, width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain);
              } else {
                symbolImage = Image.asset(imageAsset, width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain, errorBuilder: (ctx, err, stack) {
                  if (symbol.isBoardLink) return Icon(Icons.folder, size: 54 * symbol.tileSize * boxScale, color: textCol);
                  return Icon(Icons.broken_image_outlined, size: 48 * symbol.tileSize * boxScale, color: textCol);
                });
              }
            } else if (imageAsset.isNotEmpty) {
              if (kIsWeb || imageAsset.startsWith('blob:') || imageAsset.startsWith('data:')) {
                symbolImage = Image.network(imageAsset, width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain, errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image_outlined, size: 48 * symbol.tileSize * boxScale, color: textCol));
              } else {
                symbolImage = Image.file(File(imageAsset), width: 64 * symbol.tileSize * boxScale, height: 64 * symbol.tileSize * boxScale, fit: BoxFit.contain);
              }
            } else if (symbol.emoji.isNotEmpty) {
              symbolImage = Text(symbol.emoji, style: TextStyle(fontSize: 40 * symbol.tileSize * boxScale));
            } else {
              symbolImage = Icon(Icons.image_not_supported, size: 48, color: highContrast ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant);
            }

            tileChild = Material(
              borderRadius: BorderRadius.circular(16),
              color: bg,
              elevation: highContrast ? 0 : 1,
              shape: highContrast ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white, width: 2)) : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(symbol),
                onLongPress: () => onLongPress(symbol),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: imageHeight * symbol.rowSpan + (symbol.rowSpan > 1 ? (spacing * (symbol.rowSpan - 1) + 8 * (symbol.rowSpan - 1)) : 0),
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(child: FittedBox(fit: BoxFit.contain, child: symbolImage)),
                            Positioned(top: 0, right: 0, child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : (highContrast ? Colors.white : Colors.grey), size: max(14, 16 * boxScale))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(symbol.label, textAlign: TextAlign.center, maxLines: 2 * symbol.rowSpan, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: max(14, 12 * symbol.tileSize * boxScale), fontWeight: FontWeight.w600, color: textCol)),
                    ],
                  ),
                ),
              ),
            );
          }

          positionedTiles.add(Positioned(
            left: spacing + col * (childWidth + spacing),
            top: row * (baseTileHeight + spacing),
            width: childWidth * symbol.colSpan + spacing * (symbol.colSpan - 1),
            height: baseTileHeight * symbol.rowSpan + spacing * (symbol.rowSpan - 1),
            child: tileChild,
          ));
        }

        var maxBottomRow = 0;
        for (int index = 0; index < symbols.length; index++) {
          if (coveredCells.contains(index)) continue;
          final row = index ~/ layout.columns;
          final bottomRow = row + symbols[index].rowSpan - 1;
          if (bottomRow > maxBottomRow) maxBottomRow = bottomRow;
        }
        final numRows = maxBottomRow + 1;
        final totalHeight = numRows * (baseTileHeight + spacing);

        Widget grid = SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(children: positionedTiles),
        );

        _precacheImages(context);
        if (horizontalScroll) {
          Widget scrollableGrid = scrollable
              ? SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: grid,
                )
              : grid;
          final hScroll = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            padding: EdgeInsets.fromLTRB(0, 0, 0, spacing + 12),
            child: scrollableGrid,
          );
          Widget result = hScroll;
          if (controller != null) {
            result = Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: result,
            );
          }
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: result,
          );
        }
        if (!scrollable) return grid;
        return SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(bottom: spacing),
          child: grid,
        );
      },
    );
  }

  _GridLayout _gridLayoutFor(BuildContext context, BoxConstraints constraints, int tileCount) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;

    if (fixedColumns != null && fixedColumns! > 0) {
      return _GridLayout(columns: fixedColumns!);
    }

    // Use responsive layout if available, otherwise fall back to width calc
    final responsive = AacLayoutProvider.maybeOf(context);
    int columns;
    if (responsive != null) {
      // Scale by boxScale but respect fixed board columns if set
      columns = (responsive.gridColumns * boxScale).round().clamp(1, 1000);
    } else {
      final targetTileExtent = (118.0 * boxScale).clamp(82.0, 180.0);
      columns = (width / targetTileExtent).floor().clamp(1, 1000);
    }

    return _GridLayout(columns: columns);
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
}

class _GridLayout {
  final int columns;

  const _GridLayout({
    required this.columns,
  });
}
