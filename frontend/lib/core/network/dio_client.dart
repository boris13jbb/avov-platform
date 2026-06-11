import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../storage/secure_token_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient({
    AppConfig? config,
    SecureTokenStorage? tokenStorage,
  })  : _config = config ?? AppConfig.development,
        _dio = Dio(
          BaseOptions(
            baseUrl: (config ?? AppConfig.development).apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 45),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    if (tokenStorage != null) {
      _dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    }
  }

  final AppConfig _config;
  final Dio _dio;

  Dio get dio => _dio;

  AppConfig get config => _config;
}
