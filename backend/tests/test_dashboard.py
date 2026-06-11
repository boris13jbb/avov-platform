import uuid
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.career import Career
from app.models.student import CounselorAssignment
from app.repositories.career_repository import CareerRepository
from app.repositories.user_repository import UserRepository
from app.services.llm.llm_service import LLMResult


def _delete_career_by_id(career_id: int) -> None:
    session = SessionLocal()
    try:
        career = session.get(Career, career_id)
        if career:
            CareerRepository(session).delete(career)
    finally:
        session.close()


def _career_payload(**overrides) -> dict:
    unique = uuid.uuid4().hex[:6]
    base = {
        "name": f"Carrera Dash {unique}",
        "area": "Tecnología",
        "description": "Carrera de prueba para dashboard.",
        "riasec_profile": "IRC",
        "duration": "4 años",
        "degree_type": "INGENIERIA",
        "institution_type": "AMBAS",
        "employment_field": "Software",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


def _student_payload(institution_id: int, **overrides) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    base = {
        "institution_id": institution_id,
        "user": {
            "email": f"dash_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Laura",
            "last_name": "Dashboard",
            "phone": "0991112233",
        },
        "identification": f"ID-{unique}",
        "birth_date": "2008-05-15",
        "gender": "FEMALE",
        "grade": "10",
        "parallel": "A",
        "status": "ACTIVE",
    }
    if "user" in overrides:
        base["user"] = {**base["user"], **overrides.pop("user")}
    base.update(overrides)
    return base


def _complete_test_for_student(client: TestClient, headers: dict[str, str]) -> int:
    session = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    questions = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=headers,
    ).json()["data"]["questions"]
    for question in questions:
        client.post(
            f"/api/v1/tests/{session['id']}/answers",
            headers=headers,
            json={"question_id": question["id"], "answer_value": 3},
        )
    client.post(f"/api/v1/tests/{session['id']}/finish", headers=headers)
    return session["id"]


def _cleanup_student(student_id: int) -> None:
    from app.models.student import Student
    from app.repositories.recommendation_repository import RecommendationRepository
    from app.repositories.report_repository import ReportRepository
    from app.repositories.student_repository import StudentRepository
    from app.repositories.test_session_repository import TestSessionRepository
    from app.utils.file_storage import REPORTS_DIR

    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if not student:
            return
        test_repo = TestSessionRepository(session)
        recommendation_repo = RecommendationRepository(session)
        report_repo = ReportRepository(session)
        for test_session in student.test_sessions:
            report = report_repo.get_by_test_session(test_session.id)
            if report is not None:
                pdf_path = REPORTS_DIR / f"{report.report_code}.pdf"
                if pdf_path.exists():
                    pdf_path.unlink()
                report_repo.delete_by_test_session(test_session.id)
            recommendation_repo.delete_by_test_session(test_session.id)
            test_repo.delete_session(test_session.id)
        StudentRepository(session).delete(student)
    finally:
        session.close()


@pytest.fixture
def dashboard_student(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
    for payload in [
        _career_payload(name="Ing Software Dash", riasec_profile="IRC"),
        _career_payload(name="Medicina Dash", riasec_profile="ISA"),
    ]:
        client.post("/api/v1/careers", headers=super_admin_headers, json=payload)

    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    student_id = created.json()["data"]["id"]
    login = client.post(
        "/api/v1/auth/login",
        json={"email": payload["user"]["email"], "password": payload["user"]["password"]},
    )
    headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}
    session_id = _complete_test_for_student(client, headers)

    yield headers, session_id, student_id

    _cleanup_student(student_id)


def test_super_admin_dashboard(client: TestClient, super_admin_headers: dict[str, str]):
    response = client.get(
        "/api/v1/dashboard/super-admin",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    summary = response.json()["data"]["summary"]
    assert "institutions_total" in summary
    assert "students_total" in summary
    assert "users_by_role" in summary


def test_super_admin_dashboard_forbidden_for_student(
    client: TestClient,
    dashboard_student,
):
    headers, _session_id, _student_id = dashboard_student
    response = client.get("/api/v1/dashboard/super-admin", headers=headers)
    assert response.status_code == 403


def test_institution_admin_dashboard(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    dashboard_student,
):
    response = client.get(
        "/api/v1/dashboard/institution",
        headers=institution_admin_headers,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["institution_name"]
    assert data["summary"]["students_total"] >= 1
    assert "tests_by_status" in data


def test_counselor_dashboard(
    client: TestClient,
    db,
    super_admin_headers: dict[str, str],
    sample_institution,
    dashboard_student,
):
    _headers, _session_id, student_id = dashboard_student
    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_dash_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Dash",
        role=UserRole.COUNSELOR,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    assignment = CounselorAssignment(
        counselor_id=counselor.id,
        student_id=student_id,
        institution_id=sample_institution.id,
        status=AssignmentStatus.ACTIVE,
    )
    db.add(assignment)
    db.commit()

    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": counselor.email, "password": "Counsel1234!"},
        )
        counselor_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        response = client.get(
            "/api/v1/dashboard/counselor",
            headers=counselor_headers,
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["summary"]["assigned_students"] >= 1
        assert "students_needing_attention" in data
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_student_dashboard_completed_flow(
    mock_explain,
    client: TestClient,
    dashboard_student,
):
    mock_explain.return_value = LLMResult(answer="Resumen", source="fallback")
    headers, session_id, student_id = dashboard_student

    client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)

    response = client.get("/api/v1/dashboard/student", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["student_id"] == student_id
    assert data["test"]["status"] == "COMPLETED"
    assert data["has_recommendations"] is True
    assert data["has_report"] is True
    assert "view_results" in data["next_actions"]


def test_export_students_csv(
    client: TestClient,
    institution_admin_headers: dict[str, str],
    dashboard_student,
):
    response = client.get(
        "/api/v1/exports/students",
        headers=institution_admin_headers,
    )
    assert response.status_code == 200
    assert "text/csv" in response.headers["content-type"]
    assert "identificacion" in response.text


def test_export_test_results_csv_as_counselor(
    client: TestClient,
    db,
    super_admin_headers: dict[str, str],
    sample_institution,
    dashboard_student,
):
    _headers, _session_id, student_id = dashboard_student
    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_exp_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Export",
        role=UserRole.COUNSELOR,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    assignment = CounselorAssignment(
        counselor_id=counselor.id,
        student_id=student_id,
        institution_id=sample_institution.id,
        status=AssignmentStatus.ACTIVE,
    )
    db.add(assignment)
    db.commit()

    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": counselor.email, "password": "Counsel1234!"},
        )
        counselor_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        response = client.get(
            "/api/v1/exports/test-results",
            headers=counselor_headers,
        )
        assert response.status_code == 200
        assert "perfil_dominante" in response.text
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)
