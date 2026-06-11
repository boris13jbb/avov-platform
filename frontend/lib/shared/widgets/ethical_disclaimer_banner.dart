import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/public_settings_provider.dart';
import '../../core/theme/app_colors.dart';

class EthicalDisclaimerBanner extends ConsumerWidget {
  const EthicalDisclaimerBanner({super.key, this.message});

  /// Si se proporciona, tiene prioridad sobre la configuración pública del servidor.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(publicSettingsProvider);
    final String text;
    if (message != null && message!.isNotEmpty) {
      text = message!;
    } else {
      text = settingsAsync.when(
        data: (settings) => settings.ethicalDisclaimer.isNotEmpty
            ? settings.ethicalDisclaimer
            : AppConstants.ethicalDisclaimer,
        loading: () => AppConstants.ethicalDisclaimer,
        error: (_, __) => AppConstants.ethicalDisclaimer,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
