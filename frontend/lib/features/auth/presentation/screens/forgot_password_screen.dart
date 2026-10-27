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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
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
      final message = await ref.read(authRepositoryProvider).forgotPassword(
            email: _emailController.text.trim(),
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
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: _successMessage != null
            ? PasswordSuccessNotice(
                message: _successMessage!,
                actionLabel: 'Volver al inicio de sesión',
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
                            'Ingresa tu correo electrónico. Si existe una cuenta '
                            'activa, recibirás instrucciones para restablecer la contraseña.',
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            key: const Key('forgot-password-email'),
                            controller: _emailController,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              border: OutlineInputBorder(),
                            ),
                            validator: AppValidators.email,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const Key('forgot-password-submit'),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Enviar instrucciones'),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => context.go(RouteNames.login),
                            child: const Text('Volver al inicio de sesión'),
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
