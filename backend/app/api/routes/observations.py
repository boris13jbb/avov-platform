from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.responses import success_response
from app.models.user import User
from app.schemas.observation import ObservationCreate
from app.services.observation_service import ObservationService

router = APIRouter(prefix="/observations", tags=["Observaciones"])


@router.get("", dependencies=[Depends(security)])
def list_observations_by_session(
    test_session_id: int = Query(..., ge=1),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = ObservationService(db).list_by_test_session(
        test_session_id,
        current_user,
        page=page,
        page_size=page_size,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Observaciones obtenidas correctamente",
    )


@router.get("/latest", dependencies=[Depends(security)])
def get_latest_observation(
    test_session_id: int = Query(..., ge=1),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    observation = ObservationService(db).get_latest_for_session(
        test_session_id,
        current_user,
    )
    return success_response(
        data=observation.model_dump(mode="json"),
        message="Última observación obtenida correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_observation(
    body: ObservationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    observation = ObservationService(db).create_observation(body, current_user)
    return success_response(
        data=observation.model_dump(mode="json"),
        message="Observación registrada correctamente",
    )
