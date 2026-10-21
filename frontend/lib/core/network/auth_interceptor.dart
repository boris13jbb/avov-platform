import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../features/auth/domain/auth_tokens.dart';
import '../storage/secure_token_storage.dart';

/// Adjunta el access token y renueva la sesión ante un 401 recuperable.
///
/// Usa un [Dio] sin este interceptor para `POST /auth/refresh`.
/// Varias peticiones concurrentes esperan la misma renovación.
/// Si el refresh token cambia o desaparece durante la renovación
/// (logout u otro inicio de sesión), los tokens nuevos se descartan.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    SecureTokenStorage? tokenStorage,
    Dio? refreshDio,
    String? apiBaseUrl,
    this.onSessionInvalidated,
  })  : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: apiBaseUrl ?? AppConfig.development.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  static const _retriedExtraKey = 'avov_auth_retried';

  final SecureTokenStorage _tokenStorage;
  final Dio _refreshDio;
  final void Function()? onSessionInvalidated;

  Dio? _client;
  Future<bool>? _ongoingRefresh;

  /// Enlaza el cliente que reintentará la petición original.
  void bindClient(Dio client) {
    _client = client;
  }

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
    if (!_shouldAttemptRefresh(err)) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[_retriedExtraKey] == true) {
      await _invalidateCurrentSession();
      handler.next(err);
      return;
    }

    final refreshed = await _refreshInFlight();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    final client = _client;
    if (client == null) {
      handler.next(err);
      return;
    }

    try {
      final request = err.requestOptions;
      request.extra[_retriedExtraKey] = true;
      final access = await _tokenStorage.getAccessToken();
      if (access == null || access.isEmpty) {
        handler.next(err);
        return;
      }
      request.headers['Authorization'] = 'Bearer $access';
      final response = await client.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldAttemptRefresh(DioException err) {
    if (err.response?.statusCode != 401) {
      return false;
    }
    if (_isAnonymous(err.requestOptions)) {
      return false;
    }
    return true;
  }

  Future<bool> _refreshInFlight() {
    final ongoing = _ongoingRefresh;
    if (ongoing != null) {
      return ongoing;
    }
    final started = _performRefresh();
    _ongoingRefresh = started;
    started.whenComplete(() {
      if (identical(_ongoingRefresh, started)) {
        _ongoingRefresh = null;
      }
    });
    return started;
  }

  Future<bool> _performRefresh() async {
    final expectedRefresh = await _tokenStorage.getRefreshToken();
    if (expectedRefresh == null || expectedRefresh.isEmpty) {
      await _invalidateCurrentSession();
      return false;
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: <String, String>{'refresh_token': expectedRefresh},
      );
      final tokens = AuthTokens.fromResponseData(response.data);
      final currentRefresh = await _tokenStorage.getRefreshToken();
      if (currentRefresh != expectedRefresh) {
        // Logout u otra sesión sustituyó los tokens.
        return false;
      }
      await _tokenStorage.saveAccessToken(tokens.accessToken);
      await _tokenStorage.saveRefreshToken(tokens.refreshToken);
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        final currentRefresh = await _tokenStorage.getRefreshToken();
        if (currentRefresh == expectedRefresh) {
          await _invalidateCurrentSession();
        }
        return false;
      }
      // Red o 5xx: no destruir una sesión que podría seguir siendo válida.
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _invalidateCurrentSession() async {
    await _tokenStorage.clearTokens();
    onSessionInvalidated?.call();
  }

  bool _isAnonymous(RequestOptions options) {
    final path = options.uri.path;
    return path.endsWith('/auth/login') || path.endsWith('/auth/refresh');
  }
}
