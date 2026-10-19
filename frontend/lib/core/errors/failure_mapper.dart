import 'package:dio/dio.dart';

import 'app_exception.dart';

class FailureMapper {
  FailureMapper._();

  static const connectionMessage = 'No se pudo conectar con el servidor.';
  static const unexpectedMessage =
      'Ocurrió un error inesperado. Intenta nuevamente.';
  static const invalidCredentialsMessage = 'Correo o contraseña incorrectos.';
  static const inactiveAccountMessage =
      'Tu cuenta no está activa. Contacta al administrador.';
  static const sessionExpiredMessage =
      'Tu sesión ya no es válida. Inicia sesión de nuevo.';
  static const forbiddenMessage =
      'No tienes permisos para acceder a este recurso.';
  static const tooManyRequestsMessage =
      'Demasiados intentos. Espera un momento antes de volver a intentarlo.';
  static const unavailableMessage =
      'El servicio no está disponible temporalmente.';
  static const validationMessage = 'Revisa los datos ingresados.';
  static const notFoundMessage = 'No se encontró el recurso solicitado.';
  static const conflictMessage =
      'El registro entra en conflicto con datos ya existentes.';

  /// Traduce errores de Dio a mensajes visibles.
  ///
  /// No reintenta la petición. El login no debe repetirse tras 401 o 429.
  static AppException fromDioException(
    DioException error, {
    bool duringLogin = false,
  }) {
    final statusCode = error.response?.statusCode;

    if (_isConnectionFailure(error)) {
      return NetworkException(connectionMessage, statusCode: statusCode);
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          _unauthorizedMessage(error, duringLogin: duringLogin),
        );
      case 403:
        return AppException(forbiddenMessage, statusCode: 403);
      case 429:
        return AppException(tooManyRequestsMessage, statusCode: 429);
      case 503:
        return AppException(unavailableMessage, statusCode: 503);
      case 404:
        return AppException(
          _safeServerMessage(error) ?? notFoundMessage,
          statusCode: 404,
        );
      case 409:
        return AppException(
          _safeServerMessage(error) ?? conflictMessage,
          statusCode: 409,
        );
      case 422:
        return ValidationException(
          _safeServerMessage(error) ?? validationMessage,
          fieldErrors: _fieldErrors(error),
        );
      default:
        return AppException(unexpectedMessage, statusCode: statusCode);
    }
  }

  static bool _isConnectionFailure(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  static String _unauthorizedMessage(
    DioException error, {
    required bool duringLogin,
  }) {
    if (!duringLogin) {
      return sessionExpiredMessage;
    }
    final serverMessage = _serverMessage(error);
    if (serverMessage == inactiveAccountMessage) {
      return inactiveAccountMessage;
    }
    return invalidCredentialsMessage;
  }

  static List<String> _fieldErrors(DioException error) {
    final data = error.response?.data;
    if (data is! Map) {
      return const [];
    }
    final errors = data['errors'];
    if (errors is! List) {
      return const [];
    }
    final messages = <String>[];
    for (final item in errors) {
      if (item is! Map) {
        continue;
      }
      final message = item['message'];
      if (message is! String) {
        continue;
      }
      final text = message.trim();
      if (!_isSafeMessage(text)) {
        continue;
      }
      final field = item['field'];
      messages.add(field is String && field.trim().isNotEmpty
          ? '${field.trim()}: $text'
          : text);
    }
    return messages;
  }

  static bool _isSafeMessage(String text) {
    if (text.isEmpty || text.length > 180 || text.contains('\n')) {
      return false;
    }
    final lower = text.toLowerCase();
    return !lower.contains('traceback') &&
        !lower.contains('sql') &&
        !lower.contains('exception') &&
        !lower.contains('token');
  }

  static String? _safeServerMessage(DioException error) {
    final message = _serverMessage(error);
    if (message != null && _isSafeMessage(message)) {
      return message;
    }
    return null;
  }

  static String? _serverMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
