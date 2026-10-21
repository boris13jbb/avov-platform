import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/providers/providers.dart';
import '../../data/api_vocational_repository.dart';
import '../../domain/vocational_repository.dart';
import '../../domain/vocational_test.dart';

final vocationalRepositoryProvider = Provider<VocationalRepository>((ref) {
  return ApiVocationalRepository(ref.watch(dioClientProvider).dio);
});

/// Historial acumulado del estudiante autenticado (`GET /tests`).
///
/// Página 1 al construir; páginas siguientes con [VocationalHistory.notifyLoadMore].
final vocationalHistoryProvider =
    AutoDisposeAsyncNotifierProvider<VocationalHistory, VocationalHistoryState>(
  VocationalHistory.new,
);

class VocationalHistoryState {
  const VocationalHistoryState({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<VocationalSession> items;
  final int page;
  final int pages;
  final int total;
  final bool loadingMore;
  final String? loadMoreError;

  bool get hasMore => page < pages;

  VocationalHistoryState copyWith({
    List<VocationalSession>? items,
    int? page,
    int? pages,
    int? total,
    bool? loadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return VocationalHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

class VocationalHistory extends AutoDisposeAsyncNotifier<VocationalHistoryState> {
  static const pageSize = 20;

  @override
  Future<VocationalHistoryState> build() {
    return _fetchPage(1);
  }

  /// Reinicia desde la página 1 sin mezclar páginas previas.
  ///
  /// Conserva el valor anterior durante la recarga para no mostrar un vacío
  /// falso. Devuelve `true` solo si la página 1 se obtuvo correctamente.
  Future<bool> refresh() async {
    final previous = state;
    if (previous.hasValue) {
      state = const AsyncLoading<VocationalHistoryState>()
          .copyWithPrevious(previous);
    } else {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() => _fetchPage(1));
    state = result;
    // AsyncError puede conservar hasValue tras copyWithPrevious.
    return result.hasValue && !result.hasError;
  }

  /// Solicita la página siguiente y acumula sin duplicar por `id`.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(loadingMore: true, clearLoadMoreError: true),
    );
    try {
      final next = await _fetchPage(current.page + 1);
      final merged = _mergeUnique(current.items, next.items);
      state = AsyncData(
        VocationalHistoryState(
          items: merged,
          page: next.page,
          pages: next.pages,
          total: next.total,
        ),
      );
    } on AppException catch (error) {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreError: error.message),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          loadingMore: false,
          loadMoreError: FailureMapper.unexpectedMessage,
        ),
      );
    }
  }

  Future<VocationalHistoryState> _fetchPage(int page) async {
    final result = await ref.read(vocationalRepositoryProvider).listSessions(
          page: page,
          pageSize: pageSize,
        );
    return VocationalHistoryState(
      items: result.items,
      page: result.page,
      pages: result.pages,
      total: result.total,
    );
  }

  static List<VocationalSession> _mergeUnique(
    List<VocationalSession> existing,
    List<VocationalSession> incoming,
  ) {
    final seen = {for (final item in existing) item.id};
    return [
      ...existing,
      for (final item in incoming)
        if (seen.add(item.id)) item,
    ];
  }
}

final vocationalQuestionsProvider = FutureProvider.autoDispose
    .family<VocationalQuestionnaire, int>((ref, sessionId) {
  return ref.watch(vocationalRepositoryProvider).questions(sessionId);
});

final vocationalResultProvider =
    FutureProvider.autoDispose.family<VocationalResult, int>((ref, sessionId) {
  return ref.watch(vocationalRepositoryProvider).result(sessionId);
});
