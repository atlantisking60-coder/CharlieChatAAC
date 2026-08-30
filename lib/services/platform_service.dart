import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

/// Platform detection utilities for cross-platform support
class PlatformService {
  /// Returns true if running on the web
  static bool get isWeb => kIsWeb;

  /// Returns true if running on iOS
  static bool get isIos => !kIsWeb && defaultTargetPlatform.toString().contains('ios');

  /// Returns true if running on Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform.toString().contains('android');

  /// Returns true if running on a mobile platform (iOS or Android)
  static bool get isMobile => isIos || isAndroid;

  /// Returns true if running on a native platform (not web)
  static bool get isNative => !isWeb;

  /// Safe file picker that handles web and native differences
  static Future<List<PlatformFile>> pickImageFiles({
    bool allowMultiple = false,
    String? dialogTitle,
  }) async {
    try {
      return await FilePicker.pickFiles(
        type: FileType.image,
        dialogTitle: dialogTitle,
      );
    } catch (e) {
      debugPrint('Error picking files: $e');
      return const [];
    }
  }

  /// Safe file picker for any file type
  static Future<List<PlatformFile>> pickFiles({
    bool allowMultiple = false,
    String? dialogTitle,
    FileType type = FileType.any,
  }) async {
    try {
      return await FilePicker.pickFiles(
        type: type,
        dialogTitle: dialogTitle,
      );
    } catch (e) {
      debugPrint('Error picking files: $e');
      return const [];
    }
  }

  /// Get platform display name
  static String getPlatformName() {
    if (isWeb) return 'Web';
    if (isIos) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Unknown';
  }
}
