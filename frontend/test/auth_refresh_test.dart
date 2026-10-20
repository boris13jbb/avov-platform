import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avov_frontend/core/network/auth_interceptor.dart';
import 'package:avov_frontend/core/session/session_listenable.dart';
import 'package:avov_frontend/core/storage/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = SecureTokenStorage(storage: const FlutterSecureStorage());
  });

  test('access vigente no llama a refresh', () async {
    await storage.saveAccessToken('access-vigente');
    await storage.saveRefreshToken('refresh-vigente');
    final adapter = _ScriptAdapter([
      _okBody({'ok': true}),
    ]);
    final client = _boundClient(storage, adapter);

    final response = await client.get<dynamic>('/tests/1/questions');
    expect(response.statusCode, 200);
    expect(adapter.refreshCalls, 0);
    expect(adapter.otherCalls, 1);
    expect(await storage.getAccessToken(), 'access-vigente');
  });

  test('access expirado y refresh válido renueva y recupera la petición', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-viejo');
    final adapter = _ScriptAdapter([
      _failBody(401),
      _tokenBody(access: 'access-nuevo', refresh: 'refresh-nuevo'),
      _okBody({'recovered': true}),
    ]);
    final client = _boundClient(storage, adapter);

    final response = await client.get<dynamic>('/auth/me');
    expect(response.data['recovered'], isTrue);
    expect(adapter.refreshCalls, 1);
    expect(await storage.getAccessToken(), 'access-nuevo');
    expect(await storage.getRefreshToken(), 'refresh-nuevo');
  });

  test('refresh inválido limpia la sesión', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-invalido');
    var notified = 0;
    final adapter = _ScriptAdapter([
      _failBody(401),
      _failBody(401),
    ]);
    final client = _boundClient(
      storage,
      adapter,
      onSessionInvalidated: () => notified += 1,
    );

    await expectLater(
      client.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(notified, 1);
  });

  test('error de red en refresh no destruye la sesión', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-vigente');
    final adapter = _ScriptAdapter([
      _failBody(401),
      _connectionError(),
    ]);
    final client = _boundClient(storage, adapter);

    await expectLater(
      client.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getAccessToken(), 'access-viejo');
    expect(await storage.getRefreshToken(), 'refresh-vigente');
  });

  test('varias peticiones concurrentes con 401 ejecutan un solo refresh',
      () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-viejo');
    final adapter = _ScriptAdapter([
      _failBody(401),
      _failBody(401),
      _failBody(401),
      _tokenBody(access: 'access-nuevo', refresh: 'refresh-nuevo'),
      _okBody({'a': 1}),
      _okBody({'b': 2}),
      _okBody({'c': 3}),
    ]);
    final client = _boundClient(storage, adapter);

    final results = await Future.wait([
      client.get<dynamic>('/tests/1/questions'),
      client.get<dynamic>('/tests/2/questions'),
      client.get<dynamic>('/tests/3/questions'),
    ]);

    expect(adapter.refreshCalls, 1);
    expect(results.length, 3);
    expect(await storage.getAccessToken(), 'access-nuevo');
    expect(await storage.getRefreshToken(), 'refresh-nuevo');
  });

  test('la petición original no se reintenta indefinidamente', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-viejo');
    var notified = 0;
    final adapter = _ScriptAdapter([
      _failBody(401),
      _tokenBody(access: 'access-nuevo', refresh: 'refresh-nuevo'),
      _failBody(401),
    ]);
    final client = _boundClient(
      storage,
      adapter,
      onSessionInvalidated: () => notified += 1,
    );

    await expectLater(
      client.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.refreshCalls, 1);
    expect(notified, 1);
    expect(await storage.getAccessToken(), isNull);
  });

  test('login y refresh no generan ciclos de renovación', () async {
    final adapter = _ScriptAdapter([
      _failBody(401),
      _failBody(401),
    ]);
    final client = _boundClient(storage, adapter);
    await storage.saveAccessToken('access');
    await storage.saveRefreshToken('refresh');

    await expectLater(
      client.post<dynamic>('/auth/login', data: {'email': 'a', 'password': 'b'}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.refreshCalls, 0);
    expect(await storage.getAccessToken(), 'access');

    final refreshBefore = adapter.refreshCalls;
    await expectLater(
      client.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': 'refresh'},
      ),
      throwsA(isA<DioException>()),
    );
    // Solo la llamada directa a /auth/refresh; el interceptor no encadena otra.
    expect(adapter.refreshCalls, refreshBefore + 1);
    expect(await storage.getAccessToken(), 'access');
  });

  test('logout durante la renovación no restaura tokens antiguos', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-viejo');
    final gate = Completer<void>();
    final adapter = _ScriptAdapter([
      _failBody(401),
      _delayedToken(
        gate: gate,
        access: 'access-fantasma',
        refresh: 'refresh-fantasma',
      ),
    ]);
    final client = _boundClient(storage, adapter);

    final pending = client.get<dynamic>('/auth/me');
    await Future<void>.delayed(Duration.zero);
    await storage.clearTokens();
    gate.complete();

    await expectLater(pending, throwsA(isA<DioException>()));
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('el cuerpo de un POST se reenvía una sola vez tras renovar', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-viejo');
    final adapter = _ScriptAdapter([
      _failBody(401),
      _tokenBody(access: 'access-nuevo', refresh: 'refresh-nuevo'),
      _okBody({'saved': true}),
    ]);
    final client = _boundClient(storage, adapter);

    final response = await client.post<dynamic>(
      '/tests/15/answers',
      data: <String, dynamic>{
        'question_id': 3,
        'answer_value': 4,
      },
    );

    expect(response.data['saved'], isTrue);
    // Intento con access caducado + un único reintento tras renovar.
    expect(adapter.postBodies, hasLength(2));
    expect(adapter.postBodies.last['answer_value'], 4);
    expect(adapter.refreshCalls, 1);
  });

  test('refresh inválido notifica al enrutador para forzar el login', () async {
    await storage.saveAccessToken('access-viejo');
    await storage.saveRefreshToken('refresh-invalido');
    await storage.saveUserRole('STUDENT');
    final session = SessionListenable();
    var notifications = 0;
    session.addListener(() => notifications += 1);
    final adapter = _ScriptAdapter([
      _failBody(401),
      _failBody(401),
    ]);
    final client = _boundClient(
      storage,
      adapter,
      onSessionInvalidated: session.notifyAuthChanged,
    );

    await expectLater(
      client.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(notifications, 1);
  });
}

