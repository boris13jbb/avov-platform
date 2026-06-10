from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.core.enums import QuestionStatus, TestSessionStatus
from app.models.riasec import Question, RiasecCategory, RiasecResult, TestAnswer, TestSession
from app.models.student import Student


class TestSessionRepository:
    OPEN_STATUSES = (TestSessionStatus.STARTED, TestSessionStatus.IN_PROGRESS)

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, session_id: int) -> TestSession | None:
        stmt = (
            select(TestSession)
            .options(joinedload(TestSession.student).joinedload(Student.user))
            .where(TestSession.id == session_id)
        )
        return self.db.scalar(stmt)

    def get_open_session_for_student(self, student_id: int) -> TestSession | None:
        stmt = (
            select(TestSession)
            .where(
                TestSession.student_id == student_id,
                TestSession.status.in_(self.OPEN_STATUSES),
            )
            .order_by(TestSession.started_at.desc())
        )
        return self.db.scalar(stmt)

    def create_session(self, student_id: int, total_questions: int) -> TestSession:
        session = TestSession(
            student_id=student_id,
            status=TestSessionStatus.STARTED,
            total_questions=total_questions,
            current_question=1,
        )
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def update_session_progress(
        self,
        session: TestSession,
        *,
        status: TestSessionStatus | None = None,
        current_question: int | None = None,
    ) -> TestSession:
        if status is not None:
            session.status = status
        if current_question is not None:
            session.current_question = current_question

        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def complete_session(self, session: TestSession) -> TestSession:
        session.status = TestSessionStatus.COMPLETED
        session.finished_at = datetime.now(timezone.utc).replace(tzinfo=None)
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def list_active_questions(self) -> list[Question]:
        stmt = (
            select(Question)
            .join(RiasecCategory, Question.category_id == RiasecCategory.id)
            .options(joinedload(Question.category))
            .where(Question.status == QuestionStatus.ACTIVE)
            .order_by(RiasecCategory.code.asc(), Question.order_number.asc())
        )
        return list(self.db.scalars(stmt).unique().all())

    def get_active_question_ids(self) -> set[int]:
        stmt = select(Question.id).where(Question.status == QuestionStatus.ACTIVE)
        return set(self.db.scalars(stmt).all())

    def get_answer(self, session_id: int, question_id: int) -> TestAnswer | None:
        stmt = select(TestAnswer).where(
            TestAnswer.test_session_id == session_id,
            TestAnswer.question_id == question_id,
        )
        return self.db.scalar(stmt)

    def list_answers_for_session(self, session_id: int) -> list[TestAnswer]:
        stmt = (
            select(TestAnswer)
            .options(
                joinedload(TestAnswer.question).joinedload(Question.category),
            )
            .where(TestAnswer.test_session_id == session_id)
        )
        return list(self.db.scalars(stmt).unique().all())

    def count_answers(self, session_id: int) -> int:
        stmt = (
            select(func.count())
            .select_from(TestAnswer)
            .where(TestAnswer.test_session_id == session_id)
        )
        return self.db.scalar(stmt) or 0

    def upsert_answer(
        self,
        session_id: int,
        question_id: int,
        answer_value: int,
    ) -> TestAnswer:
        existing = self.get_answer(session_id, question_id)
        if existing:
            existing.answer_value = answer_value
            self.db.add(existing)
            self.db.commit()
            self.db.refresh(existing)
            return existing

        answer = TestAnswer(
            test_session_id=session_id,
            question_id=question_id,
            answer_value=answer_value,
        )
        self.db.add(answer)
        self.db.commit()
        self.db.refresh(answer)
        return answer

    def get_riasec_result(self, session_id: int) -> RiasecResult | None:
        stmt = select(RiasecResult).where(RiasecResult.test_session_id == session_id)
        return self.db.scalar(stmt)

    def get_latest_riasec_result_for_student(self, student_id: int) -> RiasecResult | None:
        stmt = (
            select(RiasecResult)
            .join(TestSession, RiasecResult.test_session_id == TestSession.id)
            .where(
                TestSession.student_id == student_id,
                TestSession.status == TestSessionStatus.COMPLETED,
            )
            .order_by(RiasecResult.created_at.desc())
        )
        return self.db.scalar(stmt)

    def create_riasec_result(
        self,
        *,
        test_session_id: int,
        student_id: int,
        score_r: int,
        score_i: int,
        score_a: int,
        score_s: int,
        score_e: int,
        score_c: int,
        dominant_profile: str,
        secondary_profile: str,
    ) -> RiasecResult:
        result = RiasecResult(
            test_session_id=test_session_id,
            student_id=student_id,
            score_r=score_r,
            score_i=score_i,
            score_a=score_a,
            score_s=score_s,
            score_e=score_e,
            score_c=score_c,
            dominant_profile=dominant_profile,
            secondary_profile=secondary_profile,
        )
        self.db.add(result)
        self.db.commit()
        self.db.refresh(result)
        return result

    def delete_session(self, session_id: int) -> None:
        session = self.get_by_id(session_id)
        if session is None:
            return

        answers = self.list_answers_for_session(session_id)
        for answer in answers:
            self.db.delete(answer)

        result = self.get_riasec_result(session_id)
        if result:
            self.db.delete(result)

        self.db.delete(session)
        self.db.commit()
