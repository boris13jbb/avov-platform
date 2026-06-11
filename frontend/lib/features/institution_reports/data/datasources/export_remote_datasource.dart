import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';

class ExportFile {
  const ExportFile({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}

class ExportRemoteDatasource {
  ExportRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ExportFile> downloadStudentsCsv() async {
    return _downloadCsv('/exports/students', 'estudiantes_institucion.csv');
  }

  Future<ExportFile> downloadTestResultsCsv() async {
    return _downloadCsv('/exports/test-results', 'resultados_test_institucion.csv');
  }

  Future<ExportFile> _downloadCsv(String path, String fallbackName) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw AppException('El archivo CSV está vacío');
      }

      final disposition = response.headers.value('content-disposition') ?? '';
      final fileName = _extractFileName(disposition) ?? fallbackName;

      return ExportFile(bytes: bytes, fileName: fileName);
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  String? _extractFileName(String disposition) {
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return match?.group(1);
  }
}
