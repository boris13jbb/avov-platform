import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/institution.dart';
import '../../../../core/models/managed_user.dart';
import '../../../../core/providers/providers.dart';
import '../../../institutions/presentation/providers/institution_provider.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository.dart';

final userRemoteDatasourceProvider = Provider<UserRemoteDatasource>((ref) {
  return UserRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    remoteDatasource: ref.watch(userRemoteDatasourceProvider),
  );
});

class UserListQuery {
  const UserListQuery({
    this.page = 1,
    this.search,
    this.role,
    this.institutionId,
    this.status,
  });

  final int page;
  final String? search;
  final String? role;
  final int? institutionId;
  final String? status;

  UserListQuery copyWith({
    int? page,
    String? search,
    String? role,
    int? institutionId,
    String? status,
    bool clearSearch = false,
    bool clearRole = false,
    bool clearInstitution = false,
    bool clearStatus = false,
  }) {
    return UserListQuery(
      page: page ?? this.page,
      search: clearSearch ? null : (search ?? this.search),
      role: clearRole ? null : (role ?? this.role),
      institutionId:
          clearInstitution ? null : (institutionId ?? this.institutionId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserListQuery &&
        other.page == page &&
        other.search == search &&
        other.role == role &&
        other.institutionId == institutionId &&
        other.status == status;
  }

  @override
  int get hashCode =>
      Object.hash(page, search, role, institutionId, status);
}

final userListProvider =
    FutureProvider.family<PaginatedUsers, UserListQuery>((ref, query) {
  return ref.watch(userRepositoryProvider).listUsers(
        page: query.page,
        search: query.search,
        role: query.role,
        institutionId: query.institutionId,
        status: query.status,
      );
});

final userDetailProvider =
    FutureProvider.family<ManagedUser, int>((ref, id) {
  return ref.watch(userRepositoryProvider).getUser(id);
});

final activeInstitutionsProvider =
    FutureProvider<List<Institution>>((ref) async {
  final repository = ref.watch(institutionRepositoryProvider);
  final result = await repository.listInstitutions(
    page: 1,
    pageSize: 100,
    status: InstitutionStatus.active.apiValue,
  );
  return result.items;
});

final userMutationProvider =
    StateNotifierProvider<UserMutationController, AsyncValue<void>>(
  (ref) => UserMutationController(ref.watch(userRepositoryProvider)),
);

class UserMutationController extends StateNotifier<AsyncValue<void>> {
  UserMutationController(this._repository) : super(const AsyncData(null));

  final UserRepository _repository;

  Future<ManagedUser?> create(ManagedUser user, {required String password}) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.createUser(user, password: password);
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<ManagedUser?> update(ManagedUser user) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateUser(user);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    state = const AsyncLoading();
    try {
      await _repository.updateUserStatus(id, status);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
