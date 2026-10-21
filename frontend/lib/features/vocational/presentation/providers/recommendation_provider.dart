import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_recommendation_repository.dart';
import '../../domain/career_recommendation.dart';
import '../../domain/recommendation_repository.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return ApiRecommendationRepository(ref.watch(dioClientProvider).dio);
});

/// Lista persistida. No genera automáticamente al abrir el resultado
/// (evita efectos secundarios al consultar o descargar PDF).
final sessionRecommendationsProvider = FutureProvider.autoDispose
    .family<CareerRecommendationPage, int>((ref, sessionId) async {
  final repo = ref.watch(recommendationRepositoryProvider);
  return repo.listForSession(sessionId);
});
