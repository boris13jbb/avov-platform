import uuid
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.models.career import Career
from app.repositories.career_repository import CareerRepository
from app.repositories.report_repository import ReportRepository
from app.services.llm.llm_service import LLMResult
from app.utils.file_storage import REPORTS_DIR


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
        "name": f"Carrera PDF {unique}",
        "area": "Tecnología",
        "description": "Carrera de prueba para reportes PDF.",
        "riasec_profile": "IRC",
        "duration": "4 años",
        "degree_type": "INGENIERIA",
        "institution_type": "AMBAS",
        "employment_field": "Software, sistemas, datos",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


def _student_payload(institution_id: int, **overrides) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    base = {
        "institution_id": institution_id,
        "user": {
            "email": f"pdf_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Pedro",
            "last_name": "Reportes",
            "phone": "0991112233",
        },
        "identification": f"ID-{unique}",
        "birth_date": "2008-05-15",
        "gender": "MALE",
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
    from app.repositories.student_repository import StudentRepository
    from app.repositories.test_session_repository import TestSessionRepository

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
def report_career_ids(client: TestClient, super_admin_headers: dict[str, str]):
    created_ids: list[int] = []
    payloads = [
        _career_payload(name="Ing. Software PDF", riasec_profile="IRC"),
        _career_payload(name="Medicina PDF", riasec_profile="ISA"),
        _career_payload(name="Diseño PDF", riasec_profile="AES"),
        _career_payload(name="Administración PDF", riasec_profile="ESC"),
        _career_payload(name="Enfermería PDF", riasec_profile="SIC"),
    ]
    for payload in payloads:
        response = client.post(
            "/api/v1/careers",
            headers=super_admin_headers,
            json=payload,
        )
        assert response.status_code == 200
        created_ids.append(response.json()["data"]["id"])

    yield created_ids

    for career_id in created_ids:
        _delete_career_by_id(career_id)


@pytest.fixture
def report_student(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    report_career_ids,
):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    assert created.status_code == 200
    student_id = created.json()["data"]["id"]

    login = client.post(
        "/api/v1/auth/login",
        json={"email": payload["user"]["email"], "password": payload["user"]["password"]},
    )
    headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}
    session_id = _complete_test_for_student(client, headers)

    yield headers, session_id, student_id

    _cleanup_student(student_id)


def test_download_pdf_without_recommendations(
    client: TestClient,
    report_student,
):
    headers, session_id, _student_id = report_student
    response = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=headers,
    )
    assert response.status_code == 422


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_download_pdf_success(
    mock_explain,
    client: TestClient,
    report_student,
):
    mock_explain.return_value = LLMResult(answer="Resumen IA para PDF", source="fallback")
    headers, session_id, student_id = report_student

    generate = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    assert generate.status_code == 200

    response = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=headers,
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content[:4] == b"%PDF"
    assert response.headers.get("x-report-generated") == "true"
    assert response.headers.get("x-report-code")

    second = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=headers,
    )
    assert second.status_code == 200
    assert second.headers.get("x-report-generated") == "false"

    history = client.get(
        f"/api/v1/reports/student/{student_id}",
        headers=headers,
    )
    assert history.status_code == 200
    assert len(history.json()["data"]["items"]) == 1


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_download_pdf_forbidden_for_other_student(
    mock_explain,
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    report_student,
    report_career_ids,
):
    mock_explain.return_value = LLMResult(answer="Resumen IA", source="fallback")
    headers, session_id, _student_id = report_student

    client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )

    other_payload = _student_payload(sample_institution.id)
    other_created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=other_payload,
    )
    other_id = other_created.json()["data"]["id"]
    other_login = client.post(
        "/api/v1/auth/login",
        json={
            "email": other_payload["user"]["email"],
            "password": other_payload["user"]["password"],
        },
    )
    other_headers = {
        "Authorization": f"Bearer {other_login.json()['data']['access_token']}"
    }

    try:
        response = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=other_headers,
        )
        assert response.status_code == 403
    finally:
        _cleanup_student(other_id)


def test_pdf_renderer_generates_bytes():
    from datetime import datetime, timezone

    from app.services.pdf_renderer import (
        PDFInstitutionData,
        PDFRecommendationData,
        PDFReportContext,
        PDFRiasecData,
        PDFRenderer,
        PDFStudentData,
    )

    context = PDFReportContext(
        report_code="AVOV-1-TESTCODE",
        test_finished_at=datetime.now(timezone.utc),
        institution=PDFInstitutionData(
            name="Instituto Demo",
            code="INST-001",
            city="Quito",
            province="Pichincha",
            address="Av. Demo",
            phone="0999999999",
            email="demo@instituto.edu.co",
        ),
        student=PDFStudentData(
            full_name="Ana Prueba",
            identification="ID-123",
            grade="10",
            parallel="A",
        ),
        riasec=PDFRiasecData(
            score_r=30,
            score_i=28,
            score_a=25,
            score_s=22,
            score_e=20,
            score_c=18,
            dominant_profile="R",
            secondary_profile="I",
            combined_profile="RIA",
        ),
        recommendations=[
            PDFRecommendationData(
                career_name="Ingeniería en Software",
                area="Tecnología",
                match_percentage=75.5,
                ai_explanation="Alta compatibilidad con perfil técnico.",
            )
        ],
        observations=[],
        generator_name="Ana Prueba",
        generator_role="STUDENT",
    )

    pdf_bytes = PDFRenderer().render(context)
    assert pdf_bytes[:4] == b"%PDF"
    assert len(pdf_bytes) > 500
