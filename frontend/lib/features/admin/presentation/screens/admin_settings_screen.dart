import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/system_setting.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _booleanValues = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<SystemSetting> settings) {
    for (final setting in settings) {
      if (setting.isBoolean) {
        _booleanValues[setting.key] = setting.value.toLowerCase() == 'true';
        continue;
      }
      _controllers.putIfAbsent(
        setting.key,
        () => TextEditingController(text: setting.value),
      );
      _controllers[setting.key]!.text = setting.value;
    }
  }

  Future<void> _saveSetting(SystemSetting setting) async {
    final value = setting.isBoolean
        ? (_booleanValues[setting.key] == true ? 'true' : 'false')
        : _controllers[setting.key]?.text.trim() ?? '';

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El valor no puede estar vacío')),
      );
      return;
    }

    final result = await ref
        .read(systemSettingsMutationProvider.notifier)
        .update(key: setting.key, value: value);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(systemSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${setting.label} actualizado')),
      );
    } else {
      final error = ref.read(systemSettingsMutationProvider).error;
      final message = error is AppException
          ? error.message
          : 'No se pudo guardar el parámetro';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(dioClientProvider).config;
    final settingsAsync = ref.watch(systemSettingsProvider);
    final mutationState = ref.watch(systemSettingsMutationProvider);
    final isLoading = mutationState.isLoading;
    final errorMessage = mutationState.whenOrNull(
      error: (error, _) => error is AppException
          ? error.message
          : 'No se pudo guardar la configuración',
    );

    return DashboardShell(
      title: 'Configuración del sistema',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isLoading ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          settingsAsync.when(
            data: (settings) {
              _syncControllers(settings);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (errorMessage != null) ...[
                    ErrorBanner(
                      message: errorMessage,
                      onDismiss: () => ref
                          .read(systemSettingsMutationProvider.notifier)
                          .clearError(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información de la aplicación',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Cliente', value: config.appName),
                          const _InfoRow(label: 'Versión API', value: '0.1.0'),
                          _InfoRow(label: 'API base', value: config.apiBaseUrl),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Parámetros globales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...settings.map((setting) => _SettingCard(
                        setting: setting,
                        controller: _controllers[setting.key],
                        booleanValue: _booleanValues[setting.key],
                        isLoading: isLoading,
                        onBooleanChanged: setting.isBoolean
                            ? (value) => setState(
                                  () => _booleanValues[setting.key] = value,
                                )
                            : null,
                        onSave: () => _saveSetting(setting),
                      )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(systemSettingsProvider),
                child: const Text('Reintentar'),
              ),
            ),
          ),
          if (isLoading)
            const LoadingOverlay(message: 'Guardando configuración...'),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.setting,
    required this.controller,
    required this.booleanValue,
    required this.isLoading,
    required this.onSave,
    this.onBooleanChanged,
  });

  final SystemSetting setting;
  final TextEditingController? controller;
  final bool? booleanValue;
  final bool isLoading;
  final VoidCallback onSave;
  final ValueChanged<bool>? onBooleanChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              setting.label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (setting.description != null) ...[
              const SizedBox(height: 4),
              Text(
                setting.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            if (setting.isBoolean)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activado'),
                value: booleanValue ?? false,
                onChanged: isLoading ? null : onBooleanChanged,
              )
            else
              TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: setting.isMultiline ? 4 : 1,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  isDense: !setting.isMultiline,
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: isLoading ? null : onSave,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
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
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
