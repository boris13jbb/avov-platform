from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.responses import success_response
from app.models.user import User
from app.services.recommendation_service import RecommendationService

router = APIRouter(prefix="/recommendations", tags=["Recomendaciones"])


@router.get("/sessions/{session_id}", dependencies=[Depends(security)])
def list_session_recommendations(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    data = RecommendationService(db).list_for_session(session_id, current_user)
    return success_response(
        data=data.model_dump(mode="json"),
        message="Recomendaciones obtenidas correctamente"
        if data.total
        else "No hay recomendaciones generadas para esta evaluación",
    )


@router.post("/sessions/{session_id}/generate", dependencies=[Depends(security)])
def generate_session_recommendations(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    data = RecommendationService(db).generate_for_session(session_id, current_user)
    if data.total == 0:
        message = (
            "No se encontraron carreras compatibles con el perfil RIASEC. "
            "El catálogo activo no produjo coincidencias."
        )
    elif data.used_fallback:
        message = (
            "Recomendaciones generadas con búsqueda alternativa en MySQL "
            "(Qdrant no disponible o sin resultados)"
        )
    else:
        message = "Recomendaciones generadas correctamente"
    return success_response(
        data=data.model_dump(mode="json"),
        message=message,
    )
