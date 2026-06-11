import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(
          body?['message'] as String? ?? 'No se pudo iniciar sesión',
        );
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw AppException('Respuesta de autenticación inválida');
      }
      return data;
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<String> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(
          body?['message'] as String? ?? 'No se pudo enviar la solicitud',
        );
      }
      return body['message'] as String? ??
          'Si el correo está registrado, recibirás instrucciones en breve.';
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'token': token,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(
          body?['message'] as String? ?? 'No se pudo restablecer la contraseña',
        );
      }
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(
          body?['message'] as String? ?? 'No se pudo cambiar la contraseña',
        );
      }
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw AppException(
          body?['message'] as String? ?? 'No se pudo obtener el perfil',
        );
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw AppException('Respuesta de perfil inválida');
      }
      return data;
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }
}
