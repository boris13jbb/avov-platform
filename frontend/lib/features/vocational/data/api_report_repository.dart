import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/report_history.dart';
import '../domain/report_repository.dart';

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._dio);

  final Dio _dio;

  @override
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/reports/$sessionId/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'Accept': 'application/pdf'},
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw AppException('El servidor devolvió un informe vacío.');
      }
      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw AppException('El archivo recibido no es un PDF válido.');
      }
      final disposition = response.headers.value('content-disposition');
      final code = response.headers.value('x-report-code');
      final filename = _filenameFromDisposition(disposition) ??
          'informe-vocacional-$sessionId.pdf';
      return VocationalPdfFile(
        bytes: bytes,
        filename: filename,
        reportCode: code,
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on AppException {
      rethrow;
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }

  @override
  Future<ReportHistoryPage> listStudentReports(
    int studentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/reports/student/$studentId',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = readSuccessData(response.data);
      return ReportHistoryPage.fromJson(data);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on AppException {
      rethrow;
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }

  static String? _filenameFromDisposition(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(header);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw.contains('..') || raw.contains('/') || raw.contains('\\')) {
      return null;
    }
    return raw;
  }
}
