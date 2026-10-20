import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/providers/providers.dart';
import '../../data/api_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_tokens.dart';

class AuthSessionState {
  const AuthSessionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.profile,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final UserProfile? profile;

  AuthSessionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    UserProfile? profile,
  }) {
    return AuthSessionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      profile: profile ?? this.profile,
    );
  }
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() => const AuthSessionState();

  /// Ignora una segunda pulsación mientras la primera sigue en curso.
  Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final profile = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      ref.read(sessionListenableProvider).notifyAuthChanged();
      state = AuthSessionState(profile: profile);
      return profile;
    } on AppException catch (error) {
      state = AuthSessionState(errorMessage: error.message);
      return null;
    } catch (_) {
      state = const AuthSessionState(
        errorMessage: FailureMapper.unexpectedMessage,
      );
      return null;
    }
  }

  /// Cierra la sesión una sola vez. Un fallo de red no conserva el estado.
  Future<void> logout() async {
    if (state.isSubmitting) {
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // El repositorio ya borra los tokens locales antes de propagar el fallo.
    } finally {
      ref.read(sessionListenableProvider).notifyAuthChanged();
      state = const AuthSessionState();
    }
  }
}

final apiAuthRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  return ApiAuthRepository(
    dio: ref.watch(dioClientProvider).dio,
    storage: ref.watch(tokenStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(apiAuthRepositoryProvider);
});

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
  AuthSessionNotifier.new,
);
