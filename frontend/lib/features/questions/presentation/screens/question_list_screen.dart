import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/question.dart';
import '../providers/question_provider.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  int? _busyQuestionId;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(questionListProvider);
    final page = ref.watch(questionPageProvider);
    final categoryFilter = ref.watch(questionCategoryFilterProvider);
    final statusFilter = ref.watch(questionStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas RIASEC'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ListNotice(
            message: error is AppException
                ? error.message
                : FailureMapper.unexpectedMessage,
            onRetry: () => ref.invalidate(questionListProvider),
          ),
          data: (result) {
            if (result.total == 0) {
              return _ListNotice(
                message:
                    'No hay preguntas que coincidan con los filtros actuales.',
                actionLabel: 'Crear pregunta',
                onRetry: () => context.go(RouteNames.adminQuestionNew),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            prefixIcon: Icon(Icons.search),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            ref.read(questionSearchProvider.notifier).state =
                                value.trim();
                            ref.read(questionPageProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: categoryFilter,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            for (final code in riasecCategoryFilterCodes)
                              DropdownMenuItem<String?>(
                                value: code,
                                child: Text(
                                  '$code — ${riasecCategoryFilterLabels[code]}',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            ref
                                .read(questionCategoryFilterProvider.notifier)
                                .state = value;
                            ref.read(questionPageProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'ACTIVE',
                              child: Text('Activas'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'INACTIVE',
                              child: Text('Inactivas'),
                            ),
                          ],
                          onChanged: (value) {
                            ref
                                .read(questionStatusFilterProvider.notifier)
                                .state = value;
                            ref.read(questionPageProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go(RouteNames.adminQuestionNew),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear pregunta'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final question = result.items[index];
                      return _QuestionTile(
                        question: question,
                        busy: _busyQuestionId == question.id,
                        onToggleStatus: () => _toggleStatus(question),
                        onEdit: () =>
                            context.go(RouteNames.adminQuestionEdit(question.id)),
                      );
                    },
                  ),
                ),
                if (result.pages > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: page > 1
                              ? () => ref
                                  .read(questionPageProvider.notifier)
                                  .state = page - 1
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página $page de ${result.pages}'),
                        IconButton(
                          onPressed: page < result.pages
                              ? () => ref
                                  .read(questionPageProvider.notifier)
                                  .state = page + 1
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleStatus(VocationalQuestion question) async {
    if (_busyQuestionId != null) {
      return;
    }
    final activate = question.status != 'ACTIVE';
    final confirmed = await ConfirmDialog.show(
      context,
      title: activate ? 'Activar pregunta' : 'Desactivar pregunta',
      message: activate
          ? 'La pregunta volverá a estar disponible en el test.'
          : 'La pregunta quedará inactiva y no se usará en nuevas evaluaciones.',
      confirmLabel: activate ? 'Activar' : 'Desactivar',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busyQuestionId = question.id);
    try {
      await ref.read(questionRepositoryProvider).updateStatus(
            id: question.id,
            status: activate ? 'ACTIVE' : 'INACTIVE',
          );
      ref.invalidate(questionListProvider);
    } on AppException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busyQuestionId = null);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.busy,
    required this.onToggleStatus,
    required this.onEdit,
  });

  final VocationalQuestion question;
  final bool busy;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final active = question.status == 'ACTIVE';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.category.code} · Orden ${question.orderNumber}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(question.text),
            const SizedBox(height: 8),
            Text(question.statusLabel),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : onEdit,
                  child: const Text('Editar'),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : onToggleStatus,
                  child: Text(active ? 'Desactivar' : 'Activar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListNotice extends StatelessWidget {
  const _ListNotice({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Reintentar',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

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
            FilledButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
