import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

@JS('showDirectoryPicker')
external JSPromise<web.FileSystemDirectoryHandle> _showDirectoryPicker();

/// Cached directory handle so the user only grants permission once.
web.FileSystemDirectoryHandle? _cachedDirHandle;

/// Prompt the user to choose a directory. Returns null if cancelled.
Future<web.FileSystemDirectoryHandle?> pickDirectory() async {
  if (_cachedDirHandle != null) return _cachedDirHandle;
  try {
    final promise = _showDirectoryPicker();
    final result = await promise.toDart;
    _cachedDirHandle = result;
    return _cachedDirHandle;
  } catch (_) {
    return null;
  }
}

/// Write [content] to [path] (slash-separated segments) under [dirHandle].
/// Creates intermediate directories as needed.
Future<void> writeTextToPath(dynamic dirHandle, String path, String content) async {
  final segments = path.split('/');
  var current = dirHandle as web.FileSystemDirectoryHandle;

  // Navigate/create directories for all segments except the last (the file).
  for (var i = 0; i < segments.length - 1; i++) {
    final options = web.FileSystemGetDirectoryOptions(create: true);
    current = await current.getDirectoryHandle(segments[i], options).toDart;
  }

  final fileName = segments.last;
  final options = web.FileSystemGetFileOptions(create: true);
  final fileHandle = await current.getFileHandle(fileName, options).toDart;

  final writable = await fileHandle.createWritable().toDart;
  await writable.write(content.toJS).toDart;
  await writable.close().toDart;
}

/// Check if the File System Access API is available in this browser.
bool get isSupported {
  try {
    return (web.window as JSObject).hasProperty('showDirectoryPicker'.toJS).toDart;
  } catch (_) {
    return false;
  }
}

void resetCachedDirectory() {
  _cachedDirHandle = null;
}
