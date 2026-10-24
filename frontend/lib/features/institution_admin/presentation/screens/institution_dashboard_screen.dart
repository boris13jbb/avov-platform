import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../providers/institution_dashboard_provider.dart';

class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(institutionDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de la institución'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(institutionDashboardProvider),
          ),
          data: (data) {
            final compact = MediaQuery.sizeOf(context).width < 700;
            final institutionLabel = data.profile.institutionId == null
                ? 'Tu sesión no tiene una institución asignada.'
                : 'Institución asignada: identificador ${data.profile.institutionId}. '
                    'El nombre no está disponible para este rol.';
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${data.profile.firstName} ${data.profile.lastName}'.trim(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(data.profile.email),
                const SizedBox(height: 8),
                Text(institutionLabel),
                const SizedBox(height: 24),
                if (compact)
                  Column(
                    children: [
                      _Metric(label: 'Estudiantes', value: '${data.studentTotal}'),
                      const SizedBox(height: 16),
                      _Metric(label: 'Orientadores', value: '${data.counselorTotal}'),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Estudiantes',
                          value: '${data.studentTotal}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Metric(
                          label: 'Orientadores',
                          value: '${data.counselorTotal}',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.go(RouteNames.institutionStudents),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Gestionar estudiantes'),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.go(RouteNames.institutionCounselors),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Gestionar orientadores'),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.go(RouteNames.institutionAssignments),
                    icon: const Icon(Icons.link_outlined),
                    label: const Text('Gestionar asignaciones'),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
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
