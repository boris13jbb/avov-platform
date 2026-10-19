import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../providers/vocational_provider.dart';

class VocationalResultScreen extends ConsumerWidget {
  const VocationalResultScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(vocationalResultProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado vocacional')),
      body: SafeArea(
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Notice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(vocationalResultProvider(sessionId)),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Perfil ${data.combinedProfile ?? data.dominantProfile ?? 'sin código'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (data.dominantProfile != null)
                Text('Dominante: ${data.dominantProfile}'),
              if (data.secondaryProfile != null)
                Text('Secundario: ${data.secondaryProfile}'),
              const SizedBox(height: 16),
              _Score(label: 'Realista', value: data.scoreR),
              _Score(label: 'Investigador', value: data.scoreI),
              _Score(label: 'Artístico', value: data.scoreA),
              _Score(label: 'Social', value: data.scoreS),
              _Score(label: 'Emprendedor', value: data.scoreE),
              _Score(label: 'Convencional', value: data.scoreC),
              if (data.interpretation != null) ...[
                const SizedBox(height: 16),
                Text(data.interpretation!),
              ],
              const SizedBox(height: 16),
              const Text(
                'Este resultado es orientativo y no reemplaza la orientación profesional '
                'de un psicólogo, docente u orientador educativo.',
              ),
              const SizedBox(height: 12),
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
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
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
