import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/providers/providers.dart';
import '../../data/datasources/export_remote_datasource.dart';
import '../../data/repositories/export_repository.dart';

final exportRemoteDatasourceProvider = Provider<ExportRemoteDatasource>((ref) {
  return ExportRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepository(
    remoteDatasource: ref.watch(exportRemoteDatasourceProvider),
  );
});

enum ExportType { students, testResults }

final exportMutationProvider =
    StateNotifierProvider<ExportMutationController, AsyncValue<void>>(
  (ref) => ExportMutationController(ref.watch(exportRepositoryProvider)),
);

class ExportMutationController extends StateNotifier<AsyncValue<void>> {
  ExportMutationController(this._repository) : super(const AsyncData(null));

  final ExportRepository _repository;

  Future<String?> downloadAndOpen(ExportType type) async {
    state = const AsyncLoading();
    try {
      final file = switch (type) {
        ExportType.students => await _repository.downloadStudentsCsv(),
        ExportType.testResults => await _repository.downloadTestResultsCsv(),
      };

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${file.fileName}';
      await File(path).writeAsBytes(file.bytes);
      await OpenFilex.open(path);
      state = const AsyncData(null);
      return file.fileName;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
