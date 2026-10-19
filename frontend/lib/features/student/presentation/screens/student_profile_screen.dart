import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../users/presentation/providers/users_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentOperatorProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis datos'),
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
              const SizedBox(height: 8),
              Text(data.email),
              const SizedBox(height: 8),
              const Text('Rol: estudiante'),
              const SizedBox(height: 16),
              Text(
                data.institutionId == null
                    ? 'Tu sesión no tiene una institución asignada.'
                    : 'Institución asignada: identificador ${data.institutionId}. '
                        'El nombre no está disponible para este rol.',
              ),
              const SizedBox(height: 16),
              const Text(
                'La ficha académica no se puede consultar. '
                'No existe una operación que devuelva el perfil del estudiante autenticado '
                'sin un identificador, y este rol no puede listar estudiantes.',
              ),
            ],
          ),
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
