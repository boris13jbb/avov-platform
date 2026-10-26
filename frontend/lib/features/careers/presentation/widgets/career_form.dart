import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../domain/career.dart';

typedef CareerSubmit = Future<void> Function(CareerDraft draft);

class CareerForm extends StatefulWidget {
  const CareerForm({
    super.key,
    required this.onSubmit,
    this.initial,
    this.submitLabel = 'Guardar carrera',
  });

  final CareerSubmit onSubmit;
  final Career? initial;
  final String submitLabel;

  @override
  State<CareerForm> createState() => _CareerFormState();
}

class _CareerFormState extends State<CareerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _riasecController;
  late final TextEditingController _durationController;
  late final TextEditingController _employmentFieldController;
  late String _degreeType;
  late String _institutionType;
  late String _status;
  bool _submitting = false;
  String? _errorMessage;
  List<String> _fieldErrors = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _areaController = TextEditingController(text: initial?.area ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _riasecController =
        TextEditingController(text: initial?.riasecProfile ?? '');
    _durationController = TextEditingController(text: initial?.duration ?? '');
    _employmentFieldController =
        TextEditingController(text: initial?.employmentField ?? '');
    _degreeType = initial?.degreeType ?? degreeTypeValues.first;
    _institutionType = initial?.institutionType ?? institutionTypeValues.first;
    _status = initial?.status == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    _riasecController.dispose();
    _durationController.dispose();
    _employmentFieldController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _fieldErrors = const [];
    });
    try {
      await widget.onSubmit(
        CareerDraft(
          name: _nameController.text.trim(),
          area: _areaController.text.trim(),
          description: _descriptionController.text.trim(),
          riasecProfile: _riasecController.text.trim().toUpperCase(),
          duration: _durationController.text.trim(),
          degreeType: _degreeType,
          institutionType: _institutionType,
          employmentField: _employmentFieldController.text.trim(),
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
                TextFormField(
                  key: const Key('career-name'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: _backendError('name'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'nombre',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    labelText: 'Área',
                    errorText: _backendError('area'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) => AppValidators.required(
                    value,
                    fieldName: 'área',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    errorText: _backendError('description'),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'descripción',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length < 10) {
                      return 'La descripción debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('career-riasec'),
                  controller: _riasecController,
                  decoration: InputDecoration(
                    labelText: 'Perfil RIASEC',
                    helperText: 'Solo letras R, I, A, S, E o C (ej.: IRC)',
                    errorText: _backendError('riasec_profile'),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'perfil RIASEC',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (!RegExp(r'^[RIASEC]+$').hasMatch(value!.trim().toUpperCase())) {
                      return 'Usa solo las letras R, I, A, S, E o C';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: 'Duración (opcional)',
                    errorText: _backendError('duration'),
                  ),
                  enabled: !_submitting,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _degreeType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de título',
                    errorText: _backendError('degree_type'),
                  ),
                  items: [
                    for (final value in degreeTypeValues)
                      DropdownMenuItem(
                        value: value,
                        child: Text(degreeTypeLabels[value] ?? value),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _degreeType = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _institutionType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de institución',
                    errorText: _backendError('institution_type'),
                  ),
                  items: [
                    for (final value in institutionTypeValues)
                      DropdownMenuItem(
                        value: value,
                        child: Text(institutionTypeLabels[value] ?? value),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _institutionType = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employmentFieldController,
                  decoration: InputDecoration(
                    labelText: 'Campo laboral',
                    errorText: _backendError('employment_field'),
                  ),
                  enabled: !_submitting,
                  validator: (value) => AppValidators.required(
                    value,
                    fieldName: 'campo laboral',
                  ),
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
