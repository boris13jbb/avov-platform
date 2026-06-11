import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/test_session.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/ethical_disclaimer_banner.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/test_provider.dart';

class TestFinishScreen extends ConsumerStatefulWidget {
  const TestFinishScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<TestFinishScreen> createState() => _TestFinishScreenState();
}

class _TestFinishScreenState extends ConsumerState<TestFinishScreen> {
  RiasecResult? _result;
  String? _errorMessage;
  bool _isFinishing = false;

  Future<void> _confirmFinish() async {
    setState(() {
      _isFinishing = true;
      _errorMessage = null;
    });

    final result =
        await ref.read(testMutationProvider.notifier).finishTest(widget.sessionId);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(studentDashboardProvider);
      setState(() {
        _result = result;
        _isFinishing = false;
      });
    } else {
      final error = ref.read(testMutationProvider).error;
      setState(() {
        _isFinishing = false;
        _errorMessage = error is AppException
            ? error.message
            : 'No se pudo finalizar el test';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync =
        ref.watch(sessionQuestionsProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar test'),
        automaticallyImplyLeading: _result == null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            questionsAsync.when(
              data: (data) {
                final session = data.session;
                final answered = session.answeredCount;
                final total = session.totalQuestions;

                if (_result != null) {
                  return _ResultView(
                    result: _result!,
                    onBackToDashboard: () =>
                        context.go(RouteNames.studentDashboard),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        ErrorBanner(
                          message: _errorMessage!,
                          onDismiss: () =>
                              setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Icon(
                        Icons.fact_check_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¿Listo para enviar tu test?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Has respondido $answered de $total preguntas. '
                        'Al confirmar, calcularemos tu perfil RIASEC y no podrás '
                        'modificar las respuestas.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _SummaryRow(
                                label: 'Preguntas respondidas',
                                value: '$answered / $total',
                              ),
                              _SummaryRow(
                                label: 'Progreso',
                                value: '${session.progressPercent.toStringAsFixed(0)}%',
                              ),
                              _SummaryRow(
                                label: 'Estado',
                                value: session.status.label,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const EthicalDisclaimerBanner(),
                      const SizedBox(height: 24),
                      if (answered < total) ...[
                        FilledButton(
                          onPressed: _isFinishing
                              ? null
                              : () => context.go(
                                    RouteNames.studentTestSession(
                                      widget.sessionId,
                                    ),
                                  ),
                          child: const Text('Completar preguntas pendientes'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: _isFinishing || answered < total
                            ? null
                            : _confirmFinish,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar y calcular RIASEC'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(
                    sessionQuestionsProvider(widget.sessionId),
                  ),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
            if (_isFinishing)
              const LoadingOverlay(message: 'Calculando tu perfil RIASEC...'),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onBackToDashboard,
  });

  final RiasecResult result;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Test completado!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu perfil RIASEC',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Perfil dominante',
                    value: result.dominantProfile ?? '—',
                  ),
                  _SummaryRow(
                    label: 'Perfil secundario',
                    value: result.secondaryProfile ?? '—',
                  ),
                  _SummaryRow(
                    label: 'Perfil combinado',
                    value: result.combinedProfile ?? '—',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(label: 'R (Realista)', value: '${result.scoreR}'),
                  _SummaryRow(label: 'I (Investigador)', value: '${result.scoreI}'),
                  _SummaryRow(label: 'A (Artístico)', value: '${result.scoreA}'),
                  _SummaryRow(label: 'S (Social)', value: '${result.scoreS}'),
                  _SummaryRow(label: 'E (Emprendedor)', value: '${result.scoreE}'),
                  _SummaryRow(label: 'C (Convencional)', value: '${result.scoreC}'),
                ],
              ),
            ),
          ),
          if (result.interpretation != null &&
              result.interpretation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result.interpretation!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const EthicalDisclaimerBanner(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBackToDashboard,
            child: const Text('Volver a mi panel'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push(RouteNames.studentResults),
            child: const Text('Ver resultados completos'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
