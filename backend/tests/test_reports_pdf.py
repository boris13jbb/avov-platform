"""Fase 15: generación y descarga segura de informes PDF."""

from __future__ import annotations

import uuid
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.career import Recommendation
from app.models.report import Report
from app.models.student import CounselorAssignment, Student
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import (
    TestSessionRepository as VocationalTestSessionRepository,
)
from app.repositories.user_repository import UserRepository
from app.schemas.institution import InstitutionCreate
from app.utils.file_storage import get_report_blob_store, resolve_report_path


def _student_payload(institution_id: int) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    return {
        "institution_id": institution_id,
        "user": {
            "email": f"pdf_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Ana",
            "last_name": "Informe",
            "phone": "0991113344",
        },
        "identification": f"PDF-{unique}",
        "birth_date": "2008-05-15",
        "gender": "FEMALE",
        "grade": "10",
        "parallel": "B",
        "status": "ACTIVE",
    }


def _delete_reports_for_session(session_id: int) -> None:
    """Elimina informes (y archivos) de una sesión para liberar FK generated_by."""
    db = SessionLocal()
    try:
        reports = (
            db.query(Report).filter(Report.test_session_id == session_id).all()
        )
        for report in reports:
            try:
                path = resolve_report_path(Path(report.file_path).name)
                if path.is_file():
                    path.unlink()
            except ValueError:
                pass
            db.delete(report)
        db.commit()
    finally:
        db.close()


def _delete_student_by_id(student_id: int) -> None:
    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student is None:
            return
        test_repo = VocationalTestSessionRepository(session)
        for test_session in list(student.test_sessions):
            reports = (
                session.query(Report)
                .filter(Report.test_session_id == test_session.id)
                .all()
            )
            for report in reports:
                try:
                    path = resolve_report_path(Path(report.file_path).name)
                    if path.is_file():
                        path.unlink()
                except ValueError:
                    pass
            session.query(Recommendation).filter(
                Recommendation.test_session_id == test_session.id
            ).delete()
            session.query(Report).filter(
                Report.test_session_id == test_session.id
            ).delete()
            session.commit()
            test_repo.delete_session(test_session.id)
        StudentRepository(session).delete(student)
    finally:
        session.close()


def _finish_session(client: TestClient, headers: dict[str, str]) -> int:
    started = client.post("/api/v1/tests/start", headers=headers)
    assert started.status_code == 200
    session_id = started.json()["data"]["id"]
    questions = client.get(
        f"/api/v1/tests/{session_id}/questions",
        headers=headers,
    ).json()["data"]["questions"]
    for question in questions:
        assert (
            client.post(
                f"/api/v1/tests/{session_id}/answers",
                headers=headers,
                json={"question_id": question["id"], "answer_value": 4},
            ).status_code
            == 200
        )
    finished = client.post(f"/api/v1/tests/{session_id}/finish", headers=headers)
    assert finished.status_code == 200
    return session_id


@pytest.fixture
def pdf_student(client: TestClient, super_admin_headers, sample_institution):
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
        json={
            "email": payload["user"]["email"],
            "password": payload["user"]["password"],
        },
    )
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}
    yield headers, student_id, payload
    _delete_student_by_id(student_id)


