from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class RecommendationItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    career_id: int
    career_name: str
    career_area: str
    career_riasec_profile: str
    match_percentage: float
    qdrant_score: float | None = None
    ai_explanation: str | None = None
    source: str | None = None
    created_at: datetime
    updated_at: datetime


class RecommendationListResponse(BaseModel):
    test_session_id: int
    student_id: int
    riasec_profile: str
    used_fallback: bool = False
    items: list[RecommendationItemResponse] = Field(default_factory=list)
    total: int = 0
