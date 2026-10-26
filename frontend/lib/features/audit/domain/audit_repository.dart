import 'audit_log.dart';

abstract class AuditRepository {
  Future<AuditLogPage> list(AuditLogQuery query);

  Future<AuditLogEntry> getById(int id);
}
