from __future__ import annotations

from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.enums import CareerStatus, TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.career import Recommendation
from app.models.user import User
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.recommendation import RecommendationItemResponse, RecommendationListResponse
from app.schemas.vector import CareerSearchRequest, CareerVectorMatch
from app.services.test_session_service import TestSessionService
from app.services.vector_service import VectorService

ETHICAL_NOTE = (
    "Este resultado es orientativo y no reemplaza la orientación profesional "
    "de un psicólogo, docente u orientador educativo."
)
DEFAULT_LIMIT = 10
RIASEC_WEIGHT = 0.60
QDRANT_WEIGHT = 0.40


class RecommendationService:
    RESULT_VIEW_ROLES = TestSessionService.RESULT_VIEW_ROLES

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = RecommendationRepository(db)
        self.session_repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.vector = VectorService(db)
        self._session_service = TestSessionService(db)

    def list_for_session(
        self,
        session_id: int,
        current_user: User,
    ) -> RecommendationListResponse:
        session = self._get_completed_session(session_id)
        self._session_service._ensure_can_view_result(session, current_user)
        result = self.session_repo.get_riasec_result(session_id)
        if result is None:
            raise NotFoundException("Resultado RIASEC no encontrado")

        profile = self._profile_code(result)
        items = self.repo.list_for_session(session_id)
        return RecommendationListResponse(
            test_session_id=session_id,
            student_id=session.student_id,
            riasec_profile=profile,
            used_fallback=False,
            items=[self._to_item(row) for row in items],
            total=len(items),
        )

    def generate_for_session(
        self,
        session_id: int,
        current_user: User,
    ) -> RecommendationListResponse:
        session = self._get_completed_session(session_id)
        self._ensure_can_generate(session, current_user)
        result = self.session_repo.get_riasec_result(session_id)
        if result is None:
            raise ValidationException(
                "La sesión no tiene resultado RIASEC. Finaliza el test antes de generar recomendaciones."
            )

        profile = self._profile_code(result)
        if not profile:
            raise ValidationException(
                "No hay perfil RIASEC suficiente para generar recomendaciones"
            )

        search = self.vector.search_careers(
            CareerSearchRequest(riasec_profile=profile, limit=DEFAULT_LIMIT)
        )

        ranked: list[tuple[CareerVectorMatch, float, float]] = []
        for match in search.items:
            # Defensa: no persistir career_id ausente o inactivo (FK MySQL).
            career = self.vector.career_repo.get_by_id(match.career_id)
            if career is None or career.status != CareerStatus.ACTIVE:
                continue
            riasec_score = self._riasec_letter_score(profile, match.riasec_profile)
            qdrant_score = self._normalize_qdrant_score(match)
            hybrid = round(
                (riasec_score * RIASEC_WEIGHT) + (qdrant_score * QDRANT_WEIGHT),
                2,
            )
            hybrid = max(0.0, min(100.0, hybrid))
            ranked.append((match, hybrid, qdrant_score))

        ranked.sort(key=lambda item: (-item[1], item[0].career_id))

        self.repo.delete_for_session(session_id)
        rows: list[Recommendation] = []
        for match, hybrid, qdrant_score in ranked:
            rows.append(
                Recommendation(
                    student_id=session.student_id,
                    test_session_id=session_id,
                    career_id=match.career_id,
                    match_percentage=Decimal(str(hybrid)),
                    qdrant_score=qdrant_score,
                    ai_explanation=self._build_explanation(
                        career_name=match.name,
                        match_percentage=hybrid,
                        profile=profile,
                    ),
                )
            )

        persisted = self.repo.create_many(rows) if rows else []
        return RecommendationListResponse(
            test_session_id=session_id,
            student_id=session.student_id,
            riasec_profile=profile,
            used_fallback=search.used_fallback,
            items=[self._to_item(row, source=self._source_for(row.career_id, search.items)) for row in persisted],
            total=len(persisted),
        )

    def _get_completed_session(self, session_id: int):
        session = self.session_repo.get_by_id(session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")
        if session.status != TestSessionStatus.COMPLETED:
            raise ValidationException(
                "Solo se pueden recomendar carreras para evaluaciones finalizadas"
            )
        return session

    def _ensure_can_generate(self, session, current_user: User) -> None:
        self._session_service._ensure_can_view_result(session, current_user)
        if current_user.role == UserRole.STUDENT:
            student = self.student_repo.get_by_user_id(current_user.id)
            if student is None or session.student_id != student.id:
                raise ForbiddenException(
                    "Solo el estudiante dueño puede generar recomendaciones"
                )
            return
        if current_user.role in (
            UserRole.SUPER_ADMIN,
            UserRole.INSTITUTION_ADMIN,
            UserRole.COUNSELOR,
        ):
            return
        raise ForbiddenException("No tienes permisos para generar recomendaciones")

    @staticmethod
    def _profile_code(result) -> str:
        combined = getattr(result, "combined_profile", None)
        if combined:
            return str(combined).upper()
        parts = [
            letter
            for letter in (
                result.dominant_profile or "",
                result.secondary_profile or "",
            )
            if letter
        ]
        return "".join(parts).upper()

    @staticmethod
    def _riasec_letter_score(student_profile: str, career_profile: str) -> float:
        profile_letters = {c for c in student_profile.upper() if c.isalpha()}
        if not profile_letters:
            return 0.0
        career_letters = {c for c in (career_profile or "").upper() if c.isalpha()}
        overlap = len(profile_letters & career_letters)
        return round((overlap / len(profile_letters)) * 100, 2)

    @staticmethod
    def _normalize_qdrant_score(match: CareerVectorMatch) -> float:
        raw = match.qdrant_score
        if raw is None:
            return 0.0
        if raw <= 1.0:
            return round(max(raw, 0.0) * 100, 2)
        return round(max(0.0, min(100.0, float(raw))), 2)

    @staticmethod
    def _build_explanation(
        *,
        career_name: str,
        match_percentage: float,
        profile: str,
    ) -> str:
        return (
            f"La carrera {career_name} muestra una compatibilidad estimada del "
            f"{match_percentage:.0f}% con tu perfil RIASEC {profile}. {ETHICAL_NOTE}"
        )

    @staticmethod
    def _source_for(career_id: int, matches: list[CareerVectorMatch]) -> str | None:
        for match in matches:
            if match.career_id == career_id:
                return match.source
        return None

    @staticmethod
    def _to_item(
        row: Recommendation,
        *,
        source: str | None = None,
    ) -> RecommendationItemResponse:
        career = row.career
        return RecommendationItemResponse(
            id=row.id,
            career_id=row.career_id,
            career_name=career.name if career else "",
            career_area=career.area if career else "",
            career_riasec_profile=career.riasec_profile if career else "",
            match_percentage=float(row.match_percentage),
            qdrant_score=row.qdrant_score,
            ai_explanation=row.ai_explanation,
            source=source,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )
