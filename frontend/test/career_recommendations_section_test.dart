import 'package:avov_frontend/features/vocational/domain/career_recommendation.dart';
import 'package:avov_frontend/features/vocational/domain/recommendation_repository.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/recommendation_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/widgets/career_recommendations_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecRepo implements RecommendationRepository {
  _FakeRecRepo(this.page);

  final CareerRecommendationPage page;
  int generateCalls = 0;

  @override
  Future<CareerRecommendationPage> listForSession(int sessionId) async {
    return page;
  }

  @override
  Future<CareerRecommendationPage> generateForSession(int sessionId) async {
    generateCalls += 1;
    return page;
  }
}

void main() {
  testWidgets('muestra carreras recomendadas y no el mensaje estático antiguo',
      (tester) async {
    final page = CareerRecommendationPage(
      testSessionId: 139,
      studentId: 900000,
      riasecProfile: 'RIA',
      usedFallback: false,
      total: 1,
      items: const [
        CareerRecommendation(
          id: 1,
          careerId: 10,
          careerName: 'Ingeniería de Sistemas',
          careerArea: 'Tecnología',
          careerRiasecProfile: 'RIA',
          matchPercentage: 82,
          aiExplanation: 'Explicación de prueba.',
        ),
      ],
    );
    final repo = _FakeRecRepo(page);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareerRecommendationsSection(sessionId: 139),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carreras recomendadas'), findsOneWidget);
    expect(find.textContaining('Ingeniería de Sistemas'), findsOneWidget);
    expect(find.textContaining('82%'), findsOneWidget);
    expect(
      find.textContaining('no están disponibles'),
      findsNothing,
    );
  });

  testWidgets('lista vacía muestra mensaje coherente', (tester) async {
    final page = CareerRecommendationPage(
      testSessionId: 1,
      studentId: 1,
      riasecProfile: 'RIA',
      usedFallback: true,
      total: 0,
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(_FakeRecRepo(page)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CareerRecommendationsSection(sessionId: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No hay carreras compatibles'),
      findsOneWidget,
    );
    expect(find.textContaining('búsqueda alternativa'), findsOneWidget);
  });
}
