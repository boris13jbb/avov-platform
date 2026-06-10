from sqlalchemy.orm import Session

from app.core.enums import QuestionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.user import User
from app.repositories.question_repository import QuestionRepository
from app.schemas.question import (
    PaginatedQuestions,
    QuestionCreate,
    QuestionResponse,
    QuestionStatusUpdate,
    QuestionUpdate,
)


class QuestionService:
    MAX_PAGE_SIZE = 100

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = QuestionRepository(db)

    def list_questions(
        self,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        category_id: int | None = None,
        category_code: str | None = None,
        status: QuestionStatus | None = None,
    ) -> PaginatedQuestions:
        if page < 1:
            raise ValidationException("La página debe ser mayor o igual a 1")
        if page_size < 1 or page_size > self.MAX_PAGE_SIZE:
            raise ValidationException(
                f"El tamaño de página debe estar entre 1 y {self.MAX_PAGE_SIZE}"
            )

        effective_status = self._resolve_status_filter(current_user, status)

        items, total = self.repo.list(
            page=page,
            page_size=page_size,
            search=search,
            category_id=category_id,
            category_code=category_code,
            status=effective_status,
        )
        return PaginatedQuestions.build(items, total, page, page_size)

    def get_question(self, question_id: int, current_user: User) -> QuestionResponse:
        question = self._get_or_404(question_id)
        if question.status != QuestionStatus.ACTIVE:
            self._ensure_super_admin(current_user)
        return QuestionResponse.model_validate(question)

    def create_question(self, payload: QuestionCreate) -> QuestionResponse:
        self._validate_category(payload.category_id)
        self._validate_unique_order(payload.category_id, payload.order_number)

        question = self.repo.create(payload)
        return QuestionResponse.model_validate(question)

    def update_question(self, question_id: int, payload: QuestionUpdate) -> QuestionResponse:
        question = self._get_or_404(question_id)

        if not payload.model_dump(exclude_unset=True):
            raise ValidationException("Debe enviar al menos un campo para actualizar")

        target_category_id = payload.category_id or question.category_id
        target_order_number = payload.order_number or question.order_number

        if payload.category_id:
            self._validate_category(payload.category_id)

        if (
            payload.category_id is not None or payload.order_number is not None
        ) and (target_category_id, target_order_number) != (
            question.category_id,
            question.order_number,
        ):
            existing = self.repo.get_by_category_and_order(
                target_category_id,
                target_order_number,
            )
            if existing and existing.id != question.id:
                raise ValidationException(
                    "Ya existe una pregunta con ese orden en la categoría"
                )

        updated = self.repo.update(question, payload)
        return QuestionResponse.model_validate(updated)

    def update_question_status(
        self,
        question_id: int,
        payload: QuestionStatusUpdate,
    ) -> QuestionResponse:
        question = self._get_or_404(question_id)
        updated = self.repo.update_status(question, payload.status)
        return QuestionResponse.model_validate(updated)

    def _get_or_404(self, question_id: int):
        question = self.repo.get_by_id(question_id)
        if question is None:
            raise NotFoundException("Pregunta no encontrada")
        return question

    def _validate_category(self, category_id: int) -> None:
        category = self.repo.get_category_by_id(category_id)
        if category is None:
            raise NotFoundException("Categoría RIASEC no encontrada")

    def _validate_unique_order(self, category_id: int, order_number: int) -> None:
        existing = self.repo.get_by_category_and_order(category_id, order_number)
        if existing:
            raise ValidationException(
                "Ya existe una pregunta con ese orden en la categoría"
            )

    @staticmethod
    def _resolve_status_filter(
        current_user: User,
        status: QuestionStatus | None,
    ) -> QuestionStatus:
        if status is None:
            return QuestionStatus.ACTIVE
        if status != QuestionStatus.ACTIVE and current_user.role != UserRole.SUPER_ADMIN:
            raise ForbiddenException("No tienes permisos para filtrar por ese estado")
        return status

    @staticmethod
    def _ensure_super_admin(current_user: User) -> None:
        if current_user.role != UserRole.SUPER_ADMIN:
            raise ForbiddenException("No tienes permisos para ver esta pregunta")
