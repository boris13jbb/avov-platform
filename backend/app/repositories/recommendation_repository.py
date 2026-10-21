from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.orm import Session, joinedload

from app.models.career import Recommendation


class RecommendationRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_for_session(self, session_id: int) -> list[Recommendation]:
        stmt = (
            select(Recommendation)
            .options(joinedload(Recommendation.career))
            .where(Recommendation.test_session_id == session_id)
            .order_by(Recommendation.match_percentage.desc(), Recommendation.id.asc())
        )
        return list(self.db.scalars(stmt).unique().all())

    def delete_for_session(self, session_id: int) -> int:
        result = self.db.execute(
            delete(Recommendation).where(Recommendation.test_session_id == session_id)
        )
        self.db.commit()
        return int(result.rowcount or 0)

    def create_many(self, rows: list[Recommendation]) -> list[Recommendation]:
        self.db.add_all(rows)
        self.db.commit()
        for row in rows:
            self.db.refresh(row)
        return self.list_for_session(rows[0].test_session_id) if rows else []