@pytest.fixture
def reports_dir(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    monkeypatch.setenv("AVOV_REPORTS_BACKEND", "local")
    get_report_blob_store.cache_clear()
    yield tmp_path
    get_report_blob_store.cache_clear()


def test_reports_router_registered():
    from app.main import app

    paths = {getattr(route, "path", "") for route in app.routes}
    assert any("/reports" in path and "pdf" in path for path in paths)


def test_download_pdf_valid_and_parseable(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _student_id, payload = pdf_student
    session_id = _finish_session(client, headers)

    # Opcional: generar recomendaciones (no obligatorio para PDF).
    client.post(
        f"/api/v1/recommendations/sessions/{session_id}/generate",
        headers=headers,
    )

    response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/pdf")
    body = response.content
    assert body.startswith(b"%PDF-")
    assert b"%%EOF" in body[-2048:]
    assert "X-Report-Code" in response.headers
    code = response.headers["X-Report-Code"]
    assert code.startswith("AVOV-S")

    # Parser compatible: pypdf si está instalado; si no, firma + texto embebido.
    try:
        from pypdf import PdfReader
        from io import BytesIO

        reader = PdfReader(BytesIO(body))
        assert len(reader.pages) >= 1
        text = "\n".join((page.extract_text() or "") for page in reader.pages)
        assert "AVOV" in text or "Informe" in text or "RIASEC" in text
        assert payload["user"]["first_name"] in text or "Informe" in text
    except ImportError:
        # Sin pypdf: al menos firma válida y tamaño razonable.
        assert len(body) > 500

    # Idempotencia: segunda descarga reutiliza el mismo código.
    second = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert second.status_code == 200
    assert second.headers["X-Report-Code"] == code
    assert second.content.startswith(b"%PDF-")

    # No altera estado de la sesión ni inventa recomendaciones forzadas aquí.
    status = client.get(f"/api/v1/tests/{session_id}", headers=headers)
    # Algunos contratos no exponen GET /tests/{id}; usar historial.
    history = client.get("/api/v1/tests", headers=headers)
    assert history.status_code == 200
    items = history.json()["data"]["items"]
    match = next(i for i in items if i["id"] == session_id)
    assert match["status"] == "COMPLETED"


def test_pdf_requires_auth(client: TestClient, pdf_student, reports_dir):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    response = client.get(f"/api/v1/reports/{session_id}/pdf")
    assert response.status_code == 401


def test_pdf_rejects_incomplete_session(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    started = client.post("/api/v1/tests/start", headers=headers)
    session_id = started.json()["data"]["id"]
    response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 422


def test_pdf_not_found_session(client: TestClient, pdf_student, reports_dir):
    headers, _, _ = pdf_student
    response = client.get("/api/v1/reports/999999991/pdf", headers=headers)
    assert response.status_code in (403, 404)


def test_student_cannot_download_other_student_pdf(
    client: TestClient,
    pdf_student,
    super_admin_headers,
    sample_institution,
    reports_dir,
):
    headers_a, _, _ = pdf_student
    session_a = _finish_session(client, headers_a)
    assert (
        client.get(f"/api/v1/reports/{session_a}/pdf", headers=headers_a).status_code
        == 200
    )

    payload_b = _student_payload(sample_institution.id)
    created_b = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload_b,
    )
    assert created_b.status_code == 200
    student_b_id = created_b.json()["data"]["id"]
    try:
        login_b = client.post(
            "/api/v1/auth/login",
            json={
                "email": payload_b["user"]["email"],
                "password": payload_b["user"]["password"],
            },
        )
        headers_b = {
            "Authorization": f"Bearer {login_b.json()['data']['access_token']}"
        }
        forbidden = client.get(
            f"/api/v1/reports/{session_a}/pdf",
            headers=headers_b,
        )
        assert forbidden.status_code == 403
    finally:
        _delete_student_by_id(student_b_id)


def test_missing_file_regenerates(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    first = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert first.status_code == 200
    code = first.headers["X-Report-Code"]
    path = resolve_report_path(f"{code}.pdf")
    assert path.is_file()
    path.unlink()
    assert not path.is_file()

    second = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert second.status_code == 200
    assert second.headers["X-Report-Code"] == code
    assert second.content.startswith(b"%PDF-")
    assert path.is_file()


def test_storage_write_failure(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    with patch(
        "app.utils.file_storage.LocalReportBlobStore.write_bytes",
        side_effect=OSError("disco lleno"),
    ):
        response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 422


def test_audit_failure_after_create(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    with patch(
        "app.repositories.audit_repository.AuditRepository.create",
        side_effect=RuntimeError("audit down"),
    ):
        response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 422


def test_pdf_without_external_ai(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    with patch(
        "app.services.llm.llm_service.LLMService",
        side_effect=AssertionError("no debe llamarse IA"),
    ):
        response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 200
    assert response.content.startswith(b"%PDF-")


def test_download_does_not_call_recommendation_generate(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, _, _ = pdf_student
    session_id = _finish_session(client, headers)
    with patch(
        "app.services.recommendation_service.RecommendationService.generate_for_session",
        side_effect=AssertionError("no generar recomendaciones"),
    ):
        response = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert response.status_code == 200


def _assert_denied_pdf(response) -> None:
    """Denegación sin filtrar PDF, rutas ni datos del estudiante."""
    assert response.status_code == 403
    body = response.content
    assert not body.startswith(b"%PDF-")
    text = body.decode("utf-8", errors="ignore").lower()
    assert "storage" not in text
    assert "reports_dir" not in text
    assert "../" not in text
    assert "c:\\" not in text
    assert "/var/" not in text


def test_institution_admin_can_download_own_institution_pdf(
    client: TestClient,
    pdf_student,
    institution_admin_headers,
    reports_dir,
):
    student_headers, _, payload = pdf_student
    session_id = _finish_session(client, student_headers)
    # El estudiante genera el registro (generated_by) para no bloquear el teardown del admin.
    seeded = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=student_headers,
    )
    assert seeded.status_code == 200

    allowed = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=institution_admin_headers,
    )
    assert allowed.status_code == 200
    assert allowed.headers["content-type"].startswith("application/pdf")
    assert allowed.content.startswith(b"%PDF-")
    assert allowed.headers["X-Report-Code"] == seeded.headers["X-Report-Code"]
    # El admin autorizado recibe el informe con datos del estudiante de su institución.
    assert (
        payload["user"]["first_name"].encode() in allowed.content
        or b"Informe" in allowed.content
    )


def test_institution_admin_denied_other_institution_pdf(
    client: TestClient,
    db,
    super_admin_headers,
    institution_admin_headers,
    sample_institution,
    reports_dir,
):
    """Admin de institución A no descarga PDF de estudiante en institución B."""
    inst_repo = InstitutionRepository(db)
    other_institution = inst_repo.create(
        InstitutionCreate(
            name="Institución Externa PDF",
            code=f"EXT-{uuid.uuid4().hex[:6].upper()}",
            province="Guayas",
            city="Guayaquil",
        )
    )
    other_student_id = None
    try:
        payload = _student_payload(other_institution.id)
        created = client.post(
            "/api/v1/students",
            headers=super_admin_headers,
            json=payload,
        )
        assert created.status_code == 200
        other_student_id = created.json()["data"]["id"]
        login = client.post(
            "/api/v1/auth/login",
            json={
                "email": payload["user"]["email"],
                "password": payload["user"]["password"],
            },
        )
        assert login.status_code == 200
        other_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        session_id = _finish_session(client, other_headers)

        # Control: el propio estudiante sí puede descargar.
        own = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=other_headers,
        )
        assert own.status_code == 200
        assert own.content.startswith(b"%PDF-")

        denied = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=institution_admin_headers,
        )
        _assert_denied_pdf(denied)
        denied_text = denied.content.decode("utf-8", errors="ignore")
        assert payload["user"]["first_name"] not in denied_text
        assert payload["identification"] not in denied_text
        assert payload["user"]["email"] not in denied_text

        # Si se elude la autorización, la descarga pasaría: este assert demuestra
        # que el 403 depende de _ensure_can_view_result.
        with patch(
            "app.services.test_session_service.TestSessionService._ensure_can_view_result",
            return_value=None,
        ):
            bypassed = client.get(
                f"/api/v1/reports/{session_id}/pdf",
                headers=institution_admin_headers,
            )
        assert bypassed.status_code == 200
        assert bypassed.content.startswith(b"%PDF-")
        # Liberar FK generated_by del admin de muestra antes del teardown del fixture.
        _delete_reports_for_session(session_id)
    finally:
        if other_student_id is not None:
            _delete_student_by_id(other_student_id)
        inst_repo.delete(other_institution)


def test_counselor_can_download_assigned_student_pdf(
    client: TestClient,
    db,
    pdf_student,
    sample_institution,
    reports_dir,
):
    student_headers, student_id, _ = pdf_student
    session_id = _finish_session(client, student_headers)
    seeded = client.get(
        f"/api/v1/reports/{session_id}/pdf",
        headers=student_headers,
    )
    assert seeded.status_code == 200

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_pdf_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="PDF",
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
        assert login.status_code == 200
        counselor_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        allowed = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=counselor_headers,
        )
        assert allowed.status_code == 200
        assert allowed.content.startswith(b"%PDF-")
        assert allowed.headers["X-Report-Code"] == seeded.headers["X-Report-Code"]
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)


def test_counselor_denied_without_assignment_pdf(
    client: TestClient,
    db,
    super_admin_headers,
    pdf_student,
    sample_institution,
    reports_dir,
):
    """COUNSELOR sin CounselorAssignment ACTIVE no descarga el PDF."""
    student_headers, _, payload = pdf_student
    session_id = _finish_session(client, student_headers)

    # Segundo estudiante sin relación con el orientador (misma institución).
    other_payload = _student_payload(sample_institution.id)
    created_other = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=other_payload,
    )
    assert created_other.status_code == 200
    other_student_id = created_other.json()["data"]["id"]

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_deny_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="SinAsignacion",
        role=UserRole.COUNSELOR,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    # Asignación solo al otro estudiante: la sesión del pdf_student queda sin vínculo.
    assignment = CounselorAssignment(
        counselor_id=counselor.id,
        student_id=other_student_id,
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
        assert login.status_code == 200
        counselor_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        denied = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=counselor_headers,
        )
        _assert_denied_pdf(denied)
        denied_text = denied.content.decode("utf-8", errors="ignore")
        assert payload["user"]["first_name"] not in denied_text
        assert payload["identification"] not in denied_text

        with patch(
            "app.services.test_session_service.TestSessionService._ensure_can_view_result",
            return_value=None,
        ):
            bypassed = client.get(
                f"/api/v1/reports/{session_id}/pdf",
                headers=counselor_headers,
            )
        assert bypassed.status_code == 200
        assert bypassed.content.startswith(b"%PDF-")
        _delete_reports_for_session(session_id)
    finally:
        _delete_reports_for_session(session_id)
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)
        _delete_student_by_id(other_student_id)
