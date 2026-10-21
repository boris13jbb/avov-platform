import 'dart:io';

Future<String> saveBytesToUser({
  required List<int> bytes,
  required String filename,
}) async {
  final safe = filename.replaceAll(RegExp(r'[\\/]+'), '_');
  final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}$safe');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
