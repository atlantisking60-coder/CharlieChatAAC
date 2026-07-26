import 'package:cross_file/cross_file.dart';
import 'board_ocr_service.dart';
import 'external_symbol_service.dart';

abstract class OcrImplementation {
  Future<BoardOcrResult?> processScreenshot(XFile imageFile, {ExternalSymbolService? symbolService});
  void dispose();
}
