import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/student.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/student_provider.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _gradeController = TextEditingController();
  final _parallelController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _representativePhoneController = TextEditingController();
  final _representativeEmailController = TextEditingController();

  ManagedStudent? _student;
  StudentGender _gender = StudentGender.notSpecified;
  DateTime? _birthDate;
  bool _initialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _gradeController.dispose();
    _parallelController.dispose();
    _representativeNameController.dispose();
    _representativePhoneController.dispose();
    _representativeEmailController.dispose();
    super.dispose();
  }

  void _populate(ManagedStudent student) {
    if (_initialized) return;
    _student = student;
    _phoneController.text = student.user.phone ?? '';
    _gradeController.text = student.grade;
    _parallelController.text = student.parallel ?? '';
    _representativeNameController.text = student.representativeName ?? '';
    _representativePhoneController.text = student.representativePhone ?? '';
    _representativeEmailController.text = student.representativeEmail ?? '';
    _gender = student.gender;
    _birthDate = student.birthDate;
    _initialized = true;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 15),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit(int studentId) async {
    if (!_formKey.currentState!.validate() || _student == null || _birthDate == null) {
      return;
    }

    final updated = ManagedStudent(
      id: _student!.id,
      userId: _student!.userId,
      institutionId: _student!.institutionId,
      identification: _student!.identification,
      birthDate: _birthDate!,
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
      user: StudentUser(
        id: _student!.user.id,
        email: _student!.user.email,
        firstName: _student!.user.firstName,
        lastName: _student!.user.lastName,
        status: _student!.user.status,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
      createdAt: _student!.createdAt,
      updatedAt: _student!.updatedAt,
    );

    final result =
        await ref.read(studentMutationProvider.notifier).update(updated);
    if (!mounted || result == null) return;

    ref.invalidate(studentDetailProvider(studentId));
    ref.invalidate(studentDashboardProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final mutationState = ref.watch(studentMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar el perfil',
    );

    return dashboardAsync.when(
      data: (data) {
        final studentId = (data['student_id'] as num?)?.toInt();
        if (studentId == null) {
          return DashboardShell(
            title: 'Mi perfil',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            body: const Center(child: Text('No se encontró el perfil estudiantil')),
          );
        }

        final detailAsync = ref.watch(studentDetailProvider(studentId));
        return detailAsync.when(
          data: (student) {
            _populate(student);
            return _buildForm(
              student: student,
              studentId: studentId,
              isLoading: isLoading,
              errorMessage: errorMessage,
            );
          },
          loading: () => const DashboardShell(
            title: 'Mi perfil',
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => DashboardShell(
            title: 'Mi perfil',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    ref.invalidate(studentDetailProvider(studentId)),
                child: const Text('Reintentar'),
              ),
            ),
          ),
        );
      },
      loading: () => const DashboardShell(
        title: 'Mi perfil',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => DashboardShell(
        title: 'Mi perfil',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(studentDashboardProvider),
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required ManagedStudent student,
    required int studentId,
    required bool isLoading,
    required String? errorMessage,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DashboardShell(
      title: 'Mi perfil',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isLoading ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      title: Text(student.user.fullName),
                      subtitle: Text(student.user.email),
                      trailing: Text(student.identification),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    ErrorBanner(message: errorMessage),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.optionalPhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gradeController,
                    decoration: const InputDecoration(
                      labelText: 'Grado/Curso *',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'grado'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parallelController,
                    decoration: const InputDecoration(
                      labelText: 'Paralelo',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StudentGender>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: StudentGender.values
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender.label),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _gender = value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de nacimiento'),
                    subtitle: Text(
                      _birthDate == null
                          ? 'Selecciona una fecha'
                          : dateFormat.format(_birthDate!),
                    ),
                    trailing: IconButton(
                      onPressed: isLoading ? null : _pickBirthDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _representativeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Representante',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _representativePhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono representante',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: AppValidators.optionalPhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _representativeEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo representante',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.optionalEmail,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : () => _submit(studentId),
                    child: const Text('Guardar perfil'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context.push(RouteNames.changePassword),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Cambiar contraseña'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LoadingOverlay(message: 'Guardando...'),
        ],
      ),
    );
  }
}
