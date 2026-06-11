from datetime import datetime

from pydantic import BaseModel

from app.core.enums import TestSessionStatus
from app.schemas.test_session import RiasecResultResponse, TestSessionResponse


class UsersByRoleSummary(BaseModel):
    SUPER_ADMIN: int = 0
    INSTITUTION_ADMIN: int = 0
    COUNSELOR: int = 0
    STUDENT: int = 0


class SuperAdminDashboardSummary(BaseModel):
    institutions_total: int
    institutions_active: int
    users_total: int
    users_by_role: UsersByRoleSummary
    students_total: int
    tests_completed: int
    tests_in_progress: int
    reports_generated: int
    careers_active: int
    questions_active: int


class SuperAdminDashboardResponse(BaseModel):
    summary: SuperAdminDashboardSummary


class TestsByStatusSummary(BaseModel):
    STARTED: int = 0
    IN_PROGRESS: int = 0
    COMPLETED: int = 0
    CANCELLED: int = 0


class RiasecDistributionItem(BaseModel):
    profile: str
    count: int


class RecentCompletionItem(BaseModel):
    student_id: int
    student_name: str
    test_session_id: int
    finished_at: datetime | None
    dominant_profile: str | None


class InstitutionDashboardSummary(BaseModel):
    students_total: int
    students_active: int
    counselors_total: int
    tests_completed: int
    tests_in_progress: int
    tests_not_started: int
    reports_generated: int


class InstitutionDashboardResponse(BaseModel):
    institution_id: int
    institution_name: str
    summary: InstitutionDashboardSummary
    tests_by_status: TestsByStatusSummary
    riasec_distribution: list[RiasecDistributionItem]
    recent_completions: list[RecentCompletionItem]


class CounselorDashboardSummary(BaseModel):
    assigned_students: int
    tests_completed: int
    tests_in_progress: int
    pending_review: int


class StudentAttentionItem(BaseModel):
    student_id: int
    full_name: str
    test_status: TestSessionStatus | None
    test_session_id: int | None
    has_observations: bool
    has_report: bool
    has_recommendations: bool
    dominant_profile: str | None


class CounselorDashboardResponse(BaseModel):
    counselor_id: int
    summary: CounselorDashboardSummary
    students_needing_attention: list[StudentAttentionItem]


class StudentTestOverview(BaseModel):
    has_open_session: bool
    open_session: TestSessionResponse | None
    latest_completed_session_id: int | None
    status: TestSessionStatus | None


class StudentDashboardResponse(BaseModel):
    student_id: int
    profile_complete: bool
    test: StudentTestOverview
    riasec_result: RiasecResultResponse | None
    has_recommendations: bool
    recommendations_count: int
    has_report: bool
    latest_report_code: str | None
    next_actions: list[str]
