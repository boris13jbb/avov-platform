import 'package:dio/dio.dart';

import '../../config/app_config.dart';

class DioClient {
  DioClient({AppConfig? config})
      : _config = config ?? AppConfig.development,
        _dio = Dio(
          BaseOptions(
            baseUrl: (config ?? AppConfig.development).apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final AppConfig _config;
  final Dio _dio;

  Dio get dio => _dio;

  AppConfig get config => _config;
}
