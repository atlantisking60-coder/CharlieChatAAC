import 'board_export_download_stub.dart'
    if (dart.library.html) 'board_export_download_web.dart';

Future<void> downloadBoardExportBytes(List<int> bytes, String fileName, String mimeType) async {
  await downloadBoardExportBytesImpl(bytes, fileName, mimeType);
}
