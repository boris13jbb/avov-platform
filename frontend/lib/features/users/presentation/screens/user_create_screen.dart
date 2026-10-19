import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../domain/managed_user.dart';
import '../providers/users_provider.dart';
import '../widgets/user_form.dart';

class UserCreateScreen extends ConsumerWidget {
  const UserCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutions = ref.watch(institutionChoicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),
      body: SafeArea(
        child: institutions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _FormNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(institutionChoicesProvider),
          ),
          data: (items) => UserForm(
            institutions: [
              for (final item in items)
                if (item.status == 'ACTIVE') item,
            ],
            includePassword: true,
            onSubmit: (UserDraft draft) async {
              await ref.read(userAccountRepositoryProvider).create(draft);
              ref.invalidate(userListProvider);
              ref.invalidate(adminDashboardProvider);
              ref.read(userPageProvider.notifier).state = 1;
              if (context.mounted) {
                context.go(RouteNames.adminUsers);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _FormNotice extends StatelessWidget {
  const _FormNotice({required this.message, required this.onRetry});

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
