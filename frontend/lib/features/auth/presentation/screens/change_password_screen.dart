import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../router/role_destination.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../providers/auth_session_provider.dart';
import '../widgets/password_success_notice.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final message = await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _passwordController.text,
            confirmPassword: _confirmController.text,
          );
      setState(() => _successMessage = message);
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = FailureMapper.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _goBack() {
    final role = ref.read(currentOperatorProvider).maybeWhen(
          data: (profile) => profile.role,
          orElse: () => null,
        );
    context.go(destinationForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: _successMessage != null
            ? PasswordSuccessNotice(
                message: _successMessage!,
                actionLabel: 'Volver al panel',
                onAction: _goBack,
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            key: const Key('change-password-current'),
                            controller: _currentController,
                            enabled: !_busy,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña actual',
                              border: OutlineInputBorder(),
                            ),
                            validator: AppValidators.loginPassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('change-password-new'),
                            controller: _passwordController,
                            enabled: !_busy,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: AppValidators.password,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('change-password-confirm'),
                            controller: _confirmController,
                            enabled: !_busy,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar nueva contraseña',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => AppValidators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const Key('change-password-submit'),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Actualizar contraseña'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
