import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  bool _starting = false;
  String? _startError;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentOperatorProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del estudiante'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(currentOperatorProvider),
          ),
          data: (data) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${data.firstName} ${data.lastName}'.trim(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(data.email),
                const SizedBox(height: 16),
                const Text(
                  'Tu ficha académica no está disponible desde este panel. '
                  'La sesión no incluye el identificador del estudiante y '
                  'el listado de estudiantes no está permitido para este rol.',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => context.go(RouteNames.studentProfile),
                    child: const Text('Ver mis datos de sesión'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Evaluación vocacional',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El progreso aparece dentro de la evaluación, después de iniciarla. '
                  'No hay un listado de sesiones anteriores.',
                ),
                const SizedBox(height: 12),
                if (_startError != null) ...[
                  Text(
                    _startError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _starting ? null : _start,
                    child: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar o continuar el test'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Las recomendaciones de carreras no están disponibles. '
                  'Ese servicio no tiene operaciones.',
                ),
              ],
            ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    if (_starting) {
      return;
    }
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final session = await ref.read(vocationalRepositoryProvider).start();
      if (!mounted) {
        return;
      }
      context.go(RouteNames.studentTest(session.id));
    } on AppException catch (error) {
      setState(() => _startError = error.message);
    } catch (_) {
      setState(() => _startError = FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
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
