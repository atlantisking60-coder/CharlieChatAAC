import 'package:cross_file/cross_file.dart';
import '../models/symbol_tile.dart';
import 'external_symbol_service.dart';
import 'ocr_interface.dart';

// Import stub by default
import 'ocr_stub.dart'
    // On mobile, use the ML Kit implementation
    if (dart.library.io) 'ocr_mobile_impl.dart'
    // On web, use the Tesseract implementation
    if (dart.library.js_interop) 'ocr_web_impl.dart';

/// BOARD OCR RESULT
/// Data structure containing extracted tiles and grid info.
class BoardOcrResult {
  final List<SymbolTile> tiles;
  final int rows;
  final int columns;

  BoardOcrResult({
    required this.tiles,
    required this.rows,
    required this.columns,
  });
}

/// BOARD OCR SERVICE
/// Extracts grid data and icons from screenshots.
/// Uses mobile-only ML Kit via conditional implementation.
class BoardOcrService {
  late final OcrImplementation _impl;

  BoardOcrService() {
    _impl = getOcrImplementation();
  }

  Future<BoardOcrResult?> processScreenshot(XFile imageFile, {ExternalSymbolService? symbolService}) async {
    try {
      return await _impl.processScreenshot(imageFile, symbolService: symbolService);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _impl.dispose();
  }
}
