import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/assistant_message.dart';

class AssistantRemoteDatasource {
  AssistantRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AssistantReply> sendChat({
    required String message,
    int? testSessionId,
  }) async {
    return _post(
      '/assistant/chat',
      {
        'message': message,
        if (testSessionId != null) 'test_session_id': testSessionId,
      },
      'No se pudo obtener respuesta del asistente',
    );
  }

  Future<AssistantReply> explainProfile({int? testSessionId}) async {
    return _post(
      '/assistant/explain-profile',
      {
        if (testSessionId != null) 'test_session_id': testSessionId,
      },
      'No se pudo explicar el perfil RIASEC',
    );
  }

  Future<AssistantReply> explainCareers({
    required List<int> careerIds,
    int? testSessionId,
  }) async {
    return _post(
      '/assistant/explain-careers',
      {
        'career_ids': careerIds,
        if (testSessionId != null) 'test_session_id': testSessionId,
      },
      'No se pudieron explicar las carreras',
    );
  }

  Future<AssistantReply> _post(
    String path,
    Map<String, dynamic> body,
    String fallbackMessage,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AppException(data?['message'] as String? ?? fallbackMessage);
      }
      final payload = data['data'];
      if (payload is! Map<String, dynamic>) {
        throw AppException('Respuesta del asistente inválida');
      }
      return AssistantReply.fromJson(payload);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }
}
