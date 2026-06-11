import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/test_provider.dart';
import '../widgets/scale_answer_selector.dart';

class TestInstructionsScreen extends ConsumerStatefulWidget {
  const TestInstructionsScreen({super.key, this.continueTest = false});

  final bool continueTest;

  @override
  ConsumerState<TestInstructionsScreen> createState() =>
      _TestInstructionsScreenState();
}

class _TestInstructionsScreenState extends ConsumerState<TestInstructionsScreen> {
  Future<void> _startOrContinue() async {
    final session =
        await ref.read(testMutationProvider.notifier).startTest();
    if (!mounted || session == null) return;

    context.go(RouteNames.studentTestSession(session.id));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(testMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo iniciar el test',
    );

    return DashboardShell(
      title: 'Test vocacional',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isLoading ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null) ...[
                  ErrorBanner(
                    message: errorMessage,
                    onDismiss: () =>
                        ref.read(testMutationProvider.notifier).clearError(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.continueTest
                      ? 'Continúa tu test vocacional'
                      : 'Instrucciones del test RIASEC',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Responderás ${AppConstants.riasecQuestionCount} preguntas '
                  'sobre actividades y preferencias. No hay respuestas correctas '
                  'o incorrectas: elige la opción que mejor refleje tu interés.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Text(
                  'Escala de respuesta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const ScaleAnswerSelector(
                  selectedValue: null,
                  onSelected: _noop,
                  enabled: false,
                ),
                const SizedBox(height: 20),
                const EthicalDisclaimerBanner(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _startOrContinue,
                    icon: Icon(
                      widget.continueTest
                          ? Icons.play_arrow_outlined
                          : Icons.quiz_outlined,
                    ),
                    label: Text(
                      widget.continueTest
                          ? 'Continuar test'
                          : 'Comenzar test',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const LoadingOverlay(message: 'Preparando tu sesión de test...'),
        ],
      ),
    );
  }
}

void _noop(int _) {}
