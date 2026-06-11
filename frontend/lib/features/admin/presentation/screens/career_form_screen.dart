import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/career.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class CareerFormScreen extends ConsumerStatefulWidget {
  const CareerFormScreen({super.key, this.careerId});

  final int? careerId;

  bool get isEditing => careerId != null;

  @override
  ConsumerState<CareerFormScreen> createState() => _CareerFormScreenState();
}

class _CareerFormScreenState extends ConsumerState<CareerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _riasecController = TextEditingController();
  final _durationController = TextEditingController();
  final _employmentFieldController = TextEditingController();

  DegreeType _degreeType = DegreeType.licenciatura;
  CareerInstitutionType _institutionType = CareerInstitutionType.ambas;
  CareerStatus _status = CareerStatus.active;
  bool _initialized = false;

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

  void _populateForm(Career career) {
    if (_initialized) return;
    _nameController.text = career.name;
    _areaController.text = career.area;
    _descriptionController.text = career.description;
    _riasecController.text = career.riasecProfile;
    _durationController.text = career.duration ?? '';
    _employmentFieldController.text = career.employmentField;
    _degreeType = career.degreeType;
    _institutionType = career.institutionType;
    _status = career.status;
    _initialized = true;
  }

  String? _validateRiasec(String? value) {
    final requiredError = AppValidators.required(value, fieldName: 'perfil RIASEC');
    if (requiredError != null) return requiredError;
    final normalized = value!.trim().toUpperCase();
    if (!RegExp(r'^[RIASEC]+$').hasMatch(normalized)) {
      return 'Solo se permiten las letras R, I, A, S, E o C';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final career = Career(
      id: widget.careerId ?? 0,
      name: _nameController.text.trim(),
      area: _areaController.text.trim(),
      description: _descriptionController.text.trim(),
      riasecProfile: _riasecController.text.trim().toUpperCase(),
      duration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      degreeType: _degreeType,
      institutionType: _institutionType,
      employmentField: _employmentFieldController.text.trim(),
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(careerMutationProvider.notifier);
    final result = widget.isEditing
        ? await notifier.update(career)
        : await notifier.create(career);

    if (!mounted || result == null) return;

    ref.invalidate(careerListProvider);
    if (widget.isEditing) {
      ref.invalidate(careerDetailProvider(widget.careerId!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    context.go(RouteNames.adminCareerDetail(result.career.id));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(careerMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar la carrera',
    );

    if (widget.isEditing) {
      final detailAsync = ref.watch(careerDetailProvider(widget.careerId!));
      return detailAsync.when(
        data: (career) {
          _populateForm(career);
          return _buildScaffold(isLoading: isLoading, errorMessage: errorMessage);
        },
        loading: () => const DashboardShell(
          title: 'Editar carrera',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => DashboardShell(
          title: 'Editar carrera',
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  ref.invalidate(careerDetailProvider(widget.careerId!)),
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
      title: widget.isEditing ? 'Editar carrera' : 'Nueva carrera',
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
                          ref.read(careerMutationProvider.notifier).clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.minLength(value, min: 3, fieldName: 'El nombre'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Área *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'área'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.minLength(value, min: 10, fieldName: 'La descripción'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _riasecController,
                    decoration: const InputDecoration(
                      labelText: 'Perfil RIASEC *',
                      hintText: 'Ej: RIA',
                      prefixIcon: Icon(Icons.psychology_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    enabled: !isLoading,
                    validator: _validateRiasec,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración',
                      hintText: 'Ej: 4 años',
                      prefixIcon: Icon(Icons.schedule_outlined),
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DegreeType>(
                    initialValue: _degreeType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de título *',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: DegreeType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _degreeType = value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CareerInstitutionType>(
                    initialValue: _institutionType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de institución *',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    items: CareerInstitutionType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _institutionType = value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _employmentFieldController,
                    decoration: const InputDecoration(
                      labelText: 'Campo laboral *',
                      prefixIcon: Icon(Icons.business_center_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'campo laboral'),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CareerStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: CareerStatus.values
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
                    child: Text(widget.isEditing ? 'Guardar cambios' : 'Crear carrera'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            LoadingOverlay(
              message: widget.isEditing ? 'Guardando...' : 'Creando carrera...',
            ),
        ],
      ),
    );
  }
}
