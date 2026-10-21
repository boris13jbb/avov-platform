import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../institutions/domain/institution.dart';
import '../../domain/managed_user.dart';

typedef UserSubmit = Future<void> Function(UserDraft draft);

class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    required this.onSubmit,
    required this.institutions,
    this.initial,
    this.lockRole = false,
    this.roleLockMessage =
        'No puedes cambiar tu propio rol desde esta pantalla.',
    this.allowedRoles = userRoles,
    this.fixedInstitutionId,
    this.submitLabel = 'Guardar usuario',
    this.includePassword = false,
  });

  final UserSubmit onSubmit;
  final List<Institution> institutions;
  final ManagedUser? initial;
  final bool lockRole;
  final String roleLockMessage;
  final List<String> allowedRoles;
  final int? fixedInstitutionId;
  final String submitLabel;
  final bool includePassword;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late String _role;
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
    final initialRole = initial?.role ??
        (widget.allowedRoles.contains('STUDENT')
            ? 'STUDENT'
            : widget.allowedRoles.first);
    _role = widget.allowedRoles.contains(initialRole)
        ? initialRole
        : widget.allowedRoles.first;
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
        UserDraft(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: _role,
          status: _status,
          password: widget.includePassword ? _passwordController.text : null,
          institutionId: _role == 'SUPER_ADMIN' ? null : _institutionId,
          phone: _phoneController.text.trim(),
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
    final needsInstitution = _role != 'SUPER_ADMIN';
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
                  key: const Key('user-first-name'),
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
                  key: const Key('user-last-name'),
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
                  key: const Key('user-email'),
                  controller: _emailController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    errorText: _backendError('email'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: 12),
                if (widget.includePassword) ...[
                  TextFormField(
                    key: const Key('user-password'),
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
                DropdownButtonFormField<String>(
                  key: const Key('user-role'),
                  initialValue: _role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: [
                    for (final role in widget.allowedRoles)
                      DropdownMenuItem(
                        value: role,
                        child: Text(userRoleLabel(role)),
                      ),
                  ],
                  onChanged: _submitting || widget.lockRole
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _role = value;
                            if (value == 'SUPER_ADMIN') {
                              _institutionId = null;
                            }
                          });
                        },
                ),
                if (widget.lockRole) ...[
                  const SizedBox(height: 8),
                  Text(widget.roleLockMessage),
                ],
                const SizedBox(height: 12),
                if (needsInstitution && widget.fixedInstitutionId != null) ...[
                  const Text(
                    'La institución es la de tu sesión y no se puede cambiar.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (needsInstitution &&
                    widget.fixedInstitutionId == null &&
                    widget.institutions.isEmpty)
                  FormField<void>(
                    validator: (_) =>
                        'No hay instituciones activas para asignar',
                    builder: (state) => Text(
                      state.errorText ??
                          'No hay instituciones activas para asignar',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (needsInstitution &&
                    widget.fixedInstitutionId == null &&
                    widget.institutions.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    key: const Key('user-institution'),
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
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _institutionId = value),
                    validator: (value) {
                      if (value == null) {
                        return 'La institución es obligatoria para este rol';
                      }
                      return null;
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
    final known = widget.institutions.any((item) => item.id == id);
    return known ? id : null;
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
