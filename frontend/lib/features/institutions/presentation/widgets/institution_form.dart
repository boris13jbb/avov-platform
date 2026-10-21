import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../domain/institution.dart';

typedef InstitutionSubmit = Future<void> Function(InstitutionDraft draft);

class InstitutionForm extends StatefulWidget {
  const InstitutionForm({
    super.key,
    required this.onSubmit,
    this.initial,
    this.submitLabel = 'Guardar institución',
  });

  final InstitutionSubmit onSubmit;
  final Institution? initial;
  final String submitLabel;

  @override
  State<InstitutionForm> createState() => _InstitutionFormState();
}

class _InstitutionFormState extends State<InstitutionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late String _status;
  bool _submitting = false;
  String? _errorMessage;
  List<String> _fieldErrors = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _codeController = TextEditingController(text: initial?.code ?? '');
    _provinceController = TextEditingController(text: initial?.province ?? '');
    _cityController = TextEditingController(text: initial?.city ?? '');
    _addressController = TextEditingController(text: initial?.address ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _status = initial?.status == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        InstitutionDraft(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
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
                  key: const Key('institution-name'),
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
                    if (value.trim().length > 150) {
                      return 'El nombre no puede superar 150 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('institution-code'),
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    errorText: _backendError('code'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'código',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length > 50) {
                      return 'El código no puede superar 50 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('institution-province'),
                  controller: _provinceController,
                  decoration: InputDecoration(
                    labelText: 'Provincia',
                    errorText: _backendError('province'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'provincia',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length > 100) {
                      return 'La provincia no puede superar 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('institution-city'),
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    errorText: _backendError('city'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'ciudad',
                    );
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length > 100) {
                      return 'La ciudad no puede superar 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección (opcional)',
                    errorText: _backendError('address'),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    if (value != null && value.trim().length > 255) {
                      return 'La dirección no puede superar 255 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    errorText: _backendError('phone'),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: _optionalPhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo (opcional)',
                    errorText: _backendError('email'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_submitting,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    return AppValidators.email(value);
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

  String? _optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d{7,15}$').hasMatch(value.trim())) {
      return 'El teléfono debe contener entre 7 y 15 dígitos';
    }
    return null;
  }
}
