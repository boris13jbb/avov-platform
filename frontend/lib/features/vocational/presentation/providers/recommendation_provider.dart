import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_recommendation_repository.dart';
import '../../domain/career_recommendation.dart';
import '../../domain/recommendation_repository.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return ApiRecommendationRepository(ref.watch(dioClientProvider).dio);
});

/// Lista persistida; si está vacía, genera vía POST una sola vez.
final sessionRecommendationsProvider = FutureProvider.autoDispose
    .family<CareerRecommendationPage, int>((ref, sessionId) async {
  final repo = ref.watch(recommendationRepositoryProvider);
  final listed = await repo.listForSession(sessionId);
  if (listed.total > 0) {
    return listed;
  }
  return repo.generateForSession(sessionId);
});
