import 'dart:io' show Directory, File, Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/symbol_tile.dart';
import 'board_ocr_service.dart';
import 'external_symbol_service.dart';
import 'ocr_interface.dart';

class OcrMobileImpl implements OcrImplementation {
  TextRecognizer? _textRecognizer;

  OcrMobileImpl() {
    if (Platform.isAndroid || Platform.isIOS) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  @override
  Future<BoardOcrResult?> processScreenshot(XFile imageFile, {ExternalSymbolService? symbolService}) async {
    if (_textRecognizer == null) return null;

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final recognizedText = await _textRecognizer!.processImage(inputImage);

    if (recognizedText.blocks.isEmpty) return null;

    // Filter out very small text or single characters that aren't likely labels
    final blocks = recognizedText.blocks.where((b) {
      final t = b.text.trim();
      return t.length >= 2 || (t.isNotEmpty && _isLikelyShortLabel(t));
    }).toList();
    
    if (blocks.isEmpty) return null;

    // Group text blocks into rows based on Y coordinate
    blocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    List<List<TextBlock>> rowGroups = [];
    if (blocks.isNotEmpty) {
      List<TextBlock> currentRow = [blocks[0]];
      for (int i = 1; i < blocks.length; i++) {
        final prev = blocks[i - 1];
        final curr = blocks[i];
        // If the vertical gap is small, they belong to the same row
        if ((curr.boundingBox.top - prev.boundingBox.top).abs() < prev.boundingBox.height * 1.5) {
          currentRow.add(curr);
        } else {
          rowGroups.add(currentRow);
          currentRow = [curr];
        }
      }
      rowGroups.add(currentRow);
    }

    // Sort each row by X coordinate
    for (var row in rowGroups) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    }

    final rowCount = rowGroups.length;
    final colCount = rowGroups.map((r) => r.length).reduce(max);

    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    final appDir = await getApplicationDocumentsDirectory();
    final symbolsDir = Directory('${appDir.path}/custom_symbols');
    if (!await symbolsDir.exists()) await symbolsDir.create(recursive: true);

    List<SymbolTile> tiles = [];
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < colCount; c++) {
        if (c < rowGroups[r].length) {
          final block = rowGroups[r][c];
          String rawLabel = block.text.replaceAll('\n', ' ').trim();
          
          // Try to guess the word if it seems cut off
          String finalLabel = rawLabel;
          ExternalSymbol? librarySymbol;
          
          if (symbolService != null) {
            librarySymbol = await _findLibraryMatch(rawLabel, symbolService);
            if (librarySymbol != null) {
              finalLabel = librarySymbol.label;
            }
          }

          String imagePath = '';
          if (librarySymbol != null) {
            imagePath = librarySymbol.imageUrl;
          } else if (decodedImage != null) {
            // Crop from screenshot if no library match
            imagePath = await _cropTileImage(decodedImage, block, r, c, symbolsDir);
          }

          tiles.add(SymbolTile(
            id: 'ocr_${DateTime.now().microsecondsSinceEpoch}_$r$c',
            label: finalLabel.toLowerCase(),
            category: librarySymbol?.source ?? 'Imported',
            imageAsset: imagePath,
            bgColor: 'transparent',
            textColor: '#000000',
          ));
        } else {
          tiles.add(SymbolTile(
            id: 'ocr_empty_${DateTime.now().microsecondsSinceEpoch}_$r$c',
            label: '',
            category: 'Imported',
            imageAsset: '',
            bgColor: 'transparent',
            textColor: '#000000',
          ));
        }
      }
    }

    return BoardOcrResult(
      tiles: tiles,
      rows: rowCount,
      columns: colCount,
    );
  }

  bool _isLikelyShortLabel(String t) {
    final lower = t.toLowerCase();
    return const {'a', 'i', 'my', 'me', 'go', 'up', 'do', 'no'}.contains(lower);
  }

  Future<ExternalSymbol?> _findLibraryMatch(String rawLabel, ExternalSymbolService service) async {
    final clean = rawLabel.toLowerCase().trim();
    if (clean.length < 2) return null;

    // 1. Try exact match
    final exactMatches = await service.searchAssets(clean, limit: 1);
    if (exactMatches.isNotEmpty && exactMatches.first.label.toLowerCase() == clean) {
      return exactMatches.first;
    }

    // 2. Try to guess cut-off text: search for symbols STARTING with the fragment
    // We use a slightly broader search and then filter
    final suggestions = await service.searchAll(clean, limit: 5);
    for (final s in suggestions) {
      final label = s.label.toLowerCase();
      // If it starts with our fragment and the fragment is long enough to be significant
      if (label.startsWith(clean) && clean.length >= 3) {
        return s;
      }
      // Or if it's very close (levenshtein handled by searchAll)
      if (label == clean) return s;
    }

    return null;
  }

  Future<String> _cropTileImage(img.Image decodedImage, TextBlock block, int r, int c, Directory symbolsDir) async {
    final b = block.boundingBox;
    
    // Most AAC tiles have the image ABOVE the text.
    // We'll estimate the tile area as a square centered above or around the text.
    final tileSize = max(b.width, b.height) * 2.5;
    final centerX = b.left + b.width / 2;
    // Shift the center upwards from the text block
    final centerY = b.top - (b.height * 0.5); 
    
    final cropX = (centerX - tileSize / 2).clamp(0, decodedImage.width.toDouble()).toInt();
    final cropY = (centerY - tileSize).clamp(0, decodedImage.height.toDouble()).toInt();
    final cropW = tileSize.toInt().clamp(1, decodedImage.width - cropX);
    final cropH = (tileSize * 1.2).toInt().clamp(1, decodedImage.height - cropY);
    
    try {
      final cropped = img.copyCrop(decodedImage, x: cropX, y: cropY, width: cropW, height: cropH);
      final fileName = 'ocr_crop_${DateTime.now().microsecondsSinceEpoch}_$r$c.png';
      final file = File('${symbolsDir.path}/$fileName');
      await file.writeAsBytes(img.encodePng(cropped));
      return file.path;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return '';
    }
  }

  @override
  void dispose() {
    _textRecognizer?.close();
  }
}

OcrImplementation getOcrImplementation() => OcrMobileImpl();
