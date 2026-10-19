import 'package:flutter/foundation.dart';

/// Configuración de la aplicación.
///
/// La URL de la API tiene una sola fuente: [apiBaseUrl].
/// Se puede fijar al compilar con `--dart-define=API_BASE_URL=...`.
/// Sin ese valor, el emulador Android usa `10.0.2.2` para llegar al
/// equipo anfitrión. El resto de plataformas usa `127.0.0.1`.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
  });

  final String apiBaseUrl;
  final String appName;

  static const envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const _hostApiBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static AppConfig get development => AppConfig(
        apiBaseUrl: resolveApiBaseUrl(),
        appName: 'AVOV',
      );

  /// Elige la URL sin leer secretos ni cambiar el puerto publicado.
  static String resolveApiBaseUrl({
    String envUrl = envApiBaseUrl,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final configured = envUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }
    final target = platform ?? defaultTargetPlatform;
    if (!isWeb && target == TargetPlatform.android) {
      return _androidEmulatorApiBaseUrl;
    }
    return _hostApiBaseUrl;
  }
}
