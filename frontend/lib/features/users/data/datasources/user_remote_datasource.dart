import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/models/managed_user.dart';

class UserRemoteDatasource {
  UserRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PaginatedUsers> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    int? institutionId,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null && role.isNotEmpty) 'role': role,
          if (institutionId != null) 'institution_id': institutionId,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return _parseData(
        response.data,
        PaginatedUsers.fromJson,
        'No se pudieron cargar los usuarios',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedUser> getUser(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/$id');
      return _parseData(
        response.data,
        ManagedUser.fromJson,
        'No se pudo cargar el usuario',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedUser> createUser(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users',
        data: body,
      );
      return _parseData(
        response.data,
        ManagedUser.fromJson,
        'No se pudo crear el usuario',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedUser> updateUser(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/$id',
        data: body,
      );
      return _parseData(
        response.data,
        ManagedUser.fromJson,
        'No se pudo actualizar el usuario',
      );
    } on DioException catch (error) {
      throw FailureMapper.fromDioException(error);
    }
  }

  Future<ManagedUser> updateUserStatus(int id, String status) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/$id/status',
        data: {'status': status},
      );
      return _parseData(
        response.data,
        ManagedUser.fromJson,
        'No se pudo actualizar el estado del usuario',
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
      throw AppException('Respuesta de usuario inválida');
    }
    return fromJson(data);
  }
}
