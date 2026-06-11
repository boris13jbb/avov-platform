import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardRemoteDatasourceProvider = Provider<DashboardRemoteDatasource>(
  (ref) => DashboardRemoteDatasource(ref.watch(dioClientProvider).dio),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    remoteDatasource: ref.watch(dashboardRemoteDatasourceProvider),
  ),
);

final superAdminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getSuperAdminDashboard();
});

final institutionDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getInstitutionDashboard();
});

final counselorDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getCounselorDashboard();
});

final studentDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStudentDashboard();
});
