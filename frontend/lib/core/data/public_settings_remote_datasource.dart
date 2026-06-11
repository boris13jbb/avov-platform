import 'package:dio/dio.dart';

import '../models/public_settings.dart';

class PublicSettingsRemoteDatasource {
  PublicSettingsRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PublicSettings> fetchPublicSettings() async {
    final response = await _dio.get('/settings/public');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return PublicSettings.fromJson(data);
  }
}
