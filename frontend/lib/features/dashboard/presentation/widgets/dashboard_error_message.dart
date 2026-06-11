import '../../../../core/errors/app_exception.dart';

String buildDashboardErrorMessage({
  required Object? error,
  required String apiBaseUrl,
  required String fallback,
}) {
  final lines = <String>[];

  if (error is AppException && error.message.isNotEmpty) {
    lines.add(error.message);
  } else {
    lines.add(fallback);
  }

  final isLocalhost = apiBaseUrl.contains('localhost') ||
      apiBaseUrl.contains('127.0.0.1');

  if (isLocalhost) {
    lines.add(
      'La app apunta a $apiBaseUrl, que no funciona en un teléfono físico.',
    );
    lines.add(
      'Vuelve a lanzar con: .\\scripts\\run-android-device.ps1 -ApiIp TU_IP_WIFI',
    );
  } else {
    lines.add('API: $apiBaseUrl');
    lines.add(
      'Comprueba que el teléfono y la PC estén en la misma WiFi y que Docker esté activo.',
    );
    lines.add(
      'Si usas VPN en el teléfono, desactívala para acceder a la API local.',
    );
    lines.add(
      'Prueba en el navegador del móvil: $apiBaseUrl/health/live',
    );
  }

  return lines.join('\n');
}
