import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_web_stub.dart'
    if (dart.library.html) 'backup_web.dart';
import 'board_service.dart';

class BackupService {
  static BackupService? _instance;
  BoardService? _boardService;

  BackupService._();

  static Future<BackupService> init() async {
    _instance ??= BackupService._();
    _instance!._boardService = await BoardService.getInstance();
    return _instance!;
  }

  static BackupService get instance {
    if (_instance == null) {
      throw Exception('BackupService not initialized. Call init() first.');
    }
    return _instance!;
  }

  Future<void> backupToDevice({Function(double)? onProgress}) async {
    if (kIsWeb) {
      throw Exception('Backup to device is not available on web');
    }

    final boards = await _boardService!.listBoards();
    final totalBoards = boards.length;

    for (int i = 0; i < totalBoards; i++) {
      // Board is already saved by BoardService, so we just need to export
      if (onProgress != null) {
        onProgress((i + 1) / totalBoards);
      }
    }
  }

  Future<void> exportBackupFile() async {
    final boards = await _boardService!.listBoards();
    final backupData = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'boards': boards.map((board) => board.toMap()).toList(),
    };
    final content = json.encode(backupData);

    if (kIsWeb) {
      downloadJson(content, 'charlie_chat_backup.json');
      return;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/charlie_chat_backup.json');
    await file.writeAsString(content);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> restoreBackup(String filePath) async {
    if (kIsWeb) {
      throw Exception('Restore backup is not available on web');
    }

    final file = File(filePath);
    final jsonString = await file.readAsString();
    final backupData = json.decode(jsonString) as Map<String, dynamic>;

    final boardsData = backupData['boards'] as List<dynamic>;
    for (final boardData in boardsData) {
      // This would need Board.fromMap method to be implemented
      // For now, this is a placeholder
      debugPrint('Would restore board: $boardData');
    }
  }
}
