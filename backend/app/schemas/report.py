"""Esquemas de historial de informes PDF (sin rutas de almacenamiento)."""

from __future__ import annotations

from datetime import datetime
from math import ceil

from pydantic import BaseModel, ConfigDict


class ReportHistoryItem(BaseModel):
    """Metadatos públicos de un informe persistido."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    student_id: int
    test_session_id: int
    report_code: str
    generated_by: int
    created_at: datetime
    updated_at: datetime


class PaginatedReports(BaseModel):
    items: list[ReportHistoryItem]
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
    ) -> "PaginatedReports":
        pages = ceil(total / page_size) if total > 0 else 0
        return cls(
            items=[ReportHistoryItem.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )
