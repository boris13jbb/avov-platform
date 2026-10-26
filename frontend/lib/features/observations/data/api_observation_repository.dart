import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/observation.dart';
import '../domain/observation_repository.dart';

class ApiObservationRepository implements ObservationRepository {
  ApiObservationRepository(this._dio);

  final Dio _dio;

  @override
  Future<ObservationPage> listBySession({
    required int testSessionId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/observations',
        queryParameters: <String, dynamic>{
          'test_session_id': testSessionId,
          'page': page,
          'page_size': pageSize,
        },
      );
      return ObservationPage.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<CounselorObservation> latestForSession(int testSessionId) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/observations/latest',
        queryParameters: <String, dynamic>{
          'test_session_id': testSessionId,
        },
      );
      return CounselorObservation.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<CounselorObservation> create(ObservationDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/observations',
        data: draft.toJson(),
      );
      return CounselorObservation.fromJson(readSuccessData(response.data));
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
