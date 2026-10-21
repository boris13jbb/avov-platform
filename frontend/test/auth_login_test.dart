import 'dart:async';
import 'dart:typed_data';

import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/core/errors/failure_mapper.dart';
import 'package:avov_frontend/core/network/auth_interceptor.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:avov_frontend/features/auth/data/api_auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_repository.dart';
import 'package:avov_frontend/features/auth/domain/auth_tokens.dart';
import 'package:avov_frontend/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:avov_frontend/router/role_destination.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  });

  test('el destino depende del rol devuelto por el backend', () {
    expect(destinationForRole('SUPER_ADMIN'), '/admin/dashboard');
    expect(destinationForRole('INSTITUTION_ADMIN'), '/institution/dashboard');
    expect(destinationForRole('COUNSELOR'), '/counselor/dashboard');
    expect(destinationForRole('STUDENT'), '/student/dashboard');
    expect(destinationForRole(null), '/unauthorized');
    expect(destinationForRole('OTRO'), '/unauthorized');
  });

  test('login exitoso guarda los dos tokens y el rol', () async {
    final repository = _repository(
      storage,
      script: [
        _ok(_tokenBody()),
        _ok(_profileBody(role: 'COUNSELOR')),
      ],
    );

    final profile = await repository.login(
      email: 'persona@escuela.test',
      password: 'clave-prueba',
    );

    expect(profile.role, 'COUNSELOR');
    expect(await storage.getAccessToken(), 'access-de-prueba');
    expect(await storage.getRefreshToken(), 'refresh-de-prueba');
    expect(await storage.getUserRole(), 'COUNSELOR');
  });

  test('una contraseña incorrecta no guarda tokens ni muestra el cuerpo interno',
      () async {
    await storage.saveAccessToken('sesion-previa');
    final repository = _repository(
      storage,
      script: [
        _fail(
          401,
          message: 'Credenciales incorrectas. SQLSTATE detalle interno',
        ),
      ],
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(
        isA<UnauthorizedException>().having(
          (error) => error.message,
          'message',
          FailureMapper.invalidCredentialsMessage,
        ),
      ),
    );
    expect(await storage.getAccessToken(), 'sesion-previa');
  });

  test('una cuenta inactiva conserva el mensaje seguro del backend', () async {
    final repository = _repository(
      storage,
      script: [
        _fail(401, message: FailureMapper.inactiveAccountMessage),
      ],
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(
        isA<UnauthorizedException>().having(
          (error) => error.message,
          'message',
          FailureMapper.inactiveAccountMessage,
        ),
      ),
    );
  });

  test('un fallo de conexión no guarda tokens', () async {
    final repository = _repository(
      storage,
      script: [_connectionFailure()],
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(
        isA<NetworkException>().having(
          (error) => error.message,
          'message',
          FailureMapper.connectionMessage,
        ),
      ),
    );
    expect(await storage.getAccessToken(), isNull);
  });

  test('HTTP 429 informa la espera y no reintenta el login', () async {
    var loginCalls = 0;
    final repository = _repository(
      storage,
      script: [_fail(429, message: 'detalle interno')],
      onLogin: () => loginCalls += 1,
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          FailureMapper.tooManyRequestsMessage,
        ),
      ),
    );
    expect(loginCalls, 1);
    expect(await storage.getAccessToken(), isNull);
  });

  test('HTTP 403 no muestra el detalle interno', () {
    final error = FailureMapper.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 403,
          data: const <String, dynamic>{
            'message': 'detalle interno del servidor',
          },
        ),
      ),
    );

    expect(error.statusCode, 403);
    expect(error.message, FailureMapper.forbiddenMessage);
    expect(error.message, isNot(contains('detalle interno')));
  });

  test('HTTP 503 usa un mensaje controlado', () async {
    final repository = _repository(
      storage,
      script: [
        _fail(
          503,
          message: 'No se pudo comprobar el límite de intentos de inicio de sesión.',
        ),
      ],
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          FailureMapper.unavailableMessage,
        ),
      ),
    );
  });

  test('si el perfil falla, la sesión recién guardada se limpia', () async {
    final repository = _repository(
      storage,
      script: [
        _ok(_tokenBody()),
        _fail(401, message: 'Token inválido o expirado'),
      ],
    );

    await expectLater(
      repository.login(
        email: 'persona@escuela.test',
        password: 'clave-prueba',
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUserRole(), isNull);
  });

  test('un 401 con refresh inválido limpia la sesión y avisa al enrutador',
      () async {
    await storage.saveAccessToken('access-de-prueba');
    await storage.saveRefreshToken('refresh-de-prueba');
    await storage.saveUserRole('STUDENT');
    var notified = false;
    final adapter = _StatusAdapter(401);
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
    refreshDio.httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
    dio.httpClientAdapter = adapter;
    final interceptor = AuthInterceptor(
      tokenStorage: storage,
      refreshDio: refreshDio,
      onSessionInvalidated: () => notified = true,
    );
    dio.interceptors.add(interceptor);
    interceptor.bindClient(dio);

    await expectLater(
      dio.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUserRole(), isNull);
    expect(notified, isTrue);
  });

  test('un 401 de login no borra una sesión anterior desde el interceptor',
      () async {
    await storage.saveAccessToken('sesion-previa');
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
    dio.httpClientAdapter = _StatusAdapter(401);
    final interceptor = AuthInterceptor(tokenStorage: storage);
    dio.interceptors.add(interceptor);
    interceptor.bindClient(dio);

    await expectLater(
      dio.post<dynamic>('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getAccessToken(), 'sesion-previa');
  });

  test('el notifier ignora un segundo login mientras el primero sigue activo',
      () async {
    final repository = _SlowRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(authSessionProvider.notifier);

    final first = notifier.login(email: 'persona@escuela.test', password: 'a');
    final second = notifier.login(email: 'persona@escuela.test', password: 'b');
    repository.finish();
    await Future.wait([first, second]);

    expect(repository.calls, 1);
    expect(container.read(authSessionProvider).profile?.role, 'STUDENT');
  });
}

class _SlowRepository implements AuthRepository {
  final Completer<UserProfile> _pending = Completer<UserProfile>();
  int calls = 0;

  void finish() {
    if (!_pending.isCompleted) {
      _pending.complete(
        const UserProfile(
          id: 1,
          email: 'persona@escuela.test',
          firstName: 'Ana',
          lastName: 'Pérez',
          role: 'STUDENT',
          status: 'ACTIVE',
        ),
      );
    }
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) {
    calls += 1;
    return _pending.future;
  }

  @override
  Future<UserProfile> currentProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}
}

ApiAuthRepository _repository(
  SecureTokenStorage storage, {
  required List<_ScriptedResponse> script,
  void Function()? onLogin,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.uri.path.contains('/auth/login')) {
          onLogin?.call();
        }
        if (script.isEmpty) {
          handler.reject(_dioError(options, 500, message: 'sin guion'));
          return;
        }
        final next = script.removeAt(0);
        if (next.error != null) {
          handler.reject(next.error!(options));
          return;
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: next.data,
          ),
        );
      },
    ),
  );
  return ApiAuthRepository(dio: dio, storage: storage);
}

