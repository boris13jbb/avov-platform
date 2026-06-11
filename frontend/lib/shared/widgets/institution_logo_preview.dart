import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/utils/api_url_resolver.dart';

class InstitutionLogoPreview extends ConsumerWidget {
  const InstitutionLogoPreview({
    super.key,
    this.logoUrl,
    this.pendingBytes,
    this.size = 120,
    this.borderRadius = 12,
  });

  final String? logoUrl;
  final Uint8List? pendingBytes;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiBaseUrl = ref.watch(dioClientProvider).config.apiBaseUrl;
    final resolvedLogoUrl = ApiUrlResolver.resolveMediaUrl(apiBaseUrl, logoUrl);
    final hasPendingLogo = pendingBytes != null && pendingBytes!.isNotEmpty;
    final hasRemoteLogo = resolvedLogoUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPendingLogo
          ? Image.memory(
              pendingBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderIcon(),
            )
          : hasRemoteLogo
              ? Image.network(
                  resolvedLogoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _errorPlaceholder(context),
                )
              : _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return const Icon(Icons.image_outlined, size: 40);
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 4),
          Text(
            'No se pudo cargar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
    );
  }
}
