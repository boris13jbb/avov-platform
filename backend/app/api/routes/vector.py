from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.vector import CareerSearchRequest
from app.security.permissions import require_roles
from app.services.vector_service import VectorService

router = APIRouter(prefix="/vector", tags=["Vector / Qdrant"])


@router.post("/rebuild-careers", dependencies=[Depends(security)])
def rebuild_careers_index(
    _current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    result = VectorService(db).rebuild_careers_index()
    return success_response(
        data=result.model_dump(mode="json"),
        message="Índice vectorial de carreras reconstruido correctamente",
    )


@router.post("/search-careers", dependencies=[Depends(security)])
def search_careers(
    body: CareerSearchRequest,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = VectorService(db).search_careers(body)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Búsqueda semántica de carreras realizada correctamente",
    )
