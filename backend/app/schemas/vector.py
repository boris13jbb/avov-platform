from pydantic import BaseModel, Field, field_validator


class CareerSearchRequest(BaseModel):
    query: str | None = Field(default=None, max_length=500)
    riasec_profile: str | None = Field(default=None, max_length=10)
    limit: int = Field(default=10, ge=1, le=50)

    @field_validator("query", "riasec_profile")
    @classmethod
    def strip_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None

    def has_search_criteria(self) -> bool:
        return bool(self.query or self.riasec_profile)


class CareerVectorMatch(BaseModel):
    career_id: int
    name: str
    area: str
    riasec_profile: str
    degree_type: str
    institution_type: str
    score: float
    qdrant_score: float
    source: str


class CareerSearchResponse(BaseModel):
    items: list[CareerVectorMatch]
    total: int
    query_text: str
    used_fallback: bool = False


class RebuildCareersResponse(BaseModel):
    collection: str
    indexed: int
    vector_size: int
    source: str = "mysql"
