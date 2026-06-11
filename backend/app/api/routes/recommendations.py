from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.recommendation import (
    CounselorObservationRequest,
    GenerateRecommendationsRequest,
)
from app.security.permissions import require_roles
from app.services.recommendation_service import RecommendationService

router = APIRouter(prefix="/recommendations", tags=["Recomendaciones"])


@router.post("/generate", dependencies=[Depends(security)])
async def generate_recommendations(
    body: GenerateRecommendationsRequest,
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    result = await RecommendationService(db).generate(body, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Recomendaciones generadas correctamente",
    )


@router.get("/student/{student_id}", dependencies=[Depends(security)])
def list_student_recommendations(
    student_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = RecommendationService(db).list_for_student(student_id, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Recomendaciones obtenidas correctamente",
    )


@router.post("/{recommendation_id}/observations", dependencies=[Depends(security)])
def add_counselor_observation(
    recommendation_id: int,
    body: CounselorObservationRequest,
    current_user: User = Depends(require_roles(UserRole.COUNSELOR)),
    db: Session = Depends(get_db),
):
    result = RecommendationService(db).add_counselor_observation(
        recommendation_id,
        body.observation,
        current_user,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Observación profesional registrada correctamente",
    )
