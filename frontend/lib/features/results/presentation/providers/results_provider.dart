import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/models/recommendation.dart';
import '../../../../core/providers/providers.dart';
import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/results_repository.dart';

final recommendationRemoteDatasourceProvider =
    Provider<RecommendationRemoteDatasource>((ref) {
  return RecommendationRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final reportRemoteDatasourceProvider = Provider<ReportRemoteDatasource>((ref) {
  return ReportRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return ResultsRepository(
    recommendationDatasource: ref.watch(recommendationRemoteDatasourceProvider),
    reportDatasource: ref.watch(reportRemoteDatasourceProvider),
  );
});

final studentRecommendationsProvider =
    FutureProvider.family<RecommendationList, int>((ref, studentId) {
  return ref.watch(resultsRepositoryProvider).listStudentRecommendations(studentId);
});

final resultsMutationProvider =
    StateNotifierProvider<ResultsMutationController, AsyncValue<void>>(
  (ref) => ResultsMutationController(ref.watch(resultsRepositoryProvider)),
);

class ResultsMutationController extends StateNotifier<AsyncValue<void>> {
  ResultsMutationController(this._repository) : super(const AsyncData(null));

  final ResultsRepository _repository;

  Future<RecommendationList?> generateRecommendations({int? testSessionId}) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.generateRecommendations(
        testSessionId: testSessionId,
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<String?> downloadAndOpenPdf(int testSessionId) async {
    state = const AsyncLoading();
    try {
      final file = await _repository.downloadPdf(testSessionId);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${file.fileName}';
      await File(path).writeAsBytes(file.bytes);
      await OpenFilex.open(path);
      state = const AsyncData(null);
      return file.reportCode;
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
