import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../institutions/domain/institution.dart';
import '../../../users/domain/managed_user.dart';
import '../../domain/managed_student.dart';

typedef StudentSubmit = Future<void> Function(StudentDraft draft);

class StudentForm extends StatefulWidget {
  const StudentForm({
    super.key,
    required this.onSubmit,
    required this.institutions,
    this.initial,
    this.submitLabel = 'Guardar estudiante',
    this.includePassword = false,
    this.lockInstitution = false,
    this.fixedInstitutionId,
  });

  final StudentSubmit onSubmit;
  final List<Institution> institutions;
  final ManagedStudent? initial;
  final String submitLabel;
  final bool includePassword;
  final bool lockInstitution;
  final int? fixedInstitutionId;

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _identificationController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _gradeController;
  late final TextEditingController _parallelController;
  late final TextEditingController _representativeNameController;
  late final TextEditingController _representativePhoneController;
  late final TextEditingController _representativeEmailController;
  late String _gender;
  late String _status;
  int? _institutionId;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;
  List<String> _fieldErrors = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _firstNameController = TextEditingController(text: initial?.firstName ?? '');
    _lastNameController = TextEditingController(text: initial?.lastName ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _passwordController = TextEditingController();
    _identificationController = TextEditingController(text: initial?.identification ?? '');
    _birthDateController = TextEditingController(text: initial?.birthDate ?? '');
    _gradeController = TextEditingController(text: initial?.grade ?? '');
    _parallelController = TextEditingController(text: initial?.parallel ?? '');
    _representativeNameController =
        TextEditingController(text: initial?.representativeName ?? '');
    _representativePhoneController =
        TextEditingController(text: initial?.representativePhone ?? '');
    _representativeEmailController =
        TextEditingController(text: initial?.representativeEmail ?? '');
    _gender = initial?.gender ?? 'NOT_SPECIFIED';
    _status = initial?.status ?? 'ACTIVE';
    _institutionId = widget.fixedInstitutionId ?? initial?.institutionId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _identificationController.dispose();
    _birthDateController.dispose();
    _gradeController.dispose();
    _parallelController.dispose();
    _representativeNameController.dispose();
    _representativePhoneController.dispose();
    _representativeEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final institutionId = _institutionId;
    if (institutionId == null) {
      setState(() => _errorMessage = 'La institución es obligatoria');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _fieldErrors = const [];
    });
    try {
      await widget.onSubmit(
        StudentDraft(
          institutionId: institutionId,
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          identification: _identificationController.text.trim(),
          birthDate: _birthDateController.text.trim(),
          gender: _gender,
          grade: _gradeController.text.trim(),
          status: _status,
          password: widget.includePassword ? _passwordController.text : null,
          phone: _phoneController.text.trim(),
          parallel: _parallelController.text.trim(),
          representativeName: _representativeNameController.text.trim(),
          representativePhone: _representativePhoneController.text.trim(),
          representativeEmail: _representativeEmailController.text.trim(),
        ),
      );
      _passwordController.clear();
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
                  key: const Key('student-first-name'),
                  controller: _firstNameController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: _backendError('first_name'),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _name(value, 'nombre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('student-last-name'),
                  controller: _lastNameController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    errorText: _backendError('last_name'),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _name(value, 'apellido'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('student-email'),
                  controller: _emailController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    errorText: _backendError('email'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: 12),
                if (widget.includePassword) ...[
                  TextFormField(
                    key: const Key('student-password'),
                    controller: _passwordController,
                    enabled: !_submitting,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña inicial',
                      errorText: _backendError('password'),
                      suffixIcon: IconButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: AppValidators.password,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _phoneController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    errorText: _backendError('phone'),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _optionalPhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('student-identification'),
                  controller: _identificationController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Identificación',
                    errorText: _backendError('identification'),
                  ),
                  validator: (value) {
                    final required = AppValidators.required(
                      value,
                      fieldName: 'identificación',
                    );
                    if (required != null) {
                      return required;
                    }
                    final length = value!.trim().length;
                    if (length < 5 || length > 50) {
                      return 'La identificación debe tener entre 5 y 50 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('student-birth-date'),
                  controller: _birthDateController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento (AAAA-MM-DD)',
                    errorText: _backendError('birth_date'),
                  ),
                  validator: _birthDate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('student-gender'),
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: [
                    for (final gender in studentGenders)
                      DropdownMenuItem(
                        value: gender,
                        child: Text(studentGenderLabel(gender)),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _gender = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('student-grade'),
                  controller: _gradeController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Curso',
                    errorText: _backendError('grade'),
                  ),
                  validator: (value) {
                    final required = AppValidators.required(value, fieldName: 'curso');
                    if (required != null) {
                      return required;
                    }
                    if (value!.trim().length > 20) {
                      return 'El curso no puede superar 20 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _parallelController,
                  enabled: !_submitting,
                  decoration: const InputDecoration(labelText: 'Paralelo (opcional)'),
                  validator: (value) {
                    if (value != null && value.trim().length > 10) {
                      return 'El paralelo no puede superar 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (widget.fixedInstitutionId != null) ...[
                  const Text(
                    'La institución es la de tu sesión y no se puede cambiar.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.fixedInstitutionId == null && widget.institutions.isEmpty)
                  FormField<void>(
                    validator: (_) => 'No hay instituciones activas para asignar',
                    builder: (state) => Text(
                      state.errorText ?? 'No hay instituciones activas para asignar',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (widget.fixedInstitutionId == null &&
                    widget.institutions.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    key: const Key('student-institution'),
                    initialValue: _knownInstitutionId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Institución'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Selecciona una institución'),
                      ),
                      for (final institution in widget.institutions)
                        DropdownMenuItem<int?>(
                          value: institution.id,
                          child: Text(institution.name),
                        ),
                    ],
                    onChanged: _submitting || widget.lockInstitution
                        ? null
                        : (value) => setState(() => _institutionId = value),
                    validator: (value) {
                      if (value == null) {
                        return 'La institución es obligatoria';
                      }
                      return null;
                    },
                  ),
                if (widget.lockInstitution) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'La institución no se puede cambiar desde esta pantalla.',
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _representativeNameController,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del representante (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _representativePhoneController,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono del representante (opcional)',
                  ),
                  validator: _optionalPhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _representativeEmailController,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: 'Correo del representante (opcional)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    return AppValidators.email(value);
                  },
                ),
                if (widget.includePassword) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      for (final status in userStatuses)
                        DropdownMenuItem(
                          value: status,
                          child: Text(userStatusLabel(status)),
                        ),
                    ],
                    onChanged: _submitting
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

  int? get _knownInstitutionId {
    final id = _institutionId;
    if (id == null) {
      return null;
    }
    return widget.institutions.any((item) => item.id == id) ? id : null;
  }

  String? _name(String? value, String field) {
    final required = AppValidators.required(value, fieldName: field);
    if (required != null) {
      return required;
    }
    if (value!.trim().length > 100) {
      return 'El campo $field no puede superar 100 caracteres';
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

  String? _birthDate(String? value) {
    final required = AppValidators.required(value, fieldName: 'fecha de nacimiento');
    if (required != null) {
      return required;
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value!.trim());
    if (match == null) {
      return 'Usa el formato AAAA-MM-DD';
    }
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      return 'La fecha de nacimiento no es válida';
    }
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    if (parsed.isAfter(current)) {
      return 'La fecha de nacimiento no puede ser futura';
    }
    return null;
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
