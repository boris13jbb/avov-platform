import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../domain/question.dart';
import '../providers/question_provider.dart';

typedef QuestionSubmit = Future<void> Function(QuestionDraft draft);

class QuestionForm extends ConsumerStatefulWidget {
  const QuestionForm({
    super.key,
    required this.onSubmit,
    this.initial,
    this.submitLabel = 'Guardar pregunta',
  });

  final QuestionSubmit onSubmit;
  final VocationalQuestion? initial;
  final String submitLabel;

  @override
  ConsumerState<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends ConsumerState<QuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _orderController;
  int? _categoryId;
  late String _status;
  bool _submitting = false;
  String? _errorMessage;
  List<String> _fieldErrors = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _textController = TextEditingController(text: initial?.text ?? '');
    _orderController = TextEditingController(
      text: initial?.orderNumber.toString() ?? '',
    );
    _categoryId = initial?.categoryId;
    _status = initial?.status == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
  }

  @override
  void dispose() {
    _textController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _errorMessage = 'Selecciona una categoría RIASEC');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _fieldErrors = const [];
    });
    try {
      await widget.onSubmit(
        QuestionDraft(
          categoryId: categoryId,
          text: _textController.text.trim(),
          orderNumber: int.parse(_orderController.text.trim()),
          status: _status,
        ),
      );
    } on ValidationException catch (error) {
      setState(() {
        _errorMessage = error.message;
        _fieldErrors = error.fieldErrors;
      });
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(questionCategoryChoicesProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                categories.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    error is AppException
                        ? error.message
                        : FailureMapper.unexpectedMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'No hay categorías disponibles. Verifica que existan preguntas RIASEC en el sistema.',
                      );
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: InputDecoration(
                        labelText: 'Categoría RIASEC',
                        errorText: _backendError('category_id'),
                      ),
                      items: [
                        for (final category in items)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.label),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _categoryId = value),
                      validator: (value) =>
                          value == null ? 'Selecciona una categoría' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('question-text'),
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Texto de la pregunta',
                    errorText: _backendError('text'),
                    alignLabelWithHint: true,
                  ),
                  minLines: 2,
                  maxLines: 5,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'texto',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length < 10) {
                      return 'El texto debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('question-order'),
                  controller: _orderController,
                  decoration: InputDecoration(
                    labelText: 'Número de orden',
                    errorText: _backendError('order_number'),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'número de orden',
                    );
                    if (required != null) {
                      return required;
                    }
                    final parsed = int.tryParse(value!.trim());
                    if (parsed == null || parsed < 1 || parsed > 100) {
                      return 'Indica un número entre 1 y 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Activa')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactiva')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _backendError(String field) {
    final prefix = '$field: ';
    for (final item in _fieldErrors) {
      if (item.startsWith(prefix)) {
        return item.substring(prefix.length);
      }
    }
    return null;
  }
}
