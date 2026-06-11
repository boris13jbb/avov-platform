import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/institution.dart';

class InstitutionRemoteDatasource {
  InstitutionRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PaginatedInstitutions> listInstitutions({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? province,
    String? city,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/institutions',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (province != null && province.isNotEmpty) 'province': province,
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      return _parseData(
        response.data,
        PaginatedInstitutions.fromJson,
        'No se pudieron cargar las instituciones',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Institution> getInstitution(int id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/institutions/$id');
      return _parseData(
        response.data,
        Institution.fromJson,
        'No se pudo cargar la institución',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Institution> createInstitution(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/institutions',
        data: body,
      );
      return _parseData(
        response.data,
        Institution.fromJson,
        'No se pudo crear la institución',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Institution> uploadInstitutionLogo(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/institutions/$id/logo',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
          ),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      return _parseData(
        response.data,
        Institution.fromJson,
        'No se pudo subir el logo',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Institution> updateInstitution(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/institutions/$id',
        data: body,
      );
      return _parseData(
        response.data,
        Institution.fromJson,
        'No se pudo actualizar la institución',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<Institution> deactivateInstitution(int id) async {
    try {
      final response =
          await _dio.delete<Map<String, dynamic>>('/institutions/$id');
      return _parseData(
        response.data,
        Institution.fromJson,
        'No se pudo desactivar la institución',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  T _parseData<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) fromJson,
    String fallbackMessage,
  ) {
    if (body == null || body['success'] != true) {
      throw AppException(body?['message'] as String? ?? fallbackMessage);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AppException('Respuesta de institución inválida');
    }
    return fromJson(data);
  }
}
