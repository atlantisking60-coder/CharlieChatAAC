/// No-op stub for non-web platforms. Web platforms use backup_web.dart instead.
void downloadJson(String content, String filename) {
  throw UnsupportedError('downloadJson is only supported on web');
}
