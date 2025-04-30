import 'dart:html' as html;
import 'package:csv/csv.dart';

void downloadCSVImpl(List<List<String>> rows, String filename) {
  final csv = const ListToCsvConverter().convert(rows);
  final blob = html.Blob([csv]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
