from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.enums import QuestionStatus


class CategoryBrief(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    code: str
    name: str


class QuestionCreate(BaseModel):
    category_id: int
    text: str = Field(min_length=10)
    order_number: int = Field(ge=1, le=100)
    status: QuestionStatus = QuestionStatus.ACTIVE

    @field_validator("text")
    @classmethod
    def strip_text(cls, value: str) -> str:
        return value.strip()


class QuestionUpdate(BaseModel):
    category_id: int | None = None
    text: str | None = Field(default=None, min_length=10)
    order_number: int | None = Field(default=None, ge=1, le=100)
    status: QuestionStatus | None = None

    @field_validator("text")
    @classmethod
    def strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()


class QuestionStatusUpdate(BaseModel):
    status: QuestionStatus


class QuestionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    category: CategoryBrief
    text: str
    order_number: int
    status: QuestionStatus
    created_at: datetime
    updated_at: datetime


class PaginatedQuestions(BaseModel):
    items: list[QuestionResponse]
    total: int
    page: int
    page_size: int
    pages: int

    @classmethod
    def build(
        cls,
        items: list,
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedQuestions":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[QuestionResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
