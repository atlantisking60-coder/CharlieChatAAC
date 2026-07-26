// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

const defaultPort = 8787;

String _folderName(String name) => name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

Future<File?> _findBoardFile(Directory root, String id) async {
  if (!await root.exists()) return null;
  await for (final entity in root.list(recursive: true)) {
    if (entity is File && p.basename(entity.path) == '$id.json') return entity;
  }
  return null;
}

Future<Directory> _boardDirectory(Directory root, Map<String, dynamic> data) async {
  final area = data['area'] as String? ?? 'Common';
  final name = data['name'] as String? ?? 'Board';
  final parentId = data['parentBoardId'] as String?;
  final areaRoot = Directory(p.join(root.path, area));
  Directory? parent;
  if (parentId != null && parentId.isNotEmpty) {
    final parentFile = await _findBoardFile(root, parentId);
    if (parentFile != null) parent = parentFile.parent;
  }

  final tier = (data['tier'] as num?)?.toInt() ?? 1;
  if (parent == null && tier > 1) {
    if (!await areaRoot.exists()) await areaRoot.create(recursive: true);
    return areaRoot;
  }

  final directory = Directory(p.join((parent ?? areaRoot).path, _folderName(name)));
  if (!await directory.exists()) await directory.create(recursive: true);
  return directory;
}

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? defaultPort : defaultPort;
  
  // Robust project root detection: 
  // If we are in the 'tools' directory, go up one level.
  var projectRoot = Directory.current.path;
  if (p.basename(projectRoot) == 'tools') {
    projectRoot = p.dirname(projectRoot);
  } else if (!Directory(p.join(projectRoot, 'lib')).existsSync()) {
    // Fallback: check if 'lib' exists one level up
    final parent = p.dirname(projectRoot);
    if (Directory(p.join(parent, 'lib')).existsSync()) {
      projectRoot = parent;
    }
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

  print('Charlie Chat dev save server listening on http://localhost:$port');
  print('Project root: $projectRoot');
  print('Board edits from the web preview will be written to lib/data/boards/[Area]/');

  await for (final request in server) {
    final response = request.response;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      await response.close();
      continue;
    }

    if (request.method == 'GET' && request.uri.path == '/listBoards') {
      try {
        final root = Directory('$projectRoot/lib/data/boards');
        final boards = <Map<String, dynamic>>[];
        if (await root.exists()) {
          await for (final entity in root.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.json')) {
              try {
                final content = await entity.readAsString();
                boards.add(json.decode(content) as Map<String, dynamic>);
              } catch (_) {}
            }
          }
        }
        response.statusCode = 200;
        response.headers.contentType = ContentType.json;
        response.write(json.encode(boards));
      } catch (e) {
        response.statusCode = 500;
        response.write(json.encode({'ok': false, 'error': e.toString()}));
      }
      await response.close();
      continue;
    }

    if (request.method == 'GET' && request.uri.path == '/loadBoard') {
      try {
        final id = request.uri.queryParameters['id'];
        final area = request.uri.queryParameters['area'];
        if (id == null) {
          response.statusCode = 400;
          response.write(json.encode({'ok': false, 'error': 'Missing id'}));
        } else {
          File? foundFile;
          // 1. Try provided area first
          if (area != null && area.isNotEmpty) {
            final areaFile = File('$projectRoot/lib/data/boards/$area/$id.json');
            if (await areaFile.exists()) {
              foundFile = areaFile;
            }
          }
          
          // 2. Search all subdirectories if not found
          if (foundFile == null) {
            final root = Directory('$projectRoot/lib/data/boards');
            if (await root.exists()) {
              await for (final entity in root.list(recursive: true)) {
                if (entity is File && entity.path.endsWith('$id.json')) {
                  foundFile = entity;
                  break;
                }
              }
            }
          }

          if (foundFile != null && await foundFile.exists()) {
            response.statusCode = 200;
            response.headers.contentType = ContentType.json;
            response.write(await foundFile.readAsString());
          } else {
            response.statusCode = 404;
            response.write(json.encode({'ok': false, 'error': 'Board not found on disk'}));
          }
        }
      } catch (e) {
        response.statusCode = 500;
        response.write(json.encode({'ok': false, 'error': e.toString()}));
      }
      await response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/deleteBoard') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final id = data['id'] as String?;
        final area = data['area'] as String?;

        if (id == null || area == null || id.isEmpty || area.isEmpty) {
          response.statusCode = 400;
          response.write(json.encode({'ok': false, 'error': 'Missing id or area'}));
        } else {
          final root = Directory('$projectRoot/lib/data/boards');
          final file = await _findBoardFile(root, id);
          if (file != null) {
            await file.delete();
            print('Deleted ${file.path}');
          }
          response.statusCode = 200;
          response.write(json.encode({'ok': true}));
        }
      } catch (e, st) {
        print('Error deleting board: $e\n$st');
        response.statusCode = 500;
        response.write(json.encode({'ok': false, 'error': e.toString()}));
      }
      await response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/saveImage') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final filename = data['filename'] as String?;
        final base64Data = data['data'] as String?;

        if (filename == null || base64Data == null) {
          response.statusCode = 400;
          response.write(json.encode({'ok': false, 'error': 'Missing filename or data'}));
        } else {
          final dir = Directory('$projectRoot/assets/symbols/Custom');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          // Requirement: if an image that already exists in our Assets Library, the app should use the existing Image.
          // We check by filename.
          final file = File('${dir.path}/$filename');
          if (await file.exists()) {
            print('Using existing image ${file.path}');
            response.statusCode = 200;
            response.write(json.encode({'ok': true, 'path': 'assets/symbols/Custom/$filename'}));
          } else {
            final bytes = base64Decode(base64Data.contains(',') ? base64Data.split(',').last : base64Data);
            await file.writeAsBytes(bytes);
            print('Saved new image ${file.path}');
            response.statusCode = 200;
            response.write(json.encode({'ok': true, 'path': 'assets/symbols/Custom/$filename'}));
          }
        }
      } catch (e, st) {
        print('Error saving image: $e\n$st');
        response.statusCode = 500;
        response.write(json.encode({'ok': false, 'error': e.toString()}));
      }
      await response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/backupBoard') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = json.decode(body) as Map<String, dynamic>;

        final backupBase = Directory('$projectRoot/BACKUP BOARDS');
        if (!await backupBase.exists()) {
          await backupBase.create(recursive: true);
        }

        final now = DateTime.now();
        final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
        final id = data['id']?.toString() ?? 'unknown';
        final name = data['name']?.toString() ?? '';
        final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '').replaceAll(' ', '_');
        final filename = '${id}_${safeName}_$ts.json';

        final file = File('${backupBase.path}/$filename');
        await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
        print('Backup saved ${file.path}');

        response.statusCode = 200;
        response.write(json.encode({'ok': true, 'path': file.path}));
      } catch (e, st) {
        print('Error backing up board: $e\n$st');
        response.statusCode = 500;
        response.write(json.encode({'ok': false, 'error': e.toString()}));
      }
      await response.close();
      continue;
    }

    if (request.method != 'POST' || request.uri.path != '/saveBoard') {
      response.statusCode = 404;
      response.write(json.encode({'ok': false, 'error': 'Not found'}));
      await response.close();
      continue;
    }

    try {
      final body = await utf8.decoder.bind(request).join();
      final data = json.decode(body) as Map<String, dynamic>;
      final allowContentReduction = data['allowContentReduction'] as bool? ?? true;
      final id = data['id'] as String?;
      final area = data['area'] as String?;

      if (id == null || area == null || id.isEmpty || area.isEmpty) {
        response.statusCode = 400;
        response.write(json.encode({'ok': false, 'error': 'Missing id or area'}));
        await response.close();
        continue;
      }

      final root = Directory('$projectRoot/lib/data/boards');
      final dir = await _boardDirectory(root, data);
      final file = File('${dir.path}/$id.json');

      // Safety Lock: Don't overwrite a large existing file with a tiny/empty one 
      // unless it's a new file.
      final newTilesList = data['tiles'] as List?;
      final nonEmptyNewTiles = newTilesList?.where((t) {
        final label = t['label']?.toString() ?? '';
        final image = t['image']?.toString() ?? '';
        return label.isNotEmpty || image.isNotEmpty;
      }).length ?? 0;

      if (await file.exists()) {
        final existingContent = await file.readAsString();
        final existingData = json.decode(existingContent) as Map<String, dynamic>;
        final existingTilesList = existingData['tiles'] as List?;
        final nonEmptyExistingTiles = existingTilesList?.where((t) {
          final label = t['label']?.toString() ?? '';
          final image = t['image']?.toString() ?? '';
          return label.isNotEmpty || image.isNotEmpty;
        }).length ?? 0;
        
        // If the number of content-carrying tiles drops by more than 50%
        if (!allowContentReduction && nonEmptyNewTiles < nonEmptyExistingTiles * 0.5 && nonEmptyExistingTiles > 5) {
          print('Safety Lock: Rejected save for $id because non-empty tile count dropped from $nonEmptyExistingTiles to $nonEmptyNewTiles. Please check browser state.');
          response.statusCode = 403;
          response.write(json.encode({'ok': false, 'error': 'Safety Lock: Sudden content drop'}));
          await response.close();
          continue;
        }

        // Extremely conservative: Never overwrite a board that has content with one that has ZERO content.
        if (!allowContentReduction && nonEmptyExistingTiles > 0 && nonEmptyNewTiles == 0) {
           print('Safety Lock: BLOCKED complete wipe of board $id.');
           response.statusCode = 403;
           response.write(json.encode({'ok': false, 'error': 'Safety Lock: Cannot wipe board'}));
           await response.close();
           continue;
        }
      }

      await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
      await for (final entity in root.list(recursive: true)) {
        if (entity is File &&
            p.normalize(entity.path) != p.normalize(file.path) &&
            p.basename(entity.path) == '$id.json') {
          await entity.delete();
        }
      }

      print('Saved ${file.path}');
      
      // Update the Storage Report
      await _updateStorageReport(projectRoot);

      response.statusCode = 200;
      response.write(json.encode({'ok': true, 'path': file.path}));
    } catch (e, st) {
      print('Error saving board: $e\n$st');
      response.statusCode = 500;
      response.write(json.encode({'ok': false, 'error': e.toString()}));
    }

    await response.close();
  }
}

