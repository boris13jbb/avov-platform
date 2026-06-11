import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/institution.dart';
import '../../../../core/models/managed_user.dart';
import '../../../../core/models/user_role.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../domain/user_management_config.dart';
import '../providers/user_provider.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({
    super.key,
    required this.config,
    this.userId,
  });

  final UserManagementConfig config;
  final int? userId;

  bool get isEditing => userId != null;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late UserRole _selectedRole;
  UserAccountStatus _status = UserAccountStatus.active;
  int? _selectedInstitutionId;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.config.creatableRoles.first;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _populateForm(ManagedUser user) {
    if (_initialized) return;
    _emailController.text = user.email;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone ?? '';
    _selectedRole = user.role;
    _status = user.status;
    _selectedInstitutionId = user.institutionId;
    _initialized = true;
  }

  bool get _requiresInstitution => _selectedRole != UserRole.superAdmin;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiresInstitution && _selectedInstitutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una institución para este rol'),
        ),
      );
      return;
    }

    final user = ManagedUser(
      id: widget.userId ?? 0,
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      status: _status,
      institutionId: _requiresInstitution ? _selectedInstitutionId : null,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(userMutationProvider.notifier);
    final result = widget.isEditing
        ? await notifier.update(user)
        : await notifier.create(
            user,
            password: _passwordController.text,
          );

    if (!mounted || result == null) return;

    ref.invalidate(userListProvider);
    if (widget.isEditing) {
      ref.invalidate(userDetailProvider(widget.userId!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing ? 'Usuario actualizado' : 'Usuario creado',
        ),
      ),
    );

    context.go(widget.config.detailRoute(result.id));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(userMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar el usuario',
    );

    if (widget.isEditing) {
      final detailAsync = ref.watch(userDetailProvider(widget.userId!));
      return detailAsync.when(
        data: (user) {
          _populateForm(user);
          return _buildScaffold(isLoading: isLoading, errorMessage: errorMessage);
        },
        loading: () => DashboardShell(
          title: widget.config.editTitle,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => DashboardShell(
          title: widget.config.editTitle,
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  ref.invalidate(userDetailProvider(widget.userId!)),
              child: const Text('Reintentar'),
            ),
          ),
        ),
      );
    }

    return _buildScaffold(isLoading: isLoading, errorMessage: errorMessage);
  }

  Widget _buildScaffold({
    required bool isLoading,
    required String? errorMessage,
  }) {
    final institutionsAsync = widget.config.showInstitutionPicker
        ? ref.watch(activeInstitutionsProvider)
        : null;

    return DashboardShell(
      title: widget.isEditing ? widget.config.editTitle : widget.config.newTitle,
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
                      onDismiss: () =>
                          ref.read(userMutationProvider.notifier).clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombres *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !isLoading,
                    validator: (value) => AppValidators.required(
                      value,
                      fieldName: 'nombres',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !isLoading,
                    validator: (value) => AppValidators.required(
                      value,
                      fieldName: 'apellidos',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    validator: AppValidators.optionalPhone,
                  ),
                  const SizedBox(height: 16),
                  if (widget.config.creatableRoles.length > 1)
                    DropdownButtonFormField<UserRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: widget.config.creatableRoles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            ),
                          )
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                  if (!_requiresInstitution) {
                                    _selectedInstitutionId = null;
                                  }
                                });
                              }
                            },
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      child: Text(_selectedRole.label),
                    ),
                  if (_requiresInstitution &&
                      widget.config.showInstitutionPicker &&
                      institutionsAsync != null) ...[
                    const SizedBox(height: 16),
                    institutionsAsync.when(
                      data: (institutions) =>
                          DropdownButtonFormField<int>(
                        initialValue: _selectedInstitutionId,
                        decoration: const InputDecoration(
                          labelText: 'Institución *',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        items: institutions
                            .map(
                              (Institution institution) =>
                                  DropdownMenuItem<int>(
                                value: institution.id,
                                child: Text(institution.name),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() => _selectedInstitutionId = value);
                              },
                        validator: (value) =>
                            _requiresInstitution && value == null
                                ? 'Selecciona una institución'
                                : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text(
                        'No se pudieron cargar las instituciones',
                      ),
                    ),
                  ],
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: isLoading
                              ? null
                              : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: isLoading
                              ? null
                              : () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      enabled: !isLoading,
                      validator: (value) => AppValidators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: Text(
                      widget.isEditing ? 'Guardar cambios' : 'Crear usuario',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            LoadingOverlay(
              message: widget.isEditing ? 'Guardando...' : 'Creando usuario...',
            ),
        ],
      ),
    );
  }
}
