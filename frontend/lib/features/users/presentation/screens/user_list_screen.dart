import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../institutions/domain/institution.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/managed_user.dart';
import '../providers/users_provider.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(userListProvider);
    final page = ref.watch(userPageProvider);
    final names = ref.watch(institutionChoicesProvider);
    final operator = ref.watch(currentOperatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
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
            onPressed: () => ref.invalidate(userListProvider),
          ),
          data: (result) {
            final filtering = ref.watch(userSearchProvider).isNotEmpty ||
                ref.watch(userRoleFilterProvider) != null ||
                ref.watch(userStatusFilterProvider) != null ||
                ref.watch(userInstitutionFilterProvider) != null;
            if (result.total == 0 && !filtering) {
              return _Notice(
                message: 'Todavía no hay usuarios.',
                actionLabel: 'Crear usuario',
                onPressed: () => context.go(RouteNames.adminUserNew),
              );
            }
            final institutionNames = names.maybeWhen(
              data: (items) => {for (final item in items) item.id: item.name},
              orElse: () => const <int, String>{},
            );
            final operatorId = operator.maybeWhen(
              data: (profile) => profile.id,
              orElse: () => null,
            );
            return Column(
              children: [
                const _Filters(),
                Expanded(
                  child: result.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Todavía no hay usuarios que coincidan con la búsqueda.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: result.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = result.items[index];
                            return _UserTile(
                              user: user,
                              institutionName: user.institutionId == null
                                  ? null
                                  : institutionNames[user.institutionId!] ??
                                      'Institución ${user.institutionId}',
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
                              ? () => ref.read(userPageProvider.notifier).state =
                                  page - 1
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página $page de ${result.pages}'),
                        IconButton(
                          onPressed: page < result.pages
                              ? () => ref.read(userPageProvider.notifier).state =
                                  page + 1
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
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              key: const Key('user-search'),
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final term = value.trim();
                ref.read(userSearchProvider.notifier).state =
                    term.length > 100 ? term.substring(0, 100) : term;
                ref.read(userPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              key: const Key('user-role-filter'),
              initialValue: ref.watch(userRoleFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los roles')),
                for (final role in userRoles)
                  DropdownMenuItem(value: role, child: Text(userRoleLabel(role))),
              ],
              onChanged: (value) {
                ref.read(userRoleFilterProvider.notifier).state = value;
                ref.read(userPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<int?>(
              key: const Key('user-institution-filter'),
              initialValue: ref.watch(userInstitutionFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Institución'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas las instituciones'),
                ),
                for (final institution in ref.watch(institutionChoicesProvider).maybeWhen(
                      data: (items) => items,
                      orElse: () => const <Institution>[],
                    ))
                  DropdownMenuItem<int?>(
                    value: institution.id,
                    child: Text(institution.name),
                  ),
              ],
              onChanged: (value) {
                ref.read(userInstitutionFilterProvider.notifier).state = value;
                ref.read(userPageProvider.notifier).state = 1;
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String?>(
              key: const Key('user-status-filter'),
              initialValue: ref.watch(userStatusFilterProvider),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                for (final status in userStatuses)
                  DropdownMenuItem(
                    value: status,
                    child: Text(userStatusLabel(status)),
                  ),
              ],
              onChanged: (value) {
                ref.read(userStatusFilterProvider.notifier).state = value;
                ref.read(userPageProvider.notifier).state = 1;
              },
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go(RouteNames.adminUserNew),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Crear usuario'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  const _UserTile({
    required this.user,
    required this.institutionName,
    required this.canChangeStatus,
  });

  final ManagedUser user;
  final String? institutionName;
  final bool canChangeStatus;

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final compact = MediaQuery.sizeOf(context).width < 1100;
    final details = [
      user.email,
      user.roleLabel,
      if (widget.institutionName != null) widget.institutionName!,
    ].join(' · ');
    final actions = _actions(user);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(user.statusLabel),
                  const SizedBox(height: 8),
                  Text(details),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(details),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(user.statusLabel),
                  const SizedBox(width: 12),
                  Wrap(spacing: 8, children: actions),
                ],
              ),
      ),
    );
  }

  List<Widget> _actions(ManagedUser user) {
    return [
      OutlinedButton(
        onPressed: _busy
            ? null
            : () => context.go(RouteNames.adminUserEdit(user.id)),
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
    ];
  }

  Future<void> _setStatus(String status) async {
    if (_busy) {
      return;
    }
    final copy = _statusCopy(status);
    setState(() => _busy = true);
    final confirmed = await ConfirmDialog.show(
      context,
      title: copy.title,
      message: copy.message,
      confirmLabel: copy.confirm,
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
      ref.invalidate(userListProvider);
      ref.invalidate(adminDashboardProvider);
    } on AppException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

({String title, String message, String confirm}) _statusCopy(String status) {
  switch (status) {
    case 'INACTIVE':
      return (
        title: 'Desactivar usuario',
        message:
            'La cuenta quedará inactiva y no podrá iniciar sesión. El usuario no se elimina.',
        confirm: 'Desactivar',
      );
    case 'BLOCKED':
      return (
        title: 'Bloquear usuario',
        message:
            'La cuenta quedará bloqueada y no podrá iniciar sesión. El usuario no se elimina.',
        confirm: 'Bloquear',
      );
    default:
      return (
        title: 'Activar usuario',
        message: 'La cuenta volverá a estar activa y podrá iniciar sesión.',
        confirm: 'Activar',
      );
  }
}
