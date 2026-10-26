import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_career_repository.dart';
import '../../domain/career.dart';
import '../../domain/career_repository.dart';

final careerRepositoryProvider = Provider<CareerRepository>((ref) {
  return ApiCareerRepository(ref.watch(dioClientProvider).dio);
});

final careerPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final careerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final careerStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final careerListProvider = FutureProvider.autoDispose<CareerPage>((ref) {
  final page = ref.watch(careerPageProvider);
  final search = ref.watch(careerSearchProvider).trim();
  final status = ref.watch(careerStatusFilterProvider);
  return ref.watch(careerRepositoryProvider).list(
        page: page,
        pageSize: 20,
        search: search.isEmpty ? null : search,
        status: status,
      );
});

final careerDetailProvider =
    FutureProvider.autoDispose.family<Career, int>((ref, id) {
  return ref.watch(careerRepositoryProvider).getById(id);
});
