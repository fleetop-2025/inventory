// lib/widgets/download_csv_io.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

Future<void> downloadCSVIO(List<List<dynamic>> rows, String filename) async {
  final csv = const ListToCsvConverter().convert(rows);
  final dir = await getExternalStorageDirectory(); // or getApplicationDocumentsDirectory
  final path = '${dir!.path}/$filename';
  final file = File(path);
  await file.writeAsString(csv);
}
