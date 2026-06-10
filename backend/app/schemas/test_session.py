from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import TestSessionStatus
from app.schemas.question import CategoryBrief


class TestSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    student_id: int
    status: TestSessionStatus
    started_at: datetime
    finished_at: datetime | None
    total_questions: int
    current_question: int
    answered_count: int = 0
    progress_percent: float = 0.0
    created_at: datetime
    updated_at: datetime


class TestAnswerCreate(BaseModel):
    question_id: int
    answer_value: int = Field(ge=1, le=5)


class TestAnswerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    question_id: int
    answer_value: int
    created_at: datetime
    updated_at: datetime


class QuestionForTest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    category: CategoryBrief
    text: str
    order_number: int
    answer_value: int | None = None


class SessionQuestionsResponse(BaseModel):
    session: TestSessionResponse
    questions: list[QuestionForTest]


class RiasecScores(BaseModel):
    score_r: int
    score_i: int
    score_a: int
    score_s: int
    score_e: int
    score_c: int


class RiasecResultResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    test_session_id: int
    student_id: int
    score_r: int
    score_i: int
    score_a: int
    score_s: int
    score_e: int
    score_c: int
    dominant_profile: str | None
    secondary_profile: str | None
    combined_profile: str | None = None
    interpretation: str | None
    created_at: datetime
    updated_at: datetime
