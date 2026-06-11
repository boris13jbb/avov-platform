import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepository {
  DashboardRepository({required DashboardRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final DashboardRemoteDatasource _remoteDatasource;

  Future<Map<String, dynamic>> getSuperAdminDashboard() =>
      _remoteDatasource.getSuperAdminDashboard();

  Future<Map<String, dynamic>> getInstitutionDashboard() =>
      _remoteDatasource.getInstitutionDashboard();

  Future<Map<String, dynamic>> getCounselorDashboard() =>
      _remoteDatasource.getCounselorDashboard();

  Future<Map<String, dynamic>> getStudentDashboard() =>
      _remoteDatasource.getStudentDashboard();
}
