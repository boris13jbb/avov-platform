/// Contrato de descarga de informe PDF vocacional.
abstract class ReportRepository {
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId);
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
