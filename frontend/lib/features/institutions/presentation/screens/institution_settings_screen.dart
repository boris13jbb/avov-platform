import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/institution.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/institution_logo_preview.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/institution_provider.dart';

class InstitutionSettingsScreen extends ConsumerStatefulWidget {
  const InstitutionSettingsScreen({super.key});

  @override
  ConsumerState<InstitutionSettingsScreen> createState() =>
      _InstitutionSettingsScreenState();
}

class _InstitutionSettingsScreenState
    extends ConsumerState<InstitutionSettingsScreen> {
  static const _maxLogoBytes = 2 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  Institution? _loadedInstitution;
  String? _displayLogoUrl;
  String? _pendingLogoName;
  Uint8List? _pendingLogoBytes;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateForm(Institution institution) {
    if (_initialized) return;
    _loadedInstitution = institution;
    _displayLogoUrl = institution.logoUrl;
    _nameController.text = institution.name;
    _provinceController.text = institution.province;
    _cityController.text = institution.city;
    _addressController.text = institution.address ?? '';
    _phoneController.text = institution.phone ?? '';
    _emailController.text = institution.email ?? '';
    _initialized = true;
  }

  Future<void> _pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (!mounted || pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    if (bytes.length > _maxLogoBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El logo no puede superar 2 MB')),
      );
      return;
    }

    final fileName = pickedFile.name.isNotEmpty
        ? pickedFile.name
        : 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    setState(() {
      _pendingLogoBytes = Uint8List.fromList(bytes);
      _pendingLogoName = fileName;
    });
  }

  Future<void> _uploadLogo() async {
    if (_loadedInstitution == null ||
        _pendingLogoBytes == null ||
        _pendingLogoName == null) {
      return;
    }

    final notifier = ref.read(institutionMutationProvider.notifier);
    final result = await notifier.uploadLogo(
      institutionId: _loadedInstitution!.id,
      bytes: _pendingLogoBytes!,
      filename: _pendingLogoName!,
    );
    if (!mounted || result == null) return;

    setState(() {
      _loadedInstitution = result;
      _displayLogoUrl = result.logoUrl;
      _pendingLogoBytes = null;
      _pendingLogoName = null;
    });

    ref.invalidate(institutionSettingsProvider);
    ref.invalidate(institutionDetailProvider(result.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo actualizado correctamente')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loadedInstitution == null) return;

    final institution = Institution(
      id: _loadedInstitution!.id,
      name: _nameController.text.trim(),
      code: _loadedInstitution!.code,
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
      logoUrl: _loadedInstitution!.logoUrl,
      status: _loadedInstitution!.status,
      createdAt: _loadedInstitution!.createdAt,
      updatedAt: _loadedInstitution!.updatedAt,
    );

    final notifier = ref.read(institutionMutationProvider.notifier);
    final result = await notifier.updateSettings(institution);
    if (!mounted || result == null) return;

    setState(() {
      _loadedInstitution = result;
      _displayLogoUrl = result.logoUrl;
    });

    ref.invalidate(institutionSettingsProvider);
    ref.invalidate(institutionDetailProvider(result.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(institutionSettingsProvider);
    final mutationState = ref.watch(institutionMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar la configuración',
    );

    return settingsAsync.when(
      data: (institution) {
        _populateForm(institution);
        return _buildScaffold(
          institution: institution,
          isLoading: isLoading,
          errorMessage: errorMessage,
        );
      },
      loading: () => const DashboardShell(
        title: 'Configuración institución',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => DashboardShell(
        title: 'Configuración institución',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(institutionSettingsProvider),
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isLoading) {
    final hasPendingLogo = _pendingLogoBytes != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Logo institucional',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Center(
              child: InstitutionLogoPreview(
                logoUrl: _displayLogoUrl,
                pendingBytes: _pendingLogoBytes,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasPendingLogo
                  ? 'Archivo seleccionado: $_pendingLogoName'
                  : 'Formatos: PNG, JPG o WEBP. Máximo 2 MB. '
                      'La vista previa usa la misma URL de API configurada en la app.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _pickLogo,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Seleccionar imagen'),
            ),
            if (hasPendingLogo) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: isLoading ? null : _uploadLogo,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Subir logo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required Institution institution,
    required bool isLoading,
    required String? errorMessage,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return DashboardShell(
      title: 'Configuración institución',
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos de referencia',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Código',
                            value: institution.code,
                          ),
                          _InfoRow(
                            label: 'Estado',
                            value: institution.status.label,
                          ),
                          _InfoRow(
                            label: 'Última actualización',
                            value: dateFormat.format(institution.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLogoSection(isLoading),
                  const SizedBox(height: 16),
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
                    validator: (value) => AppValidators.minLength(
                      value,
                      min: 3,
                      fieldName: 'El nombre',
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
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'provincia'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'ciudad'),
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: const Text('Guardar configuración'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
