import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vocational/presentation/providers/vocational_provider.dart';

/// Controles de «Cargar más» del historial paginado del estudiante.
class VocationalHistoryLoadMore extends ConsumerWidget {
  const VocationalHistoryLoadMore({super.key, required this.history});

  final VocationalHistoryState history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!history.hasMore && history.loadMoreError == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.loadMoreError != null) ...[
            Text(
              history.loadMoreError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          if (history.hasMore || history.loadMoreError != null)
            OutlinedButton(
              key: const Key('vocational-history-load-more'),
              onPressed: history.loadingMore
                  ? null
                  : () => ref.read(vocationalHistoryProvider.notifier).loadMore(),
              child: history.loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      history.loadMoreError == null
                          ? 'Cargar más evaluaciones'
                          : 'Reintentar carga',
                    ),
            ),
        ],
      ),
    );
  }
}
