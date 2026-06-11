import 'package:dio/dio.dart';

import 'app_exception.dart';

class FailureMapper {
  FailureMapper._();

  static AppException fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == 401) {
      final message = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      return UnauthorizedException(
        message ?? 'Sesión expirada o no autorizada',
      );
    }

    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return AppException(message, statusCode: statusCode);
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          'Tiempo de espera agotado. Verifica tu conexión.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          'No se pudo conectar con el servidor.',
          statusCode: statusCode,
        );
      default:
        return AppException(
          'Ocurrió un error inesperado. Intenta nuevamente.',
          statusCode: statusCode,
        );
    }
  }
}
