import '../../../core/models/career.dart';
import '../../../core/models/question.dart';
import '../../../core/models/system_setting.dart';
import 'admin_remote_datasource.dart';

class AdminRepository {
  AdminRepository({required AdminRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final AdminRemoteDatasource _remoteDatasource;

  Future<PaginatedCareers> listCareers({
    int page = 1,
    String? search,
    String? status,
  }) =>
      _remoteDatasource.listCareers(page: page, search: search, status: status);

  Future<Career> getCareer(int id) => _remoteDatasource.getCareer(id);

  Future<CareerMutationResult> createCareer(Career career) =>
      _remoteDatasource.createCareer(career.toCreateJson());

  Future<CareerMutationResult> updateCareer(Career career) =>
      _remoteDatasource.updateCareer(career.id, career.toUpdateJson());

  Future<CareerMutationResult> deactivateCareer(int id) =>
      _remoteDatasource.deactivateCareer(id);

  Future<PaginatedQuestions> listQuestions({
    int page = 1,
    String? search,
    String? status,
  }) =>
      _remoteDatasource.listQuestions(
        page: page,
        search: search,
        status: status,
      );

  Future<Question> getQuestion(int id) => _remoteDatasource.getQuestion(id);

  Future<Question> createQuestion(Question question) =>
      _remoteDatasource.createQuestion(question.toCreateJson());

  Future<Question> updateQuestion(Question question) =>
      _remoteDatasource.updateQuestion(question.id, question.toUpdateJson());

  Future<Question> deactivateQuestion(int id) =>
      _remoteDatasource.deleteQuestion(id);

  Future<List<RiasecCategory>> listRiasecCategories() =>
      _remoteDatasource.listRiasecCategories();

  Future<List<SystemSetting>> listSystemSettings() =>
      _remoteDatasource.listSystemSettings();

  Future<SystemSetting> updateSystemSetting({
    required String key,
    required String value,
  }) =>
      _remoteDatasource.updateSystemSetting(key: key, value: value);

  Future<Map<String, dynamic>> rebuildVectorIndex() =>
      _remoteDatasource.rebuildVectorIndex();

  Future<Map<String, dynamic>> listAuditLogs({
    int page = 1,
    String? action,
    String? entity,
  }) =>
      _remoteDatasource.listAuditLogs(
        page: page,
        action: action,
        entity: entity,
      );

  Future<Map<String, dynamic>> getAuditLog(int id) =>
      _remoteDatasource.getAuditLog(id);
}
