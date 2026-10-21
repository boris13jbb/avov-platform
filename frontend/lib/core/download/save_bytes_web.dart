// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveBytesToUser({
  required List<int> bytes,
  required String filename,
}) async {
  final safe = filename.replaceAll(RegExp(r'[\\/]+'), '_');
  final data = Uint8List.fromList(bytes);
  final blob = html.Blob([data], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = safe
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return safe;
}
