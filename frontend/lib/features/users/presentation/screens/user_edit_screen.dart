import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../institutions/domain/institution.dart';
import '../../domain/managed_user.dart';
import '../providers/users_provider.dart';
import '../widgets/user_form.dart';

class UserEditScreen extends ConsumerWidget {
  const UserEditScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(userDetailProvider(userId));
    final institutions = ref.watch(institutionChoicesProvider);
    final operator = ref.watch(currentOperatorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar usuario')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EditNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(userDetailProvider(userId)),
          ),
          data: (user) {
            return institutions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _EditNotice(
                message: error is AppException
                    ? error.message
                    : FailureMapper.unexpectedMessage,
                onRetry: () => ref.invalidate(institutionChoicesProvider),
              ),
              data: (items) {
                final lockRole = operator.maybeWhen(
                  data: (profile) => profile.id == user.id,
                  orElse: () => true,
                );
                return UserForm(
                  key: ValueKey('${user.id}-${user.email}-${user.role}'),
                  initial: user,
                  institutions: _institutionChoices(items, user),
                  lockRole: lockRole,
                  submitLabel: 'Guardar cambios',
                  onSubmit: (UserDraft draft) async {
                    final safeDraft = lockRole
                        ? UserDraft(
                            email: draft.email,
                            firstName: draft.firstName,
                            lastName: draft.lastName,
                            role: user.role,
                            status: user.status,
                            institutionId: user.role == 'SUPER_ADMIN'
                                ? null
                                : draft.institutionId,
                            phone: draft.phone,
                          )
                        : draft;
                    await ref
                        .read(userAccountRepositoryProvider)
                        .update(user.id, safeDraft);
                    ref.invalidate(userListProvider);
                    ref.invalidate(adminDashboardProvider);
                    ref.invalidate(userDetailProvider(userId));
                    if (context.mounted) {
                      context.go(RouteNames.adminUsers);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

List<Institution> _institutionChoices(
  List<Institution> source,
  ManagedUser user,
) {
  final choices = <Institution>[
    for (final item in source)
      if (item.status == 'ACTIVE') item,
  ];
  final institutionId = user.institutionId;
  if (institutionId == null ||
      choices.any((item) => item.id == institutionId)) {
    return choices;
  }
  for (final item in source) {
    if (item.id == institutionId) {
      return [...choices, item];
    }
  }
  return [
    ...choices,
    Institution(
      id: institutionId,
      name: 'Institución $institutionId',
      code: '-',
      province: '-',
      city: '-',
      status: 'INACTIVE',
    ),
  ];
}

class _EditNotice extends StatelessWidget {
  const _EditNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
