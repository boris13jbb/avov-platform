import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/assistant_message.dart';
import '../domain/assistant_repository.dart';

class ApiAssistantRepository implements AssistantRepository {
  ApiAssistantRepository(this._dio);

  final Dio _dio;

  @override
  Future<AssistantReply> chat({
    required String message,
    int? testSessionId,
  }) {
    return _post('/assistant/chat', <String, dynamic>{
      'message': message,
      if (testSessionId != null) 'test_session_id': testSessionId,
    });
  }

  @override
  Future<AssistantReply> explainProfile({int? testSessionId}) {
    return _post('/assistant/explain-profile', <String, dynamic>{
      if (testSessionId != null) 'test_session_id': testSessionId,
    });
  }

  @override
  Future<AssistantReply> explainCareers({
    required List<int> careerIds,
    int? testSessionId,
  }) {
    return _post('/assistant/explain-careers', <String, dynamic>{
      'career_ids': careerIds,
      if (testSessionId != null) 'test_session_id': testSessionId,
    });
  }

  Future<AssistantReply> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return AssistantReply.fromJson(readSuccessData(response.data));
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }
}
