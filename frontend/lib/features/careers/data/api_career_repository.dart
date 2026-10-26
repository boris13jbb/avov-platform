import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/career.dart';
import '../domain/career_repository.dart';

class ApiCareerRepository implements CareerRepository {
  ApiCareerRepository(this._dio);

  final Dio _dio;

  @override
  Future<CareerPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? area,
    String? status,
  }) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/careers',
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
          if (status != null) 'status': status,
        },
      );
      return _parsePage(response.data);
    });
  }

  @override
  Future<Career> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/careers/$id');
      return Career.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Career> create(CareerDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/careers',
        data: draft.toJson(),
      );
      return Career.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Career> update(int id, CareerDraft draft) {
    return _send(() async {
      final response = await _dio.put<dynamic>(
        '/careers/$id',
        data: draft.toUpdateJson(),
      );
      return Career.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<Career> deactivate(int id) {
    return _send(() async {
      final response = await _dio.delete<dynamic>('/careers/$id');
      return Career.fromJson(readSuccessData(response.data));
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

  CareerPage _parsePage(Object? raw) {
    final data = readSuccessData(raw);
    final itemsRaw = data['items'];
    final total = data['total'];
    final page = data['page'];
    final pages = data['pages'];
    if (itemsRaw is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Página de carreras incompleta');
    }
    return CareerPage(
      items: [
        for (final item in itemsRaw)
          if (item is Map<String, dynamic>)
            Career.fromJson(item)
          else if (item is Map)
            Career.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Carrera incompleta'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}
