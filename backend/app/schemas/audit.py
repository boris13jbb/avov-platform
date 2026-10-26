from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict


class AuditLogUserSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    first_name: str | None = None
    last_name: str | None = None
    institution_id: int | None = None


class AuditLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int | None
    action: str
    entity: str
    entity_id: int | None
    ip_address: str | None
    user_agent: str | None
    details: dict | None
    created_at: datetime
    user: AuditLogUserSummary | None = None


class PaginatedAuditLogs(BaseModel):
    items: list[AuditLogResponse]
    total: int
    page: int
    page_size: int
    pages: int

    @classmethod
    def build(
        cls,
        items: list[AuditLogResponse],
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedAuditLogs":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
