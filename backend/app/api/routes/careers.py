from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import CareerStatus, DegreeType, UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.career import CareerCreate, CareerUpdate
from app.security.permissions import require_roles
from app.services.career_service import CareerService

router = APIRouter(prefix="/careers", tags=["Carreras"])


@router.get("", dependencies=[Depends(security)])
def list_careers(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, max_length=100),
    area: str | None = Query(None, max_length=100),
    riasec_profile: str | None = Query(None, max_length=10),
    degree_type: DegreeType | None = None,
    status: CareerStatus | None = None,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = CareerService(db).list_careers(
        page=page,
        page_size=page_size,
        search=search,
        area=area,
        riasec_profile=riasec_profile,
        degree_type=degree_type,
        status=status,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Carreras obtenidas correctamente",
    )


@router.get("/{career_id}", dependencies=[Depends(security)])
def get_career(
    career_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    career = CareerService(db).get_career(career_id)
    return success_response(
        data=career.model_dump(mode="json"),
        message="Carrera obtenida correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_career(
    body: CareerCreate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    service = CareerService(db)
    career, vector_synced = service.create_career(body, current_user)
    payload = career.model_dump(mode="json")
    payload["vector_synced"] = vector_synced
    return success_response(
        data=payload,
        message=service.build_mutation_message(
            "Carrera creada correctamente",
            vector_synced,
        ),
    )


@router.put("/{career_id}", dependencies=[Depends(security)])
def update_career(
    career_id: int,
    body: CareerUpdate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    service = CareerService(db)
    career, vector_synced = service.update_career(career_id, body, current_user)
    payload = career.model_dump(mode="json")
    payload["vector_synced"] = vector_synced
    return success_response(
        data=payload,
        message=service.build_mutation_message(
            "Carrera actualizada correctamente",
            vector_synced,
        ),
    )


@router.delete("/{career_id}", dependencies=[Depends(security)])
def delete_career(
    career_id: int,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    service = CareerService(db)
    career, vector_synced = service.delete_career(career_id, current_user)
    payload = career.model_dump(mode="json")
    payload["vector_synced"] = vector_synced
    return success_response(
        data=payload,
        message=service.build_mutation_message(
            "Carrera desactivada correctamente",
            vector_synced,
        ),
    )
