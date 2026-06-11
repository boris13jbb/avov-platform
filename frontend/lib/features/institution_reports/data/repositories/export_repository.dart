import '../datasources/export_remote_datasource.dart';

class ExportRepository {
  ExportRepository({required ExportRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final ExportRemoteDatasource _remoteDatasource;

  Future<ExportFile> downloadStudentsCsv() =>
      _remoteDatasource.downloadStudentsCsv();

  Future<ExportFile> downloadTestResultsCsv() =>
      _remoteDatasource.downloadTestResultsCsv();
}
