import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';

class DashboardRemoteDatasource {
  DashboardRemoteDatasource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getSuperAdminDashboard() =>
      _getDashboard('/dashboard/super-admin');

  Future<Map<String, dynamic>> getInstitutionDashboard() =>
      _getDashboard('/dashboard/institution');

  Future<Map<String, dynamic>> getCounselorDashboard() =>
      _getDashboard('/dashboard/counselor');

  Future<Map<String, dynamic>> getStudentDashboard() =>
      _getDashboard('/dashboard/student');

  Future<Map<String, dynamic>> _getDashboard(String path) async {
    try {
      final response = await _getWithRetry(path);
      return _parseDashboardBody(response.data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Map<String, dynamic> _parseDashboardBody(dynamic rawBody) {
    if (rawBody is! Map) {
      throw AppException('Respuesta de dashboard inválida');
    }

    final body = Map<String, dynamic>.from(rawBody);
    final success = body['success'];
    if (success != true && success != 'true') {
      throw AppException(
        body['message'] as String? ?? 'No se pudo cargar el dashboard',
      );
    }

    final data = body['data'];
    if (data is! Map) {
      throw AppException('Respuesta de dashboard inválida');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Response<dynamic>> _getWithRetry(String path) async {
    try {
      return await _dio.get<dynamic>(path);
    } on DioException catch (error) {
      final shouldRetry = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      if (!shouldRetry) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return await _dio.get<dynamic>(path);
    }
  }
}
