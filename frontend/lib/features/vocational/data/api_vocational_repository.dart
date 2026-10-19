import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/vocational_repository.dart';
import '../domain/vocational_test.dart';

class ApiVocationalRepository implements VocationalRepository {
  ApiVocationalRepository(this._dio);

  final Dio _dio;

  @override
  Future<VocationalSessionPage> listSessions({int page = 1, int pageSize = 20}) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/tests',
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
        },
      );
      return VocationalSessionPage.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<VocationalSession> start() {
    return _send(() async {
      final response = await _dio.post<dynamic>('/tests/start');
      return VocationalSession.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<VocationalQuestionnaire> questions(int sessionId) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/tests/$sessionId/questions');
      return VocationalQuestionnaire.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) {
    return _send(() async {
      await _dio.post<dynamic>(
        '/tests/$sessionId/answers',
        data: <String, dynamic>{
          'question_id': questionId,
          'answer_value': answerValue,
        },
      );
    });
  }

  @override
  Future<VocationalResult> finish(int sessionId) {
    return _send(() async {
      final response = await _dio.post<dynamic>('/tests/$sessionId/finish');
      return VocationalResult.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<VocationalResult> result(int sessionId) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/tests/$sessionId/result');
      return VocationalResult.fromJson(readSuccessData(response.data));
    });
  }

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }
}
