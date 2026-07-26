import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import '../models/symbol_tile.dart';
import 'board_ocr_service.dart';
import 'external_symbol_service.dart';
import 'ocr_interface.dart';

@JS('window')
external JSObject get window;

@JS('Tesseract')
extension type Tesseract(JSObject _) implements JSObject {
  @JS('recognize')
  external JSPromise recognize(JSAny image, String lang);
}

@JS()
extension type TesseractResult(JSObject _) implements JSObject {
  external TesseractData get data;
}

@JS()
extension type TesseractData(JSObject _) implements JSObject {
  external JSArray<TesseractLine> get lines;
  external JSArray<TesseractWord> get words;
}

@JS()
extension type TesseractLine(JSObject _) implements JSObject {
  external String get text;
  external TesseractBBox get bbox;
  external JSArray<TesseractWord> get words;
}

@JS()
extension type TesseractWord(JSObject _) implements JSObject {
  external String get text;
  external TesseractBBox get bbox;
}

@JS()
extension type TesseractBBox(JSObject _) implements JSObject {
  external double get x0;
  external double get y0;
  external double get x1;
  external double get y1;
}

class OcrWebImpl implements OcrImplementation {
  @override
  Future<BoardOcrResult?> processScreenshot(XFile imageFile, {ExternalSymbolService? symbolService}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
      
      final tesseract = window.getProperty('Tesseract'.toJS) as Tesseract?;
      if (tesseract == null) return null;
      
      final promise = tesseract.recognize(base64Image.toJS, 'eng');
      final jsResult = await promise.toDart;
      if (jsResult == null) return null;
      
      final result = jsResult as TesseractResult;
      final data = result.data;
      final lines = data.lines;
      
      if (lines.length == 0) return null;

      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // detect rows and columns
      List<List<_TextBlock>> grid = [];
      final jsLines = lines.toDart;

      for (var i = 0; i < jsLines.length; i++) {
        final line = jsLines[i];
        final jsWords = line.words.toDart;
        List<_TextBlock> rowItems = [];
        
        for (var j = 0; j < jsWords.length; j++) {
          final word = jsWords[j];
          final text = word.text.trim();
          if (text.length < 2 && !_isLikelyShortLabel(text)) continue;
          
          rowItems.add(_TextBlock(
            text: text,
            left: word.bbox.x0,
            top: word.bbox.y0,
            width: word.bbox.x1 - word.bbox.x0,
            height: word.bbox.y1 - word.bbox.y0,
          ));
        }
        
        if (rowItems.isNotEmpty) {
          // Merge horizontally close words into single tiles
          rowItems.sort((a, b) => a.left.compareTo(b.left));
          List<_TextBlock> merged = [];
          var current = rowItems[0];
          for (int k = 1; k < rowItems.length; k++) {
            final next = rowItems[k];
            if (next.left - (current.left + current.width) < current.height * 2.0) {
              current = _TextBlock(
                text: '${current.text} ${next.text}',
                left: current.left,
                top: min(current.top, next.top),
                width: (next.left + next.width) - current.left,
                height: max(current.height, next.height),
              );
            } else {
              merged.add(current);
              current = next;
            }
          }
          merged.add(current);
          grid.add(merged);
        }
      }

      if (grid.isEmpty) return null;

      final rowCount = grid.length;
      final colCount = grid.map((r) => r.length).reduce(max);

      List<SymbolTile> tiles = [];
      for (int r = 0; r < rowCount; r++) {
        final row = grid[r];
        for (int c = 0; c < colCount; c++) {
          if (c < row.length) {
            final block = row[c];
            ExternalSymbol? match;
            if (symbolService != null) {
              match = await _findLibraryMatch(block.text, symbolService);
            }

            final label = match?.label ?? block.text;
            final image = match?.imageUrl ?? _cropTile(decodedImage, block);

            tiles.add(SymbolTile(
              id: 'ocr_web_${DateTime.now().microsecondsSinceEpoch}_$r$c',
              label: label.toLowerCase(),
              category: match?.source ?? 'Imported',
              imageAsset: image,
              bgColor: 'transparent',
              textColor: '#000000',
            ));
          } else {
            tiles.add(SymbolTile(
              id: 'ocr_empty_${DateTime.now().microsecondsSinceEpoch}_$r$c',
              label: '',
              category: 'Imported',
              imageAsset: '',
            ));
          }
        }
      }

      return BoardOcrResult(tiles: tiles, rows: rowCount, columns: colCount);
    } catch (e) {
      debugPrint('Web OCR Error: $e');
      return null;
    }
  }

  bool _isLikelyShortLabel(String t) => const {'a', 'i', 'my', 'me', 'go', 'up', 'do', 'no'}.contains(t.toLowerCase());

  Future<ExternalSymbol?> _findLibraryMatch(String raw, ExternalSymbolService service) async {
    final clean = raw.toLowerCase().trim();
    if (clean.length < 2) return null;
    final exact = await service.searchAssets(clean, limit: 1);
    if (exact.isNotEmpty && exact.first.label.toLowerCase() == clean) return exact.first;
    final sugs = await service.searchAll(clean, limit: 5);
    for (final s in sugs) {
      if (s.label.toLowerCase().startsWith(clean) && clean.length >= 3) return s;
      if (s.label.toLowerCase() == clean) return s;
    }
    return null;
  }

  String _cropTile(img.Image src, _TextBlock block) {
    // AAC grid logic: tiles are usually square, label is at the bottom.
    // We estimate the tile bounds based on the text block.
    final tileS = max(block.width, block.height * 4.0);
    final cx = block.left + block.width / 2;
    final cy = block.top - (tileS * 0.4); 
    
    final x = (cx - tileS / 2).clamp(0, src.width.toDouble()).toInt();
    final y = (cy - tileS / 2).clamp(0, src.height.toDouble()).toInt();
    final w = tileS.toInt().clamp(1, src.width - x);
    final h = tileS.toInt().clamp(1, src.height - y);
    
    try {
      return 'data:image/png;base64,${base64Encode(img.encodePng(img.copyCrop(src, x: x, y: y, width: w, height: h)))}';
    } catch (_) { return ''; }
  }

  @override
  void dispose() {}
}

class _TextBlock {
  final String text;
  final double left, top, width, height;
  _TextBlock({required this.text, required this.left, required this.top, required this.width, required this.height});
}

OcrImplementation getOcrImplementation() => OcrWebImpl();