class _ScriptedResponse {
  _ScriptedResponse.ok(this.data) : error = null;

  _ScriptedResponse.fail(this.error) : data = null;

  final Object? data;
  final DioException Function(RequestOptions options)? error;
}

_ScriptedResponse _ok(Object data) => _ScriptedResponse.ok(data);

_ScriptedResponse _fail(int status, {required String message}) {
  return _ScriptedResponse.fail(
    (options) => _dioError(options, status, message: message),
  );
}

_ScriptedResponse _connectionFailure() {
  return _ScriptedResponse.fail(
    (options) => DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'SocketException: conexión rechazada',
    ),
  );
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"success":false,"message":"Token inválido","data":null,"errors":[]}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioException _dioError(
  RequestOptions options,
  int status, {
  required String message,
}) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        'success': false,
        'message': message,
        'data': null,
        'errors': <Map<String, String>>[],
      },
    ),
  );
}

Map<String, dynamic> _tokenBody() {
  return <String, dynamic>{
    'success': true,
    'message': 'Inicio de sesión exitoso',
    'data': <String, dynamic>{
      'access_token': 'access-de-prueba',
      'refresh_token': 'refresh-de-prueba',
      'token_type': 'bearer',
      'expires_in': 1800,
    },
    'errors': <Map<String, String>>[],
  };
}

Map<String, dynamic> _profileBody({required String role}) {
  return <String, dynamic>{
    'success': true,
    'message': 'Perfil obtenido correctamente',
    'data': <String, dynamic>{
      'id': 7,
      'email': 'persona@escuela.test',
      'first_name': 'Ana',
      'last_name': 'Pérez',
      'role': role,
      'status': 'ACTIVE',
      'institution_id': 3,
      'phone': null,
      'avatar_url': null,
      'last_login_at': null,
    },
    'errors': <Map<String, String>>[],
  };
}
