import 'managed_student.dart';

/// Contrato de `/students`.
///
/// El estudiante es un perfil propio, vinculado a un usuario con rol STUDENT.
/// No hay eliminación física ni restablecimiento de contraseña.
/// El estado de la cuenta se cambia con `PATCH /students/{id}/status`.
/// La institución no se puede mover: el esquema de edición no admite `institution_id`.
abstract class StudentRepository {
  Future<ManagedStudentPage> list(StudentListQuery query);

  Future<ManagedStudent> getById(int id);

  Future<ManagedStudent> create(StudentDraft draft);

  Future<ManagedStudent> update(int id, StudentDraft draft);

  Future<ManagedStudent> updateStatus(int id, String status);
}