Future<void> _updateStorageReport(String projectRoot) async {
  try {
    final reportFile = File('$projectRoot/BOARD_STORAGE_REPORT.txt');
    final activeDir = Directory('$projectRoot/lib/data/boards');
    final backupDir = Directory('$projectRoot/lib/data/BACKUP boards');

    final activeFiles = <String, String>{};
    if (await activeDir.exists()) {
      await for (final entity in activeDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          activeFiles[entity.uri.pathSegments.last] = entity.path.replaceFirst(projectRoot, '');
        }
      }
    }

    final backupFiles = <String, String>{};
    if (await backupDir.exists()) {
      await for (final entity in backupDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          backupFiles[entity.uri.pathSegments.last] = entity.path.replaceFirst(projectRoot, '');
        }
      }
    }

    final duplicates = activeFiles.keys.where((k) => backupFiles.containsKey(k)).toList();

    final buffer = StringBuffer();
    buffer.writeln('================================================================================');
    buffer.writeln('CHARLIE CHAT BOARD DATA STORAGE REPORT');
    buffer.writeln('================================================================================');
    buffer.writeln('Last Updated: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('This document tracks where your board data is stored and helps identify if ');
    buffer.writeln('duplicates exist.');
    buffer.writeln('');
    buffer.writeln('PRIMARY SOURCE OF TRUTH (DEV MODE):');
    buffer.writeln('- Location: lib/data/boards/[Area]/[BoardID].json');
    buffer.writeln('- Usage: When you are running the "Web Live Preview", any edits you make are ');
    buffer.writeln('  automatically written here by the Dev Save Server. On app startup, the app');
    buffer.writeln('  scans these folders and loads these files first.');
    buffer.writeln('');
    buffer.writeln('BACKUP STORAGE:');
    buffer.writeln('- Location: lib/data/BACKUP boards/[Area]/[BoardID].json');
    buffer.writeln('- Usage: These are manual backups. The app DOES NOT read from here unless ');
    buffer.writeln('  a developer (like me) manually copies a file from here back into the ');
    buffer.writeln('  primary "lib/data/boards/" folder.');
    buffer.writeln('');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('DUPLICATE CHECK (Summary of files found in multiple areas):');
    buffer.writeln('--------------------------------------------------------------------------------');
    if (duplicates.isEmpty) {
      buffer.writeln('No duplicates found between Active and Backup folders.');
    } else {
      buffer.writeln('The following ${duplicates.length} boards exist in BOTH folders:');
      for (var i = 0; i < duplicates.length; i++) {
        final filename = duplicates[i];
        buffer.writeln('${i + 1}. $filename');
        buffer.writeln('   - Active: ${activeFiles[filename]}');
        buffer.writeln('   - Backup: ${backupFiles[filename]}');
      }
    }
    buffer.writeln('');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('STORAGE FLOW - WHY THINGS GO WRONG:');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('1. MIRRORING: Edits in the browser -> Dev Save Server -> lib/data/boards/...');
    buffer.writeln('2. OVERWRITING: If the app starts and can\u0027t find your project root, it loads ');
    buffer.writeln('   empty defaults. If the server is running, it might then "mirror" those empty ');
    buffer.writeln('   defaults BACK to your disk, erasing your work.');
    buffer.writeln('3. FIX APPLIED: I have added a "Safety Lock" that prevents the app from ');
    buffer.writeln('   mirroring a board if it contains 0 images or only blank tiles.');
    buffer.writeln('');
    buffer.writeln('================================================================================');
    buffer.writeln('REPORT GENERATOR: Updated by dev_save_server.dart on every board save.');
    buffer.writeln('================================================================================');

    await reportFile.writeAsString(buffer.toString());
  } catch (e) {
    print('Error updating storage report: $e');
  }
}
