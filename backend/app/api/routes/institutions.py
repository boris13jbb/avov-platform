from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import InstitutionStatus, UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.institution import InstitutionCreate, InstitutionUpdate
from app.security.permissions import require_roles
from app.services.institution_service import InstitutionService

router = APIRouter(prefix="/institutions", tags=["Instituciones"])


@router.get("", dependencies=[Depends(security)])
def list_institutions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, max_length=100),
    status: InstitutionStatus | None = None,
    province: str | None = Query(None, max_length=100),
    city: str | None = Query(None, max_length=100),
    _current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    result = InstitutionService(db).list_institutions(
        page=page,
        page_size=page_size,
        search=search,
        status=status,
        province=province,
        city=city,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Instituciones obtenidas correctamente",
    )


@router.get("/{institution_id}", dependencies=[Depends(security)])
def get_institution(
    institution_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    institution = InstitutionService(db).get_institution(institution_id, current_user)
    return success_response(
        data=institution.model_dump(mode="json"),
        message="Institución obtenida correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_institution(
    body: InstitutionCreate,
    _current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    institution = InstitutionService(db).create_institution(body)
    return success_response(
        data=institution.model_dump(mode="json"),
        message="Institución creada correctamente",
    )


@router.put("/{institution_id}", dependencies=[Depends(security)])
def update_institution(
    institution_id: int,
    body: InstitutionUpdate,
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    institution = InstitutionService(db).update_institution(
        institution_id,
        body,
        current_user=current_user,
    )
    return success_response(
        data=institution.model_dump(mode="json"),
        message="Institución actualizada correctamente",
    )


@router.post("/{institution_id}/logo", dependencies=[Depends(security)])
async def upload_institution_logo(
    institution_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(
        require_roles(UserRole.SUPER_ADMIN, UserRole.INSTITUTION_ADMIN)
    ),
    db: Session = Depends(get_db),
):
    content = await file.read()
    institution = InstitutionService(db).upload_logo(
        institution_id,
        content,
        file.content_type or "",
        current_user,
    )
    return success_response(
        data=institution.model_dump(mode="json"),
        message="Logo de institución actualizado correctamente",
    )


@router.delete("/{institution_id}", dependencies=[Depends(security)])
def delete_institution(
    institution_id: int,
    _current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    institution = InstitutionService(db).delete_institution(institution_id)
    return success_response(
        data=institution.model_dump(mode="json"),
        message="Institución desactivada correctamente",
    )
