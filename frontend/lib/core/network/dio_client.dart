import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient({
    AppConfig? config,
    AuthInterceptor? authInterceptor,
  })  : _config = config ?? AppConfig.development,
        _dio = Dio(
          BaseOptions(
            baseUrl: (config ?? AppConfig.development).apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    final interceptor = authInterceptor ??
        AuthInterceptor(apiBaseUrl: _config.apiBaseUrl);
    _dio.interceptors.add(interceptor);
    interceptor.bindClient(_dio);
  }

  final AppConfig _config;
  final Dio _dio;

  Dio get dio => _dio;

  AppConfig get config => _config;
}
