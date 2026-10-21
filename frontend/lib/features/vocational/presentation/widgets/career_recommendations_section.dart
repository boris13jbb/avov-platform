import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/career_recommendation.dart';
import '../providers/recommendation_provider.dart';

/// Bloque de carreras recomendadas ligado a una sesión finalizada.
class CareerRecommendationsSection extends ConsumerWidget {
  const CareerRecommendationsSection({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionRecommendationsProvider(sessionId));
    return async.when(
      // Icono estático: evita que pumpAndSettle cuelgue por animación infinita.
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Icon(Icons.hourglass_top, semanticLabel: 'Cargando recomendaciones'),
        ),
      ),
      error: (error, _) => _RecError(
        message: error is AppException
            ? error.message
            : FailureMapper.unexpectedMessage,
        onRetry: () =>
            ref.invalidate(sessionRecommendationsProvider(sessionId)),
      ),
      data: (page) => _RecBody(
        page: page,
        onRegenerate: () async {
          try {
            await ref
                .read(recommendationRepositoryProvider)
                .generateForSession(sessionId);
            ref.invalidate(sessionRecommendationsProvider(sessionId));
          } catch (_) {
            ref.invalidate(sessionRecommendationsProvider(sessionId));
          }
        },
      ),
    );
  }
}

class _RecBody extends StatelessWidget {
  const _RecBody({required this.page, required this.onRegenerate});

  final CareerRecommendationPage page;
  final Future<void> Function() onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carreras recomendadas',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (page.usedFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Se usó la búsqueda alternativa en el catálogo (MySQL) '
              'porque el índice vectorial no estuvo disponible o no devolvió resultados.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (page.items.isEmpty)
          const Text(
            'No hay carreras compatibles en el catálogo activo para este perfil.',
          )
        else
          for (final item in page.items) ...[
            Text(
              '${item.careerName} · ${item.matchPercentage.toStringAsFixed(0)}%',
              style: theme.textTheme.titleSmall,
            ),
            Text('${item.careerArea} · Perfil ${item.careerRiasecProfile}'),
            if (item.aiExplanation != null) ...[
              const SizedBox(height: 4),
              Text(item.aiExplanation!),
            ],
            const SizedBox(height: 12),
          ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              onRegenerate();
            },
            child: const Text('Actualizar recomendaciones'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Este resultado es orientativo y no reemplaza la orientación profesional '
          'de un psicólogo, docente u orientador educativo.',
        ),
      ],
    );
  }
}

class _RecError extends StatelessWidget {
  const _RecError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
