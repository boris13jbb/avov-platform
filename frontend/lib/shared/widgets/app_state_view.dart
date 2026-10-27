import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Estado centrado reutilizable: error, vacío o mensaje informativo.
///
/// Sustituye las variantes privadas `_Notice` / `_DashboardMessage` dispersas.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  /// Error de carga/red con reintento.
  const AppStateView.error({
    super.key,
    required this.message,
    VoidCallback? onRetry,
  })  : icon = Icons.cloud_off_outlined,
        iconColor = AppColors.textSecondary,
        actionLabel = onRetry == null ? null : 'Reintentar',
        onAction = onRetry,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Lista o sección sin resultados.
  const AppStateView.empty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  })  : iconColor = AppColors.textSecondary,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  final String message;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 44,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabecera de página con título y subtítulo opcionales.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.caption,
  });

  final String title;
  final String? subtitle;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle!, style: theme.textTheme.titleMedium),
        ],
        if (caption != null && caption!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Contenedor de métrica compacta para paneles.
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
