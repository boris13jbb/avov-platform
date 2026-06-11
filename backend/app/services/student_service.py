from sqlalchemy.orm import Session

from app.core.enums import Gender, InstitutionStatus, UserRole, UserStatus
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.student import Student
from app.models.user import User
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository
from app.schemas.student import (
    PaginatedStudents,
    StudentCounselorAssignRequest,
    StudentCreate,
    StudentResponse,
    StudentStatusUpdate,
    StudentUpdate,
)


class StudentService:
    MAX_PAGE_SIZE = 100
    LIST_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN, UserRole.COUNSELOR}
    CREATE_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN}
    MANAGE_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN}

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = StudentRepository(db)
        self.user_repo = UserRepository(db)
        self.institution_repo = InstitutionRepository(db)

    def list_students(
        self,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        institution_id: int | None = None,
        status: UserStatus | None = None,
        grade: str | None = None,
        gender: Gender | None = None,
    ) -> PaginatedStudents:
        if current_user.role not in self.LIST_ROLES:
            raise ForbiddenException("No tienes permisos para listar estudiantes")

        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        scoped_institution_id, counselor_id = self._resolve_list_scope(
            current_user,
            institution_id,
        )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            search=search,
            institution_id=scoped_institution_id,
            counselor_id=counselor_id,
            status=status,
            grade=grade,
            gender=gender,
        )
        return PaginatedStudents.build(items, total, page, page_size)

    def get_student(self, student_id: int, current_user: User) -> StudentResponse:
        student = self._get_or_404(student_id)
        self._ensure_can_view(student, current_user)
        return StudentResponse.model_validate(student)

    def create_student(self, payload: StudentCreate, current_user: User) -> StudentResponse:
        if current_user.role not in self.CREATE_ROLES:
            raise ForbiddenException("No tienes permisos para crear estudiantes")

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            payload = payload.model_copy(
                update={"institution_id": current_user.institution_id}
            )

        self._validate_institution(payload.institution_id, current_user)

        if self.user_repo.get_by_email(str(payload.user.email)):
            raise ValidationException("El correo electrónico ya está registrado")

        if self.repo.get_by_identification(payload.identification):
            raise ValidationException("La identificación ya está registrada")

        student = self.repo.create_with_user(payload)
        return StudentResponse.model_validate(student)

    def update_student(
        self,
        student_id: int,
        payload: StudentUpdate,
        current_user: User,
    ) -> StudentResponse:
        student = self._get_or_404(student_id)
        self._ensure_can_manage(student, current_user)

        if current_user.role == UserRole.STUDENT:
            payload = self._filter_student_self_update(payload)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        if payload.identification and payload.identification != student.identification:
            existing = self.repo.get_by_identification(payload.identification)
            if existing and existing.id != student.id:
                raise ValidationException("La identificación ya está registrada")

        if payload.user and payload.user.email:
            existing_user = self.user_repo.get_by_email(str(payload.user.email))
            if existing_user and existing_user.id != student.user_id:
                raise ValidationException("El correo electrónico ya está registrado")

        updated = self.repo.update(student, payload)
        return StudentResponse.model_validate(updated)

    def update_student_status(
        self,
        student_id: int,
        payload: StudentStatusUpdate,
        current_user: User,
    ) -> StudentResponse:
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("No tienes permisos para cambiar el estado")

        student = self._get_or_404(student_id)
        self._ensure_can_manage(student, current_user)

        updated = self.repo.update_user_status(student, payload.status)
        return StudentResponse.model_validate(updated)

    def assign_counselor(
        self,
        student_id: int,
        payload: StudentCounselorAssignRequest,
        current_user: User,
    ) -> StudentResponse:
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException(
                "No tienes permisos para asignar orientadores a estudiantes"
            )

        student = self._get_or_404(student_id)
        self._ensure_can_manage(student, current_user)

        counselor = self.user_repo.get_by_id(payload.counselor_id)
        if counselor is None:
            raise NotFoundException("Orientador no encontrado")
        if counselor.role != UserRole.COUNSELOR:
            raise ValidationException("El usuario indicado no es un orientador")
        if counselor.status != UserStatus.ACTIVE:
            raise ValidationException("El orientador no está activo")
        if counselor.institution_id != student.institution_id:
            raise ValidationException(
                "El orientador debe pertenecer a la misma institución del estudiante"
            )

        self.repo.assign_counselor(
            student_id=student.id,
            counselor_id=counselor.id,
            institution_id=student.institution_id,
        )
        return StudentResponse.model_validate(student)

    def _get_or_404(self, student_id: int) -> Student:
        student = self.repo.get_by_id(student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")
        return student

    def _validate_institution(self, institution_id: int, current_user: User) -> None:
        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if institution_id != current_user.institution_id:
                raise ForbiddenException(
                    "Solo puedes crear estudiantes para tu propia institución"
                )

        institution = self.institution_repo.get_by_id(institution_id)
        if institution is None:
            raise NotFoundException("Institución no encontrada")
        if institution.status != InstitutionStatus.ACTIVE:
            raise ValidationException("La institución no está activa")

    def _resolve_list_scope(
        self,
        current_user: User,
        institution_id: int | None,
    ) -> tuple[int | None, int | None]:
        if current_user.role == UserRole.SUPER_ADMIN:
            return institution_id, None

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if institution_id and institution_id != current_user.institution_id:
                raise ForbiddenException(
                    "No tienes permisos para ver estudiantes de otra institución"
                )
            return current_user.institution_id, None

        if current_user.role == UserRole.COUNSELOR:
            return current_user.institution_id, current_user.id

        raise ForbiddenException("No tienes permisos para listar estudiantes")

    def _ensure_can_view(self, student: Student, current_user: User) -> None:
        if current_user.role == UserRole.STUDENT:
            if student.user_id == current_user.id:
                return
            raise ForbiddenException("No tienes permisos para ver este estudiante")

        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if student.institution_id == current_user.institution_id:
                return
            raise ForbiddenException("No tienes permisos para ver este estudiante")

        if current_user.role == UserRole.COUNSELOR:
            if (
                student.institution_id == current_user.institution_id
                and self.repo.is_assigned_to_counselor(student.id, current_user.id)
            ):
                return
            raise ForbiddenException("No tienes permisos para ver este estudiante")

        raise ForbiddenException("No tienes permisos para ver este estudiante")

    def _ensure_can_manage(self, student: Student, current_user: User) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.STUDENT:
            if student.user_id == current_user.id:
                return
            raise ForbiddenException("No tienes permisos para gestionar este estudiante")

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if student.institution_id == current_user.institution_id:
                return
            raise ForbiddenException("No tienes permisos para gestionar este estudiante")

        raise ForbiddenException("No tienes permisos para gestionar este estudiante")

    @staticmethod
    def _filter_student_self_update(payload: StudentUpdate) -> StudentUpdate:
        user_data = None
        if payload.user is not None:
            user_data = payload.user.model_dump(exclude_unset=True)
            user_data.pop("email", None)

        filtered = payload.model_dump(exclude_unset=True)
        filtered.pop("identification", None)
        filtered.pop("user", None)

        if user_data:
            from app.schemas.student import StudentUserUpdate

            filtered["user"] = StudentUserUpdate.model_validate(user_data)

        return StudentUpdate.model_validate(filtered)
