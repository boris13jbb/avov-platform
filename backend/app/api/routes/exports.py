from fastapi import APIRouter, Depends
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.api.deps import get_db, security
from app.core.enums import UserRole
from app.models.user import User
from app.security.permissions import require_roles
from app.services.export_service import ExportService

router = APIRouter(prefix="/exports", tags=["Exportaciones"])


@router.get("/students", dependencies=[Depends(security)])
def export_students_csv(
    current_user: User = Depends(require_roles(UserRole.INSTITUTION_ADMIN)),
    db: Session = Depends(get_db),
):
    result = ExportService(db).export_students_csv(current_user)
    return Response(
        content=result.content,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{result.filename}"'},
    )


@router.get("/test-results", dependencies=[Depends(security)])
def export_test_results_csv(
    current_user: User = Depends(
        require_roles(UserRole.INSTITUTION_ADMIN, UserRole.COUNSELOR)
    ),
    db: Session = Depends(get_db),
):
    result = ExportService(db).export_test_results_csv(current_user)
    return Response(
        content=result.content,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{result.filename}"'},
    )
