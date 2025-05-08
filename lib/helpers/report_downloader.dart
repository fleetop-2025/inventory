import 'dart:typed_data';

import 'report_downloader_stub.dart'
if (dart.library.html) 'report_downloader_web.dart';

Future<void> downloadReportHelper(Uint8List bytes, String filename) async {
  return downloadReportImpl(bytes, filename);
}
