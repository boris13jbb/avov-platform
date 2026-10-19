import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../domain/managed_user.dart';
import '../domain/user_account_repository.dart';

class ApiUserAccountRepository implements UserAccountRepository {
  ApiUserAccountRepository(this._dio);

  final Dio _dio;

  @override
  Future<ManagedUserPage> list(UserListQuery query) {
    return _send(() async {
      final response = await _dio.get<dynamic>(
        '/users',
        queryParameters: <String, dynamic>{
          'page': query.page,
          'page_size': query.pageSize,
          if (query.search != null && query.search!.trim().isNotEmpty)
            'search': query.search!.trim(),
          if (query.role != null) 'role': query.role,
          if (query.status != null) 'status': query.status,
          if (query.institutionId != null)
            'institution_id': query.institutionId,
        },
      );
      return _parsePage(response.data);
    });
  }

  @override
  Future<ManagedUser> getById(int id) {
    return _send(() async {
      final response = await _dio.get<dynamic>('/users/$id');
      return ManagedUser.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedUser> create(UserDraft draft) {
    return _send(() async {
      final response = await _dio.post<dynamic>(
        '/users',
        data: draft.toCreateJson(),
      );
      return ManagedUser.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedUser> update(int id, UserDraft draft) {
    return _send(() async {
      final response = await _dio.put<dynamic>(
        '/users/$id',
        data: draft.toUpdateJson(),
      );
      return ManagedUser.fromJson(readSuccessData(response.data));
    });
  }

  @override
  Future<ManagedUser> updateStatus(int id, String status) {
    return _send(() async {
      final response = await _dio.patch<dynamic>(
        '/users/$id/status',
        data: <String, String>{'status': status},
      );
      return ManagedUser.fromJson(readSuccessData(response.data));
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

  ManagedUserPage _parsePage(Object? raw) {
    final data = readSuccessData(raw);
    final itemsRaw = data['items'];
    final total = data['total'];
    final page = data['page'];
    final pages = data['pages'];
    if (itemsRaw is! List || total is! int || page is! int || pages is! int) {
      throw const FormatException('Página de usuarios incompleta');
    }
    return ManagedUserPage(
      items: [
        for (final item in itemsRaw)
          if (item is Map<String, dynamic>)
            ManagedUser.fromJson(item)
          else if (item is Map)
            ManagedUser.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Usuario incompleto'),
      ],
      total: total,
      page: page,
      pages: pages,
    );
  }
}
