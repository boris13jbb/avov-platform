import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/audit_log.dart';
import '../providers/audit_provider.dart';
import '../../../../router/app_navigation.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class AuditLogListScreen extends ConsumerStatefulWidget {
  const AuditLogListScreen({
    super.key,
    required this.detailRouteBuilder,
  });

  final String Function(int logId) detailRouteBuilder;

  @override
  ConsumerState<AuditLogListScreen> createState() => _AuditLogListScreenState();
}

class _AuditLogListScreenState extends ConsumerState<AuditLogListScreen> {
  final _actionController = TextEditingController();
  final _entityController = TextEditingController();

  @override
  void dispose() {
    _actionController.dispose();
    _entityController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(auditActionFilterProvider.notifier).state =
        _actionController.text.trim().isEmpty
            ? null
            : _actionController.text.trim();
    ref.read(auditEntityFilterProvider.notifier).state =
        _entityController.text.trim().isEmpty
            ? null
            : _entityController.text.trim();
    ref.read(auditPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(auditLogListProvider);
    final page = ref.watch(auditPageProvider);

    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: const Text('Auditoría del sistema'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('audit-filter-action'),
                      controller: _actionController,
                      decoration: const InputDecoration(
                        labelText: 'Acción',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('audit-filter-entity'),
                      controller: _entityController,
                      decoration: const InputDecoration(
                        labelText: 'Entidad',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('audit-apply-filters'),
                    onPressed: _applyFilters,
                    child: const Text('Filtrar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: logs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Notice(
                  message: error is AppException
                      ? error.message
                      : FailureMapper.unexpectedMessage,
                  onRetry: () => ref.invalidate(auditLogListProvider),
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return const Center(
                      child: Text('No hay registros con los filtros actuales.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = result.items[index];
                      return _AuditTile(
                        entry: item,
                        onTap: () => AppNavigation.open(
                            context, widget.detailRouteBuilder(item.id)),
                      );
                    },
                  );
                },
              ),
            ),
            _PaginationBar(
              page: page,
              pages:
                  logs.maybeWhen(data: (data) => data.pages, orElse: () => 0),
              onPrevious: page > 1
                  ? () => ref.read(auditPageProvider.notifier).state = page - 1
                  : null,
              onNext: logs.maybeWhen(
                data: (data) => data.page < data.pages
                    ? () =>
                        ref.read(auditPageProvider.notifier).state = page + 1
                    : null,
                orElse: () => null,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry, required this.onTap});

  final AuditLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt.toLocal());
    final actor = entry.user?.displayName ?? 'Usuario ${entry.userId ?? '—'}';
    return ListTile(
      onTap: onTap,
      title: Text('${entry.action} · ${entry.entity}'),
      subtitle: Text('$when · $actor'),
      trailing: entry.entityId == null ? null : Text('#${entry.entityId}'),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: onPrevious,
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 16),
          Text('Página $page${pages > 0 ? ' de $pages' : ''}'),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onNext,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
