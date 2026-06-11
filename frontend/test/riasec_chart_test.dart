import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/shared/widgets/riasec_chart.dart';

void main() {
  testWidgets('RiasecChart muestra las seis categorías', (tester) async {
    const scores = RiasecScores(
      scoreR: 30,
      scoreI: 45,
      scoreA: 20,
      scoreS: 35,
      scoreE: 25,
      scoreC: 40,
      dominantProfile: 'I',
      secondaryProfile: 'C',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RiasecChart(scores: scores),
        ),
      ),
    );

    expect(find.text('Realista'), findsOneWidget);
    expect(find.text('Investigador'), findsOneWidget);
    expect(find.text('Artístico'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Emprendedor'), findsOneWidget);
    expect(find.text('Convencional'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });

  test('RiasecScores.fromMap parsea puntajes', () {
    final scores = RiasecScores.fromMap({
      'score_r': 10,
      'score_i': 20,
      'score_a': 30,
      'score_s': 40,
      'score_e': 50,
      'score_c': 60,
      'dominant_profile': 'C',
    });

    expect(scores.scoreC, 60);
    expect(scores.dominantProfile, 'C');
    expect(scores.isHighlighted('C'), isTrue);
    expect(scores.isHighlighted('R'), isFalse);
  });
}
