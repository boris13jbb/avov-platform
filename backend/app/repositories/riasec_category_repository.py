from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.riasec import RiasecCategory


class RiasecCategoryRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_all(self) -> list[RiasecCategory]:
        stmt = select(RiasecCategory).order_by(RiasecCategory.code.asc())
        return list(self.db.scalars(stmt).all())
