from sqlalchemy.orm import Session

from app.core.enums import CareerStatus
from app.core.exceptions import ValidationException
from app.models.career import Career
from app.repositories.career_repository import CareerRepository
from app.schemas.vector import (
    CareerSearchRequest,
    CareerSearchResponse,
    CareerVectorMatch,
    RebuildCareersResponse,
)
from app.services.embedding_service import build_profile_search_text
from app.services.qdrant_service import QdrantService


class VectorService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.career_repo = CareerRepository(db)
        self.qdrant = QdrantService()

    def rebuild_careers_index(self) -> RebuildCareersResponse:
        careers = self.career_repo.list_all_active()

        if not self.qdrant.is_available():
            raise ValidationException(
                "Qdrant no está disponible. Verifica el servicio antes de reconstruir el índice."
            )

        self.qdrant.recreate_collection()
        indexed = self.qdrant.upsert_careers(careers)

        return RebuildCareersResponse(
            collection=self.qdrant.settings.qdrant_collection_careers,
            indexed=indexed,
            vector_size=self.qdrant.settings.qdrant_vector_size,
        )

    def search_careers(self, payload: CareerSearchRequest) -> CareerSearchResponse:
        if not payload.has_search_criteria():
            raise ValidationException(
                "Debes enviar al menos 'query' o 'riasec_profile' para buscar carreras"
            )

        query_text = build_profile_search_text(
            riasec_profile=payload.riasec_profile,
            query=payload.query,
        )

        if self.qdrant.is_available():
            try:
                items = self.qdrant.search_careers(query_text, limit=payload.limit)
                if items:
                    return CareerSearchResponse(
                        items=[CareerVectorMatch.model_validate(item) for item in items],
                        total=len(items),
                        query_text=query_text,
                        used_fallback=False,
                    )
            except Exception:
                pass

        fallback_items = self._search_mysql_fallback(
            riasec_profile=payload.riasec_profile,
            query=payload.query,
            limit=payload.limit,
        )
        return CareerSearchResponse(
            items=fallback_items,
            total=len(fallback_items),
            query_text=query_text,
            used_fallback=True,
        )

    def _search_mysql_fallback(
        self,
        *,
        riasec_profile: str | None,
        query: str | None,
        limit: int,
    ) -> list[CareerVectorMatch]:
        if riasec_profile:
            careers = self.career_repo.list_active_by_riasec_letters(riasec_profile)
        elif query:
            careers, _ = self.career_repo.list(
                page=1,
                page_size=limit,
                search=query,
                status=CareerStatus.ACTIVE,
            )
        else:
            careers = self.career_repo.list_all_active()[:limit]

        profile_letters = {
            letter
            for letter in (riasec_profile or "").upper()
            if letter.isalpha()
        }

        scored: list[tuple[Career, float]] = []
        for career in careers:
            score = self._mysql_match_score(career, profile_letters, query)
            scored.append((career, score))

        scored.sort(key=lambda item: item[1], reverse=True)
        top_items = scored[:limit]

        return [
            CareerVectorMatch(
                career_id=career.id,
                name=career.name,
                area=career.area,
                riasec_profile=career.riasec_profile,
                degree_type=career.degree_type.value,
                institution_type=career.institution_type.value,
                score=round(score / 100, 4),
                qdrant_score=score,
                source="mysql_fallback",
            )
            for career, score in top_items
        ]

    @staticmethod
    def _mysql_match_score(
        career: Career,
        profile_letters: set[str],
        query: str | None,
    ) -> float:
        if profile_letters:
            career_letters = {
                letter for letter in career.riasec_profile.upper() if letter.isalpha()
            }
            overlap = len(profile_letters & career_letters)
            return round((overlap / len(profile_letters)) * 100, 2)

        if query:
            term = query.lower()
            haystack = " ".join(
                [
                    career.name.lower(),
                    career.area.lower(),
                    career.description.lower(),
                    career.employment_field.lower(),
                    career.riasec_profile.lower(),
                ]
            )
            return 100.0 if term in haystack else 50.0

        return 0.0
