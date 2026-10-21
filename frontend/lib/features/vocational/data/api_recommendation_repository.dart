import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/career_recommendation.dart';
import '../domain/recommendation_repository.dart';

class ApiRecommendationRepository implements RecommendationRepository {
  ApiRecommendationRepository(this._dio);

  final Dio _dio;

  @override
  Future<CareerRecommendationPage> listForSession(int sessionId) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/recommendations/sessions/$sessionId',
      );
      return CareerRecommendationPage.fromJson(
        readSuccessData(response.data),
      );
    });
  }

  @override
  Future<CareerRecommendationPage> generateForSession(int sessionId) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/recommendations/sessions/$sessionId/generate',
      );
      return CareerRecommendationPage.fromJson(
        readSuccessData(response.data),
      );
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
