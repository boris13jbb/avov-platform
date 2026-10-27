import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_navigation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';
import '../../../admin/presentation/providers/admin_dashboard_provider.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/institution.dart';

class InstitutionListScreen extends ConsumerWidget {
  const InstitutionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(institutionListProvider);
    final page = ref.watch(institutionPageProvider);

    return InternalRouteScope(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: NavigationBackButton.maybeOf(context),
          title: const Text('Instituciones'),
          actions: const [SessionMenuButton()],
        ),
        body: SafeArea(
          child: list.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppStateView.error(
              message: error is AppException
                  ? error.message
                  : FailureMapper.unexpectedMessage,
              onRetry: () => ref.invalidate(institutionListProvider),
            ),
            data: (result) {
              if (result.total == 0) {
                return AppStateView.empty(
                  message:
                      'Todavía no hay instituciones registradas. Crea la primera para comenzar.',
                  actionLabel: 'Crear institución',
                  onAction: () => AppNavigation.open(
                    context,
                    RouteNames.adminInstitutionNew,
                  ),
                  icon: Icons.apartment_outlined,
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Buscar',
                              prefixIcon: Icon(Icons.search),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              ref
                                  .read(institutionSearchProvider.notifier)
                                  .state = value.trim();
                              ref.read(institutionPageProvider.notifier).state =
                                  1;
                            },
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => AppNavigation.open(
                            context,
                            RouteNames.adminInstitutionNew,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear institución'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: result.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        return _InstitutionTile(
                          institution: result.items[index],
                        );
                      },
                    ),
                  ),
                  if (result.pages > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: page > 1
                                ? () => ref
                                    .read(institutionPageProvider.notifier)
                                    .state = page - 1
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Página $page de ${result.pages}'),
                          IconButton(
                            onPressed: page < result.pages
                                ? () => ref
                                    .read(institutionPageProvider.notifier)
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
      ),
    );
  }
}

class _InstitutionTile extends ConsumerStatefulWidget {
  const _InstitutionTile({required this.institution});

  final Institution institution;

  @override
  ConsumerState<_InstitutionTile> createState() => _InstitutionTileState();
}

class _InstitutionTileState extends ConsumerState<_InstitutionTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final institution = widget.institution;
    final compact = MediaQuery.sizeOf(context).width < 700;
    final details = [
      institution.code,
      '${institution.city}, ${institution.province}',
      if (institution.email != null) institution.email!,
      if (institution.phone != null) institution.phone!,
      if (institution.address != null) institution.address!,
    ].join(' · ');
    final actions = _actions(institution);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    institution.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(institution.statusLabel),
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
                          institution.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(details),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(institution.statusLabel),
                  const SizedBox(width: 12),
                  Wrap(spacing: 8, children: actions),
                ],
              ),
      ),
    );
  }

  List<Widget> _actions(Institution institution) {
    final active = institution.status == 'ACTIVE';
    return [
      OutlinedButton(
        onPressed: _busy
            ? null
            : () => AppNavigation.open(
                context, RouteNames.adminInstitutionEdit(institution.id)),
        child: const Text('Editar'),
      ),
      FilledButton.tonal(
        onPressed: _busy ? null : () => active ? _deactivate() : _activate(),
        child: Text(active ? 'Desactivar' : 'Activar'),
      ),
    ];
  }

  Future<void> _deactivate() async {
    await _changeStatus(
      title: 'Desactivar institución',
      message:
          'La institución quedará inactiva. El registro se conserva y podrás activarla después.',
      confirmLabel: 'Desactivar',
      action: () => ref
          .read(institutionRepositoryProvider)
          .deactivate(widget.institution.id),
    );
  }

  Future<void> _activate() async {
    await _changeStatus(
      title: 'Activar institución',
      message: 'La institución volverá a estar activa.',
      confirmLabel: 'Activar',
      action: () => ref
          .read(institutionRepositoryProvider)
          .activate(widget.institution.id),
    );
  }

  Future<void> _changeStatus({
    required String title,
    required String message,
    required String confirmLabel,
    required Future<Institution> Function() action,
  }) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }
    try {
      await action();
      ref.invalidate(institutionListProvider);
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
