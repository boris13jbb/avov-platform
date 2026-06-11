from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.security.permissions import require_roles
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/super-admin", dependencies=[Depends(security)])
def get_super_admin_dashboard(
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    result = DashboardService(db).get_super_admin_dashboard(current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Métricas del dashboard obtenidas correctamente",
    )


@router.get("/institution", dependencies=[Depends(security)])
def get_institution_dashboard(
    current_user: User = Depends(require_roles(UserRole.INSTITUTION_ADMIN)),
    db: Session = Depends(get_db),
):
    result = DashboardService(db).get_institution_dashboard(current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Métricas institucionales obtenidas correctamente",
    )


@router.get("/counselor", dependencies=[Depends(security)])
def get_counselor_dashboard(
    current_user: User = Depends(require_roles(UserRole.COUNSELOR)),
    db: Session = Depends(get_db),
):
    result = DashboardService(db).get_counselor_dashboard(current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Métricas del orientador obtenidas correctamente",
    )


@router.get("/student", dependencies=[Depends(security)])
def get_student_dashboard(
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    result = DashboardService(db).get_student_dashboard(current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Estado del estudiante obtenido correctamente",
    )
