import 'package:flutter/material.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../shared/widgets/error_banner.dart';

class ObservationForm extends StatefulWidget {
  const ObservationForm({
    super.key,
    required this.onSubmit,
    this.busy = false,
    this.errorMessage,
  });

  final Future<void> Function(String text) onSubmit;
  final bool busy;
  final String? errorMessage;

  @override
  State<ObservationForm> createState() => _ObservationFormState();
}

class _ObservationFormState extends State<ObservationForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.busy) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await widget.onSubmit(_controller.text.trim());
    if (mounted) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errorMessage != null) ...[
            ErrorBanner(message: widget.errorMessage!),
            const SizedBox(height: 12),
          ],
          TextFormField(
            key: const Key('observation-text'),
            controller: _controller,
            enabled: !widget.busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 10000,
            decoration: const InputDecoration(
              labelText: 'Observación del orientador',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) => AppValidators.required(value, fieldName: 'observación'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('observation-submit'),
              onPressed: widget.busy ? null : _submit,
              icon: widget.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.note_add_outlined),
              label: const Text('Registrar observación'),
            ),
          ),
        ],
      ),
    );
  }
}
