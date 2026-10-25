from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.counselor import CounselorObservation


class ObservationRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        *,
        test_session_id: int,
        counselor_id: int,
        observation: str,
    ) -> CounselorObservation:
        row = CounselorObservation(
            test_session_id=test_session_id,
            counselor_id=counselor_id,
            observation=observation,
        )
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

    def get_by_id(self, observation_id: int) -> CounselorObservation | None:
        return self.db.get(CounselorObservation, observation_id)

    def list_by_test_session(
        self,
        test_session_id: int,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[CounselorObservation], int]:
        filters = [CounselorObservation.test_session_id == test_session_id]
        offset = (page - 1) * page_size

        stmt = (
            select(CounselorObservation)
            .where(*filters)
            .order_by(CounselorObservation.id.desc())
            .offset(offset)
            .limit(page_size)
        )
        items = list(self.db.scalars(stmt).all())

        count_stmt = (
            select(func.count())
            .select_from(CounselorObservation)
            .where(*filters)
        )
        total = self.db.scalar(count_stmt) or 0
        return items, total

    def get_latest_for_session(
        self,
        test_session_id: int,
    ) -> CounselorObservation | None:
        stmt = (
            select(CounselorObservation)
            .where(CounselorObservation.test_session_id == test_session_id)
            .order_by(CounselorObservation.id.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)
