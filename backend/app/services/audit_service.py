from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundException, ValidationException
from app.models.audit import AuditLog
from app.repositories.audit_repository import AuditRepository
from app.schemas.audit import AuditLogResponse, PaginatedAuditLogs


class AuditService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = AuditRepository(db)

    def list_logs(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        action: str | None = None,
        entity: str | None = None,
    ) -> PaginatedAuditLogs:
        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            action=action,
            entity=entity,
        )
        return PaginatedAuditLogs.build(items, total, page, page_size)

    def get_log(self, log_id: int) -> AuditLogResponse:
        record = self.repo.get_by_id(log_id)
        if record is None:
            raise NotFoundException("Registro de auditoría no encontrado")
        return AuditLogResponse.model_validate(record)

    def log(
        self,
        *,
        action: str,
        entity: str,
        user_id: int | None = None,
        entity_id: int | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
        details: dict | None = None,
    ) -> AuditLog:
        record = AuditLog(
            user_id=user_id,
            action=action,
            entity=entity,
            entity_id=entity_id,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record
