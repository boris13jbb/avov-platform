import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/counselor_observation.dart';
import '../../../../core/models/recommendation.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/test_session.dart';
import '../../../../core/providers/providers.dart';
import '../../../results/data/repositories/results_repository.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../students/data/datasources/student_remote_datasource.dart';
import '../../../students/data/repositories/student_repository.dart';
import '../../../vocational_test/data/datasources/test_remote_datasource.dart';
import '../../../vocational_test/data/repositories/test_repository.dart';

class CounselorStudentCase {
  const CounselorStudentCase({
    required this.student,
    this.recommendations,
    this.riasec,
  });

  final ManagedStudent student;
  final RecommendationList? recommendations;
  final RiasecResult? riasec;

  int? get testSessionId =>
      riasec?.testSessionId ?? recommendations?.testSessionId;

  bool get hasRecommendations =>
      recommendations != null && recommendations!.items.isNotEmpty;

  bool get canAddObservation => testSessionId != null;
}

final counselorStudentCaseProvider =
    FutureProvider.family<CounselorStudentCase, int>((ref, studentId) async {
  final studentRepo = StudentRepository(
    remoteDatasource: StudentRemoteDatasource(ref.watch(dioClientProvider).dio),
  );
  final resultsRepo = ref.watch(resultsRepositoryProvider);
  final testRepo = TestRepository(
    remoteDatasource: TestRemoteDatasource(ref.watch(dioClientProvider).dio),
  );

  final student = await studentRepo.getStudent(studentId);

  RecommendationList? recommendations;
  RiasecResult? riasec;

  try {
    recommendations = await resultsRepo.listStudentRecommendations(studentId);
    riasec = await testRepo.getResult(recommendations.testSessionId);
  } on AppException catch (error) {
    if (error.message.contains('test vocacional completado')) {
      recommendations = null;
      riasec = null;
    } else {
      rethrow;
    }
  }

  return CounselorStudentCase(
    student: student,
    recommendations: recommendations,
    riasec: riasec,
  );
});

final counselorObservationProvider =
    StateNotifierProvider<CounselorObservationController, AsyncValue<void>>(
  (ref) => CounselorObservationController(ref.watch(resultsRepositoryProvider)),
);

class CounselorObservationController extends StateNotifier<AsyncValue<void>> {
  CounselorObservationController(this._repository) : super(const AsyncData(null));

  final ResultsRepository _repository;

  Future<CounselorObservation?> submit({
    required int testSessionId,
    required String observation,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.addCounselorObservationBySession(
        testSessionId: testSessionId,
        observation: observation,
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
