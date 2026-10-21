import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';

final counselorPageProvider = StateProvider<int>((ref) => 1);

/// Lista solo orientadores. No envía `institution_id`: el backend usa el de la sesión.
final counselorListProvider = FutureProvider.autoDispose<ManagedUserPage>((ref) async {
  final operator = await ref.watch(authRepositoryProvider).currentProfile();
  if (operator.role != 'INSTITUTION_ADMIN') {
    throw AppException('No tienes permiso para consultar orientadores.');
  }
  return ref.watch(userAccountRepositoryProvider).list(
        UserListQuery(
          page: ref.watch(counselorPageProvider),
          pageSize: 20,
          role: 'COUNSELOR',
        ),
      );
});
