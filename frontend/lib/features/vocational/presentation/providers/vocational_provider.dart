import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_vocational_repository.dart';
import '../../domain/vocational_repository.dart';
import '../../domain/vocational_test.dart';

final vocationalRepositoryProvider = Provider<VocationalRepository>((ref) {
  return ApiVocationalRepository(ref.watch(dioClientProvider).dio);
});

final vocationalQuestionsProvider = FutureProvider.autoDispose
    .family<VocationalQuestionnaire, int>((ref, sessionId) {
  return ref.watch(vocationalRepositoryProvider).questions(sessionId);
});

final vocationalResultProvider =
    FutureProvider.autoDispose.family<VocationalResult, int>((ref, sessionId) {
  return ref.watch(vocationalRepositoryProvider).result(sessionId);
});
