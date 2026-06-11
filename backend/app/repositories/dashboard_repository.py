from __future__ import annotations

from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session

from app.core.enums import (
    AssignmentStatus,
    CareerStatus,
    InstitutionStatus,
    QuestionStatus,
    TestSessionStatus,
    UserRole,
    UserStatus,
)
from app.models.career import Career
from app.models.counselor import CounselorObservation
from app.models.institution import Institution
from app.models.report import Report
from app.models.riasec import Question, RiasecResult, TestSession
from app.models.student import CounselorAssignment, Student
from app.models.user import User


class DashboardRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def count_institutions(self, *, status: InstitutionStatus | None = None) -> int:
        filters = []
        if status is not None:
            filters.append(Institution.status == status)
        stmt = select(func.count()).select_from(Institution).where(*filters)
        return int(self.db.scalar(stmt) or 0)

    def count_users(
        self,
        *,
        role: UserRole | None = None,
        institution_id: int | None = None,
    ) -> int:
        filters = []
        if role is not None:
            filters.append(User.role == role)
        if institution_id is not None:
            filters.append(User.institution_id == institution_id)
        stmt = select(func.count()).select_from(User).where(*filters)
        return int(self.db.scalar(stmt) or 0)

    def count_users_by_role(self, institution_id: int | None = None) -> dict[str, int]:
        filters = []
        if institution_id is not None:
            filters.append(User.institution_id == institution_id)
        stmt = (
            select(User.role, func.count())
            .where(*filters)
            .group_by(User.role)
        )
        rows = self.db.execute(stmt).all()
        return {role.value: int(count) for role, count in rows}

    def count_students(
        self,
        *,
        institution_id: int | None = None,
        counselor_id: int | None = None,
        active_only: bool = False,
    ) -> int:
        filters = [User.role == UserRole.STUDENT]
        if institution_id is not None:
            filters.append(Student.institution_id == institution_id)
        if active_only:
            filters.append(User.status == UserStatus.ACTIVE)

        stmt = (
            select(func.count())
            .select_from(Student)
            .join(User, Student.user_id == User.id)
            .where(*filters)
        )
        if counselor_id is not None:
            stmt = stmt.join(
                CounselorAssignment,
                and_(
                    CounselorAssignment.student_id == Student.id,
                    CounselorAssignment.counselor_id == counselor_id,
                    CounselorAssignment.status == AssignmentStatus.ACTIVE,
                ),
            )
        return int(self.db.scalar(stmt) or 0)

    def count_counselors(self, institution_id: int) -> int:
        return self.count_users(
            role=UserRole.COUNSELOR,
            institution_id=institution_id,
        )

    def count_test_sessions(
        self,
        *,
        status: TestSessionStatus | None = None,
        institution_id: int | None = None,
        counselor_id: int | None = None,
    ) -> int:
        filters = []
        if status is not None:
            filters.append(TestSession.status == status)
        if institution_id is not None:
            filters.append(Student.institution_id == institution_id)
        if counselor_id is not None:
            filters.append(CounselorAssignment.counselor_id == counselor_id)
            filters.append(CounselorAssignment.status == AssignmentStatus.ACTIVE)

        stmt = select(func.count()).select_from(TestSession)
        if institution_id is not None or counselor_id is not None:
            stmt = stmt.join(Student, TestSession.student_id == Student.id)
        if counselor_id is not None:
            stmt = stmt.join(
                CounselorAssignment,
                CounselorAssignment.student_id == Student.id,
            )
        stmt = stmt.where(*filters)
        return int(self.db.scalar(stmt) or 0)

    def count_tests_by_status(
        self,
        *,
        institution_id: int | None = None,
        counselor_id: int | None = None,
    ) -> dict[str, int]:
        result = {status.value: 0 for status in TestSessionStatus}
        for status in TestSessionStatus:
            result[status.value] = self.count_test_sessions(
                status=status,
                institution_id=institution_id,
                counselor_id=counselor_id,
            )
        return result

    def count_students_without_tests(
        self,
        *,
        institution_id: int | None = None,
        counselor_id: int | None = None,
    ) -> int:
        filters = [User.role == UserRole.STUDENT]
        if institution_id is not None:
            filters.append(Student.institution_id == institution_id)

        subquery = select(TestSession.student_id).distinct()
        stmt = (
            select(func.count())
            .select_from(Student)
            .join(User, Student.user_id == User.id)
            .where(*filters, Student.id.not_in(subquery))
        )
        if counselor_id is not None:
            stmt = stmt.join(
                CounselorAssignment,
                and_(
                    CounselorAssignment.student_id == Student.id,
                    CounselorAssignment.counselor_id == counselor_id,
                    CounselorAssignment.status == AssignmentStatus.ACTIVE,
                ),
            )
        return int(self.db.scalar(stmt) or 0)

    def count_reports(self, *, institution_id: int | None = None) -> int:
        stmt = select(func.count()).select_from(Report)
        if institution_id is not None:
            stmt = stmt.join(Student, Report.student_id == Student.id).where(
                Student.institution_id == institution_id
            )
        return int(self.db.scalar(stmt) or 0)

    def count_careers_active(self) -> int:
        stmt = (
            select(func.count())
            .select_from(Career)
            .where(Career.status == CareerStatus.ACTIVE)
        )
        return int(self.db.scalar(stmt) or 0)

    def count_questions_active(self) -> int:
        stmt = (
            select(func.count())
            .select_from(Question)
            .where(Question.status == QuestionStatus.ACTIVE)
        )
        return int(self.db.scalar(stmt) or 0)

    def get_riasec_distribution(
        self,
        *,
        institution_id: int | None = None,
        limit: int = 10,
    ) -> list[tuple[str, int]]:
        filters = [RiasecResult.dominant_profile.is_not(None)]
        stmt = (
            select(RiasecResult.dominant_profile, func.count())
            .join(Student, RiasecResult.student_id == Student.id)
            .where(*filters)
            .group_by(RiasecResult.dominant_profile)
            .order_by(func.count().desc())
            .limit(limit)
        )
        if institution_id is not None:
            stmt = stmt.where(Student.institution_id == institution_id)
        rows = self.db.execute(stmt).all()
        return [(profile, int(count)) for profile, count in rows if profile]

    def get_recent_completions(
        self,
        *,
        institution_id: int,
        limit: int = 5,
    ) -> list[tuple[int, str, int, object, str | None]]:
        stmt = (
            select(
                Student.id,
                User.first_name,
                User.last_name,
                TestSession.id,
                TestSession.finished_at,
                RiasecResult.dominant_profile,
            )
            .join(TestSession, TestSession.student_id == Student.id)
            .join(User, Student.user_id == User.id)
            .join(RiasecResult, RiasecResult.test_session_id == TestSession.id)
            .where(
                Student.institution_id == institution_id,
                TestSession.status == TestSessionStatus.COMPLETED,
            )
            .order_by(TestSession.finished_at.desc())
            .limit(limit)
        )
        rows = self.db.execute(stmt).all()
        return [
            (
                student_id,
                f"{first_name} {last_name}".strip(),
                session_id,
                finished_at,
                dominant,
            )
            for student_id, first_name, last_name, session_id, finished_at, dominant in rows
        ]

    def get_assigned_students_overview(
        self,
        counselor_id: int,
        *,
        limit: int = 20,
    ) -> list[dict]:
        stmt = (
            select(Student, User)
            .join(User, Student.user_id == User.id)
            .join(
                CounselorAssignment,
                and_(
                    CounselorAssignment.student_id == Student.id,
                    CounselorAssignment.counselor_id == counselor_id,
                    CounselorAssignment.status == AssignmentStatus.ACTIVE,
                ),
            )
            .order_by(User.last_name.asc(), User.first_name.asc())
            .limit(limit)
        )
        rows = self.db.execute(stmt).all()
        overview: list[dict] = []
        for student, user in rows:
            latest_session = self._get_latest_session(student.id)
            latest_completed = self._get_latest_completed_session(student.id)
            session_for_flags = latest_completed or latest_session
            session_id = session_for_flags.id if session_for_flags else None
            overview.append(
                {
                    "student_id": student.id,
                    "full_name": f"{user.first_name} {user.last_name}".strip(),
                    "test_status": latest_session.status if latest_session else None,
                    "test_session_id": session_id,
                    "has_observations": self._has_observations(session_id),
                    "has_report": self._has_report(session_id),
                    "has_recommendations": self._has_recommendations(session_id),
                    "dominant_profile": self._get_dominant_profile(session_id),
                }
            )
        return overview

    def _get_latest_session(self, student_id: int) -> TestSession | None:
        stmt = (
            select(TestSession)
            .where(TestSession.student_id == student_id)
            .order_by(TestSession.started_at.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)

    def _get_latest_completed_session(self, student_id: int) -> TestSession | None:
        stmt = (
            select(TestSession)
            .where(
                TestSession.student_id == student_id,
                TestSession.status == TestSessionStatus.COMPLETED,
            )
            .order_by(TestSession.finished_at.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)

    def _has_observations(self, test_session_id: int | None) -> bool:
        if test_session_id is None:
            return False
        stmt = (
            select(func.count())
            .select_from(CounselorObservation)
            .where(CounselorObservation.test_session_id == test_session_id)
        )
        return int(self.db.scalar(stmt) or 0) > 0

    def _has_report(self, test_session_id: int | None) -> bool:
        if test_session_id is None:
            return False
        stmt = (
            select(func.count())
            .select_from(Report)
            .where(Report.test_session_id == test_session_id)
        )
        return int(self.db.scalar(stmt) or 0) > 0

    def _has_recommendations(self, test_session_id: int | None) -> bool:
        if test_session_id is None:
            return False
        from app.models.career import Recommendation

        stmt = (
            select(func.count())
            .select_from(Recommendation)
            .where(Recommendation.test_session_id == test_session_id)
        )
        return int(self.db.scalar(stmt) or 0) > 0

    def _get_dominant_profile(self, test_session_id: int | None) -> str | None:
        if test_session_id is None:
            return None
        stmt = select(RiasecResult.dominant_profile).where(
            RiasecResult.test_session_id == test_session_id
        )
        return self.db.scalar(stmt)
