import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_audit_repository.dart';
import '../../domain/audit_log.dart';
import '../../domain/audit_repository.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return ApiAuditRepository(ref.watch(dioClientProvider).dio);
});

final auditPageProvider = StateProvider<int>((ref) => 1);

final auditActionFilterProvider = StateProvider<String?>((ref) => null);

final auditEntityFilterProvider = StateProvider<String?>((ref) => null);

final auditLogListProvider = FutureProvider.autoDispose<AuditLogPage>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final page = ref.watch(auditPageProvider);
  final action = ref.watch(auditActionFilterProvider);
  final entity = ref.watch(auditEntityFilterProvider);
  return repo.list(
    AuditLogQuery(
      page: page,
      action: action,
      entity: entity,
    ),
  );
});

final auditLogDetailProvider =
    FutureProvider.autoDispose.family<AuditLogEntry, int>((ref, id) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getById(id);
});
