import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/institution.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/institution_provider.dart';

class InstitutionFormScreen extends ConsumerStatefulWidget {
  const InstitutionFormScreen({super.key, this.institutionId});

  final int? institutionId;

  bool get isEditing => institutionId != null;

  @override
  ConsumerState<InstitutionFormScreen> createState() =>
      _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends ConsumerState<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  InstitutionStatus _status = InstitutionStatus.active;
  bool _initialized = false;

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

  void _populateForm(Institution institution) {
    if (_initialized) return;
    _nameController.text = institution.name;
    _codeController.text = institution.code;
    _provinceController.text = institution.province;
    _cityController.text = institution.city;
    _addressController.text = institution.address ?? '';
    _phoneController.text = institution.phone ?? '';
    _emailController.text = institution.email ?? '';
    _status = institution.status;
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final institution = Institution(
      id: widget.institutionId ?? 0,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      province: _provinceController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(institutionMutationProvider.notifier);
    final result = widget.isEditing
        ? await notifier.update(institution)
        : await notifier.create(institution);

    if (!mounted || result == null) return;

    ref.invalidate(institutionListProvider);
    if (widget.isEditing) {
      ref.invalidate(institutionDetailProvider(widget.institutionId!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Institución actualizada'
              : 'Institución creada correctamente',
        ),
      ),
    );

    context.go(RouteNames.adminInstitutionDetail(result.id));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(institutionMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar la institución',
    );

    if (widget.isEditing) {
      final detailAsync =
          ref.watch(institutionDetailProvider(widget.institutionId!));

      return detailAsync.when(
        data: (institution) {
          _populateForm(institution);
          return _buildScaffold(isLoading: isLoading, errorMessage: errorMessage);
        },
        loading: () => const DashboardShell(
          title: 'Editar institución',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => DashboardShell(
          title: 'Editar institución',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                institutionDetailProvider(widget.institutionId!),
              ),
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
    return DashboardShell(
      title: widget.isEditing ? 'Editar institución' : 'Nueva institución',
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
                          .read(institutionMutationProvider.notifier)
                          .clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.minLength(value, min: 3, fieldName: 'El nombre'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código *',
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    enabled: !isLoading,
                    validator: (value) => AppValidators.required(
                      value,
                      fieldName: 'código',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _provinceController,
                    decoration: const InputDecoration(
                      labelText: 'Provincia *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) => AppValidators.required(
                      value,
                      fieldName: 'provincia',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) => AppValidators.required(
                      value,
                      fieldName: 'ciudad',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    enabled: !isLoading,
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
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: AppValidators.optionalEmail,
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InstitutionStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: InstitutionStatus.values
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
                    onPressed: isLoading ? null : _submit,
                    child: Text(widget.isEditing ? 'Guardar cambios' : 'Crear institución'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            LoadingOverlay(
              message: widget.isEditing ? 'Guardando...' : 'Creando institución...',
            ),
        ],
      ),
    );
  }
}
