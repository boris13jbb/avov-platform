import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';
import '../../../vocational/domain/vocational_test.dart';

/// Fila de una evaluación abierta: fecha/estado, progreso y Continuar.
class OpenVocationalSessionTile extends StatelessWidget {
  const OpenVocationalSessionTile({
    super.key,
    required this.session,
    this.continueKey,
  });

  final VocationalSession session;
  final Key? continueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.openSummaryLabel,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Respuestas guardadas: ${session.answeredCount} de ${session.totalQuestions}',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: continueKey,
            onPressed: () => context.push(RouteNames.studentTest(session.id)),
            child: const Text('Continuar esta evaluación'),
          ),
        ],
      ),
    );
  }
}

/// Aviso cuando hay más de una evaluación abierta.
class MultipleOpenSessionsNotice extends StatelessWidget {
  const MultipleOpenSessionsNotice({super.key});

  static const message =
      'Tienes varias evaluaciones pendientes. Elige cuál quieres continuar. '
      'Ninguna se ha perdido ni se han unido las sesiones.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
      ),
    );
  }
}
