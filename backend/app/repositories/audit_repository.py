from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.audit import AuditLog
from app.models.user import User


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
        user_id: int | None = None,
        from_date: datetime | None = None,
        to_date: datetime | None = None,
        institution_id: int | None = None,
        retention_days: int | None = None,
    ) -> tuple[list[AuditLog], int]:
        filters: list = []

        if retention_days is not None and retention_days > 0:
            cutoff = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(
                days=retention_days
            )
            filters.append(AuditLog.created_at >= cutoff)

        if action is not None:
            filters.append(AuditLog.action == action.strip())
        if entity is not None:
            filters.append(AuditLog.entity == entity.strip())
        if user_id is not None:
            filters.append(AuditLog.user_id == user_id)
        if from_date is not None:
            filters.append(AuditLog.created_at >= from_date)
        if to_date is not None:
            filters.append(AuditLog.created_at <= to_date)

        offset = (page - 1) * page_size
        base = select(AuditLog)
        count_base = select(func.count()).select_from(AuditLog)

        if institution_id is not None:
            base = base.join(User, AuditLog.user_id == User.id).where(
                User.institution_id == institution_id
            )
            count_base = (
                select(func.count())
                .select_from(AuditLog)
                .join(User, AuditLog.user_id == User.id)
                .where(User.institution_id == institution_id)
            )

        stmt = (
            base.where(*filters)
            .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = count_base.where(*filters)
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(
        self,
        *,
        user_id: int | None,
        action: str,
        entity: str,
        entity_id: int | None,
        details: dict | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> AuditLog:
        row = AuditLog(
            user_id=user_id,
            action=action,
            entity=entity,
            entity_id=entity_id,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row
