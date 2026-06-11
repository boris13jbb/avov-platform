from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.audit import AuditLog


class AuditRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, log_id: int) -> AuditLog | None:
        return self.db.get(AuditLog, log_id)

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        action: str | None = None,
        entity: str | None = None,
    ) -> tuple[list[AuditLog], int]:
        filters = []
        if action:
            filters.append(AuditLog.action == action.strip())
        if entity:
            filters.append(AuditLog.entity == entity.strip())

        offset = (page - 1) * page_size
        stmt = (
            select(AuditLog)
            .where(*filters)
            .order_by(AuditLog.created_at.desc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = select(func.count()).select_from(AuditLog).where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total
