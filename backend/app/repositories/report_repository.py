from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.report import Report


class ReportRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, report_id: int) -> Report | None:
        return self.db.get(Report, report_id)

    def get_by_test_session(self, test_session_id: int) -> Report | None:
        stmt = (
            select(Report)
            .where(Report.test_session_id == test_session_id)
            .order_by(Report.created_at.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)

    def list_by_student(self, student_id: int) -> list[Report]:
        stmt = (
            select(Report)
            .where(Report.student_id == student_id)
            .order_by(Report.created_at.desc())
        )
        return list(self.db.scalars(stmt).all())

    def create(
        self,
        *,
        student_id: int,
        test_session_id: int,
        file_path: str,
        report_code: str,
        generated_by: int,
    ) -> Report:
        report = Report(
            student_id=student_id,
            test_session_id=test_session_id,
            file_path=file_path,
            report_code=report_code,
            generated_by=generated_by,
        )
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def delete_by_test_session(self, test_session_id: int) -> None:
        stmt = delete(Report).where(Report.test_session_id == test_session_id)
        self.db.execute(stmt)
        self.db.commit()
