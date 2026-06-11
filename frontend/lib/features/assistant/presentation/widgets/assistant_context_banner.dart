import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/assistant_context.dart';

class AssistantContextBanner extends StatelessWidget {
  const AssistantContextBanner({
    super.key,
    required this.assistantContext,
    this.onGoToTest,
    this.onGenerateRecommendations,
    this.isGeneratingRecommendations = false,
  });

  final AssistantContext assistantContext;
  final VoidCallback? onGoToTest;
  final VoidCallback? onGenerateRecommendations;
  final bool isGeneratingRecommendations;

  @override
  Widget build(BuildContext context) {
    final profileReason = assistantContext.profileBlockReason;
    final careersReason = assistantContext.careersBlockReason;

    if (profileReason == null && careersReason == null) {
      return const SizedBox.shrink();
    }

    final showTestAction =
        !assistantContext.hasCompletedTest && onGoToTest != null;
    final showGenerateAction = assistantContext.hasCompletedTest &&
        !assistantContext.hasRecommendations &&
        onGenerateRecommendations != null;

    final message = !assistantContext.hasCompletedTest
        ? profileReason!
        : careersReason!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (showTestAction || showGenerateAction) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showTestAction)
                  FilledButton.tonalIcon(
                    onPressed: onGoToTest,
                    icon: Icon(
                      assistantContext.hasOpenSession
                          ? Icons.play_arrow_outlined
                          : Icons.quiz_outlined,
                      size: 18,
                    ),
                    label: Text(
                      assistantContext.hasOpenSession
                          ? 'Continuar test'
                          : 'Ir al test vocacional',
                    ),
                  ),
                if (showGenerateAction)
                  FilledButton.tonalIcon(
                    onPressed:
                        isGeneratingRecommendations ? null : onGenerateRecommendations,
                    icon: isGeneratingRecommendations
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(
                      isGeneratingRecommendations
                          ? 'Generando...'
                          : 'Generar recomendaciones',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AssistantFallbackBanner extends StatelessWidget {
  const AssistantFallbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: AppColors.secondary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'La última respuesta fue generada en modo orientativo (sin IA avanzada). '
              'Sigue siendo útil, pero puede ser más general.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
