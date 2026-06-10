from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.core.enums import QuestionStatus
from app.models.riasec import Question, RiasecCategory
from app.schemas.question import QuestionCreate, QuestionUpdate


class QuestionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_category_by_id(self, category_id: int) -> RiasecCategory | None:
        return self.db.get(RiasecCategory, category_id)

    def get_by_id(self, question_id: int) -> Question | None:
        stmt = (
            select(Question)
            .options(joinedload(Question.category))
            .where(Question.id == question_id)
        )
        return self.db.scalar(stmt)

    def get_by_category_and_order(
        self,
        category_id: int,
        order_number: int,
    ) -> Question | None:
        stmt = select(Question).where(
            Question.category_id == category_id,
            Question.order_number == order_number,
        )
        return self.db.scalar(stmt)

    def count_active(self) -> int:
        stmt = select(func.count()).select_from(Question).where(
            Question.status == QuestionStatus.ACTIVE
        )
        return self.db.scalar(stmt) or 0

    def list(
        self,
        *,
        page: int = 1,
        page_size: int = 20,
        search: str | None = None,
        category_id: int | None = None,
        category_code: str | None = None,
        status: QuestionStatus | None = None,
    ) -> tuple[list[Question], int]:
        filters = self._build_filters(search, category_id, category_code, status)
        offset = (page - 1) * page_size

        stmt = (
            select(Question)
            .join(RiasecCategory, Question.category_id == RiasecCategory.id)
            .options(joinedload(Question.category))
            .where(*filters)
            .order_by(RiasecCategory.code.asc(), Question.order_number.asc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).unique().all())

        count_stmt = (
            select(func.count())
            .select_from(Question)
            .join(RiasecCategory, Question.category_id == RiasecCategory.id)
            .where(*filters)
        )
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def create(self, payload: QuestionCreate) -> Question:
        question = Question(
            category_id=payload.category_id,
            text=payload.text,
            order_number=payload.order_number,
            status=payload.status,
        )
        self.db.add(question)
        self.db.commit()
        created = self.get_by_id(question.id)
        if created is None:
            raise RuntimeError("No se pudo recuperar la pregunta creada")
        return created

    def update(self, question: Question, payload: QuestionUpdate) -> Question:
        update_data = payload.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(question, field, value)

        self.db.add(question)
        self.db.commit()
        updated = self.get_by_id(question.id)
        if updated is None:
            raise RuntimeError("No se pudo recuperar la pregunta actualizada")
        return updated

    def update_status(self, question: Question, status: QuestionStatus) -> Question:
        question.status = status
        self.db.add(question)
        self.db.commit()
        updated = self.get_by_id(question.id)
        if updated is None:
            raise RuntimeError("No se pudo recuperar la pregunta actualizada")
        return updated

    def delete(self, question: Question) -> None:
        self.db.delete(question)
        self.db.commit()

    @staticmethod
    def _build_filters(
        search: str | None,
        category_id: int | None,
        category_code: str | None,
        status: QuestionStatus | None,
    ) -> list:
        filters = []

        if status is not None:
            filters.append(Question.status == status)

        if category_id is not None:
            filters.append(Question.category_id == category_id)

        if category_code:
            filters.append(
                func.upper(RiasecCategory.code) == category_code.strip().upper()
            )

        if search:
            term = f"%{search.strip().lower()}%"
            filters.append(func.lower(Question.text).like(term))

        return filters
