import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/test_session.dart';

class TestRemoteDatasource {
  TestRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TestSession> startTest() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/tests/start');
      return _parseData(
        response.data,
        TestSession.fromJson,
        'No se pudo iniciar el test',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<SessionQuestions> getSessionQuestions(int sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tests/$sessionId/questions',
      );
      return _parseData(
        response.data,
        SessionQuestions.fromJson,
        'No se pudieron cargar las preguntas',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tests/$sessionId/answers',
        data: {
          'question_id': questionId,
          'answer_value': answerValue,
        },
      );
      _ensureSuccess(response.data, 'No se pudo guardar la respuesta');
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<RiasecResult> finishTest(int sessionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/tests/$sessionId/finish',
      );
      return _parseData(
        response.data,
        RiasecResult.fromJson,
        'No se pudo finalizar el test',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<RiasecResult> getResult(int sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/tests/$sessionId/result',
      );
      return _parseData(
        response.data,
        RiasecResult.fromJson,
        'No se pudo obtener el resultado',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  T _parseData<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) fromJson,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AppException('Respuesta de test inválida');
    }
    return fromJson(data);
  }

  void _ensureSuccess(Map<String, dynamic>? body, String fallbackMessage) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
  }
}
