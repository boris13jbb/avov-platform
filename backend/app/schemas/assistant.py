from pydantic import BaseModel, Field, field_validator


class AssistantChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    test_session_id: int | None = None

    @field_validator("message")
    @classmethod
    def strip_message(cls, value: str) -> str:
        return value.strip()


class ExplainProfileRequest(BaseModel):
    test_session_id: int | None = None


class ExplainCareersRequest(BaseModel):
    career_ids: list[int] = Field(min_length=1, max_length=10)
    test_session_id: int | None = None


class AssistantResponse(BaseModel):
    answer: str
    source: str
    ethical_disclaimer: str
