import 'save_bytes_stub.dart'
    if (dart.library.html) 'save_bytes_web.dart' as impl;

/// Guarda o descarga bytes en la plataforma actual.
///
/// En web inicia una descarga del navegador. En otras plataformas escribe
/// un archivo temporal y devuelve la ruta.
Future<String> saveBytesToUser({
  required List<int> bytes,
  required String filename,
}) {
  return impl.saveBytesToUser(bytes: bytes, filename: filename);
}
