import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/vector_admin_repository.dart';

class ApiVectorAdminRepository implements VectorAdminRepository {
  ApiVectorAdminRepository(this._dio);

  final Dio _dio;

  @override
  Future<RebuildCareersResult> rebuildCareersIndex() {
    return _send(() async {
      final response = await _dio.post<dynamic>('/vector/rebuild-careers');
      return RebuildCareersResult.fromJson(readSuccessData(response.data));
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
