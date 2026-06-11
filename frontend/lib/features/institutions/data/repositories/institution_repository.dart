import '../../../../core/models/institution.dart';
import '../datasources/institution_remote_datasource.dart';

class InstitutionRepository {
  InstitutionRepository({required InstitutionRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final InstitutionRemoteDatasource _remoteDatasource;

  Future<PaginatedInstitutions> listInstitutions({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? province,
    String? city,
  }) {
    return _remoteDatasource.listInstitutions(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      province: province,
      city: city,
    );
  }

  Future<Institution> getInstitution(int id) =>
      _remoteDatasource.getInstitution(id);

  Future<Institution> createInstitution(Institution institution) =>
      _remoteDatasource.createInstitution(institution.toCreateJson());

  Future<Institution> updateInstitution(Institution institution) =>
      _remoteDatasource.updateInstitution(
        institution.id,
        institution.toUpdateJson(),
      );

  Future<Institution> updateInstitutionSettings(Institution institution) =>
      _remoteDatasource.updateInstitution(
        institution.id,
        institution.toInstitutionAdminUpdateJson(),
      );

  Future<Institution> uploadInstitutionLogo({
    required int institutionId,
    required List<int> bytes,
    required String filename,
  }) =>
      _remoteDatasource.uploadInstitutionLogo(institutionId, bytes, filename);

  Future<Institution> deactivateInstitution(int id) =>
      _remoteDatasource.deactivateInstitution(id);
}
