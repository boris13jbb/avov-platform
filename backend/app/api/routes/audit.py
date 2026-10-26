from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.security.permissions import require_roles
from app.services.audit_service import AuditService

router = APIRouter(prefix="/audit", tags=["Auditoría"])


@router.get("/logs", dependencies=[Depends(security)])
def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    action: str | None = None,
    entity: str | None = None,
    user_id: int | None = Query(None, ge=1),
    from_date: datetime | None = None,
    to_date: datetime | None = None,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    result = AuditService(db).list_logs(
        current_user,
        page=page,
        page_size=page_size,
        action=action,
        entity=entity,
        user_id=user_id,
        from_date=from_date,
        to_date=to_date,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Registros de auditoría obtenidos correctamente",
    )


@router.get("/logs/{log_id}", dependencies=[Depends(security)])
def get_audit_log(
    log_id: int,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    log = AuditService(db).get_log(log_id, current_user)
    return success_response(
        data=log.model_dump(mode="json"),
        message="Registro de auditoría obtenido correctamente",
    )
