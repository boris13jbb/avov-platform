from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.report import Report


class ReportRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, report_id: int) -> Report | None:
        return self.db.get(Report, report_id)

    def get_latest_for_session(self, session_id: int) -> Report | None:
        stmt = (
            select(Report)
            .where(Report.test_session_id == session_id)
            .order_by(Report.id.desc())
            .limit(1)
        )
        return self.db.scalars(stmt).first()

    def get_by_code(self, report_code: str) -> Report | None:
        stmt = select(Report).where(Report.report_code == report_code)
        return self.db.scalars(stmt).first()

    def count_by_student(self, student_id: int) -> int:
        stmt = (
            select(func.count())
            .select_from(Report)
            .where(Report.student_id == student_id)
        )
        return int(self.db.scalar(stmt) or 0)

    def list_by_student(
        self,
        student_id: int,
        *,
        page: int,
        page_size: int,
    ) -> list[Report]:
        offset = (page - 1) * page_size
        stmt = (
            select(Report)
            .where(Report.student_id == student_id)
            .order_by(Report.created_at.desc(), Report.id.desc())
            .offset(offset)
            .limit(page_size)
        )
        return list(self.db.scalars(stmt).all())

    def create(self, report: Report) -> Report:
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def update_file_path(self, report: Report, file_path: str) -> Report:
        report.file_path = file_path
        self.db.commit()
        self.db.refresh(report)
        return report
