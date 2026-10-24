from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db, security
from app.core.enums import AssignmentStatus, UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.assignment import AssignmentCreate, AssignmentStatusUpdate
from app.security.permissions import require_roles
from app.services.assignment_service import AssignmentService

router = APIRouter(prefix="/assignments", tags=["Asignaciones"])


@router.get("", dependencies=[Depends(security)])
def list_assignments(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    institution_id: int | None = None,
    counselor_id: int | None = None,
    student_id: int | None = None,
    status: AssignmentStatus | None = None,
    current_user: User = Depends(
        require_roles(
            UserRole.SUPER_ADMIN,
            UserRole.INSTITUTION_ADMIN,
            UserRole.COUNSELOR,
        )
    ),
    db: Session = Depends(get_db),
):
    result = AssignmentService(db).list_assignments(
        current_user,
        page=page,
        page_size=page_size,
        institution_id=institution_id,
        counselor_id=counselor_id,
        student_id=student_id,
        status=status,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Asignaciones obtenidas correctamente",
    )


@router.get("/{assignment_id}", dependencies=[Depends(security)])
def get_assignment(
    assignment_id: int,
    current_user: User = Depends(
        require_roles(
            UserRole.SUPER_ADMIN,
            UserRole.INSTITUTION_ADMIN,
            UserRole.COUNSELOR,
        )
    ),
    db: Session = Depends(get_db),
):
    assignment = AssignmentService(db).get_assignment(assignment_id, current_user)
    return success_response(
        data=assignment.model_dump(mode="json"),
        message="Asignación obtenida correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_assignment(
    body: AssignmentCreate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    assignment = AssignmentService(db).create_assignment(body, current_user)
    return success_response(
        data=assignment.model_dump(mode="json"),
        message="Asignación registrada correctamente",
    )


@router.patch("/{assignment_id}/status", dependencies=[Depends(security)])
def update_assignment_status(
    assignment_id: int,
    body: AssignmentStatusUpdate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    assignment = AssignmentService(db).update_status(
        assignment_id,
        body,
        current_user,
    )
    message = (
        "Asignación desactivada correctamente"
        if body.status.value == "INACTIVE"
        else "Asignación reactivada correctamente"
    )
    return success_response(
        data=assignment.model_dump(mode="json"),
        message=message,
    )
