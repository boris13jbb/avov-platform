import 'package:flutter/material.dart';

/// Destino mínimo tras el login. El panel completo de cada rol aún no existe.
class PendingPanelScreen extends StatelessWidget {
  const PendingPanelScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sesión iniciada. El panel de este rol todavía no está implementado.',
          ),
        ),
      ),
    );
  }
}
