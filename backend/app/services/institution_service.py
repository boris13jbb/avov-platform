from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.institution import Institution
from app.models.user import User
from app.repositories.institution_repository import InstitutionRepository
from app.schemas.institution import (
    InstitutionCreate,
    InstitutionResponse,
    InstitutionUpdate,
    PaginatedInstitutions,
)


class InstitutionService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = InstitutionRepository(db)

    def list_institutions(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        status: InstitutionStatus | None = None,
        province: str | None = None,
        city: str | None = None,
    ) -> PaginatedInstitutions:
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
            status=status,
            province=province,
            city=city,
        )
        return PaginatedInstitutions.build(items, total, page, page_size)

    def get_institution(self, institution_id: int, current_user: User) -> InstitutionResponse:
        institution = self._get_or_404(institution_id)
        self._ensure_can_view(institution, current_user)
        return InstitutionResponse.model_validate(institution)

    def create_institution(self, payload: InstitutionCreate) -> InstitutionResponse:
        if self.repo.get_by_code(payload.code):
            raise ValidationException("El código de institución ya está registrado")

        institution = self.repo.create(payload)
        return InstitutionResponse.model_validate(institution)

    def update_institution(
        self,
        institution_id: int,
        payload: InstitutionUpdate,
    ) -> InstitutionResponse:
        institution = self._get_or_404(institution_id)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        if payload.code and payload.code != institution.code:
            existing = self.repo.get_by_code(payload.code)
            if existing and existing.id != institution.id:
                raise ValidationException("El código de institución ya está registrado")

        updated = self.repo.update(institution, payload)
        return InstitutionResponse.model_validate(updated)

    def delete_institution(self, institution_id: int) -> InstitutionResponse:
        institution = self._get_or_404(institution_id)

        if institution.status == InstitutionStatus.INACTIVE:
            raise ValidationException("La institución ya está inactiva")

        deleted = self.repo.soft_delete(institution)
        return InstitutionResponse.model_validate(deleted)

    def _get_or_404(self, institution_id: int) -> Institution:
        institution = self.repo.get_by_id(institution_id)
        if institution is None:
            raise NotFoundException("Institución no encontrada")
        return institution

    @staticmethod
    def _ensure_can_view(institution: Institution, current_user: User) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if current_user.institution_id == institution.id:
                return
            raise ForbiddenException("No tienes permisos para ver esta institución")

        raise ForbiddenException("No tienes permisos para ver esta institución")
