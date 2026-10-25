import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/auth_tokens.dart';

/// Cliente de los endpoints reales de sesión.
///
/// No reintenta un login que respondió 401 o 429.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) {
    return _send(
      () => _dio.post<dynamic>(
        '/auth/login',
        data: <String, String>{
          'email': email,
          'password': password,
        },
      ),
      duringLogin: true,
      parse: AuthTokens.fromResponseData,
    );
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/logout',
        data: <String, String>{'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw AppException(FailureMapper.unexpectedMessage);
      }
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  /// Renueva access y refresh. El backend revoca el refresh anterior.
  Future<AuthTokens> refresh({required String refreshToken}) {
    return _send(
      () => _dio.post<dynamic>(
        '/auth/refresh',
        data: <String, String>{'refresh_token': refreshToken},
      ),
      duringLogin: false,
      parse: AuthTokens.fromResponseData,
    );
  }

  Future<UserProfile> currentUser() {
    return _send(
      () => _dio.get<dynamic>('/auth/me'),
      duringLogin: false,
      parse: UserProfile.fromResponseData,
    );
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/change-password',
        data: <String, String>{
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      return readSuccessMessage(response.data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<T> _send<T>(
    Future<Response<dynamic>> Function() request, {
    required bool duringLogin,
    required T Function(Object? data) parse,
  }) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error, duringLogin: duringLogin);
    }
  }
}
