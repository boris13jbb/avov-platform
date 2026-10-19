import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../providers/counselor_dashboard_provider.dart';

class CounselorDashboardScreen extends ConsumerWidget {
  const CounselorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(counselorDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del orientador'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(counselorDashboardProvider),
          ),
          data: (data) {
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estudiantes asignados'),
                        const SizedBox(height: 8),
                        Text(
                          '${data.assignedStudentTotal}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.go(RouteNames.counselorStudents),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Ver estudiantes asignados'),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Orientación vocacional',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estas herramientas todavía no están disponibles para el orientador. '
                  'La API no ofrece un listado de sesiones, resultados, recomendaciones '
                  'ni observaciones que este rol pueda consultar.',
                ),
                const SizedBox(height: 12),
                const Text('• Aplicar el test RIASEC'),
                const Text('• Consultar el progreso de una evaluación'),
                const Text('• Ver resultados vocacionales'),
                const Text('• Ver recomendaciones de carreras'),
                const Text('• Registrar el seguimiento del estudiante'),
              ],
            );
          },
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
