import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_question_repository.dart';
import '../../domain/question.dart';
import '../../domain/question_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return ApiQuestionRepository(ref.watch(dioClientProvider).dio);
});

final questionPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final questionSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final questionCategoryFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final questionStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final questionListProvider = FutureProvider.autoDispose<QuestionPage>((ref) {
  final page = ref.watch(questionPageProvider);
  final search = ref.watch(questionSearchProvider).trim();
  final categoryCode = ref.watch(questionCategoryFilterProvider);
  final status = ref.watch(questionStatusFilterProvider);
  return ref.watch(questionRepositoryProvider).list(
        page: page,
        pageSize: 20,
        search: search.isEmpty ? null : search,
        categoryCode: categoryCode,
        status: status,
      );
});

final questionDetailProvider =
    FutureProvider.autoDispose.family<VocationalQuestion, int>((ref, id) {
  return ref.watch(questionRepositoryProvider).getById(id);
});

final questionCategoryChoicesProvider =
    FutureProvider.autoDispose<List<RiasecCategoryBrief>>((ref) {
  return ref.watch(questionRepositoryProvider).discoverCategories();
});
