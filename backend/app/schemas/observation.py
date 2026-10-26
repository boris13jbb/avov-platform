from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, Field


class ObservationCreate(BaseModel):
    test_session_id: int = Field(ge=1)
    observation: str = Field(min_length=1, max_length=10000)


class ObservationCounselorSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None


class ObservationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    test_session_id: int
    counselor_id: int
    observation: str
    created_at: datetime
    updated_at: datetime
    counselor: ObservationCounselorSummary | None = None


class PaginatedObservations(BaseModel):
    items: list[ObservationResponse]
    total: int
    page: int
    page_size: int
    pages: int

    @classmethod
    def build(
        cls,
        items: list[ObservationResponse],
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedObservations":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
