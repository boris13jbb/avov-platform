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

class CounselorCreateScreen extends ConsumerWidget {
  const CounselorCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operator = ref.watch(currentOperatorProvider);
    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Crear orientador'),
      ),
      body: SafeArea(
        child: operator.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(currentOperatorProvider),
          ),
          data: (profile) {
            final institutionId = profile.institutionId;
            if (profile.role != 'INSTITUTION_ADMIN' || institutionId == null) {
              return const _Notice(
                message:
                    'Tu sesión no tiene una institución asignada. No se puede crear el orientador.',
                onRetry: null,
              );
            }
            return UserForm(
              institutions: const [],
              includePassword: true,
              allowedRoles: const ['COUNSELOR'],
              lockRole: true,
              roleLockMessage: 'El rol queda fijo como orientador.',
              fixedInstitutionId: institutionId,
              submitLabel: 'Guardar orientador',
              onSubmit: (UserDraft draft) async {
                await ref.read(userAccountRepositoryProvider).create(
                      UserDraft(
                        email: draft.email,
                        firstName: draft.firstName,
                        lastName: draft.lastName,
                        role: 'COUNSELOR',
                        status: draft.status,
                        password: draft.password,
                        institutionId: institutionId,
                        phone: draft.phone,
                      ),
                    );
                ref.invalidate(counselorListProvider);
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
