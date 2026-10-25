import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';
import '../../../vocational/presentation/widgets/career_recommendations_section.dart';
import '../../../vocational/presentation/widgets/download_vocational_pdf_button.dart';
import '../../domain/observation.dart';
import '../providers/observation_provider.dart';
import '../widgets/observation_form.dart';

class CounselorSessionReviewScreen extends ConsumerStatefulWidget {
  const CounselorSessionReviewScreen({
    super.key,
    required this.studentId,
    required this.sessionId,
  });

  final int studentId;
  final int sessionId;

  @override
  ConsumerState<CounselorSessionReviewScreen> createState() =>
      _CounselorSessionReviewScreenState();
}

class _CounselorSessionReviewScreenState
    extends ConsumerState<CounselorSessionReviewScreen> {
  bool _submittingObservation = false;
  String? _observationError;

  Future<void> _createObservation(String text) async {
    setState(() {
      _submittingObservation = true;
      _observationError = null;
    });
    try {
      await ref.read(observationRepositoryProvider).create(
            ObservationDraft(
              testSessionId: widget.sessionId,
              observation: text,
            ),
          );
      ref.invalidate(sessionObservationsProvider(widget.sessionId));
      ref.invalidate(latestSessionObservationProvider(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observación registrada correctamente')),
        );
      }
    } on AppException catch (error) {
      setState(() => _observationError = error.message);
    } catch (_) {
      setState(
        () => _observationError = FailureMapper.unexpectedMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _submittingObservation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(vocationalResultProvider(widget.sessionId));
    final observations =
        ref.watch(sessionObservationsProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Sesión ${widget.sessionId}'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Resultado vocacional',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Notice(
                message: error is AppException
                    ? error.message
                    : FailureMapper.unexpectedMessage,
                onRetry: () =>
                    ref.invalidate(vocationalResultProvider(widget.sessionId)),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Perfil ${data.combinedProfile ?? data.dominantProfile ?? 'sin código'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (data.dominantProfile != null)
                    Text('Dominante: ${data.dominantProfile}'),
                  if (data.secondaryProfile != null)
                    Text('Secundario: ${data.secondaryProfile}'),
                  const SizedBox(height: 8),
                  Text('Realista: ${data.scoreR}'),
                  Text('Investigador: ${data.scoreI}'),
                  Text('Artístico: ${data.scoreA}'),
                  Text('Social: ${data.scoreS}'),
                  Text('Emprendedor: ${data.scoreE}'),
                  Text('Convencional: ${data.scoreC}'),
                  if (data.interpretation != null) ...[
                    const SizedBox(height: 8),
                    Text(data.interpretation!),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Este resultado es orientativo y no reemplaza la orientación '
                    'profesional de un psicólogo, docente u orientador educativo.',
                  ),
                  const SizedBox(height: 16),
                  DownloadVocationalPdfButton(sessionId: widget.sessionId),
                  const SizedBox(height: 16),
                  CareerRecommendationsSection(sessionId: widget.sessionId),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Observaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra notas profesionales vinculadas a esta evaluación. '
              'Las observaciones quedan asociadas a tu usuario orientador.',
            ),
            const SizedBox(height: 16),
            ObservationForm(
              busy: _submittingObservation,
              errorMessage: _observationError,
              onSubmit: _createObservation,
            ),
            const SizedBox(height: 24),
            observations.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _Notice(
                message: error is AppException
                    ? error.message
                    : FailureMapper.unexpectedMessage,
                onRetry: () => ref.invalidate(
                  sessionObservationsProvider(widget.sessionId),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const Text('Aún no hay observaciones para esta sesión.');
                }
                return Column(
                  children: [
                    for (final item in page.items) _ObservationTile(item: item),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.item});

  final CounselorObservation item;

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt.toLocal());
    final author = item.counselor?.displayName ?? 'Orientador ${item.counselorId}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(author, style: Theme.of(context).textTheme.titleSmall),
            Text(when, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(item.observation),
          ],
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
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
