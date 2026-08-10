import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum ImageCleanupMode { background, allWhite }

class ImageCleanupService {
  Future<String?> cleanImage(String source, ImageCleanupMode mode) async {
    final bytes = await _readImageBytes(source);
    if (bytes == null) return null;

    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final workImage = image.hasAlpha
        ? image
        : image.convert(format: img.Format.uint8, numChannels: 4);
    if (mode == ImageCleanupMode.background) {
      _removeEdgeWhite(workImage);
    } else {
      _removeAllWhite(workImage);
    }

    final processedBytes = img.encodePng(workImage);
    return _storeProcessedImage(processedBytes);
  }

  Future<Uint8List?> _readImageBytes(String source) async {
    try {
      if (source.startsWith('data:')) {
        final commaIndex = source.indexOf(',');
        if (commaIndex < 0) return null;
        return Uint8List.fromList(base64Decode(source.substring(commaIndex + 1)));
      }
      if (source.startsWith('http://') || source.startsWith('https://')) {
        final response = await http.get(Uri.parse(source));
        return response.statusCode == 200 ? response.bodyBytes : null;
      }
      if (source.startsWith('assets/')) {
        final data = await rootBundle.load(source);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
      if (kIsWeb) return null;
      final file = File(source);
      return await file.exists() ? file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _storeProcessedImage(List<int> bytes) async {
    if (kIsWeb) return 'data:image/png;base64,${base64Encode(bytes)}';
    final directory = Directory(
      '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}processed_symbols',
    );
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}image_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _removeAllWhite(img.Image image) {
    for (final pixel in image) {
      if (_isWhite(pixel)) pixel.a = 0;
    }
  }

  void _removeEdgeWhite(img.Image image) {
    final width = image.width;
    final height = image.height;
    final visited = Uint8List(width * height);
    final pending = <int>[];

    void addIfWhite(int x, int y) {
      final index = y * width + x;
      if (visited[index] != 0 || !_isWhite(image.getPixel(x, y))) return;
      visited[index] = 1;
      pending.add(index);
    }

    for (var x = 0; x < width; x++) {
      addIfWhite(x, 0);
      addIfWhite(x, height - 1);
    }
    for (var y = 1; y < height - 1; y++) {
      addIfWhite(0, y);
      addIfWhite(width - 1, y);
    }

    for (var cursor = 0; cursor < pending.length; cursor++) {
      final index = pending[cursor];
      final x = index % width;
      final y = index ~/ width;
      image.getPixel(x, y).a = 0;
      if (x > 0) addIfWhite(x - 1, y);
      if (x + 1 < width) addIfWhite(x + 1, y);
      if (y > 0) addIfWhite(x, y - 1);
      if (y + 1 < height) addIfWhite(x, y + 1);
    }
  }

  bool _isWhite(img.Pixel pixel) {
    final lowest = [pixel.r, pixel.g, pixel.b].reduce((a, b) => a < b ? a : b);
    final highest = [pixel.r, pixel.g, pixel.b].reduce((a, b) => a > b ? a : b);
    return lowest >= 210 && highest - lowest <= 45;
  }
}
