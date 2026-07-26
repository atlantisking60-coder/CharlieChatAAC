// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String projectRoot = r'C:\Users\Craig\Downloads\Charlie Chat';
final String boardsDir = '$projectRoot\\lib\\data\\boards';

Future<List<String>> searchArasaac(String query) async {
  final uri = Uri.https(
    'api.arasaac.org',
    '/api/pictograms/en/search/${Uri.encodeComponent(query)}',
  );
  try {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) return [];
    final body = await response.transform(utf8.decoder).join();
    final decoded = json.decode(body);
    if (decoded is! List) return [];
    final results = <String>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final id = entry['_id']?.toString() ?? entry['id']?.toString();
        if (id != null && id.isNotEmpty) {
          results.add('https://static.arasaac.org/pictograms/$id/${id}_300.png');
        }
      }
      if (results.length >= 5) break;
    }
    client.close(force: true);
    return results;
  } catch (e) {
    print('Arasaac error for "$query": $e');
    return [];
  }
}

Future<List<String>> searchOpenSymbols(String query) async {
  final uri = Uri.https(
    'www.opensymbols.org',
    '/api/v1/symbols/search',
    {'q': query},
  );
  try {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) return [];
    final body = await response.transform(utf8.decoder).join();
    final decoded = json.decode(body);
    if (decoded is! List) return [];
    final results = <String>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final imageUrl = entry['image_url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          results.add(imageUrl);
        }
      }
      if (results.length >= 5) break;
    }
    client.close(force: true);
    return results;
  } catch (e) {
    print('OpenSymbols error for "$query": $e');
    return [];
  }
}

Future<String?> findOnlineImage(String label) async {
  if (label.trim().isEmpty) return null;
  final queries = <String>[label];
  // Try base label without parenthetical content
  final base = label.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  if (base != label && base.isNotEmpty) queries.add(base);

  for (final query in queries) {
    final arasaac = await searchArasaac(query);
    if (arasaac.isNotEmpty) return arasaac.first;
    final openSymbols = await searchOpenSymbols(query);
    if (openSymbols.isNotEmpty) return openSymbols.first;
  }
  return null;
}

void main() async {
  final boardDir = Directory(boardsDir);
  final files = boardDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.json')).toList();
  var filled = 0;
  var attempted = 0;

  for (final file in files) {
    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final tiles = (data['tiles'] as List<dynamic>).cast<Map<String, dynamic>>();
    var changed = false;

    for (final tile in tiles) {
      final type = tile['type'] as String? ?? 'vocabulary';
      if (type == 'blank') continue;
      final label = (tile['label'] as String?) ?? '';
      if (label.isEmpty) continue;
      final image = tile['image'] as String?;
      if (image != null && image.isNotEmpty) continue;

      attempted++;
      print('Searching online for "$label"...');
      final url = await findOnlineImage(label);
      if (url != null) {
        tile['image'] = url;
        changed = true;
        filled++;
        print('  ${file.path.split('\\').last}: "$label" -> $url');
      } else {
        print('  ${file.path.split('\\').last}: "$label" -> not found online');
      }
    }

    if (changed) {
      file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
      print('Saved ${file.path}');
    }
  }

  print('Attempted $attempted missing tiles, filled $filled with online images.');
}
