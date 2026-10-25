import re

from sqlalchemy.orm import Session

from app.core.enums import CareerStatus, TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.riasec import RiasecResult, TestSession
from app.models.user import User
from app.repositories.career_repository import CareerRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.assistant import (
    AssistantChatRequest,
    AssistantResponse,
    ExplainCareersRequest,
    ExplainProfileRequest,
)
from app.services.assistant_rate_limit import AssistantRateLimiter
from app.services.llm.llm_service import LLMService
from app.services.llm.prompts import RIASEC_NAMES
from app.services.test_session_service import TestSessionService


class AssistantService:
    EXPLAIN_ROLES = {UserRole.STUDENT, UserRole.COUNSELOR}
    MAX_MESSAGE_LENGTH = 1000

    def __init__(self, db: Session) -> None:
        self.db = db
        self.test_repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.career_repo = CareerRepository(db)
        self.test_service = TestSessionService(db)
        self.llm = LLMService()
        self.rate_limiter = AssistantRateLimiter()

    async def chat(
        self,
        payload: AssistantChatRequest,
        current_user: User,
    ) -> AssistantResponse:
        if current_user.role != UserRole.STUDENT:
            raise ForbiddenException("Solo los estudiantes pueden usar el chat del asistente")

        self.rate_limiter.check_and_increment(current_user.id)
        message = self._sanitize_message(payload.message)
        context = self._build_chat_context(current_user, payload.test_session_id)
        result = await self.llm.answer_student_question(message, context)
        return AssistantResponse(
            answer=result.answer,
            source=result.source,
            ethical_disclaimer=result.ethical_disclaimer,
        )

    async def explain_profile(
        self,
        payload: ExplainProfileRequest,
        current_user: User,
    ) -> AssistantResponse:
        self.rate_limiter.check_and_increment(current_user.id)
        if current_user.role not in self.EXPLAIN_ROLES:
            raise ForbiddenException("No tienes permisos para solicitar esta explicación")

        riasec_result = self._resolve_riasec_result(current_user, payload.test_session_id)
        profile_data = self._profile_data_from_result(riasec_result)
        result = await self.llm.explain_riasec_profile(profile_data)
        return AssistantResponse(
            answer=result.answer,
            source=result.source,
            ethical_disclaimer=result.ethical_disclaimer,
        )

    async def explain_careers(
        self,
        payload: ExplainCareersRequest,
        current_user: User,
    ) -> AssistantResponse:
        self.rate_limiter.check_and_increment(current_user.id)
        if current_user.role not in self.EXPLAIN_ROLES:
            raise ForbiddenException("No tienes permisos para solicitar esta explicación")

        careers_data = self._load_careers(payload.career_ids)
        result = await self.llm.explain_careers(careers_data)
        return AssistantResponse(
            answer=result.answer,
            source=result.source,
            ethical_disclaimer=result.ethical_disclaimer,
        )

    def _resolve_riasec_result(
        self,
        current_user: User,
        test_session_id: int | None,
    ) -> RiasecResult:
        if test_session_id is not None:
            session = self.test_repo.get_by_id(test_session_id)
            if session is None:
                raise NotFoundException("Sesión de test no encontrada")
            self.test_service._ensure_can_view_result(session, current_user)
            if session.status != TestSessionStatus.COMPLETED:
                raise ValidationException("El test aún no ha sido completado")
            result = self.test_repo.get_riasec_result(test_session_id)
            if result is None:
                raise NotFoundException("Resultado RIASEC no encontrado")
            return result

        if current_user.role != UserRole.STUDENT:
            raise ValidationException(
                "Debes indicar test_session_id para explicar el perfil de un estudiante"
            )

        student = self._get_student_profile(current_user)
        result = self.test_repo.get_latest_riasec_result_for_student(student.id)
        if result is None:
            raise ValidationException(
                "No tienes un test vocacional completado para generar la explicación"
            )
        return result

    def _build_chat_context(
        self,
        current_user: User,
        test_session_id: int | None,
    ) -> dict:
        try:
            riasec_result = self._resolve_riasec_result(current_user, test_session_id)
            profile_summary = self._format_profile_summary(riasec_result)
        except (ValidationException, NotFoundException):
            profile_summary = "Sin perfil RIASEC completado aún."

        careers_summary = "Consulta con tu orientador para explorar carreras."
        if test_session_id:
            careers_summary = (
                f"Carreras sugeridas pendientes de recomendación formal "
                f"para la sesión {test_session_id}."
            )

        return {
            "profile_summary": profile_summary,
            "careers_summary": careers_summary,
        }

    def _load_careers(self, career_ids: list[int]) -> list[dict]:
        careers_data: list[dict] = []
        for career_id in career_ids:
            career = self.career_repo.get_by_id(career_id)
            if career is None or career.status != CareerStatus.ACTIVE:
                raise NotFoundException(f"Carrera {career_id} no encontrada o inactiva")
            careers_data.append(
                {
                    "name": career.name,
                    "area": career.area,
                    "riasec_profile": career.riasec_profile,
                    "degree_type": career.degree_type.value,
                    "employment_field": career.employment_field,
                    "description": career.description,
                }
            )
        return careers_data

    @staticmethod
    def _profile_data_from_result(result: RiasecResult) -> dict:
        return {
            "score_r": result.score_r,
            "score_i": result.score_i,
            "score_a": result.score_a,
            "score_s": result.score_s,
            "score_e": result.score_e,
            "score_c": result.score_c,
            "dominant_profile": result.dominant_profile,
            "secondary_profile": result.secondary_profile,
            "combined_profile": TestSessionService._compute_combined_profile(result),
        }

    @staticmethod
    def _format_profile_summary(result: RiasecResult) -> str:
        dominant = result.dominant_profile or "N/A"
        secondary = result.secondary_profile or "N/A"
        dominant_name = RIASEC_NAMES.get(dominant, dominant)
        secondary_name = RIASEC_NAMES.get(secondary, secondary)
        return (
            f"Dominante {dominant} ({dominant_name}), "
            f"secundario {secondary} ({secondary_name})"
        )

    def _get_student_profile(self, current_user: User):
        student = self.student_repo.get_by_user_id(current_user.id)
        if student is None:
            raise ValidationException(
                "Tu usuario no tiene perfil de estudiante registrado"
            )
        return student

    @staticmethod
    def _sanitize_message(message: str) -> str:
        cleaned = re.sub(r"\s+", " ", message.strip())
        if not cleaned:
            raise ValidationException("El mensaje no puede estar vacío")
        if len(cleaned) > AssistantService.MAX_MESSAGE_LENGTH:
            raise ValidationException(
                f"El mensaje no puede superar {AssistantService.MAX_MESSAGE_LENGTH} caracteres"
            )
        return cleaned
