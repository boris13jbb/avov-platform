from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    student_id: int
    test_session_id: int
    report_code: str
    file_path: str
    generated_by: int
    created_at: datetime
    updated_at: datetime


class ReportListResponse(BaseModel):
    student_id: int
    items: list[ReportResponse]
