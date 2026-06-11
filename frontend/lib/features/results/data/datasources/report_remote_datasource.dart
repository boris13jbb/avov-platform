import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';

class ReportPdfFile {
  const ReportPdfFile({
    required this.bytes,
    required this.fileName,
    required this.reportCode,
    required this.generated,
  });

  final List<int> bytes;
  final String fileName;
  final String reportCode;
  final bool generated;
}

class ReportRemoteDatasource {
  ReportRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ReportPdfFile> downloadPdf(int testSessionId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/reports/$testSessionId/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw AppException('El archivo PDF está vacío');
      }

      final headers = response.headers;
      final reportCode = headers.value('x-report-code') ?? 'reporte-$testSessionId';
      final generated = headers.value('x-report-generated') == 'true';
      final disposition = headers.value('content-disposition') ?? '';
      final fileName = _extractFileName(disposition) ?? '$reportCode.pdf';

      return ReportPdfFile(
        bytes: bytes,
        fileName: fileName,
        reportCode: reportCode,
        generated: generated,
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  String? _extractFileName(String disposition) {
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return match?.group(1);
  }
}
