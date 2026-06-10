from __future__ import annotations

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import CareerStatus, DegreeType
from app.models.career import Career
from app.schemas.career import CareerCreate, CareerUpdate


class CareerRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, career_id: int) -> Career | None:
        return self.db.get(Career, career_id)

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        area: str | None = None,
        riasec_profile: str | None = None,
        degree_type: DegreeType | None = None,
        status: CareerStatus | None = None,
    ) -> tuple[list[Career], int]:
        filters = self._build_filters(
            search,
            area,
            riasec_profile,
            degree_type,
            status,
        )
        offset = (page - 1) * page_size

        stmt = (
            select(Career)
            .where(*filters)
            .order_by(Career.name.asc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = select(func.count()).select_from(Career).where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(self, payload: CareerCreate) -> Career:
        career = Career(
            name=payload.name,
            area=payload.area,
            description=payload.description,
            riasec_profile=payload.riasec_profile,
            duration=payload.duration,
            degree_type=payload.degree_type,
            institution_type=payload.institution_type,
            employment_field=payload.employment_field,
            status=payload.status,
        )
        self.db.add(career)
        self.db.commit()
        self.db.refresh(career)
        return career

    def update(self, career: Career, payload: CareerUpdate) -> Career:
        update_data = payload.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(career, field, value)

        self.db.add(career)
        self.db.commit()
        self.db.refresh(career)
        return career

    def list_all_active(self) -> list[Career]:
        stmt = (
            select(Career)
            .where(Career.status == CareerStatus.ACTIVE)
            .order_by(Career.id.asc())
        )
        return list(self.db.scalars(stmt).all())

    def soft_delete(self, career: Career) -> Career:
        career.status = CareerStatus.INACTIVE
        self.db.add(career)
        self.db.commit()
        self.db.refresh(career)
        return career

    def list_active_by_riasec_letters(self, profile: str) -> list[Career]:
        letters = [letter for letter in profile.strip().upper() if letter.isalpha()]
        if not letters:
            return self.list_all_active()

        filters = [Career.status == CareerStatus.ACTIVE]
        filters.append(
            or_(*[func.upper(Career.riasec_profile).like(f"%{letter}%") for letter in letters])
        )
        stmt = select(Career).where(*filters).order_by(Career.name.asc())
        return list(self.db.scalars(stmt).all())

    def delete(self, career: Career) -> None:
        self.db.delete(career)
        self.db.commit()

    @staticmethod
    def _build_filters(
        search: str | None,
        area: str | None,
        riasec_profile: str | None,
        degree_type: DegreeType | None,
        status: CareerStatus | None,
    ) -> list:
        filters = []

        if status is not None:
            filters.append(Career.status == status)

        if degree_type is not None:
            filters.append(Career.degree_type == degree_type)

        if area:
            filters.append(
                func.lower(Career.area).like(f"%{area.strip().lower()}%")
            )

        if riasec_profile:
            normalized = riasec_profile.strip().upper()
            filters.append(
                func.upper(Career.riasec_profile).like(f"%{normalized}%")
            )

        if search:
            term = f"%{search.strip().lower()}%"
            filters.append(
                or_(
                    func.lower(Career.name).like(term),
                    func.lower(Career.area).like(term),
                    func.lower(Career.employment_field).like(term),
                    func.lower(Career.description).like(term),
                )
            )

        return filters
