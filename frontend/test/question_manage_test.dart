import 'package:avov_frontend/features/questions/domain/question.dart';
import 'package:avov_frontend/features/questions/domain/question_repository.dart';
import 'package:avov_frontend/features/questions/presentation/providers/question_provider.dart';
import 'package:avov_frontend/features/questions/presentation/screens/question_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = VocationalQuestion(
    id: 12,
    categoryId: 1,
    category: RiasecCategoryBrief(id: 1, code: 'R', name: 'Realista'),
    text: 'Me gusta reparar objetos mecánicos con mis manos.',
    orderNumber: 3,
    status: 'ACTIVE',
  );

  testWidgets('el listado de preguntas muestra categoría y texto', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(
            _MemoryRepo(items: const [sample]),
          ),
        ],
        child: const MaterialApp(home: QuestionListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('R · Orden 3'), findsOneWidget);
    expect(find.textContaining('reparar objetos mecánicos'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
  });
}

class _MemoryRepo implements QuestionRepository {
  _MemoryRepo({this.items = const []});

  final List<VocationalQuestion> items;

  @override
  Future<QuestionPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? categoryCode,
    String? status,
  }) async {
    return QuestionPage(
      items: items,
      total: items.length,
      page: 1,
      pages: items.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<VocationalQuestion> getById(int id) => throw UnimplementedError();

  @override
  Future<List<RiasecCategoryBrief>> discoverCategories() async => const [];

  @override
  Future<VocationalQuestion> create(QuestionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<VocationalQuestion> update(int id, QuestionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<VocationalQuestion> updateStatus({
    required int id,
    required String status,
  }) =>
      throw UnimplementedError();
}
