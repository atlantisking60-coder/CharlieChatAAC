import '../data/board_index.dart';
import 'board_service.dart';
import 'external_symbol_service.dart';

/// Searches for boards by name, fuzzy name match, curated word synonyms, and
/// (as a last resort) by the actual tile content of boards — e.g. searching
/// "rock" surfaces the "Rocks" board by name, and also boards like "Musical
/// Genres" that merely contain a "rock" tile, without needing a hand-written
/// synonym list for every possible word.
///
/// Results are returned in relevance tiers (exact/name match first, then
/// fuzzy name match, then synonym-expanded name match, then content match),
/// each tier sorted alphabetically, capped at [limit] total results.
Future<List<BoardIndexEntry>> searchBoards(
  String query, {
  required ExternalSymbolService symbolService,
  int limit = 12,
}) async {
  final q = query.trim().toLowerCase();
  if (q.length < 2) return const [];

  // De-duplicate the compiled index by id (keeps the first occurrence),
  // and filter out boards that belong to a different profile.
  final boardService = await BoardService.getInstance();
  final byId = <String, BoardIndexEntry>{};
  for (final entry in staticBoardIndex) {
    if (!boardService.isBoardIdVisible(entry.id)) continue;
    byId.putIfAbsent(entry.id, () => entry);
  }
  final candidates = byId.values.toList();

  final seen = <String>{};
  final results = <BoardIndexEntry>[];

  void addAll(Iterable<BoardIndexEntry> entries) {
    for (final e in entries) {
      if (seen.add(e.id)) results.add(e);
    }
  }

  int byName(BoardIndexEntry a, BoardIndexEntry b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  // Tier 1: the board's own name contains the query (or the query is an
  // exact/near-exact match of the name).
  final tier1 = candidates.where((b) => b.name.toLowerCase().contains(q)).toList()
    ..sort((a, b) {
      final an = a.name.toLowerCase();
      final bn = b.name.toLowerCase();
      final aExact = an == q ? 0 : (an.startsWith(q) ? 1 : 2);
      final bExact = bn == q ? 0 : (bn.startsWith(q) ? 1 : 2);
      if (aExact != bExact) return aExact.compareTo(bExact);
      return byName(a, b);
    });
  addAll(tier1);

  // Tier 2: fuzzy match tolerant of missing/extra vowels (typos), same
  // technique used by the existing board picker dialog.
  String collapseVowels(String s) => s.toLowerCase().replaceAll(RegExp(r'[aeiouy]'), '*');
  final qCollapsed = collapseVowels(q);
  final tier2 = candidates
      .where((b) => !seen.contains(b.id) && collapseVowels(b.name).contains(qCollapsed))
      .toList()
    ..sort(byName);
  addAll(tier2);

  // Tier 3: the query has a curated synonym (e.g. "toilet" <-> "bathroom")
  // whose alternate word appears in a board name.
  final expansions = symbolService.expandedQueries(q);
  if (expansions.isNotEmpty) {
    final tier3 = candidates
        .where((b) =>
            !seen.contains(b.id) &&
            expansions.any((alt) => b.name.toLowerCase().contains(alt)))
        .toList()
      ..sort(byName);
    addAll(tier3);
  }

  // Tier 4: content match — boards aren't named after the query, but one of
  // their own tiles is. We reuse the already-prewarmed project-wide asset
  // filename index (built for the word/symbol search bar) rather than
  // loading every board's tiles, which would be far too slow. Each board's
  // tile images conventionally live in a folder named exactly after that
  // board (e.g. ".../Musical Genres/rock.png"), so a matching filename's
  // parent folder name reliably identifies the owning board.
  if (results.length < limit) {
    final nameIndex = <String, BoardIndexEntry>{
      for (final b in candidates) b.name.toLowerCase(): b,
    };
    final terms = <String>{q, ...expansions};
    final allAssets = await symbolService.searchAssets('', limit: 1 << 20);

    final matchCounts = <String, int>{};
    for (final asset in allAssets) {
      final filename = asset.label.toLowerCase();
      if (!terms.any((t) => filename.contains(t))) continue;
      final parts = asset.imageUrl.split('/');
      if (parts.length < 2) continue;
      final folder = parts[parts.length - 2].toLowerCase();
      final board = nameIndex[folder];
      if (board == null || seen.contains(board.id)) continue;
      matchCounts[board.id] = (matchCounts[board.id] ?? 0) + 1;
    }

    final tier4 = matchCounts.keys.map((id) => byId[id]!).toList()
      ..sort((a, b) {
        final countCompare = (matchCounts[b.id] ?? 0).compareTo(matchCounts[a.id] ?? 0);
        if (countCompare != 0) return countCompare;
        return byName(a, b);
      });
    addAll(tier4);
  }

  return results.take(limit).toList();
}
