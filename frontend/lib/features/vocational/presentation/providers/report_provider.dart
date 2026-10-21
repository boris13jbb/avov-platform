import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_report_repository.dart';
import '../../domain/report_history.dart';
import '../../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository(ref.watch(dioClientProvider).dio);
});

/// Historial paginado de informes PDF de un estudiante.
final studentReportsHistoryProvider =
    FutureProvider.autoDispose.family<ReportHistoryPage, int>((ref, studentId) {
  return ref.watch(reportRepositoryProvider).listStudentReports(studentId);
});
