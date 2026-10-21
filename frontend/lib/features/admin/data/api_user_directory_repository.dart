import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/user_directory_repository.dart';

/// El total sale de `GET /users`. No existe un endpoint de resumen.
class ApiUserDirectoryRepository implements UserDirectoryRepository {
  ApiUserDirectoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<int> count() async {
    try {
      final response = await _dio.get<dynamic>(
        '/users',
        queryParameters: const <String, dynamic>{
          'page': 1,
          'page_size': 1,
        },
      );
      final total = readSuccessData(response.data)['total'];
      if (total is! int || total < 0) {
        throw AppException(FailureMapper.unexpectedMessage);
      }
      return total;
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }
}
