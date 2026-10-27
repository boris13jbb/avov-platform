import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../users/presentation/widgets/user_form.dart';
import '../providers/counselor_provider.dart';
import '../providers/institution_dashboard_provider.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class CounselorEditScreen extends ConsumerWidget {
  const CounselorEditScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(userDetailProvider(userId));
    final operator = ref.watch(currentOperatorProvider);

    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Editar orientador'),
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(userDetailProvider(userId)),
          ),
          data: (user) {
            if (user.role != 'COUNSELOR') {
              return const _Notice(
                message: 'Este usuario no es un orientador de tu institución.',
                onRetry: null,
              );
            }
            final institutionId = operator.maybeWhen(
              data: (profile) => profile.institutionId ?? user.institutionId,
              orElse: () => user.institutionId,
            );
            if (institutionId == null) {
              return const _Notice(
                message:
                    'Tu sesión no tiene una institución asignada. No se puede editar el orientador.',
                onRetry: null,
              );
            }
            return UserForm(
              key: ValueKey('${user.id}-${user.email}'),
              initial: user,
              institutions: const [],
              allowedRoles: const ['COUNSELOR'],
              lockRole: true,
              roleLockMessage: 'El rol queda fijo como orientador.',
              fixedInstitutionId: institutionId,
              submitLabel: 'Guardar cambios',
              onSubmit: (UserDraft draft) async {
                await ref.read(userAccountRepositoryProvider).update(
                      user.id,
                      UserDraft(
                        email: draft.email,
                        firstName: draft.firstName,
                        lastName: draft.lastName,
                        role: 'COUNSELOR',
                        status: user.status,
                        institutionId: institutionId,
                        phone: draft.phone,
                      ),
                    );
                ref.invalidate(counselorListProvider);
                ref.invalidate(userDetailProvider(userId));
                ref.invalidate(institutionDashboardProvider);
                if (context.mounted) {
                  AppNavigation.completeTo(
                      context, RouteNames.institutionCounselors);
                }
              },
            );
          },
        ),
      ),
    ));
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (onRetry != null)
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