Dio _boundClient(
  SecureTokenStorage storage,
  _ScriptAdapter adapter, {
  void Function()? onSessionInvalidated,
}) {
  const baseUrl = 'http://127.0.0.1:8000/api/v1';
  final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
  refreshDio.httpClientAdapter = adapter;
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.httpClientAdapter = adapter;
  final interceptor = AuthInterceptor(
    tokenStorage: storage,
    refreshDio: refreshDio,
    onSessionInvalidated: onSessionInvalidated,
  );
  dio.interceptors.add(interceptor);
  interceptor.bindClient(dio);
  return dio;
}

class _QueuedItem {
  _QueuedItem.ok(this.body)
      : statusCode = 200,
        errorType = null,
        gate = null;

  _QueuedItem.fail(this.statusCode)
      : body = null,
        errorType = null,
        gate = null;

  _QueuedItem.connection()
      : statusCode = null,
        body = null,
        errorType = DioExceptionType.connectionError,
        gate = null;

  _QueuedItem.delayedOk(this.body, {required this.gate})
      : statusCode = 200,
        errorType = null;

  final int? statusCode;
  final Object? body;
  final DioExceptionType? errorType;
  final Completer<void>? gate;
}

_QueuedItem _okBody(Object body) => _QueuedItem.ok(body);

_QueuedItem _failBody(int status) => _QueuedItem.fail(status);

_QueuedItem _connectionError() => _QueuedItem.connection();

_QueuedItem _tokenBody({required String access, required String refresh}) {
  return _QueuedItem.ok(<String, dynamic>{
    'success': true,
    'message': 'Token renovado correctamente',
    'data': <String, dynamic>{
      'access_token': access,
      'refresh_token': refresh,
      'token_type': 'bearer',
      'expires_in': 1800,
    },
    'errors': <Map<String, String>>[],
  });
}

_QueuedItem _delayedToken({
  required Completer<void> gate,
  required String access,
  required String refresh,
}) {
  return _QueuedItem.delayedOk(
    <String, dynamic>{
      'success': true,
      'message': 'Token renovado correctamente',
      'data': <String, dynamic>{
        'access_token': access,
        'refresh_token': refresh,
        'token_type': 'bearer',
        'expires_in': 1800,
      },
      'errors': <Map<String, String>>[],
    },
    gate: gate,
  );
}

class _ScriptAdapter implements HttpClientAdapter {
  _ScriptAdapter(this._queue);

  final List<_QueuedItem> _queue;
  int refreshCalls = 0;
  int otherCalls = 0;
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isRefresh = options.uri.path.endsWith('/auth/refresh');
    if (isRefresh) {
      refreshCalls += 1;
    } else {
      otherCalls += 1;
      if (options.method == 'POST' && requestStream != null) {
        final chunks = await requestStream.toList();
        if (chunks.isNotEmpty) {
          final bytes = chunks.expand((chunk) => chunk).toList();
          final decoded = jsonDecode(utf8.decode(bytes));
          if (decoded is Map) {
            postBodies.add(Map<String, dynamic>.from(decoded));
          }
        }
      }
    }

    if (_queue.isEmpty) {
      return ResponseBody.fromString(
        '{"success":false,"message":"sin guion","data":null,"errors":[]}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final next = _queue.removeAt(0);
    final gate = next.gate;
    if (gate != null) {
      await gate.future;
    }
    if (next.errorType != null) {
      throw DioException(
        requestOptions: options,
        type: next.errorType!,
        message: 'conexión rechazada',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(next.body),
      next.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
