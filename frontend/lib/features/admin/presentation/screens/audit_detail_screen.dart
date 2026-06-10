import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class AuditDetailScreen extends ConsumerWidget {
  const AuditDetailScreen({super.key, required this.logId});

  final int logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(auditDetailProvider(logId));
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return DashboardShell(
      title: 'Detalle de auditoría',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        data: (log) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoTile(label: 'ID', value: '${log['id'] ?? '—'}'),
            _InfoTile(label: 'Acción', value: '${log['action'] ?? '—'}'),
            _InfoTile(label: 'Entidad', value: '${log['entity'] ?? '—'}'),
            _InfoTile(
              label: 'ID entidad',
              value: '${log['entity_id'] ?? '—'}',
            ),
            _InfoTile(
              label: 'Usuario',
              value: '${log['user_id'] ?? '—'}',
            ),
            _InfoTile(
              label: 'IP',
              value: '${log['ip_address'] ?? '—'}',
            ),
            _InfoTile(
              label: 'Fecha',
              value: _formatDate(log['created_at'] as String?, dateFormat),
            ),
            const SizedBox(height: 16),
            Text(
              'Detalles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _formatDetails(log['details']),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el registro'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(auditDetailProvider(logId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String? raw, DateFormat format) {
    if (raw == null) return '—';
    try {
      return format.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _formatDetails(dynamic details) {
    if (details == null) return 'Sin detalles adicionales';
    if (details is Map || details is List) {
      return const JsonEncoder.withIndent('  ').convert(details);
    }
    return details.toString();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
