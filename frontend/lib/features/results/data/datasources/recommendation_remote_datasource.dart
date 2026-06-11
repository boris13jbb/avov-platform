import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/counselor_observation.dart';
import '../../../../core/models/recommendation.dart';

class RecommendationRemoteDatasource {
  RecommendationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<RecommendationList> generateRecommendations({int? testSessionId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/recommendations/generate',
        data: {
          if (testSessionId != null) 'test_session_id': testSessionId,
        },
      );
      return _parseList(response.data, 'No se pudieron generar recomendaciones');
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<CounselorObservation> addCounselorObservationBySession({
    required int testSessionId,
    required String observation,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tests/$testSessionId/observations',
        data: {'observation': observation},
      );
      if (response.data == null || response.data!['success'] != true) {
        throw AppException(
          response.data?['message'] as String? ??
              'No se pudo registrar la observación',
        );
      }
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) {
        throw AppException('Respuesta de observación inválida');
      }
      return CounselorObservation.fromJson(data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<CounselorObservation> addCounselorObservation({
    required int recommendationId,
    required String observation,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/recommendations/$recommendationId/observations',
        data: {'observation': observation},
      );
      if (response.data == null || response.data!['success'] != true) {
        throw AppException(
          response.data?['message'] as String? ??
              'No se pudo registrar la observación',
        );
      }
      final data = response.data!['data'];
      if (data is! Map<String, dynamic>) {
        throw AppException('Respuesta de observación inválida');
      }
      return CounselorObservation.fromJson(data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<RecommendationList> listStudentRecommendations(int studentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/recommendations/student/$studentId',
      );
      return _parseList(response.data, 'No se pudieron cargar las recomendaciones');
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  RecommendationList _parseList(
    Map<String, dynamic>? body,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AppException('Respuesta de recomendaciones inválida');
    }
    return RecommendationList.fromJson(data);
  }
}
