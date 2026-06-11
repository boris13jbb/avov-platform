import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/counselor_provider.dart';

class CounselorObservationScreen extends ConsumerStatefulWidget {
  const CounselorObservationScreen({
    super.key,
    required this.studentId,
  });

  final int studentId;

  @override
  ConsumerState<CounselorObservationScreen> createState() =>
      _CounselorObservationScreenState();
}

class _CounselorObservationScreenState
    extends ConsumerState<CounselorObservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submit(int testSessionId) async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(counselorObservationProvider.notifier).submit(
          testSessionId: testSessionId,
          observation: _observationController.text.trim(),
        );

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(counselorDashboardProvider);
      ref.invalidate(counselorStudentCaseProvider(widget.studentId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observación registrada correctamente')),
      );
      context.pop();
      return;
    }

    final error = ref.read(counselorObservationProvider).error;
    final message = error is AppException
        ? error.message
        : 'No se pudo registrar la observación';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(counselorStudentCaseProvider(widget.studentId));
    final mutationState = ref.watch(counselorObservationProvider);
    final isBusy = mutationState.isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DashboardShell(
      title: 'Observación profesional',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isBusy ? null : () => context.pop(),
      ),
      body: caseAsync.when(
        data: (studentCase) {
          final testSessionId = studentCase.testSessionId;
          if (testSessionId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${studentCase.student.user.fullName} aún no tiene un test '
                  'vocacional completado. No es posible registrar una '
                  'observación profesional.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          studentCase.student.user.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registra una observación profesional sobre el proceso '
                          'vocacional del estudiante. Esta nota quedará asociada '
                          'al reporte PDF.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _observationController,
                          enabled: !isBusy,
                          maxLength: 2000,
                          minLines: 6,
                          maxLines: 12,
                          decoration: const InputDecoration(
                            labelText: 'Observación',
                            hintText:
                                'Describe hallazgos, recomendaciones de seguimiento '
                                'o aspectos a considerar...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'La observación es obligatoria';
                            }
                            if (text.length > 2000) {
                              return 'Máximo 2000 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _submit(testSessionId),
                        icon: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(isBusy ? 'Guardando...' : 'Guardar observación'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  error is AppException
                      ? error.message
                      : 'No se pudo cargar la información del estudiante',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    counselorStudentCaseProvider(widget.studentId),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
