from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.assistant import (
    AssistantChatRequest,
    ExplainCareersRequest,
    ExplainProfileRequest,
)
from app.security.permissions import require_roles
from app.security.rate_limit import assistant_rate_limiter
from app.services.assistant_service import AssistantService

router = APIRouter(prefix="/assistant", tags=["Asistente Virtual"])


def _ensure_assistant_quota(user: User) -> None:
    assistant_rate_limiter.ensure_not_blocked(str(user.id))
    assistant_rate_limiter.record_attempt(str(user.id))


@router.post("/chat", dependencies=[Depends(security)])
async def assistant_chat(
    body: AssistantChatRequest,
    current_user: User = Depends(require_roles(UserRole.STUDENT)),
    db: Session = Depends(get_db),
):
    _ensure_assistant_quota(current_user)
    result = await AssistantService(db).chat(body, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Respuesta del asistente generada correctamente",
    )


@router.post("/explain-profile", dependencies=[Depends(security)])
async def explain_profile(
    body: ExplainProfileRequest,
    current_user: User = Depends(
        require_roles(UserRole.STUDENT, UserRole.COUNSELOR)
    ),
    db: Session = Depends(get_db),
):
    _ensure_assistant_quota(current_user)
    result = await AssistantService(db).explain_profile(body, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Explicación del perfil RIASEC generada correctamente",
    )


@router.post("/explain-careers", dependencies=[Depends(security)])
async def explain_careers(
    body: ExplainCareersRequest,
    current_user: User = Depends(
        require_roles(UserRole.STUDENT, UserRole.COUNSELOR)
    ),
    db: Session = Depends(get_db),
):
    _ensure_assistant_quota(current_user)
    result = await AssistantService(db).explain_careers(body, current_user)
    return success_response(
        data=result.model_dump(mode="json"),
        message="Explicación de carreras generada correctamente",
    )
