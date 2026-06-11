from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class GenerateRecommendationsRequest(BaseModel):
    test_session_id: int | None = None


class RecommendationCareerBrief(BaseModel):
    id: int
    name: str
    area: str
    riasec_profile: str
    degree_type: str
    institution_type: str
    employment_field: str


class RecommendationResponse(BaseModel):
    id: int
    test_session_id: int
    student_id: int
    career_id: int
    career: RecommendationCareerBrief
    match_percentage: float
    riasec_score: float
    qdrant_score: float | None
    ai_explanation: str | None
    source: str
    created_at: datetime
    updated_at: datetime


class RecommendationListResponse(BaseModel):
    student_id: int
    test_session_id: int
    items: list[RecommendationResponse]
    ai_summary: str | None = None
    ai_source: str | None = None
    used_fallback: bool = False
    from_cache: bool = False
    ethical_disclaimer: str


class CounselorObservationRequest(BaseModel):
    observation: str = Field(min_length=1, max_length=2000)

    @field_validator("observation")
    @classmethod
    def strip_observation(cls, value: str) -> str:
        return value.strip()


class CounselorObservationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    test_session_id: int
    counselor_id: int
    observation: str
    created_at: datetime
    updated_at: datetime
