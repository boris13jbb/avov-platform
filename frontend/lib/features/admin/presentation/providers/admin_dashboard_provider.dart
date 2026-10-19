import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../auth/domain/auth_tokens.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../institutions/data/institution_remote_datasource.dart';
import '../../../institutions/domain/institution.dart';
import '../../../institutions/domain/institution_repository.dart';
import '../../data/api_user_directory_repository.dart';
import '../../domain/user_directory_repository.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.profile,
    required this.institutionTotal,
    required this.userTotal,
  });

  final UserProfile profile;
  final int institutionTotal;
  final int userTotal;
}

final institutionRepositoryProvider = Provider<InstitutionRepository>((ref) {
  return ApiInstitutionRepository(ref.watch(dioClientProvider).dio);
});

final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository>((ref) {
  return ApiUserDirectoryRepository(ref.watch(dioClientProvider).dio);
});

final institutionPageProvider = StateProvider<int>((ref) => 1);

final institutionSearchProvider = StateProvider<String>((ref) => '');

final institutionListProvider = FutureProvider.autoDispose<InstitutionPage>((ref) {
  final page = ref.watch(institutionPageProvider);
  final search = ref.watch(institutionSearchProvider).trim();
  return ref.watch(institutionRepositoryProvider).list(
        page: page,
        pageSize: 20,
        search: search.isEmpty ? null : search,
      );
});

final institutionDetailProvider =
    FutureProvider.autoDispose.family<Institution, int>((ref, id) {
  return ref.watch(institutionRepositoryProvider).getById(id);
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardData>((ref) async {
  final profile = await ref.watch(authRepositoryProvider).currentProfile();
  final institutions = await ref.watch(institutionRepositoryProvider).list(
        page: 1,
        pageSize: 1,
      );
  final users = await ref.watch(userDirectoryRepositoryProvider).count();
  return AdminDashboardData(
    profile: profile,
    institutionTotal: institutions.total,
    userTotal: users,
  );
});
