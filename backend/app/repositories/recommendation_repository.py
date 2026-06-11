from sqlalchemy import delete, select
from sqlalchemy.orm import Session, joinedload

from app.models.career import Recommendation
from app.models.counselor import CounselorObservation


class RecommendationRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, recommendation_id: int) -> Recommendation | None:
        stmt = (
            select(Recommendation)
            .options(joinedload(Recommendation.career))
            .where(Recommendation.id == recommendation_id)
        )
        return self.db.scalar(stmt)

    def list_by_test_session(self, test_session_id: int) -> list[Recommendation]:
        stmt = (
            select(Recommendation)
            .options(joinedload(Recommendation.career))
            .where(Recommendation.test_session_id == test_session_id)
            .order_by(Recommendation.match_percentage.desc(), Recommendation.id.asc())
        )
        return list(self.db.scalars(stmt).all())

    def list_by_student(self, student_id: int) -> list[Recommendation]:
        stmt = (
            select(Recommendation)
            .options(joinedload(Recommendation.career))
            .where(Recommendation.student_id == student_id)
            .order_by(
                Recommendation.test_session_id.desc(),
                Recommendation.match_percentage.desc(),
                Recommendation.id.asc(),
            )
        )
        return list(self.db.scalars(stmt).all())

    def exists_for_session(self, test_session_id: int) -> bool:
        stmt = (
            select(Recommendation.id)
            .where(Recommendation.test_session_id == test_session_id)
            .limit(1)
        )
        return self.db.scalar(stmt) is not None

    def create_batch(self, items: list[Recommendation]) -> list[Recommendation]:
        for item in items:
            self.db.add(item)
        self.db.commit()
        for item in items:
            self.db.refresh(item)
        return items

    def delete_by_test_session(self, test_session_id: int) -> None:
        stmt = delete(Recommendation).where(
            Recommendation.test_session_id == test_session_id
        )
        self.db.execute(stmt)
        self.db.commit()

    def list_observations_by_test_session(
        self,
        test_session_id: int,
    ) -> list[CounselorObservation]:
        stmt = (
            select(CounselorObservation)
            .where(CounselorObservation.test_session_id == test_session_id)
            .order_by(CounselorObservation.created_at.asc())
        )
        return list(self.db.scalars(stmt).all())

    def create_observation(
        self,
        *,
        test_session_id: int,
        counselor_id: int,
        observation: str,
    ) -> CounselorObservation:
        record = CounselorObservation(
            test_session_id=test_session_id,
            counselor_id=counselor_id,
            observation=observation,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record
