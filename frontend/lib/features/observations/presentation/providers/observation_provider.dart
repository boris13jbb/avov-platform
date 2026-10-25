import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_observation_repository.dart';
import '../../domain/observation.dart';
import '../../domain/observation_repository.dart';

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  return ApiObservationRepository(ref.watch(dioClientProvider).dio);
});

final sessionObservationsProvider = FutureProvider.autoDispose
    .family<ObservationPage, int>((ref, testSessionId) async {
  final repo = ref.watch(observationRepositoryProvider);
  return repo.listBySession(testSessionId: testSessionId);
});

final latestSessionObservationProvider = FutureProvider.autoDispose
    .family<CounselorObservation, int>((ref, testSessionId) async {
  final repo = ref.watch(observationRepositoryProvider);
  return repo.latestForSession(testSessionId);
});
