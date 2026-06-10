from sqlalchemy.orm import Session

from app.core.enums import CareerStatus, DegreeType
from app.core.exceptions import NotFoundException, ValidationException
from app.repositories.career_repository import CareerRepository
from app.schemas.career import (
    CareerCreate,
    CareerResponse,
    CareerUpdate,
    PaginatedCareers,
)


class CareerService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = CareerRepository(db)

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

    def create_career(self, payload: CareerCreate) -> CareerResponse:
        career = self.repo.create(payload)
        return CareerResponse.model_validate(career)

    def update_career(self, career_id: int, payload: CareerUpdate) -> CareerResponse:
        career = self._get_or_404(career_id)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        updated = self.repo.update(career, payload)
        return CareerResponse.model_validate(updated)

    def delete_career(self, career_id: int) -> CareerResponse:
        career = self._get_or_404(career_id)

        if career.status == CareerStatus.INACTIVE:
            raise ValidationException("La carrera ya está inactiva")

        deleted = self.repo.soft_delete(career)
        return CareerResponse.model_validate(deleted)

    def _get_or_404(self, career_id: int):
        career = self.repo.get_by_id(career_id)
        if career is None:
            raise NotFoundException("Carrera no encontrada")
        return career
