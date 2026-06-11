import json
from dataclasses import dataclass

import redis
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.enums import CareerStatus, TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.career import Career, Recommendation
from app.models.riasec import RiasecResult, TestSession
from app.models.user import User
from app.repositories.career_repository import CareerRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.recommendation import (
    CounselorObservationResponse,
    GenerateRecommendationsRequest,
    RecommendationCareerBrief,
    RecommendationListResponse,
    RecommendationResponse,
)
from app.schemas.vector import CareerSearchRequest
from app.services.llm.fallback_provider import ETHICAL_DISCLAIMER
from app.services.llm.llm_service import LLMService
from app.services.test_session_service import TestSessionService
from app.services.vector_service import VectorService


@dataclass(frozen=True)
class _ScoredCareer:
    career: Career
    riasec_score: float
    qdrant_score: float
    match_percentage: float
    source: str


class RecommendationService:
    RIASEC_WEIGHT = 0.60
    QDRANT_WEIGHT = 0.40
    MIN_CAREERS = 5
    OUTPUT_COUNT = 5
    SEARCH_LIMIT = 20
    CACHE_TTL_SECONDS = 86_400

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = RecommendationRepository(db)
        self.test_repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.career_repo = CareerRepository(db)
        self.test_service = TestSessionService(db)
        self.vector_service = VectorService(db)
        self.llm = LLMService()
        self.settings = get_settings()

    async def generate(
        self,
        payload: GenerateRecommendationsRequest,
        current_user: User,
    ) -> RecommendationListResponse:
        if current_user.role != UserRole.STUDENT:
            raise ForbiddenException("Solo los estudiantes pueden generar recomendaciones")

        student = self._get_student_profile(current_user)
        session, riasec_result = self._resolve_completed_session(
            student.id,
            payload.test_session_id,
            current_user,
        )

        cached = self._get_cache(session.id)
        if cached is not None:
            return cached

        existing = self.repo.list_by_test_session(session.id)
        if existing:
            response = self._build_list_response(
                session=session,
                items=existing,
                used_fallback=False,
                from_cache=False,
            )
            self._set_cache(session.id, response)
            return response

        active_careers = self.career_repo.list_all_active()
        if not active_careers:
            raise ValidationException("No hay carreras activas en el catálogo")

        scored_items = self._build_scored_candidates(riasec_result)
        output_count = min(self.OUTPUT_COUNT, len(active_careers))
        min_required = min(self.MIN_CAREERS, len(active_careers))

        if len(scored_items) < min_required:
            raise ValidationException(
                f"No hay suficientes carreras activas para generar recomendaciones "
                f"(disponibles: {len(scored_items)}, requeridas: {min_required})"
            )

        top_items = scored_items[:output_count]
        ai_summary, ai_source = await self._build_ai_summary(riasec_result, top_items)

        persisted: list[Recommendation] = []
        for index, item in enumerate(top_items):
            explanation = self._build_item_explanation(riasec_result, item)
            if index == 0 and ai_summary:
                explanation = ai_summary

            persisted.append(
                Recommendation(
                    student_id=session.student_id,
                    test_session_id=session.id,
                    career_id=item.career.id,
                    match_percentage=item.match_percentage,
                    qdrant_score=item.qdrant_score,
                    ai_explanation=explanation,
                )
            )

        saved = self.repo.create_batch(persisted)
        response = self._build_list_response(
            session=session,
            items=saved,
            scored_lookup={item.career.id: item for item in top_items},
            used_fallback=any(item.source == "mysql_fallback" for item in top_items),
            from_cache=False,
            ai_summary=ai_summary,
            ai_source=ai_source,
        )
        self._set_cache(session.id, response)
        return response

    def list_for_student(
        self,
        student_id: int,
        current_user: User,
    ) -> RecommendationListResponse:
        student = self.student_repo.get_by_id(student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")

        self._ensure_can_view_student_recommendations(student, current_user)

        items = self.repo.list_by_student(student_id)
        if not items:
            latest_result = self.test_repo.get_latest_riasec_result_for_student(
                student_id
            )
            if latest_result is None:
                raise NotFoundException(
                    "No hay un test vocacional completado para este estudiante"
                )
            session = self.test_repo.get_by_id(latest_result.test_session_id)
            if session is None:
                raise NotFoundException("Sesión de test no encontrada")
            return self._build_list_response(
                session=session,
                items=[],
                used_fallback=False,
                from_cache=False,
            )

        test_session_id = items[0].test_session_id
        session_items = [
            item for item in items if item.test_session_id == test_session_id
        ]
        session = self.test_repo.get_by_id(test_session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        return self._build_list_response(
            session=session,
            items=session_items,
            used_fallback=False,
            from_cache=False,
        )

    def add_counselor_observation(
        self,
        recommendation_id: int,
        observation: str,
        current_user: User,
    ) -> CounselorObservationResponse:
        if current_user.role != UserRole.COUNSELOR:
            raise ForbiddenException(
                "Solo los orientadores pueden agregar observaciones profesionales"
            )

        recommendation = self.repo.get_by_id(recommendation_id)
        if recommendation is None:
            raise NotFoundException("Recomendación no encontrada")

        session = self.test_repo.get_by_id(recommendation.test_session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        self.test_service._ensure_can_view_result(session, current_user)

        return self.add_observation_by_test_session(
            recommendation.test_session_id,
            observation,
            current_user,
        )

    def add_observation_by_test_session(
        self,
        test_session_id: int,
        observation: str,
        current_user: User,
    ) -> CounselorObservationResponse:
        if current_user.role != UserRole.COUNSELOR:
            raise ForbiddenException(
                "Solo los orientadores pueden agregar observaciones profesionales"
            )

        session = self.test_repo.get_by_id(test_session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        self.test_service._ensure_can_view_result(session, current_user)

        record = self.repo.create_observation(
            test_session_id=test_session_id,
            counselor_id=current_user.id,
            observation=observation,
        )
        return CounselorObservationResponse.model_validate(record)

    def _build_scored_candidates(self, riasec_result: RiasecResult) -> list[_ScoredCareer]:
        combined_profile = TestSessionService._compute_combined_profile(riasec_result)
        dominant = riasec_result.dominant_profile or ""
        secondary = riasec_result.secondary_profile or ""
        profile_letters = self._profile_letters(dominant, secondary)

        search = self.vector_service.search_careers(
            CareerSearchRequest(
                riasec_profile=combined_profile,
                limit=self.SEARCH_LIMIT,
            )
        )

        vector_scores: dict[int, tuple[float, str]] = {}
        for match in search.items:
            vector_scores[match.career_id] = (match.qdrant_score, match.source)

        candidate_ids = set(vector_scores)
        careers_by_id: dict[int, Career] = {}

        for career_id in candidate_ids:
            career = self.career_repo.get_by_id(career_id)
            if career is not None and career.status == CareerStatus.ACTIVE:
                careers_by_id[career.id] = career

        if len(careers_by_id) < self.MIN_CAREERS:
            supplemental = self.career_repo.list_active_by_riasec_letters(
                f"{dominant}{secondary}"
            )
            for career in supplemental:
                if career.id not in careers_by_id:
                    careers_by_id[career.id] = career

        if len(careers_by_id) < self.MIN_CAREERS:
            for career in self.career_repo.list_all_active():
                if career.id not in careers_by_id:
                    careers_by_id[career.id] = career
                if len(careers_by_id) >= self.MIN_CAREERS:
                    break

        scored: list[_ScoredCareer] = []
        for career in careers_by_id.values():
            riasec_score = self._compute_riasec_score(career, profile_letters)
            if career.id in vector_scores:
                qdrant_score, source = vector_scores[career.id]
            else:
                qdrant_score = riasec_score
                source = "mysql_fallback"

            match_percentage = self._compute_hybrid_match(riasec_score, qdrant_score)
            scored.append(
                _ScoredCareer(
                    career=career,
                    riasec_score=riasec_score,
                    qdrant_score=qdrant_score,
                    match_percentage=match_percentage,
                    source=source,
                )
            )

        scored.sort(
            key=lambda item: (item.match_percentage, item.riasec_score, item.career.id),
            reverse=True,
        )
        return scored

    async def _build_ai_summary(
        self,
        riasec_result: RiasecResult,
        items: list[_ScoredCareer],
    ) -> tuple[str | None, str | None]:
        careers_data = [
            {
                "name": item.career.name,
                "area": item.career.area,
                "riasec_profile": item.career.riasec_profile,
                "degree_type": item.career.degree_type.value,
                "employment_field": item.career.employment_field,
                "description": item.career.description,
                "student_dominant_profile": riasec_result.dominant_profile,
                "student_secondary_profile": riasec_result.secondary_profile,
            }
            for item in items
        ]
        result = await self.llm.explain_careers(careers_data)
        return result.answer, result.source

    def _build_list_response(
        self,
        *,
        session: TestSession,
        items: list[Recommendation],
        scored_lookup: dict[int, _ScoredCareer] | None = None,
        used_fallback: bool,
        from_cache: bool,
        ai_summary: str | None = None,
        ai_source: str | None = None,
    ) -> RecommendationListResponse:
        dominant = ""
        secondary = ""
        result = self.test_repo.get_riasec_result(session.id)
        profile_letters: set[str] = set()
        if result is not None:
            dominant = result.dominant_profile or ""
            secondary = result.secondary_profile or ""
            profile_letters = self._profile_letters(dominant, secondary)

        response_items: list[RecommendationResponse] = []
        for item in items:
            if scored_lookup and item.career_id in scored_lookup:
                scored = scored_lookup[item.career_id]
                riasec_score = scored.riasec_score
                qdrant_score = scored.qdrant_score
                source = scored.source
            elif item.career is not None:
                riasec_score = self._compute_riasec_score(item.career, profile_letters)
                qdrant_score = float(item.qdrant_score) if item.qdrant_score is not None else None
                source = "hybrid"
            else:
                riasec_score = 0.0
                qdrant_score = float(item.qdrant_score) if item.qdrant_score is not None else None
                source = "hybrid"

            career = item.career
            if career is None:
                career = self.career_repo.get_by_id(item.career_id)
            if career is None:
                continue

            response_items.append(
                RecommendationResponse(
                    id=item.id,
                    test_session_id=item.test_session_id,
                    student_id=item.student_id,
                    career_id=item.career_id,
                    career=RecommendationCareerBrief(
                        id=career.id,
                        name=career.name,
                        area=career.area,
                        riasec_profile=career.riasec_profile,
                        degree_type=career.degree_type.value,
                        institution_type=career.institution_type.value,
                        employment_field=career.employment_field,
                    ),
                    match_percentage=float(item.match_percentage),
                    riasec_score=riasec_score,
                    qdrant_score=qdrant_score,
                    ai_explanation=item.ai_explanation,
                    source=source,
                    created_at=item.created_at,
                    updated_at=item.updated_at,
                )
            )

        return RecommendationListResponse(
            student_id=session.student_id,
            test_session_id=session.id,
            items=response_items,
            ai_summary=ai_summary,
            ai_source=ai_source,
            used_fallback=used_fallback,
            from_cache=from_cache,
            ethical_disclaimer=ETHICAL_DISCLAIMER,
        )

    def _resolve_completed_session(
        self,
        student_id: int,
        test_session_id: int | None,
        current_user: User,
    ) -> tuple[TestSession, RiasecResult]:
        if test_session_id is not None:
            session = self.test_repo.get_by_id(test_session_id)
            if session is None:
                raise NotFoundException("Sesión de test no encontrada")
            self.test_service._ensure_session_owner(session, current_user)
            if session.status != TestSessionStatus.COMPLETED:
                raise ValidationException("El test aún no ha sido completado")
            result = self.test_repo.get_riasec_result(test_session_id)
            if result is None:
                raise NotFoundException("Resultado RIASEC no encontrado")
            return session, result

        result = self.test_repo.get_latest_riasec_result_for_student(student_id)
        if result is None:
            raise ValidationException(
                "No tienes un test vocacional completado para generar recomendaciones"
            )
        session = self.test_repo.get_by_id(result.test_session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")
        return session, result

    def _ensure_can_view_student_recommendations(
        self,
        student,
        current_user: User,
    ) -> None:
        if current_user.role == UserRole.STUDENT:
            if student.user_id != current_user.id:
                raise ForbiddenException("No tienes permisos para ver estas recomendaciones")
            return

        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if student.institution_id == current_user.institution_id:
                return
            raise ForbiddenException("No tienes permisos para ver estas recomendaciones")

        if current_user.role == UserRole.COUNSELOR:
            if (
                student.institution_id == current_user.institution_id
                and self.student_repo.is_assigned_to_counselor(
                    student.id,
                    current_user.id,
                )
            ):
                return
            raise ForbiddenException("No tienes permisos para ver estas recomendaciones")

        raise ForbiddenException("No tienes permisos para ver estas recomendaciones")

    def _get_student_profile(self, current_user: User):
        student = self.student_repo.get_by_user_id(current_user.id)
        if student is None:
            raise ValidationException(
                "Tu usuario no tiene perfil de estudiante registrado"
            )
        return student

    @staticmethod
    def _profile_letters(dominant: str, secondary: str) -> set[str]:
        letters: set[str] = set()
        for value in (dominant, secondary):
            for letter in (value or "").upper():
                if letter.isalpha():
                    letters.add(letter)
        return letters

    @classmethod
    def _compute_riasec_score(cls, career: Career, profile_letters: set[str]) -> float:
        return VectorService._mysql_match_score(career, profile_letters, None)

    @classmethod
    def _compute_hybrid_match(cls, riasec_score: float, qdrant_score: float) -> float:
        hybrid = (riasec_score * cls.RIASEC_WEIGHT) + (qdrant_score * cls.QDRANT_WEIGHT)
        return round(min(max(hybrid, 0.0), 100.0), 2)

    @staticmethod
    def _build_item_explanation(
        riasec_result: RiasecResult,
        item: _ScoredCareer,
    ) -> str:
        dominant = riasec_result.dominant_profile or "N/A"
        secondary = riasec_result.secondary_profile or "N/A"
        return (
            f"{item.career.name} es compatible con tu perfil {dominant}/{secondary} "
            f"({item.match_percentage:.0f}% de afinidad). "
            f"{ETHICAL_DISCLAIMER}"
        )

    def _cache_key(self, test_session_id: int) -> str:
        return f"avov:recommendations:session:{test_session_id}"

    def _get_cache(self, test_session_id: int) -> RecommendationListResponse | None:
        try:
            client = redis.from_url(
                self.settings.redis_url,
                socket_connect_timeout=1,
                decode_responses=True,
            )
            raw = client.get(self._cache_key(test_session_id))
            if not raw:
                return None
            payload = json.loads(raw)
            response = RecommendationListResponse.model_validate(payload)
            return response.model_copy(update={"from_cache": True})
        except Exception:
            return None

    def _set_cache(self, test_session_id: int, response: RecommendationListResponse) -> None:
        try:
            client = redis.from_url(
                self.settings.redis_url,
                socket_connect_timeout=1,
                decode_responses=True,
            )
            client.setex(
                self._cache_key(test_session_id),
                self.CACHE_TTL_SECONDS,
                response.model_copy(update={"from_cache": False}).model_dump_json(),
            )
        except Exception:
            return None
