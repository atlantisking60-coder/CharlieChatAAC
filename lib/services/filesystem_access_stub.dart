// Stub for non-web platforms. The real implementation is in filesystem_access_web.dart.

bool get isSupported => false;

Future<dynamic> pickDirectory() async => throw UnsupportedError('File System Access API is only available on web');

Future<void> writeTextToPath(dynamic dirHandle, String path, String content) async =>
    throw UnsupportedError('File System Access API is only available on web');

void resetCachedDirectory() {}
