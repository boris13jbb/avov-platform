import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/public_settings_provider.dart';
import '../../../../router/role_route_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/current_user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted || !success) {
      return;
    }

    ref.invalidate(currentUserProvider);
    ref.invalidate(superAdminDashboardProvider);
    ref.invalidate(institutionDashboardProvider);
    ref.invalidate(counselorDashboardProvider);
    ref.invalidate(studentDashboardProvider);
    final roleValue = await ref.read(authRepositoryProvider).getStoredRole();
    final role = UserRole.fromApi(roleValue);
    final destination =
        role == null ? RouteNames.home : RoleRouteMapper.routeFor(role);

    if (mounted) {
      context.go(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final settingsAsync = ref.watch(publicSettingsProvider);
    final appName = settingsAsync.when(
      data: (settings) => settings.appDisplayName,
      loading: () => 'AVOV',
      error: (_, __) => 'AVOV',
    );
    final isLoading = authState.isLoading;
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;
    final errorMessage = authState.whenOrNull(
      error: (error, _) => _buildLoginErrorMessage(error, apiBaseUrl),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Asistente Virtual de Orientación Vocacional',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (errorMessage != null) ...[
                          ErrorBanner(
                            message: errorMessage,
                            onDismiss: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .clearError();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !isLoading,
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) => AppValidators.required(
                            value,
                            fieldName: 'contraseña',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push(RouteNames.forgotPassword),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: const Text('Ingresar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading) const LoadingOverlay(message: 'Iniciando sesión...'),
          ],
        ),
      ),
    );
  }
}

String _buildLoginErrorMessage(Object error, String apiBaseUrl) {
  final lines = <String>[];

  if (error is AppException && error.message.isNotEmpty) {
    lines.add(error.message);
  } else {
    lines.add('No se pudo iniciar sesión. Intenta nuevamente.');
  }

  if (error is NetworkException ||
      (error is AppException &&
          error.message.toLowerCase().contains('tiempo de espera'))) {
    lines.add('Desactiva la VPN del teléfono.');
    lines.add('Usa la misma red WiFi que la PC.');
    lines.add('API: $apiBaseUrl');
    lines.add('Prueba en el navegador del móvil: $apiBaseUrl/health/live');
  }

  return lines.join('\n');
}
