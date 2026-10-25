import 'career.dart';

abstract class CareerRepository {
  Future<CareerPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? area,
    String? status,
  });

  Future<Career> getById(int id);

  Future<Career> create(CareerDraft draft);

  Future<Career> update(int id, CareerDraft draft);

  Future<Career> deactivate(int id);
}
