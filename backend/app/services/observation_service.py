from sqlalchemy.orm import Session

from app.core.enums import UserRole, UserStatus
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.counselor import CounselorObservation
from app.models.user import User
from app.repositories.observation_repository import ObservationRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.observation import (
    ObservationCounselorSummary,
    ObservationCreate,
    ObservationResponse,
    PaginatedObservations,
)
from app.services.test_session_service import TestSessionService


class ObservationService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ObservationRepository(db)
        self.session_repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.user_repo = UserRepository(db)
        self.session_service = TestSessionService(db)

    def list_by_test_session(
        self,
        test_session_id: int,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedObservations:
        session = self._get_session_or_404(test_session_id)
        self.session_service._ensure_can_view_result(session, current_user)
        self._validate_pagination(page, page_size)

        items, total = self.repo.list_by_test_session(
            test_session_id,
            page=page,
            page_size=page_size,
        )
        return PaginatedObservations.build(
            [self._to_response(item) for item in items],
            total,
            page,
            page_size,
        )

    def get_latest_for_session(
        self,
        test_session_id: int,
        current_user: User,
    ) -> ObservationResponse:
        session = self._get_session_or_404(test_session_id)
        self.session_service._ensure_can_view_result(session, current_user)

        latest = self.repo.get_latest_for_session(test_session_id)
        if latest is None:
            raise NotFoundException(
                "No hay observaciones registradas para esta sesión de test"
            )
        return self._to_response(latest)

    def create_observation(
        self,
        payload: ObservationCreate,
        current_user: User,
    ) -> ObservationResponse:
        if current_user.role != UserRole.COUNSELOR:
            raise ForbiddenException(
                "Solo los orientadores pueden registrar observaciones"
            )
        if current_user.status != UserStatus.ACTIVE:
            raise ForbiddenException("Tu cuenta no está activa")

        session = self._get_session_or_404(payload.test_session_id)
        student = self.student_repo.get_by_id(session.student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")

        if not self.student_repo.is_assigned_to_counselor(
            student.id,
            current_user.id,
        ):
            raise ForbiddenException(
                "No tienes una asignación activa con el estudiante de esta sesión"
            )

        if student.institution_id != current_user.institution_id:
            raise ForbiddenException(
                "No tienes permisos para registrar observaciones en esta sesión"
            )

        observation_text = payload.observation.strip()
        if not observation_text:
            raise ValidationException("La observación no puede estar vacía")

        created = self.repo.create(
            test_session_id=payload.test_session_id,
            counselor_id=current_user.id,
            observation=observation_text,
        )
        return self._to_response(created)

    def _get_session_or_404(self, session_id: int):
        session = self.session_repo.get_by_id(session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")
        return session

    @staticmethod
    def _validate_pagination(page: int, page_size: int) -> None:
        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > ObservationService.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {ObservationService.MAX_PAGE_SIZE}"
            )

    def _to_response(self, row: CounselorObservation) -> ObservationResponse:
        counselor_summary = None
        counselor = self.user_repo.get_by_id(row.counselor_id)
        if counselor is not None:
            counselor_summary = ObservationCounselorSummary(
                id=counselor.id,
                email=counselor.email,
                first_name=counselor.first_name,
                last_name=counselor.last_name,
            )
        return ObservationResponse(
            id=row.id,
            test_session_id=row.test_session_id,
            counselor_id=row.counselor_id,
            observation=row.observation,
            created_at=row.created_at,
            updated_at=row.updated_at,
            counselor=counselor_summary,
        )
