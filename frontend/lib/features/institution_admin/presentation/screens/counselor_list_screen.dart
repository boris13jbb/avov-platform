import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../users/domain/managed_user.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../providers/counselor_provider.dart';
import '../providers/institution_dashboard_provider.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class CounselorListScreen extends ConsumerWidget {
  const CounselorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(counselorListProvider);
    final page = ref.watch(counselorPageProvider);
    final operatorId = ref.watch(currentOperatorProvider).maybeWhen(
          data: (profile) => profile.id,
          orElse: () => null,
        );

    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Orientadores'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            actionLabel: 'Reintentar',
            onPressed: () => ref.invalidate(counselorListProvider),
          ),
          data: (result) {
            if (result.total == 0) {
              return _Notice(
                message: 'Todavía no hay orientadores.',
                actionLabel: 'Crear orientador',
                onPressed: () => AppNavigation.open(
                    context, RouteNames.institutionCounselorNew),
              );
            }
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: FilledButton.icon(
                      onPressed: () => AppNavigation.open(
                          context, RouteNames.institutionCounselorNew),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Crear orientador'),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = result.items[index];
                      return _CounselorTile(
                        user: user,
                        canChangeStatus:
                            operatorId != null && operatorId != user.id,
                      );
                    },
                  ),
                ),
                if (result.pages > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: page > 1
                              ? () => ref
                                  .read(counselorPageProvider.notifier)
                                  .state = page - 1
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página $page de ${result.pages}'),
                        IconButton(
                          onPressed: page < result.pages
                              ? () => ref
                                  .read(counselorPageProvider.notifier)
                                  .state = page + 1
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ));
  }
}

class _CounselorTile extends ConsumerStatefulWidget {
  const _CounselorTile({required this.user, required this.canChangeStatus});

  final ManagedUser user;
  final bool canChangeStatus;

  @override
  ConsumerState<_CounselorTile> createState() => _CounselorTileState();
}

class _CounselorTileState extends ConsumerState<_CounselorTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${user.email} · ${user.statusLabel}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => AppNavigation.open(context,
                          RouteNames.institutionCounselorEdit(user.id)),
                  child: const Text('Editar'),
                ),
                if (widget.canChangeStatus && user.isActive) ...[
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('INACTIVE'),
                    child: const Text('Desactivar'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('BLOCKED'),
                    child: const Text('Bloquear'),
                  ),
                ],
                if (widget.canChangeStatus && !user.isActive)
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _setStatus('ACTIVE'),
                    child: const Text('Activar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final confirmed = await ConfirmDialog.show(
      context,
      title: status == 'ACTIVE' ? 'Activar orientador' : 'Cambiar estado',
      message: status == 'ACTIVE'
          ? 'La cuenta volverá a estar activa y podrá iniciar sesión.'
          : 'La cuenta no podrá iniciar sesión. El orientador no se elimina.',
      confirmLabel: status == 'ACTIVE' ? 'Activar' : 'Confirmar',
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }
    try {
      await ref
          .read(userAccountRepositoryProvider)
          .updateStatus(widget.user.id, status);
      ref.invalidate(counselorListProvider);
      ref.invalidate(institutionDashboardProvider);
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(FailureMapper.unexpectedMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

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
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
