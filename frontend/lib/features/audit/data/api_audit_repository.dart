import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/audit_log.dart';
import '../domain/audit_repository.dart';

class ApiAuditRepository implements AuditRepository {
  ApiAuditRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuditLogPage> list(AuditLogQuery query) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/audit/logs',
        queryParameters: <String, dynamic>{
          'page': query.page,
          'page_size': query.pageSize,
          if (query.action != null && query.action!.trim().isNotEmpty)
            'action': query.action!.trim(),
          if (query.entity != null && query.entity!.trim().isNotEmpty)
            'entity': query.entity!.trim(),
        },
      );
      return AuditLogPage.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<AuditLogEntry> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/audit/logs/$id');
      return AuditLogEntry.fromJson(readSuccessData(response.data));
    });
  }

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    } on FormatException {
      throw AppException(FailureMapper.unexpectedMessage);
    }
  }
}
