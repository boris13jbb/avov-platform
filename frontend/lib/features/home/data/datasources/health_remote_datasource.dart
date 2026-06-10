import 'package:dio/dio.dart';

class HealthRemoteDatasource {
  HealthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/health/live');
    return response.data ?? {};
  }
}
