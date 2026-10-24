from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.student import CounselorAssignment, Student
from app.models.user import User
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository
from app.schemas.assignment import (
    AssignmentCreate,
    AssignmentPartySummary,
    AssignmentResponse,
    AssignmentStatusUpdate,
    AssignmentStudentSummary,
    PaginatedAssignments,
)


class AssignmentService:
    MAX_PAGE_SIZE = 100
    MANAGE_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN}
    LIST_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN, UserRole.COUNSELOR}

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = AssignmentRepository(db)
        self.student_repo = StudentRepository(db)
        self.user_repo = UserRepository(db)

    def list_assignments(
        self,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
        institution_id: int | None = None,
        counselor_id: int | None = None,
        student_id: int | None = None,
        status: AssignmentStatus | None = None,
    ) -> PaginatedAssignments:
        if current_user.role not in self.LIST_ROLES:
            raise ForbiddenException("No tienes permisos para listar asignaciones")

        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        scoped_institution_id, scoped_counselor_id = self._resolve_list_scope(
            current_user,
            institution_id=institution_id,
            counselor_id=counselor_id,
        )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            institution_id=scoped_institution_id,
            counselor_id=scoped_counselor_id,
            student_id=student_id,
            status=status,
        )
        return PaginatedAssignments.build(
            [self._to_response(item) for item in items],
            total,
            page,
            page_size,
        )

    def get_assignment(
        self,
        assignment_id: int,
        current_user: User,
    ) -> AssignmentResponse:
        assignment = self._get_or_404(assignment_id)
        self._ensure_can_view(assignment, current_user)
        return self._to_response(assignment)

    def create_assignment(
        self,
        payload: AssignmentCreate,
        current_user: User,
    ) -> AssignmentResponse:
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException("No tienes permisos para crear asignaciones")

        student = self._get_student_or_404(payload.student_id)
        counselor = self._get_counselor_or_404(payload.counselor_id)
        self._ensure_pair_compatible(student, counselor)
        self._ensure_can_manage_institution(student.institution_id, current_user)

        existing = self.repo.get_by_pair(
            counselor_id=counselor.id,
            student_id=student.id,
        )
        if existing is not None:
            return self._to_response(
                self._activate_or_reject_existing(existing)
            )

        try:
            created = self.repo.create(
                counselor_id=counselor.id,
                student_id=student.id,
                institution_id=student.institution_id,
                status=AssignmentStatus.ACTIVE,
            )
        except IntegrityError as exc:
            # Colisión concurrente: la unicidad de BD es la exclusión mutua.
            if not AssignmentRepository.is_assignment_unique_violation(exc):
                raise
            raced = self.repo.get_by_pair(
                counselor_id=counselor.id,
                student_id=student.id,
            )
            if raced is None:
                raise ValidationException(
                    "No se pudo registrar la asignación por un conflicto de integridad"
                ) from exc
            return self._to_response(self._activate_or_reject_existing(raced))

        return self._to_response(created)

    def _activate_or_reject_existing(
        self,
        existing: CounselorAssignment,
    ) -> CounselorAssignment:
        if existing.status == AssignmentStatus.ACTIVE:
            raise ValidationException(
                "Ya existe una asignación activa entre este orientador y estudiante"
            )
        existing.status = AssignmentStatus.ACTIVE
        return self.repo.save(existing)

    def update_status(
        self,
        assignment_id: int,
        payload: AssignmentStatusUpdate,
        current_user: User,
    ) -> AssignmentResponse:
        if current_user.role not in self.MANAGE_ROLES:
            raise ForbiddenException(
                "No tienes permisos para cambiar el estado de asignaciones"
            )

        assignment = self._get_or_404(assignment_id)
        self._ensure_can_manage_institution(assignment.institution_id, current_user)

        if assignment.status == payload.status:
            raise ValidationException(
                "La asignación ya se encuentra en el estado solicitado"
            )

        assignment.status = payload.status
        saved = self.repo.save(assignment)
        return self._to_response(saved)

    def _resolve_list_scope(
        self,
        current_user: User,
        *,
        institution_id: int | None,
        counselor_id: int | None,
    ) -> tuple[int | None, int | None]:
        if current_user.role == UserRole.SUPER_ADMIN:
            return institution_id, counselor_id

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if institution_id and institution_id != current_user.institution_id:
                raise ForbiddenException(
                    "No tienes permisos para ver asignaciones de otra institución"
                )
            if counselor_id is not None:
                counselor = self.user_repo.get_by_id(counselor_id)
                if (
                    counselor is None
                    or counselor.institution_id != current_user.institution_id
                ):
                    raise ForbiddenException(
                        "No tienes permisos para filtrar por ese orientador"
                    )
            return current_user.institution_id, counselor_id

        if current_user.role == UserRole.COUNSELOR:
            if counselor_id is not None and counselor_id != current_user.id:
                raise ForbiddenException(
                    "Solo puedes consultar tus propias asignaciones"
                )
            if (
                institution_id is not None
                and institution_id != current_user.institution_id
            ):
                raise ForbiddenException(
                    "No tienes permisos para ver asignaciones de otra institución"
                )
            return current_user.institution_id, current_user.id

        raise ForbiddenException("No tienes permisos para listar asignaciones")

    def _ensure_can_view(
        self,
        assignment: CounselorAssignment,
        current_user: User,
    ) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if assignment.institution_id == current_user.institution_id:
                return
            raise ForbiddenException(
                "No tienes permisos para ver esta asignación"
            )

        if current_user.role == UserRole.COUNSELOR:
            if (
                assignment.counselor_id == current_user.id
                and assignment.institution_id == current_user.institution_id
            ):
                return
            raise ForbiddenException(
                "No tienes permisos para ver esta asignación"
            )

        raise ForbiddenException("No tienes permisos para ver esta asignación")

    def _ensure_can_manage_institution(
        self,
        institution_id: int,
        current_user: User,
    ) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return
        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if current_user.institution_id == institution_id:
                return
            raise ForbiddenException(
                "No tienes permisos para gestionar asignaciones de otra institución"
            )
        raise ForbiddenException(
            "No tienes permisos para gestionar asignaciones"
        )

    def _ensure_pair_compatible(self, student: Student, counselor: User) -> None:
        if counselor.role != UserRole.COUNSELOR:
            raise ValidationException(
                "El usuario indicado no tiene el rol de orientador"
            )
        if counselor.status != UserStatus.ACTIVE:
            raise ValidationException("El orientador no está activo")
        if counselor.institution_id is None:
            raise ValidationException(
                "El orientador no tiene institución asignada"
            )
        if counselor.institution_id != student.institution_id:
            raise ValidationException(
                "El orientador y el estudiante deben pertenecer a la misma institución"
            )
        if student.user is not None and student.user.status != UserStatus.ACTIVE:
            raise ValidationException("El estudiante no está activo")

    def _get_or_404(self, assignment_id: int) -> CounselorAssignment:
        assignment = self.repo.get_by_id(assignment_id)
        if assignment is None:
            raise NotFoundException("Asignación no encontrada")
        return assignment

    def _get_student_or_404(self, student_id: int) -> Student:
        student = self.student_repo.get_by_id(student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")
        return student

    def _get_counselor_or_404(self, counselor_id: int) -> User:
        counselor = self.user_repo.get_by_id(counselor_id)
        if counselor is None:
            raise NotFoundException("Orientador no encontrado")
        return counselor

    def _to_response(self, assignment: CounselorAssignment) -> AssignmentResponse:
        counselor_user = self.user_repo.get_by_id(assignment.counselor_id)
        counselor_summary = None
        if counselor_user is not None:
            counselor_summary = AssignmentPartySummary(
                id=counselor_user.id,
                email=counselor_user.email,
                first_name=counselor_user.first_name,
                last_name=counselor_user.last_name,
            )

        student_summary = None
        student = assignment.student
        if student is not None:
            user_summary = None
            if student.user is not None:
                user_summary = AssignmentPartySummary(
                    id=student.user.id,
                    email=student.user.email,
                    first_name=student.user.first_name,
                    last_name=student.user.last_name,
                )
            student_summary = AssignmentStudentSummary(
                id=student.id,
                identification=student.identification,
                user=user_summary,
            )

        return AssignmentResponse(
            id=assignment.id,
            counselor_id=assignment.counselor_id,
            student_id=assignment.student_id,
            institution_id=assignment.institution_id,
            status=assignment.status,
            assigned_at=assignment.assigned_at,
            created_at=assignment.created_at,
            updated_at=assignment.updated_at,
            counselor=counselor_summary,
            student=student_summary,
        )
