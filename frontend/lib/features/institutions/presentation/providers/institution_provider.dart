import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/institution.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/datasources/institution_remote_datasource.dart';
import '../../data/repositories/institution_repository.dart';

final institutionRemoteDatasourceProvider =
    Provider<InstitutionRemoteDatasource>((ref) {
  return InstitutionRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final institutionRepositoryProvider = Provider<InstitutionRepository>((ref) {
  return InstitutionRepository(
    remoteDatasource: ref.watch(institutionRemoteDatasourceProvider),
  );
});

class InstitutionListQuery {
  const InstitutionListQuery({
    this.page = 1,
    this.search,
    this.status,
  });

  final int page;
  final String? search;
  final String? status;

  InstitutionListQuery copyWith({
    int? page,
    String? search,
    String? status,
    bool clearSearch = false,
    bool clearStatus = false,
  }) {
    return InstitutionListQuery(
      page: page ?? this.page,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InstitutionListQuery &&
        other.page == page &&
        other.search == search &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(page, search, status);
}

final institutionListProvider =
    FutureProvider.family<PaginatedInstitutions, InstitutionListQuery>(
  (ref, query) {
    return ref.watch(institutionRepositoryProvider).listInstitutions(
          page: query.page,
          search: query.search,
          status: query.status,
        );
  },
);

final institutionDetailProvider =
    FutureProvider.family<Institution, int>((ref, id) {
  return ref.watch(institutionRepositoryProvider).getInstitution(id);
});

final institutionSettingsProvider = FutureProvider<Institution>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final institutionId = user?.institutionId;
  if (institutionId == null) {
    throw StateError('No se encontró la institución del usuario actual');
  }
  return ref.watch(institutionRepositoryProvider).getInstitution(institutionId);
});

final institutionMutationProvider =
    StateNotifierProvider<InstitutionMutationController, AsyncValue<void>>(
  (ref) => InstitutionMutationController(ref.watch(institutionRepositoryProvider)),
);

class InstitutionMutationController extends StateNotifier<AsyncValue<void>> {
  InstitutionMutationController(this._repository)
      : super(const AsyncData(null));

  final InstitutionRepository _repository;

  Future<Institution?> create(Institution institution) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.createInstitution(institution);
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<Institution?> update(Institution institution) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateInstitution(institution);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<Institution?> updateSettings(Institution institution) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.updateInstitutionSettings(institution);
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<Institution?> uploadLogo({
    required int institutionId,
    required List<int> bytes,
    required String filename,
  }) async {
    state = const AsyncLoading();
    try {
      final updated = await _repository.uploadInstitutionLogo(
        institutionId: institutionId,
        bytes: bytes,
        filename: filename,
      );
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
      await _repository.deactivateInstitution(id);
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
