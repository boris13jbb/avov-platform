from sqlalchemy.orm import Session

from app.core.enums import CareerStatus, DegreeType
from app.core.exceptions import NotFoundException, ValidationException
from app.models.career import Career
from app.models.user import User
from app.repositories.career_repository import CareerRepository
from app.schemas.career import (
    CareerCreate,
    CareerResponse,
    CareerUpdate,
    PaginatedCareers,
)
from app.services.audit_service import AuditService
from app.services.vector_service import VectorService


class CareerService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = CareerRepository(db)
        self.vector_service = VectorService(db)
        self.audit = AuditService(db)

    def list_careers(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        area: str | None = None,
        riasec_profile: str | None = None,
        degree_type: DegreeType | None = None,
        status: CareerStatus | None = None,
    ) -> PaginatedCareers:
        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            search=search,
            area=area,
            riasec_profile=riasec_profile,
            degree_type=degree_type,
            status=status,
        )
        return PaginatedCareers.build(items, total, page, page_size)

    def get_career(self, career_id: int) -> CareerResponse:
        career = self._get_or_404(career_id)
        return CareerResponse.model_validate(career)

    def create_career(
        self,
        payload: CareerCreate,
        current_user: User,
    ) -> tuple[CareerResponse, bool]:
        career = self.repo.create(payload)
        synced = self.sync_career_vector(career)
        self.audit.log(
            action="CAREER_CREATED",
            entity="careers",
            user_id=current_user.id,
            entity_id=career.id,
            details={"name": career.name, "vector_synced": synced},
        )
        return CareerResponse.model_validate(career), synced

    def update_career(
        self,
        career_id: int,
        payload: CareerUpdate,
        current_user: User,
    ) -> tuple[CareerResponse, bool]:
        career = self._get_or_404(career_id)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        updated = self.repo.update(career, payload)
        synced = self.sync_career_vector(updated)
        self.audit.log(
            action="CAREER_UPDATED",
            entity="careers",
            user_id=current_user.id,
            entity_id=updated.id,
            details={"name": updated.name, "vector_synced": synced},
        )
        return CareerResponse.model_validate(updated), synced

    def delete_career(
        self,
        career_id: int,
        current_user: User,
    ) -> tuple[CareerResponse, bool]:
        career = self._get_or_404(career_id)

        if career.status == CareerStatus.INACTIVE:
            raise ValidationException("La carrera ya está inactiva")

        deleted = self.repo.soft_delete(career)
        synced = self.sync_career_vector(deleted)
        self.audit.log(
            action="CAREER_DEACTIVATED",
            entity="careers",
            user_id=current_user.id,
            entity_id=deleted.id,
            details={"name": deleted.name, "vector_synced": synced},
        )
        return CareerResponse.model_validate(deleted), synced

    def sync_career_vector(self, career: Career) -> bool:
        return self.vector_service.sync_career(career)

    @staticmethod
    def build_mutation_message(base_message: str, vector_synced: bool) -> str:
        if vector_synced:
            return f"{base_message}. Índice vectorial actualizado"
        return (
            f"{base_message}. No se pudo sincronizar Qdrant; "
            "puedes reconstruir el índice manualmente"
        )

    def _get_or_404(self, career_id: int):
        career = self.repo.get_by_id(career_id)
        if career is None:
            raise NotFoundException("Carrera no encontrada")
        return career
