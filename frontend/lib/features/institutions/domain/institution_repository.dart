import 'institution.dart';

abstract class InstitutionRepository {
  Future<InstitutionPage> list({
    required int page,
    required int pageSize,
    String? search,
  });

  Future<Institution> getById(int id);

  Future<Institution> create(InstitutionDraft draft);

  Future<Institution> update(int id, InstitutionDraft draft);

  /// `DELETE` del backend: marca la institución como inactiva. No la borra.
  Future<Institution> deactivate(int id);

  /// `PUT` con `status: ACTIVE`. Revierte una desactivación.
  Future<Institution> activate(int id);
}
