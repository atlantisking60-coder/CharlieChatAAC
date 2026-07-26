import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadBoardExportBytesImpl(List<int> bytes, String fileName, String mimeType) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = 'blank'
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
