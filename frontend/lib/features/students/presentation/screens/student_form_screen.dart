import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/managed_user.dart';
import '../../../../core/models/student.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../domain/student_management_config.dart';
import '../providers/student_provider.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({
    super.key,
    required this.config,
    this.studentId,
  });

  final StudentManagementConfig config;
  final int? studentId;

  bool get isEditing => studentId != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _identificationController = TextEditingController();
  final _gradeController = TextEditingController();
  final _parallelController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _representativePhoneController = TextEditingController();
  final _representativeEmailController = TextEditingController();

  DateTime _birthDate = DateTime(DateTime.now().year - 15, 1, 1);
  StudentGender _gender = StudentGender.notSpecified;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identificationController.dispose();
    _gradeController.dispose();
    _parallelController.dispose();
    _representativeNameController.dispose();
    _representativePhoneController.dispose();
    _representativeEmailController.dispose();
    super.dispose();
  }

  void _populateForm(ManagedStudent student) {
    if (_initialized) return;
    _emailController.text = student.user.email;
    _firstNameController.text = student.user.firstName;
    _lastNameController.text = student.user.lastName;
    _phoneController.text = student.user.phone ?? '';
    _identificationController.text = student.identification;
    _birthDate = student.birthDate;
    _gender = student.gender;
    _gradeController.text = student.grade;
    _parallelController.text = student.parallel ?? '';
    _representativeNameController.text = student.representativeName ?? '';
    _representativePhoneController.text = student.representativePhone ?? '';
    _representativeEmailController.text = student.representativeEmail ?? '';
    _initialized = true;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  ManagedStudent _buildStudent({
    required StudentUser user,
    required int id,
    required int userId,
    required int institutionId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return ManagedStudent(
      id: id,
      userId: userId,
      institutionId: institutionId,
      identification: _identificationController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      grade: _gradeController.text.trim(),
      parallel: _parallelController.text.trim().isEmpty
          ? null
          : _parallelController.text.trim(),
      representativeName: _representativeNameController.text.trim().isEmpty
          ? null
          : _representativeNameController.text.trim(),
      representativePhone: _representativePhoneController.text.trim().isEmpty
          ? null
          : _representativePhoneController.text.trim(),
      representativeEmail: _representativeEmailController.text.trim().isEmpty
          ? null
          : _representativeEmailController.text.trim(),
      user: user,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = StudentUser(
      id: widget.studentId ?? 0,
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      status: UserAccountStatus.active,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    final notifier = ref.read(studentMutationProvider.notifier);

    if (widget.isEditing) {
      final existing =
          await ref.read(studentDetailProvider(widget.studentId!).future);
      final student = _buildStudent(
        user: StudentUser(
          id: existing.user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          status: existing.user.status,
          phone: user.phone,
        ),
        id: existing.id,
        userId: existing.userId,
        institutionId: existing.institutionId,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      );

      final result = await notifier.update(student);
      if (!mounted || result == null) return;
      ref.invalidate(studentListProvider);
      ref.invalidate(studentDetailProvider(widget.studentId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante actualizado')),
      );
      context.go(widget.config.detailRoute(result.id));
      return;
    }

    final currentUser = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    final institutionId = currentUser?.institutionId;
    if (institutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar la institución del administrador'),
        ),
      );
      return;
    }

    final student = _buildStudent(
      user: user,
      id: 0,
      userId: 0,
      institutionId: institutionId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final result = await notifier.create(
      student,
      institutionId: institutionId,
      password: _passwordController.text,
    );

    if (!mounted || result == null) return;

    ref.invalidate(studentListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estudiante creado correctamente')),
    );
    context.go(widget.config.detailRoute(result.id));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(studentMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar el estudiante',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (widget.isEditing) {
      final detailAsync = ref.watch(studentDetailProvider(widget.studentId!));
      return detailAsync.when(
        data: (student) {
          _populateForm(student);
          return _buildScaffold(
            isLoading: isLoading,
            errorMessage: errorMessage,
            dateFormat: dateFormat,
          );
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
                  ref.invalidate(studentDetailProvider(widget.studentId!)),
              child: const Text('Reintentar'),
            ),
          ),
        ),
      );
    }

    return _buildScaffold(
      isLoading: isLoading,
      errorMessage: errorMessage,
      dateFormat: dateFormat,
    );
  }

  Widget _buildScaffold({
    required bool isLoading,
    required String? errorMessage,
    required DateFormat dateFormat,
  }) {
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
                          ref.read(studentMutationProvider.notifier).clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const _SectionTitle('Datos de acceso'),
                  if (!widget.isEditing) ...[
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
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
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
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
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
                  ] else ...[
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
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Datos personales'),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombres *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !isLoading,
                    validator: (v) => AppValidators.required(v, fieldName: 'nombres'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !isLoading,
                    validator: (v) => AppValidators.required(v, fieldName: 'apellidos'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _identificationController,
                    decoration: const InputDecoration(
                      labelText: 'Identificación *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (v) => AppValidators.minLength(
                      v,
                      min: 5,
                      fieldName: 'La identificación',
                    ),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de nacimiento *'),
                    subtitle: Text(dateFormat.format(_birthDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: isLoading ? null : _pickBirthDate,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<StudentGender>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: StudentGender.values
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.label),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) setState(() => _gender = value);
                          },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Datos académicos'),
                  TextFormField(
                    controller: _gradeController,
                    decoration: const InputDecoration(
                      labelText: 'Grado / curso *',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (v) => AppValidators.required(v, fieldName: 'grado'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parallelController,
                    decoration: const InputDecoration(
                      labelText: 'Paralelo',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Representante (opcional)'),
                  TextFormField(
                    controller: _representativeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del representante',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _representativePhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono del representante',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    enabled: !isLoading,
                    validator: AppValidators.optionalPhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _representativeEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo del representante',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: AppValidators.optionalEmail,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: Text(
                      widget.isEditing ? 'Guardar cambios' : 'Crear estudiante',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            LoadingOverlay(
              message:
                  widget.isEditing ? 'Guardando...' : 'Creando estudiante...',
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
