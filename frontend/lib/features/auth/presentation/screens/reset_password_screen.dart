import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../providers/auth_session_provider.dart';
import '../widgets/password_success_notice.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    if (widget.token.trim().isEmpty) {
      setState(
        () => _errorMessage = 'El enlace de restablecimiento no es válido.',
      );
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
      final message = await ref.read(authRepositoryProvider).resetPassword(
            token: widget.token.trim(),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SafeArea(
        child: _successMessage != null
            ? PasswordSuccessNotice(
                message: _successMessage!,
                actionLabel: 'Ir al inicio de sesión',
                onAction: () => context.go(RouteNames.login),
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
                          const Text(
                            'Define una contraseña segura para tu cuenta.',
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            key: const Key('reset-password-new'),
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
                            key: const Key('reset-password-confirm'),
                            controller: _confirmController,
                            enabled: !_busy,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar contraseña',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => AppValidators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const Key('reset-password-submit'),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Restablecer contraseña'),
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
