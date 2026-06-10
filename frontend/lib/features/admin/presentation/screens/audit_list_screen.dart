import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../router/route_names.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_paginated_list.dart';

class AuditListScreen extends ConsumerStatefulWidget {
  const AuditListScreen({super.key});

  @override
  ConsumerState<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends ConsumerState<AuditListScreen> {
  AdminListQuery _query = const AdminListQuery();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(auditListProvider(_query));

    return DashboardShell(
      title: 'Auditoría del sistema',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: listAsync.when(
        data: (data) {
          final items = (data['items'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          return AdminPaginatedList<Map<String, dynamic>>(
            items: items,
            page: data['page'] as int? ?? 1,
            pages: data['pages'] as int? ?? 0,
            onPageChanged: (page) =>
                setState(() => _query = _query.copyWith(page: page)),
            emptyMessage: 'Aún no hay registros de auditoría.',
            itemBuilder: (context, item) {
              final logId = (item['id'] as num?)?.toInt();
              return Card(
                child: ListTile(
                  title: Text(
                    '${item['action'] ?? ''} · ${item['entity'] ?? ''}',
                  ),
                  subtitle: Text(
                    'Usuario ${item['user_id'] ?? '—'} · '
                    '${_formatDate(item['created_at'] as String?)}',
                  ),
                  trailing: logId != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  isThreeLine: true,
                  onTap: logId == null
                      ? null
                      : () => context.push(RouteNames.adminAuditDetail(logId)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(auditListProvider(_query)),
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      return _dateFormat.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
