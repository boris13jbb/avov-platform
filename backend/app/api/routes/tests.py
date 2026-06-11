from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.recommendation import CounselorObservationRequest
from app.schemas.test_session import TestAnswerCreate
from app.services.recommendation_service import RecommendationService
from app.security.permissions import require_roles
from app.services.test_session_service import TestSessionService

router = APIRouter(prefix="/tests", tags=["Test Vocacional"])


@router.post("/start", dependencies=[Depends(security)])
def start_test(
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    session = TestSessionService(db).start_test(current_user)
    return success_response(
        data=session.model_dump(mode="json"),
        message="Sesión de test iniciada correctamente",
    )


@router.get("/{session_id}/questions", dependencies=[Depends(security)])
def get_session_questions(
    session_id: int,
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    result = TestSessionService(db).get_session_questions(session_id, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Preguntas del test obtenidas correctamente",
    )


@router.post("/{session_id}/answers", dependencies=[Depends(security)])
def save_answer(
    session_id: int,
    body: TestAnswerCreate,
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    answer = TestSessionService(db).save_answer(session_id, body, current_user)
    return success_response(
        data=answer.model_dump(mode="json"),
        message="Respuesta guardada correctamente",
    )


@router.post("/{session_id}/finish", dependencies=[Depends(security)])
def finish_test(
    session_id: int,
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    result = TestSessionService(db).finish_test(session_id, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Test finalizado y perfil RIASEC calculado correctamente",
    )


@router.get("/{session_id}/result", dependencies=[Depends(security)])
def get_test_result(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = TestSessionService(db).get_result(session_id, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Resultado RIASEC obtenido correctamente",
    )


@router.post("/{session_id}/observations", dependencies=[Depends(security)])
def add_test_observation(
    session_id: int,
    body: CounselorObservationRequest,
    current_user: User = Depends(require_roles(UserRole.COUNSELOR)),
    db: Session = Depends(get_db),
):
    result = RecommendationService(db).add_observation_by_test_session(
        session_id,
        body.observation,
        current_user,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Observación profesional registrada correctamente",
    )
