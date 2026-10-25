import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/career.dart';
import '../providers/career_provider.dart';

class CareerListScreen extends ConsumerWidget {
  const CareerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(careerListProvider);
    final page = ref.watch(careerPageProvider);
    final statusFilter = ref.watch(careerStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carreras'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ListNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(careerListProvider),
          ),
          data: (result) {
            if (result.total == 0) {
              return _ListNotice(
                message:
                    'Todavía no hay carreras registradas. Crea la primera para comenzar.',
                actionLabel: 'Crear carrera',
                onRetry: () => context.go(RouteNames.adminCareerNew),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            prefixIcon: Icon(Icons.search),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            ref.read(careerSearchProvider.notifier).state =
                                value.trim();
                            ref.read(careerPageProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String?>(
                          initialValue: statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'ACTIVE',
                              child: Text('Activas'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'INACTIVE',
                              child: Text('Inactivas'),
                            ),
                          ],
                          onChanged: (value) {
                            ref
                                .read(careerStatusFilterProvider.notifier)
                                .state = value;
                            ref.read(careerPageProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go(RouteNames.adminCareerNew),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear carrera'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _CareerTile(career: result.items[index]);
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
                                  .read(careerPageProvider.notifier)
                                  .state = page - 1
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página $page de ${result.pages}'),
                        IconButton(
                          onPressed: page < result.pages
                              ? () => ref
                                  .read(careerPageProvider.notifier)
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
    );
  }
}

class _CareerTile extends ConsumerStatefulWidget {
  const _CareerTile({required this.career});

  final Career career;

  @override
  ConsumerState<_CareerTile> createState() => _CareerTileState();
}

class _CareerTileState extends ConsumerState<_CareerTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final career = widget.career;
    final details = [
      career.area,
      career.riasecProfile,
      career.degreeTypeLabel,
      career.institutionTypeLabel,
      if (career.duration != null) career.duration!,
      career.employmentField,
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              career.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(career.statusLabel),
            const SizedBox(height: 8),
            Text(details),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => context.go(RouteNames.adminCareerEdit(career.id)),
                  child: const Text('Editar'),
                ),
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () =>
                          career.status == 'ACTIVE' ? _deactivate() : null,
                  child: const Text('Desactivar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deactivate() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Desactivar carrera',
      message:
          'La carrera quedará inactiva. El registro se conserva en el catálogo.',
      confirmLabel: 'Desactivar',
    );
    if (!confirmed || !mounted) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }
    try {
      await ref.read(careerRepositoryProvider).deactivate(widget.career.id);
      ref.invalidate(careerListProvider);
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

class _ListNotice extends StatelessWidget {
  const _ListNotice({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Reintentar',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

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
            FilledButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
