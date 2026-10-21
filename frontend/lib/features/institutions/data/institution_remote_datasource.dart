import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/institution.dart';
import '../domain/institution_repository.dart';

class ApiInstitutionRepository implements InstitutionRepository {
  ApiInstitutionRepository(this._dio);

  final Dio _dio;

  @override
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  }) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/institutions',
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      return _parsePage(response.data);
    });
  }

  @override
  Future<Institution> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/institutions/$id');
      return Institution.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Institution> create(InstitutionDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/institutions',
        data: draft.toJson(),
      );
      return Institution.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Institution> update(int id, InstitutionDraft draft) {
    return _write('/institutions/$id', draft.toUpdateJson());
  }

  @override
  Future<Institution> deactivate(int id) {
    return _send(() async {
      final response = await _dio.delete<dynamic>('/institutions/$id');
      return Institution.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Institution> activate(int id) {
    return _write('/institutions/$id', const <String, dynamic>{
      'status': 'ACTIVE',
    });
  }

  Future<Institution> _write(String path, Map<String, dynamic> body) {
    return _send(() async {
      final response = await _dio.put<dynamic>(path, data: body);
      return Institution.fromJson(readSuccessData(response.data));
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

  InstitutionPage _parsePage(Object? raw) {
    final data = readSuccessData(raw);
    final itemsRaw = data['items'];
    final total = data['total'];
    final page = data['page'];
    final pages = data['pages'];
    if (itemsRaw is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Página de instituciones incompleta');
    }
    return InstitutionPage(
      items: [
        for (final item in itemsRaw)
          if (item is Map<String, dynamic>)
            Institution.fromJson(item)
          else if (item is Map)
            Institution.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Institución incompleta'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}
