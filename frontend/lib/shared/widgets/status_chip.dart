import 'package:flutter/material.dart';

/// Chip de estado estandarizado para mostrar estados (Activo/Inactivo/Bloqueado).
///
/// Usa la paleta del theme: `success` para activo, gris para inactivo,
/// `error` para bloqueado.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  factory StatusChip.active(String label) => StatusChip(label: label, tone: StatusTone.success);
  factory StatusChip.inactive(String label) => StatusChip(label: label, tone: StatusTone.muted);
  factory StatusChip.blocked(String label) => StatusChip(label: label, tone: StatusTone.error);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    switch (tone) {
      case StatusTone.success:
        background = scheme.primary.withValues(alpha: 0.12);
        foreground = scheme.primary;
        break;
      case StatusTone.error:
        background = scheme.error.withValues(alpha: 0.12);
        foreground = scheme.error;
        break;
      case StatusTone.muted:
        background = scheme.onSurface.withValues(alpha: 0.08);
        foreground = scheme.onSurfaceVariant;
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: foreground),
      ),
      backgroundColor: background,
      visualDensity: VisualDensity.compact,
    );
  }
}

enum StatusTone { success, error, muted }
