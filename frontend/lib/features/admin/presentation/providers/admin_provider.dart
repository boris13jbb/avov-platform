import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/career.dart';
import '../../../../core/models/question.dart';
import '../../../../core/models/system_setting.dart';
import '../../../../core/providers/providers.dart';
import '../../data/admin_remote_datasource.dart';
import '../../data/admin_repository.dart';

final adminRemoteDatasourceProvider = Provider<AdminRemoteDatasource>((ref) {
  return AdminRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    remoteDatasource: ref.watch(adminRemoteDatasourceProvider),
  );
});

class AdminListQuery {
  const AdminListQuery({
    this.page = 1,
    this.search,
    this.filter,
  });

  final int page;
  final String? search;
  final String? filter;

  AdminListQuery copyWith({
    int? page,
    String? search,
    String? filter,
    bool clearSearch = false,
    bool clearFilter = false,
  }) {
    return AdminListQuery(
      page: page ?? this.page,
      search: clearSearch ? null : (search ?? this.search),
      filter: clearFilter ? null : (filter ?? this.filter),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminListQuery &&
        other.page == page &&
        other.search == search &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(page, search, filter);
}

final careerListProvider =
    FutureProvider.family<PaginatedCareers, AdminListQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listCareers(
        page: query.page,
        search: query.search,
        status: query.filter,
      );
});

final careerDetailProvider = FutureProvider.family<Career, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getCareer(id);
});

final questionListProvider =
    FutureProvider.family<PaginatedQuestions, AdminListQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listQuestions(
        page: query.page,
        search: query.search,
        status: query.filter,
      );
});

final questionDetailProvider = FutureProvider.family<Question, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getQuestion(id);
});

final riasecCategoriesProvider = FutureProvider<List<RiasecCategory>>((ref) {
  return ref.watch(adminRepositoryProvider).listRiasecCategories();
});

final systemSettingsProvider = FutureProvider<List<SystemSetting>>((ref) {
  return ref.watch(adminRepositoryProvider).listSystemSettings();
});

final auditListProvider =
    FutureProvider.family<Map<String, dynamic>, AdminListQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listAuditLogs(
        page: query.page,
        action: query.search,
        entity: query.filter,
      );
});

final auditDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, logId) {
  return ref.watch(adminRepositoryProvider).getAuditLog(logId);
});

final careerMutationProvider =
    StateNotifierProvider<CareerMutationController, AsyncValue<void>>(
  (ref) => CareerMutationController(ref.watch(adminRepositoryProvider)),
);

final questionMutationProvider =
    StateNotifierProvider<QuestionMutationController, AsyncValue<void>>(
  (ref) => QuestionMutationController(ref.watch(adminRepositoryProvider)),
);

final systemSettingsMutationProvider =
    StateNotifierProvider<SystemSettingsMutationController, AsyncValue<void>>(
  (ref) => SystemSettingsMutationController(ref.watch(adminRepositoryProvider)),
);

final vectorRebuildProvider =
    StateNotifierProvider<VectorRebuildController, AsyncValue<Map<String, dynamic>?>>(
  (ref) => VectorRebuildController(ref.watch(adminRepositoryProvider)),
);

class CareerMutationController extends StateNotifier<AsyncValue<void>> {
  CareerMutationController(this._repository) : super(const AsyncData(null));

  final AdminRepository _repository;

  Future<CareerMutationResult?> create(Career career) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.createCareer(career);
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<CareerMutationResult?> update(Career career) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateCareer(career);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<CareerMutationResult?> deactivate(int id) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.deactivateCareer(id);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}

class QuestionMutationController extends StateNotifier<AsyncValue<void>> {
  QuestionMutationController(this._repository) : super(const AsyncData(null));

  final AdminRepository _repository;

  Future<Question?> create(Question question) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.createQuestion(question);
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<Question?> update(Question question) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateQuestion(question);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> deactivate(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deactivateQuestion(id);
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

class SystemSettingsMutationController extends StateNotifier<AsyncValue<void>> {
  SystemSettingsMutationController(this._repository)
      : super(const AsyncData(null));

  final AdminRepository _repository;

  Future<SystemSetting?> update({
    required String key,
    required String value,
  }) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateSystemSetting(
        key: key,
        value: value,
      );
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}

class VectorRebuildController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  VectorRebuildController(this._repository) : super(const AsyncData(null));

  final AdminRepository _repository;

  Future<Map<String, dynamic>?> rebuild() async {
    state = const AsyncLoading();
    try {
      final result = await _repository.rebuildVectorIndex();
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
