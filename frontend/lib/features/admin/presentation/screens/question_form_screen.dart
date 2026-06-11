import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/question.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class QuestionFormScreen extends ConsumerStatefulWidget {
  const QuestionFormScreen({super.key, this.questionId});

  final int? questionId;

  bool get isEditing => questionId != null;

  @override
  ConsumerState<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends ConsumerState<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _orderController = TextEditingController();

  int? _categoryId;
  QuestionStatus _status = QuestionStatus.active;
  bool _initialized = false;

  @override
  void dispose() {
    _textController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _populateForm(Question question) {
    if (_initialized) return;
    _textController.text = question.text;
    _orderController.text = '${question.orderNumber}';
    _categoryId = question.categoryId;
    _status = question.status;
    _initialized = true;
  }

  String? _validateOrder(String? value) {
    final requiredError =
        AppValidators.required(value, fieldName: 'número de orden');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 1 || parsed > 100) {
      return 'El número de orden debe estar entre 1 y 100';
    }
    return null;
  }

  Future<void> _submit(List<RiasecCategory> categories) async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una categoría RIASEC')),
        );
      }
      return;
    }

    final category = categories.firstWhere((item) => item.id == _categoryId);
    final question = Question(
      id: widget.questionId ?? 0,
      categoryId: _categoryId!,
      category: category,
      text: _textController.text.trim(),
      orderNumber: int.parse(_orderController.text.trim()),
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(questionMutationProvider.notifier);
    final result = widget.isEditing
        ? await notifier.update(question)
        : await notifier.create(question);

    if (!mounted || result == null) return;

    ref.invalidate(questionListProvider);
    if (widget.isEditing) {
      ref.invalidate(questionDetailProvider(widget.questionId!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Pregunta actualizada correctamente'
              : 'Pregunta creada correctamente',
        ),
      ),
    );

    context.go(RouteNames.adminQuestionDetail(result.id));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(riasecCategoriesProvider);
    final mutationState = ref.watch(questionMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar la pregunta',
    );

    return categoriesAsync.when(
      data: (categories) {
        _categoryId ??= categories.isNotEmpty ? categories.first.id : null;

        if (widget.isEditing) {
          final detailAsync =
              ref.watch(questionDetailProvider(widget.questionId!));
          return detailAsync.when(
            data: (question) {
              _populateForm(question);
              return _buildScaffold(
                categories: categories,
                isLoading: isLoading,
                errorMessage: errorMessage,
              );
            },
            loading: () => const DashboardShell(
              title: 'Editar pregunta',
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => DashboardShell(
              title: 'Editar pregunta',
              body: Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(
                    questionDetailProvider(widget.questionId!),
                  ),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
          );
        }

        return _buildScaffold(
          categories: categories,
          isLoading: isLoading,
          errorMessage: errorMessage,
        );
      },
      loading: () => const DashboardShell(
        title: 'Pregunta RIASEC',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => DashboardShell(
        title: 'Pregunta RIASEC',
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(riasecCategoriesProvider),
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required List<RiasecCategory> categories,
    required bool isLoading,
    required String? errorMessage,
  }) {
    return DashboardShell(
      title: widget.isEditing ? 'Editar pregunta' : 'Nueva pregunta',
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
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null) ...[
                    ErrorBanner(
                      message: errorMessage,
                      onDismiss: () => ref
                          .read(questionMutationProvider.notifier)
                          .clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría RIASEC *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text('${category.code} — ${category.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(
                      labelText: 'Número de orden *',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    validator: _validateOrder,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Texto de la pregunta *',
                      prefixIcon: Icon(Icons.help_outline),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    enabled: !isLoading,
                    validator: (value) => AppValidators.minLength(
                      value,
                      min: 10,
                      fieldName: 'El texto',
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QuestionStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: QuestionStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : () => _submit(categories),
                    child: Text(
                      widget.isEditing ? 'Guardar cambios' : 'Crear pregunta',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            LoadingOverlay(
              message:
                  widget.isEditing ? 'Guardando...' : 'Creando pregunta...',
            ),
        ],
      ),
    );
  }
}
