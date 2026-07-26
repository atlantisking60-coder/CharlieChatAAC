import 'package:cross_file/cross_file.dart';
import 'board_ocr_service.dart';
import 'external_symbol_service.dart';
import 'ocr_interface.dart';

class OcrStub implements OcrImplementation {
  @override
  Future<BoardOcrResult?> processScreenshot(XFile imageFile, {ExternalSymbolService? symbolService}) async {
    return null;
  }

  @override
  void dispose() {}
}

OcrImplementation getOcrImplementation() => OcrStub();
