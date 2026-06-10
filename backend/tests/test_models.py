from app.models import (
    AuditLog,
    Career,
    CounselorAssignment,
    Institution,
    Question,
    RiasecCategory,
    Student,
    User,
)
from app.models.riasec import TestSession as VocationalTestSession

EXPECTED_TABLES = {
    "institutions",
    "users",
    "students",
    "riasec_categories",
    "questions",
    "test_sessions",
    "test_answers",
    "riasec_results",
    "careers",
    "recommendations",
    "reports",
    "audit_logs",
    "counselor_assignments",
    "counselor_observations",
    "system_settings",
    "refresh_tokens",
    "password_reset_tokens",
}


def test_all_tables_registered():
    tables = set(Institution.metadata.tables.keys())
    assert EXPECTED_TABLES.issubset(tables)


def test_institution_table_columns():
    columns = {col.name for col in Institution.__table__.columns}
    assert {"id", "name", "code", "province", "city", "status", "created_at", "updated_at"}.issubset(columns)


def test_user_email_unique():
    assert User.__table__.c.email.unique is True


def test_student_identification_unique():
    assert Student.__table__.c.identification.unique is True


def test_test_session_has_student_status_index():
    index_names = {i.name for i in VocationalTestSession.__table__.indexes}
    assert "ix_test_sessions_student_status" in index_names


def test_riasec_category_code_unique():
    assert RiasecCategory.__table__.c.code.unique is True


def test_career_model_exists():
    assert Career.__tablename__ == "careers"


def test_audit_log_has_no_updated_at():
    columns = {col.name for col in AuditLog.__table__.columns}
    assert "updated_at" not in columns
    assert "created_at" in columns


def test_counselor_assignment_unique():
    unique_names = {
        c.name
        for c in CounselorAssignment.__table__.constraints
        if c.name
    }
    assert "uq_counselor_assignments" in unique_names
