from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import AssignmentStatus


class AssignmentCreate(BaseModel):
    student_id: int = Field(ge=1)
    counselor_id: int = Field(ge=1)


class AssignmentStatusUpdate(BaseModel):
    status: AssignmentStatus


class AssignmentPartySummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None


class AssignmentStudentSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    identification: str | None = None
    user: AssignmentPartySummary | None = None


class AssignmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    counselor_id: int
    student_id: int
    institution_id: int
    status: AssignmentStatus
    assigned_at: datetime
    created_at: datetime
    updated_at: datetime
    counselor: AssignmentPartySummary | None = None
    student: AssignmentStudentSummary | None = None


class PaginatedAssignments(BaseModel):
    items: list[AssignmentResponse]
    total: int
    page: int
    page_size: int
    pages: int

    @classmethod
    def build(
        cls,
        items: list[AssignmentResponse],
        total: int,
        page: int,
        page_size: int,
    ) -> "PaginatedAssignments":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
