import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_report_repository.dart';
import '../../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository(ref.watch(dioClientProvider).dio);
});
