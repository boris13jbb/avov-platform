import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../providers/audit_provider.dart';
import '../../../../shared/widgets/internal_route_scope.dart';
import '../../../../shared/widgets/navigation_back_button.dart';

class AuditLogDetailScreen extends ConsumerWidget {
  const AuditLogDetailScreen({super.key, required this.logId});

  final int logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(auditLogDetailProvider(logId));
    return InternalRouteScope(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: NavigationBackButton.maybeOf(context),
        title: Text('Registro $logId'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(auditLogDetailProvider(logId)),
          ),
          data: (entry) {
            final when = DateFormat('dd/MM/yyyy HH:mm:ss')
                .format(entry.createdAt.toLocal());
            final details = entry.details == null
                ? '—'
                : const JsonEncoder.withIndent('  ').convert(entry.details);
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Acción: ${entry.action}'),
                Text('Entidad: ${entry.entity}'),
                if (entry.entityId != null)
                  Text('ID entidad: ${entry.entityId}'),
                Text('Fecha: $when'),
                if (entry.user != null) ...[
                  const SizedBox(height: 8),
                  Text('Usuario: ${entry.user!.displayName}'),
                  Text('Correo: ${entry.user!.email}'),
                ],
                if (entry.ipAddress != null) Text('IP: ${entry.ipAddress}'),
                if (entry.userAgent != null) Text('Agente: ${entry.userAgent}'),
                const SizedBox(height: 16),
                Text('Detalles',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(details),
              ],
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
