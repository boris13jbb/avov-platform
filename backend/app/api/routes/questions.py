from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db, security
from app.core.enums import QuestionStatus, UserRole
from app.core.responses import success_response
from app.models.user import User
from app.schemas.question import QuestionCreate, QuestionStatusUpdate, QuestionUpdate
from app.security.permissions import require_roles
from app.services.question_service import QuestionService

router = APIRouter(prefix="/questions", tags=["Preguntas RIASEC"])


@router.get("", dependencies=[Depends(security)])
def list_questions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, max_length=200),
    category_id: int | None = None,
    category_code: str | None = Query(None, max_length=1),
    status: QuestionStatus | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = QuestionService(db).list_questions(
        current_user,
        page=page,
        page_size=page_size,
        search=search,
        category_id=category_id,
        category_code=category_code,
        status=status,
    )
    return success_response(
        data=result.model_dump(mode="json"),
        message="Preguntas obtenidas correctamente",
    )


@router.get("/{question_id}", dependencies=[Depends(security)])
def get_question(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    question = QuestionService(db).get_question(question_id, current_user)
    return success_response(
        data=question.model_dump(mode="json"),
        message="Pregunta obtenida correctamente",
    )


@router.post("", dependencies=[Depends(security)])
def create_question(
    body: QuestionCreate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    question = QuestionService(db).create_question(body, current_user)
    return success_response(
        data=question.model_dump(mode="json"),
        message="Pregunta creada correctamente",
    )


@router.put("/{question_id}", dependencies=[Depends(security)])
def update_question(
    question_id: int,
    body: QuestionUpdate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    question = QuestionService(db).update_question(question_id, body, current_user)
    return success_response(
        data=question.model_dump(mode="json"),
        message="Pregunta actualizada correctamente",
    )


@router.patch("/{question_id}/status", dependencies=[Depends(security)])
def update_question_status(
    question_id: int,
    body: QuestionStatusUpdate,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    question = QuestionService(db).update_question_status(
        question_id,
        body,
        current_user,
    )
    return success_response(
        data=question.model_dump(mode="json"),
        message="Estado de la pregunta actualizado correctamente",
    )


@router.delete("/{question_id}", dependencies=[Depends(security)])
def delete_question(
    question_id: int,
    current_user: User = Depends(require_roles(UserRole.SUPER_ADMIN)),
    db: Session = Depends(get_db),
):
    question = QuestionService(db).delete_question(question_id, current_user)
    return success_response(
        data=question.model_dump(mode="json"),
        message="Pregunta desactivada correctamente",
    )
