import 'report_history.dart';

/// Contrato de descarga e historial de informes PDF vocacionales.
abstract class ReportRepository {
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId);

  Future<ReportHistoryPage> listStudentReports(
    int studentId, {
    int page = 1,
    int pageSize = 20,
  });
}

class VocationalPdfFile {
  const VocationalPdfFile({
    required this.bytes,
    required this.filename,
    this.reportCode,
  });

  final List<int> bytes;
  final String filename;
  final String? reportCode;
}
