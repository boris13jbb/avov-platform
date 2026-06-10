from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus
from app.models.institution import Institution
from app.schemas.institution import InstitutionCreate, InstitutionUpdate


class InstitutionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, institution_id: int) -> Institution | None:
        return self.db.get(Institution, institution_id)

    def get_by_code(self, code: str) -> Institution | None:
        normalized_code = code.strip().upper()
        stmt = select(Institution).where(Institution.code == normalized_code)
        return self.db.scalar(stmt)

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        status: InstitutionStatus | None = None,
        province: str | None = None,
        city: str | None = None,
    ) -> tuple[list[Institution], int]:
        filters = self._build_filters(search, status, province, city)
        offset = (page - 1) * page_size

        stmt = (
            select(Institution)
            .where(*filters)
            .order_by(Institution.name.asc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = select(func.count()).select_from(Institution).where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(self, payload: InstitutionCreate) -> Institution:
        institution = Institution(
            name=payload.name,
            code=payload.code,
            province=payload.province,
            city=payload.city,
            address=payload.address,
            phone=payload.phone,
            email=str(payload.email) if payload.email else None,
            logo_url=payload.logo_url,
            status=payload.status,
        )
        self.db.add(institution)
        self.db.commit()
        self.db.refresh(institution)
        return institution

    def update(
        self,
        institution: Institution,
        payload: InstitutionUpdate,
    ) -> Institution:
        update_data = payload.model_dump(exclude_unset=True)
        if "email" in update_data and update_data["email"] is not None:
            update_data["email"] = str(update_data["email"])

        for field, value in update_data.items():
            setattr(institution, field, value)

        self.db.add(institution)
        self.db.commit()
        self.db.refresh(institution)
        return institution

    def soft_delete(self, institution: Institution) -> Institution:
        institution.status = InstitutionStatus.INACTIVE
        self.db.add(institution)
        self.db.commit()
        self.db.refresh(institution)
        return institution

    def delete(self, institution: Institution) -> None:
        self.db.delete(institution)
        self.db.commit()

    @staticmethod
    def _build_filters(
        search: str | None,
        status: InstitutionStatus | None,
        province: str | None,
        city: str | None,
    ) -> list:
        filters = []

        if status is not None:
            filters.append(Institution.status == status)

        if province:
            filters.append(
                func.lower(Institution.province).like(f"%{province.strip().lower()}%")
            )

        if city:
            filters.append(
                func.lower(Institution.city).like(f"%{city.strip().lower()}%")
            )

        if search:
            term = f"%{search.strip().lower()}%"
            filters.append(
                or_(
                    func.lower(Institution.name).like(term),
                    func.lower(Institution.code).like(term),
                    func.lower(Institution.province).like(term),
                    func.lower(Institution.city).like(term),
                )
            )

        return filters
