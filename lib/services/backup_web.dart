import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Download a JSON string as a file on web.
void downloadJson(String content, String filename) {
  final parts = [content.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
