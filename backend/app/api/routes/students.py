from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import Gender, UserRole, UserStatus
from app.core.responses import success_response
from app.models.user import User
from app.schemas.student import StudentCreate, StudentStatusUpdate, StudentUpdate
from app.security.permissions import require_roles
from app.services.student_service import StudentService

router = APIRouter(prefix="/students", tags=["Estudiantes"])


@router.get("", dependencies=[Depends(security)])
def list_students(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, max_length=100),
    institution_id: int | None = None,
    status: UserStatus | None = None,
    grade: str | None = Query(None, max_length=20),
    gender: Gender | None = None,
    current_user: User = Depends(
        require_roles(
            UserRole.SUPER_ADMIN,
            UserRole.INSTITUTION_ADMIN,
            UserRole.COUNSELOR,
        )
    ),
    db: Session = Depends(get_db),
):
    result = StudentService(db).list_students(
        current_user,
        page=page,
        page_size=page_size,
        search=search,
        institution_id=institution_id,
        status=status,
        grade=grade,
        gender=gender,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Estudiantes obtenidos correctamente",
    )


@router.get("/{student_id}", dependencies=[Depends(security)])
def get_student(
    student_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = StudentService(db).get_student(student_id, current_user)
    return success_response(
        data=student.model_dump(mode="json"),
        message="Estudiante obtenido correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_student(
    body: StudentCreate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    student = StudentService(db).create_student(body, current_user)
    return success_response(
        data=student.model_dump(mode="json"),
        message="Estudiante creado correctamente",
    )


@router.put("/{student_id}", dependencies=[Depends(security)])
def update_student(
    student_id: int,
    body: StudentUpdate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    student = StudentService(db).update_student(student_id, body, current_user)
    return success_response(
        data=student.model_dump(mode="json"),
        message="Estudiante actualizado correctamente",
    )


@router.patch("/{student_id}/status", dependencies=[Depends(security)])
def update_student_status(
    student_id: int,
    body: StudentStatusUpdate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    student = StudentService(db).update_student_status(student_id, body, current_user)
    return success_response(
        data=student.model_dump(mode="json"),
        message="Estado del estudiante actualizado correctamente",
    )
