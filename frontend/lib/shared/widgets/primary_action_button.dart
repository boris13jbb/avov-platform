import 'package:flutter/material.dart';

/// Botón de acción primario estandarizado.
///
/// Aplica el `filledButtonTheme` global (ancho completo, 48px,
/// radio 8, color primary). Acepta un icono opcional.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(label);

    if (icon != null && !loading) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
