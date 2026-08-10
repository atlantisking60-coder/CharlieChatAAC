import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../data/board_icon_assets.dart';
import '../data/board_icon_mappings.dart';
import '../data/symbol_icon_assets.dart';
import 'board_service.dart';

String _sanitizeIconAssetPath(String path) {
  try {
    // Decode twice to undo accidental double-encoding (e.g. %2520 -> space).
    return Uri.decodeFull(Uri.decodeFull(path));
  } catch (_) {
    return path;
  }
}

String? _findKeyIgnoreCase(Map<String, List<String>> map, String query) {
  for (final key in map.keys) {
    if (key.toLowerCase() == query) return key;
  }
  return null;
}

String _bestBoardIconPath(String boardName, List<String> paths) {
  final lower = boardName.toLowerCase();
  // Prefer an exact file-name match
  for (final path in paths) {
    final fileName = p.basenameWithoutExtension(path).toLowerCase().trim();
    if (fileName == lower) return _sanitizeIconAssetPath(path);
  }
  // Otherwise prefer the shortest (least nested) path
  final sorted = List<String>.from(paths)..sort((a, b) => a.length.compareTo(b.length));
  return _sanitizeIconAssetPath(sorted.first);
}

String _resolveIconAssetPath(String name, String? existing) {
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final boardName = name;
  final searchName = boardName.toLowerCase().trim();

  // Try the symbol library first (non-BOARDS assets)
  final symbolKey = _findKeyIgnoreCase(symbolIconAssetMap, searchName);
  if (symbolKey != null) {
    return _bestBoardIconPath(symbolKey, symbolIconAssetMap[symbolKey]!);
  }

  final clean = searchName.replaceAll(RegExp(r'[(){}\[\].,!?;:"/#@$%^&*]'), '').trim();
  if (clean.isNotEmpty) {
    final cleanSymbolKey = _findKeyIgnoreCase(symbolIconAssetMap, clean);
    if (cleanSymbolKey != null) {
      return _bestBoardIconPath(cleanSymbolKey, symbolIconAssetMap[cleanSymbolKey]!);
    }
  }

  String? bestSymbolKey;
  int bestSymbolScore = 0;
  for (final key in symbolIconAssetMap.keys) {
    final keyLower = key.toLowerCase();
    if (keyLower.contains(searchName) ||
        searchName.contains(keyLower) ||
        (clean.isNotEmpty && (keyLower.contains(clean) || clean.contains(keyLower)))) {
      if (key.length > bestSymbolScore) {
        bestSymbolScore = key.length;
        bestSymbolKey = key;
      }
    }
  }
  if (bestSymbolKey != null) {
    return _bestBoardIconPath(bestSymbolKey, symbolIconAssetMap[bestSymbolKey]!);
  }

  // Fall back to the BOARDS folder-style icons
  final boardKey = _findKeyIgnoreCase(boardIconAssetMap, searchName);
  if (boardKey != null) {
    return _bestBoardIconPath(boardKey, boardIconAssetMap[boardKey]!);
  }

  if (clean.isNotEmpty) {
    final cleanBoardKey = _findKeyIgnoreCase(boardIconAssetMap, clean);
    if (cleanBoardKey != null) {
      return _bestBoardIconPath(cleanBoardKey, boardIconAssetMap[cleanBoardKey]!);
    }
  }

  String? bestBoardKey;
  int bestBoardScore = 0;
  for (final key in boardIconAssetMap.keys) {
    final keyLower = key.toLowerCase();
    if (keyLower.contains(searchName) ||
        searchName.contains(keyLower) ||
        (clean.isNotEmpty && (keyLower.contains(clean) || clean.contains(keyLower)))) {
      if (key.length > bestBoardScore) {
        bestBoardScore = key.length;
        bestBoardKey = key;
      }
    }
  }
  if (bestBoardKey != null) {
    return _bestBoardIconPath(bestBoardKey, boardIconAssetMap[bestBoardKey]!);
  }

  // Specific manual overrides
  final upperBoardName = boardName.toUpperCase();
  for (final entry in boardIconMappings.entries) {
    if (entry.key.toUpperCase() == upperBoardName) {
      return _sanitizeIconAssetPath(entry.value);
    }
  }

  // Last resort: construct a path from the BOARDS directory
  final fileName = boardName;
  return _sanitizeIconAssetPath('assets/BOARDS/$fileName.png');
}

String resolveBoardIconAssetPath(Board board) =>
    _resolveIconAssetPath(board.name, board.iconAssetPath);

String resolveTileIconAssetPath(Board board) =>
    _resolveIconAssetPath(board.name, board.tileIconAssetPath);

/// Renders a board tab icon from an asset path, a remote URL, or a base64
/// data URI. If the path cannot be loaded, [fallback] is shown.
Widget buildBoardIconImage(
  String? path, {
  double size = 18,
  Color? color,
  Widget? fallback,
}) {
  if (path == null || path.isEmpty) {
    return fallback ?? Icon(Icons.image, size: size, color: color);
  }

  final lower = path.toLowerCase();

  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Image.network(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback ?? Icon(Icons.image, size: size, color: color),
    );
  }

  if (lower.startsWith('data:')) {
    // Decode a base64 data URI if the platform provides one.
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'data' && uri.data != null) {
      return Image.memory(
        uri.data!.contentAsBytes(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback ?? Icon(Icons.image, size: size, color: color),
      );
    }
  }

  if (!kIsWeb && !lower.startsWith('assets/')) {
    return Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback ?? Icon(Icons.image, size: size, color: color),
    );
  }

  // On the web, serve assets directly from the dev server / production host
  // to avoid Flutter Web's AssetManifest percent-encoding issues.
  if (kIsWeb && lower.startsWith('assets/')) {
    final url = Uri.base.resolve(Uri.encodeFull(path)).toString();
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback ?? Icon(Icons.image, size: size, color: color),
    );
  }

  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => fallback ?? Icon(Icons.image, size: size, color: color),
  );
}
