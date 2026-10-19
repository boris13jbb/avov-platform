import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    SecureTokenStorage? tokenStorage,
    this.onSessionInvalidated,
  }) : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final SecureTokenStorage _tokenStorage;
  final void Function()? onSessionInvalidated;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAnonymous(options)) {
      handler.next(options);
      return;
    }
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 && !_isAnonymous(err.requestOptions)) {
      await _tokenStorage.clearTokens();
      onSessionInvalidated?.call();
    }
    handler.next(err);
  }

  bool _isAnonymous(RequestOptions options) {
    final path = options.uri.path;
    return path.endsWith('/auth/login') || path.endsWith('/auth/refresh');
  }
}
