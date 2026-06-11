from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, ValidationException
from app.models.user import User
from app.repositories.dashboard_repository import DashboardRepository
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.dashboard import (
    CounselorDashboardResponse,
    CounselorDashboardSummary,
    InstitutionDashboardResponse,
    InstitutionDashboardSummary,
    RecentCompletionItem,
    RiasecDistributionItem,
    StudentAttentionItem,
    StudentDashboardResponse,
    StudentTestOverview,
    SuperAdminDashboardResponse,
    SuperAdminDashboardSummary,
    TestsByStatusSummary,
    UsersByRoleSummary,
)
from app.schemas.test_session import RiasecResultResponse, TestSessionResponse
from app.services.test_session_service import TestSessionService


class DashboardService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = DashboardRepository(db)
        self.student_repo = StudentRepository(db)
        self.institution_repo = InstitutionRepository(db)
        self.test_repo = TestSessionRepository(db)
        self.test_service = TestSessionService(db)
        self.recommendation_repo = RecommendationRepository(db)
        self.report_repo = ReportRepository(db)

    def get_super_admin_dashboard(self, current_user: User) -> SuperAdminDashboardResponse:
        if current_user.role != UserRole.SUPER_ADMIN:
            raise ForbiddenException("No tienes permisos para ver este dashboard")

        users_by_role_raw = self.repo.count_users_by_role()
        users_by_role = UsersByRoleSummary(
            SUPER_ADMIN=users_by_role_raw.get(UserRole.SUPER_ADMIN.value, 0),
            INSTITUTION_ADMIN=users_by_role_raw.get(UserRole.INSTITUTION_ADMIN.value, 0),
            COUNSELOR=users_by_role_raw.get(UserRole.COUNSELOR.value, 0),
            STUDENT=users_by_role_raw.get(UserRole.STUDENT.value, 0),
        )

        summary = SuperAdminDashboardSummary(
            institutions_total=self.repo.count_institutions(),
            institutions_active=self.repo.count_institutions(status=InstitutionStatus.ACTIVE),
            users_total=sum(users_by_role_raw.values()),
            users_by_role=users_by_role,
            students_total=self.repo.count_students(),
            tests_completed=self.repo.count_test_sessions(status=TestSessionStatus.COMPLETED),
            tests_in_progress=self.repo.count_test_sessions(
                status=TestSessionStatus.IN_PROGRESS
            )
            + self.repo.count_test_sessions(status=TestSessionStatus.STARTED),
            reports_generated=self.repo.count_reports(),
            careers_active=self.repo.count_careers_active(),
            questions_active=self.repo.count_questions_active(),
        )
        return SuperAdminDashboardResponse(summary=summary)

    def get_institution_dashboard(
        self,
        current_user: User,
    ) -> InstitutionDashboardResponse:
        if current_user.role != UserRole.INSTITUTION_ADMIN:
            raise ForbiddenException("No tienes permisos para ver este dashboard")
        if current_user.institution_id is None:
            raise ValidationException("Tu usuario no tiene institución asignada")

        institution = self.institution_repo.get_by_id(current_user.institution_id)
        if institution is None:
            raise ValidationException("Institución no encontrada")

        institution_id = institution.id
        tests_by_status_raw = self.repo.count_tests_by_status(
            institution_id=institution_id
        )
        tests_by_status = TestsByStatusSummary(**tests_by_status_raw)

        summary = InstitutionDashboardSummary(
            students_total=self.repo.count_students(institution_id=institution_id),
            students_active=self.repo.count_students(
                institution_id=institution_id,
                active_only=True,
            ),
            counselors_total=self.repo.count_counselors(institution_id),
            tests_completed=tests_by_status.COMPLETED,
            tests_in_progress=tests_by_status.STARTED + tests_by_status.IN_PROGRESS,
            tests_not_started=self.repo.count_students_without_tests(
                institution_id=institution_id
            ),
            reports_generated=self.repo.count_reports(institution_id=institution_id),
        )

        riasec_distribution = [
            RiasecDistributionItem(profile=profile, count=count)
            for profile, count in self.repo.get_riasec_distribution(
                institution_id=institution_id
            )
        ]

        recent_completions = [
            RecentCompletionItem(
                student_id=student_id,
                student_name=student_name,
                test_session_id=session_id,
                finished_at=finished_at,
                dominant_profile=dominant,
            )
            for student_id, student_name, session_id, finished_at, dominant in (
                self.repo.get_recent_completions(institution_id=institution_id)
            )
        ]

        return InstitutionDashboardResponse(
            institution_id=institution.id,
            institution_name=institution.name,
            summary=summary,
            tests_by_status=tests_by_status,
            riasec_distribution=riasec_distribution,
            recent_completions=recent_completions,
        )

    def get_counselor_dashboard(self, current_user: User) -> CounselorDashboardResponse:
        if current_user.role != UserRole.COUNSELOR:
            raise ForbiddenException("No tienes permisos para ver este dashboard")

        assigned_students = self.repo.count_students(counselor_id=current_user.id)
        tests_completed = self.repo.count_test_sessions(
            status=TestSessionStatus.COMPLETED,
            counselor_id=current_user.id,
        )
        tests_in_progress = self.repo.count_test_sessions(
            status=TestSessionStatus.IN_PROGRESS,
            counselor_id=current_user.id,
        ) + self.repo.count_test_sessions(
            status=TestSessionStatus.STARTED,
            counselor_id=current_user.id,
        )

        overview = self.repo.get_assigned_students_overview(current_user.id)
        students_needing_attention = [
            StudentAttentionItem(**item)
            for item in overview
            if item["test_status"] == TestSessionStatus.COMPLETED
            and not item["has_observations"]
        ]

        summary = CounselorDashboardSummary(
            assigned_students=assigned_students,
            tests_completed=tests_completed,
            tests_in_progress=tests_in_progress,
            pending_review=len(students_needing_attention),
        )

        return CounselorDashboardResponse(
            counselor_id=current_user.id,
            summary=summary,
            students_needing_attention=students_needing_attention,
        )

    def get_student_dashboard(self, current_user: User) -> StudentDashboardResponse:
        if current_user.role != UserRole.STUDENT:
            raise ForbiddenException("No tienes permisos para ver este dashboard")

        student = self.student_repo.get_by_user_id(current_user.id)
        if student is None:
            raise ValidationException(
                "Tu usuario no tiene perfil de estudiante registrado"
            )

        open_session = self.test_repo.get_open_session_for_student(student.id)
        latest_result = self.test_repo.get_latest_riasec_result_for_student(student.id)
        latest_completed_session_id = (
            latest_result.test_session_id if latest_result is not None else None
        )

        open_session_response = None
        if open_session is not None:
            open_session_response = self.test_service._build_session_response(open_session)

        riasec_response = None
        if latest_result is not None:
            riasec_response = self.test_service._build_result_response(latest_result)

        recommendations = []
        if latest_completed_session_id is not None:
            recommendations = self.recommendation_repo.list_by_test_session(
                latest_completed_session_id
            )

        latest_report = None
        if latest_completed_session_id is not None:
            latest_report = self.report_repo.get_by_test_session(
                latest_completed_session_id
            )

        test_status = None
        if open_session is not None:
            test_status = open_session.status
        elif latest_completed_session_id is not None:
            test_status = TestSessionStatus.COMPLETED

        profile_complete = self._is_student_profile_complete(student)
        next_actions = self._build_next_actions(
            has_open_session=open_session is not None,
            has_completed=latest_completed_session_id is not None,
            has_recommendations=bool(recommendations),
            has_report=latest_report is not None,
            profile_complete=profile_complete,
        )

        return StudentDashboardResponse(
            student_id=student.id,
            profile_complete=profile_complete,
            test=StudentTestOverview(
                has_open_session=open_session is not None,
                open_session=open_session_response,
                latest_completed_session_id=latest_completed_session_id,
                status=test_status,
            ),
            riasec_result=riasec_response,
            has_recommendations=bool(recommendations),
            recommendations_count=len(recommendations),
            has_report=latest_report is not None,
            latest_report_code=latest_report.report_code if latest_report else None,
            next_actions=next_actions,
        )

    @staticmethod
    def _is_student_profile_complete(student) -> bool:
        return bool(
            student.grade
            and student.user.phone
            and student.representative_name
            and student.representative_phone
        )

    @staticmethod
    def _build_next_actions(
        *,
        has_open_session: bool,
        has_completed: bool,
        has_recommendations: bool,
        has_report: bool,
        profile_complete: bool,
    ) -> list[str]:
        actions: list[str] = []
        if not profile_complete:
            actions.append("complete_profile")
        if has_open_session:
            actions.append("continue_test")
        elif not has_completed:
            actions.append("start_test")
        else:
            actions.append("view_results")
            if not has_recommendations:
                actions.append("generate_recommendations")
            if has_recommendations or has_report:
                actions.append("download_pdf")
            if has_recommendations:
                actions.append("view_recommendations")
                actions.append("open_assistant")
        return actions
