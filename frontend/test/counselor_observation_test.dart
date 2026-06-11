import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/core/models/counselor_observation.dart';

void main() {
  test('CounselorObservation fromJson parsea respuesta', () {
    final observation = CounselorObservation.fromJson({
      'id': 1,
      'test_session_id': 17,
      'counselor_id': 5,
      'observation': 'Buen encaje con carreras técnicas.',
      'created_at': '2026-06-09T10:00:00',
      'updated_at': '2026-06-09T10:00:00',
    });

    expect(observation.id, 1);
    expect(observation.testSessionId, 17);
    expect(observation.observation, contains('técnicas'));
  });
}
