import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../session/session_listenable.dart';
import '../storage/secure_token_storage.dart';

final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final sessionListenableProvider = Provider<SessionListenable>((ref) {
  final listenable = SessionListenable();
  ref.onDispose(listenable.dispose);
  return listenable;
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final session = ref.watch(sessionListenableProvider);
  return DioClient(
    authInterceptor: AuthInterceptor(
      tokenStorage: storage,
      onSessionInvalidated: session.notifyAuthChanged,
    ),
  );
});
