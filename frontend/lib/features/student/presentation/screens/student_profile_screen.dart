import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../shared/widgets/student_scaffold.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../../vocational/presentation/widgets/student_reports_history_section.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(ownStudentProvider);
    return StudentScaffold(
      title: 'Mi ficha',
      section: StudentSection.profile,
      body: SafeArea(
        child: record.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(ownStudentProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(data.fullName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(data.email),
              const SizedBox(height: 8),
              Text('Estado: ${data.statusLabel}'),
              const SizedBox(height: 16),
              Text('Identificación: ${data.identification}'),
              Text('Fecha de nacimiento: ${data.birthDate}'),
              Text('Género: ${data.genderLabel}'),
              Text('Curso: ${data.grade}'),
              if (data.parallel != null && data.parallel!.isNotEmpty)
                Text('Paralelo: ${data.parallel}'),
              Text(
                'Institución: identificador ${data.institutionId}. '
                'El nombre no está incluido en la ficha.',
              ),
              if (data.representativeName != null)
                Text('Representante: ${data.representativeName}'),
              if (data.representativePhone != null)
                Text('Teléfono del representante: ${data.representativePhone}'),
              if (data.representativeEmail != null)
                Text('Correo del representante: ${data.representativeEmail}'),
              const SizedBox(height: 16),
              const Text(
                'Esta ficha es de consulta. El estudiante no puede modificarla.',
              ),
              const SizedBox(height: 24),
              StudentReportsHistorySection(studentId: data.id),
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
