import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/test_session.dart';
import '../../../../core/providers/providers.dart';
import '../../data/datasources/test_remote_datasource.dart';
import '../../data/repositories/test_repository.dart';

final testRemoteDatasourceProvider = Provider<TestRemoteDatasource>((ref) {
  return TestRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(
    remoteDatasource: ref.watch(testRemoteDatasourceProvider),
  );
});

final sessionQuestionsProvider =
    FutureProvider.family<SessionQuestions, int>((ref, sessionId) {
  return ref.watch(testRepositoryProvider).getSessionQuestions(sessionId);
});

final testResultProvider =
    FutureProvider.family<RiasecResult, int>((ref, sessionId) {
  return ref.watch(testRepositoryProvider).getResult(sessionId);
});

final testMutationProvider =
    StateNotifierProvider<TestMutationController, AsyncValue<void>>(
  (ref) => TestMutationController(ref.watch(testRepositoryProvider)),
);

class TestMutationController extends StateNotifier<AsyncValue<void>> {
  TestMutationController(this._repository) : super(const AsyncData(null));

  final TestRepository _repository;

  Future<TestSession?> startTest() async {
    state = const AsyncLoading();
    try {
      final session = await _repository.startTest();
      state = const AsyncData(null);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> saveAnswer({
    required int sessionId,
    required int questionId,
    required int answerValue,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.saveAnswer(
        sessionId: sessionId,
        questionId: questionId,
        answerValue: answerValue,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<RiasecResult?> finishTest(int sessionId) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.finishTest(sessionId);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
