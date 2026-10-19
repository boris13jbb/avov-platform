import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../auth/domain/auth_tokens.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../institutions/domain/institution.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../data/api_user_account_repository.dart';
import '../../domain/managed_user.dart';
import '../../domain/user_account_repository.dart';

final userAccountRepositoryProvider = Provider<UserAccountRepository>((ref) {
  return ApiUserAccountRepository(ref.watch(dioClientProvider).dio);
});

final userPageProvider = StateProvider<int>((ref) => 1);
final userSearchProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<String?>((ref) => null);
final userStatusFilterProvider = StateProvider<String?>((ref) => null);
final userInstitutionFilterProvider = StateProvider<int?>((ref) => null);

final userListProvider = FutureProvider.autoDispose<ManagedUserPage>((ref) {
  return ref.watch(userAccountRepositoryProvider).list(
        UserListQuery(
          page: ref.watch(userPageProvider),
          pageSize: 20,
          search: ref.watch(userSearchProvider),
          role: ref.watch(userRoleFilterProvider),
          status: ref.watch(userStatusFilterProvider),
          institutionId: ref.watch(userInstitutionFilterProvider),
        ),
      );
});

final userDetailProvider =
    FutureProvider.autoDispose.family<ManagedUser, int>((ref, id) {
  return ref.watch(userAccountRepositoryProvider).getById(id);
});

final currentOperatorProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(authRepositoryProvider).currentProfile();
});

final institutionChoicesProvider =
    FutureProvider.autoDispose<List<Institution>>((ref) async {
  final page = await ref.watch(institutionRepositoryProvider).list(
        page: 1,
        pageSize: 100,
      );
  return page.items;
});
