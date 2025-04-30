import 'download_csv_stub.dart'
if (dart.library.html) 'download_csv_web.dart';

void downloadCSV(List<List<String>> rows, String filename) {
  downloadCSVImpl(rows, filename);
}
