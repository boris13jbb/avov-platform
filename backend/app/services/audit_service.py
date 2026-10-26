from datetime import datetime

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.enums import UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.audit import AuditLog
from app.models.user import User
from app.repositories.audit_repository import AuditRepository
from app.repositories.user_repository import UserRepository
from app.schemas.audit import AuditLogResponse, AuditLogUserSummary, PaginatedAuditLogs
from app.security.audit_details import sanitize_audit_details


class AuditService:
    MAX_PAGE_SIZE = 100
    LIST_ROLES = {UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN}

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = AuditRepository(db)
        self.user_repo = UserRepository(db)
        self.settings = get_settings()

    def list_logs(
        self,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
        action: str | None = None,
        entity: str | None = None,
        user_id: int | None = None,
        from_date: datetime | None = None,
        to_date: datetime | None = None,
    ) -> PaginatedAuditLogs:
        if current_user.role not in self.LIST_ROLES:
            raise ForbiddenException("No tienes permisos para consultar auditoría")

        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )
        if from_date is not None and to_date is not None and from_date > to_date:
            raise ValidationException(
                "La fecha inicial no puede ser posterior a la fecha final"
            )

        institution_scope = None
        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if current_user.institution_id is None:
                raise ForbiddenException(
                    "Tu usuario no tiene institución asignada"
                )
            institution_scope = current_user.institution_id
            if user_id is not None:
                target = self.user_repo.get_by_id(user_id)
                if target is None or target.institution_id != institution_scope:
                    raise ForbiddenException(
                        "No tienes permisos para filtrar por ese usuario"
                    )

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            action=action,
            entity=entity,
            user_id=user_id,
            from_date=from_date,
            to_date=to_date,
            institution_id=institution_scope,
            retention_days=self.settings.audit_retention_days,
        )
        return PaginatedAuditLogs.build(
            [self._to_response(item) for item in items],
            total,
            page,
            page_size,
        )

    def get_log(self, log_id: int, current_user: User) -> AuditLogResponse:
        if current_user.role not in self.LIST_ROLES:
            raise ForbiddenException("No tienes permisos para consultar auditoría")

        log = self.repo.get_by_id(log_id)
        if log is None:
            raise NotFoundException("Registro de auditoría no encontrado")

        self._ensure_can_view_log(log, current_user)
        return self._to_response(log)

    def _ensure_can_view_log(self, log: AuditLog, current_user: User) -> None:
        if current_user.role == UserRole.SUPER_ADMIN:
            return

        if log.user_id is None:
            raise ForbiddenException(
                "No tienes permisos para ver este registro de auditoría"
            )

        actor = self.user_repo.get_by_id(log.user_id)
        if actor is None or actor.institution_id != current_user.institution_id:
            raise ForbiddenException(
                "No tienes permisos para ver este registro de auditoría"
            )

    def _to_response(self, log: AuditLog) -> AuditLogResponse:
        user_summary = None
        if log.user_id is not None:
            user = self.user_repo.get_by_id(log.user_id)
            if user is not None:
                user_summary = AuditLogUserSummary(
                    id=user.id,
                    email=user.email,
                    first_name=user.first_name,
                    last_name=user.last_name,
                    institution_id=user.institution_id,
                )
        return AuditLogResponse(
            id=log.id,
            user_id=log.user_id,
            action=log.action,
            entity=log.entity,
            entity_id=log.entity_id,
            ip_address=log.ip_address,
            user_agent=log.user_agent,
            details=sanitize_audit_details(log.details),
            created_at=log.created_at,
            user=user_summary,
        )
