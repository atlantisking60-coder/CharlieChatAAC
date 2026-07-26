class BoardExportUtils {
  static String sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'board_export' : sanitized;
  }

  static String buildExportFileName(String boardName, String format) {
    final baseName = sanitizeFileName(boardName);
    final extension = format.toLowerCase();
    return '$baseName.$extension';
  }

  static String mimeTypeForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
