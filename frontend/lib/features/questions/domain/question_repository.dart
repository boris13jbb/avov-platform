import 'question.dart';

abstract class QuestionRepository {
  Future<QuestionPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? categoryCode,
    String? status,
  });

  Future<VocationalQuestion> getById(int id);

  Future<List<RiasecCategoryBrief>> discoverCategories();

  Future<VocationalQuestion> create(QuestionDraft draft);

  Future<VocationalQuestion> update(int id, QuestionDraft draft);

  Future<VocationalQuestion> updateStatus({
    required int id,
    required String status,
  });
}
