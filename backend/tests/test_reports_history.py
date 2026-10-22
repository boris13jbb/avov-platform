"""Fase 16A: historial GET /reports/student/{student_id}."""

from __future__ import annotations

import uuid

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.report import Report
from app.models.student import CounselorAssignment
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.user_repository import UserRepository
from app.schemas.institution import InstitutionCreate
from tests.test_reports_pdf import (
    _delete_student_by_id,
    _finish_session,
    _student_payload,
)


def _history_url(student_id: int, *, page: int = 1, page_size: int = 20) -> str:
    return f"/api/v1/reports/student/{student_id}?page={page}&page_size={page_size}"


def _assert_no_storage_leak(payload) -> None:
    raw = str(payload).lower()
    assert "file_path" not in raw
    assert "storage" not in raw
    assert "reports_dir" not in raw
    assert "c:\\" not in raw
    assert "/var/" not in raw


@pytest.fixture
def reports_dir(tmp_path, monkeypatch):
    monkeypatch.setenv("AVOV_REPORTS_DIR", str(tmp_path))
    return tmp_path


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


def test_history_empty(client: TestClient, pdf_student, reports_dir):
    headers, student_id, _ = pdf_student
    response = client.get(_history_url(student_id), headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["items"] == []
    assert data["total"] == 0
    assert data["page"] == 1
    assert data["pages"] == 0
    _assert_no_storage_leak(data)


def test_history_multiple_reports_ordered(client: TestClient, pdf_student, reports_dir):
    headers, student_id, _ = pdf_student
    session_a = _finish_session(client, headers)
    pdf_a = client.get(f"/api/v1/reports/{session_a}/pdf", headers=headers)
    assert pdf_a.status_code == 200
    code_a = pdf_a.headers["X-Report-Code"]

    session_b = _finish_session(client, headers)
    pdf_b = client.get(f"/api/v1/reports/{session_b}/pdf", headers=headers)
    assert pdf_b.status_code == 200
    code_b = pdf_b.headers["X-Report-Code"]

    response = client.get(_history_url(student_id), headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total"] == 2
    assert len(data["items"]) == 2
    items = data["items"]
    assert items[0]["report_code"] == code_b
    assert items[1]["report_code"] == code_a
    assert items[0]["test_session_id"] == session_b
    assert items[1]["test_session_id"] == session_a
    assert items[0]["id"] > items[1]["id"]
    for item in items:
        assert set(item.keys()) == {
            "id",
            "student_id",
            "test_session_id",
            "report_code",
            "generated_by",
            "created_at",
            "updated_at",
        }
        assert item["student_id"] == student_id
    _assert_no_storage_leak(data)


def test_history_student_not_found(client: TestClient, super_admin_headers):
    response = client.get(_history_url(9_999_999_001), headers=super_admin_headers)
    assert response.status_code == 404


def test_history_unauthenticated(client: TestClient):
    response = client.get(_history_url(1))
    assert response.status_code in (401, 403)


def test_history_own_student_allowed(client: TestClient, pdf_student, reports_dir):
    headers, student_id, _ = pdf_student
    session_id = _finish_session(client, headers)
    assert (
        client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers).status_code
        == 200
    )
    response = client.get(_history_url(student_id), headers=headers)
    assert response.status_code == 200
    assert response.json()["data"]["total"] == 1


def test_history_denied_other_student(
    client: TestClient,
    pdf_student,
    super_admin_headers,
    sample_institution,
    reports_dir,
):
    headers_a, student_a, _ = pdf_student
    payload_b = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload_b,
    )
    assert created.status_code == 200
    student_b = created.json()["data"]["id"]
    try:
        login = client.post(
            "/api/v1/auth/login",
            json={
                "email": payload_b["user"]["email"],
                "password": payload_b["user"]["password"],
            },
        )
        assert login.status_code == 200
        headers_b = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        denied = client.get(_history_url(student_a), headers=headers_b)
        assert denied.status_code == 403
        _assert_no_storage_leak(denied.json())
    finally:
        _delete_student_by_id(student_b)


def test_history_institution_admin_own_institution(
    client: TestClient,
    pdf_student,
    institution_admin_headers,
    reports_dir,
):
    student_headers, student_id, _ = pdf_student
    session_id = _finish_session(client, student_headers)
    assert (
        client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=student_headers,
        ).status_code
        == 200
    )
    response = client.get(
        _history_url(student_id),
        headers=institution_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["total"] == 1
    _assert_no_storage_leak(response.json()["data"])


def test_history_institution_admin_other_institution_denied(
    client: TestClient,
    db,
    super_admin_headers,
    institution_admin_headers,
    reports_dir,
):
    inst_repo = InstitutionRepository(db)
    other = inst_repo.create(
        InstitutionCreate(
            name="Institución Historial Externa",
            code=f"HX-{uuid.uuid4().hex[:6].upper()}",
            province="Pichincha",
            city="Quito",
        )
    )
    other_student_id = None
    try:
        payload = _student_payload(other.id)
        created = client.post(
            "/api/v1/students",
            headers=super_admin_headers,
            json=payload,
        )
        assert created.status_code == 200
        other_student_id = created.json()["data"]["id"]
        denied = client.get(
            _history_url(other_student_id),
            headers=institution_admin_headers,
        )
        assert denied.status_code == 403
        _assert_no_storage_leak(denied.json())
    finally:
        if other_student_id is not None:
            _delete_student_by_id(other_student_id)
        inst_repo.delete(other)


def test_history_counselor_assigned_allowed(
    client: TestClient,
    db,
    pdf_student,
    sample_institution,
    reports_dir,
):
    student_headers, student_id, _ = pdf_student
    session_id = _finish_session(client, student_headers)
    assert (
        client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=student_headers,
        ).status_code
        == 200
    )

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"hist_c_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Historial",
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
        response = client.get(_history_url(student_id), headers=counselor_headers)
        assert response.status_code == 200
        assert response.json()["data"]["total"] == 1
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)


def test_history_counselor_unassigned_denied(
    client: TestClient,
    db,
    pdf_student,
    sample_institution,
    reports_dir,
):
    _, student_id, _ = pdf_student
    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"hist_c2_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="SinAsignacion",
        role=UserRole.COUNSELOR,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    db.commit()
    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": counselor.email, "password": "Counsel1234!"},
        )
        assert login.status_code == 200
        headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }
        denied = client.get(_history_url(student_id), headers=headers)
        assert denied.status_code == 403
        _assert_no_storage_leak(denied.json())
    finally:
        user_repo.delete(counselor)


def test_history_super_admin_allowed(
    client: TestClient,
    pdf_student,
    super_admin_headers,
    reports_dir,
):
    student_headers, student_id, _ = pdf_student
    session_id = _finish_session(client, student_headers)
    assert (
        client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=student_headers,
        ).status_code
        == 200
    )
    response = client.get(
        _history_url(student_id),
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["total"] == 1


def test_history_route_not_confused_with_session_pdf(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, student_id, _ = pdf_student
    response = client.get(_history_url(student_id), headers=headers)
    assert response.status_code == 200
    assert response.headers.get("content-type", "").startswith("application/json")


def test_history_multiple_reports_same_session(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    """El modelo permite varios Report por sesión; el historial lista ambos.

    No afirma que cada fila descargue un PDF histórico distinto: la descarga
    de Fase 15 sigue resolviendo por test_session_id (último informe).

    Usa SessionLocal propia para ver commits del TestClient (el fixture ``db``
    puede quedar en una transacción REPEATABLE READ iniciada antes).
    """
    headers, student_id, _ = pdf_student
    session_id = _finish_session(client, headers)
    pdf = client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers)
    assert pdf.status_code == 200
    code_first = pdf.headers["X-Report-Code"]

    aux = SessionLocal()
    try:
        existing = ReportRepository(aux).get_latest_for_session(session_id)
        assert existing is not None
        assert existing.report_code == code_first
        code_second = f"AVOV-S{session_id}-DUP{uuid.uuid4().hex[:6].upper()}"
        ReportRepository(aux).create(
            Report(
                student_id=student_id,
                test_session_id=session_id,
                file_path=f"{code_second}.pdf",
                report_code=code_second,
                generated_by=existing.generated_by,
            )
        )
    finally:
        aux.close()

    response = client.get(_history_url(student_id), headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total"] == 2
    items = data["items"]
    assert len(items) == 2
    assert {item["test_session_id"] for item in items} == {session_id}
    codes = {item["report_code"] for item in items}
    assert codes == {code_first, code_second}
    assert items[0]["id"] > items[1]["id"]
    assert {items[0]["report_code"], items[1]["report_code"]} == codes
    _assert_no_storage_leak(data)


def test_history_pagination_second_page_and_page_size_limit(
    client: TestClient,
    pdf_student,
    reports_dir,
):
    headers, student_id, _ = pdf_student
    for _ in range(3):
        session_id = _finish_session(client, headers)
        assert (
            client.get(f"/api/v1/reports/{session_id}/pdf", headers=headers).status_code
            == 200
        )

    page1 = client.get(_history_url(student_id, page=1, page_size=2), headers=headers)
    assert page1.status_code == 200
    data1 = page1.json()["data"]
    assert data1["total"] == 3
    assert data1["page"] == 1
    assert data1["page_size"] == 2
    assert data1["pages"] == 2
    assert len(data1["items"]) == 2
    ids_page1 = [item["id"] for item in data1["items"]]
    assert ids_page1[0] > ids_page1[1]

    page2 = client.get(_history_url(student_id, page=2, page_size=2), headers=headers)
    assert page2.status_code == 200
    data2 = page2.json()["data"]
    assert data2["total"] == 3
    assert data2["page"] == 2
    assert data2["page_size"] == 2
    assert data2["pages"] == 2
    assert len(data2["items"]) == 1
    ids_page2 = [item["id"] for item in data2["items"]]
    assert set(ids_page1).isdisjoint(ids_page2)
    assert max(ids_page2) < min(ids_page1)

    ok_max = client.get(
        _history_url(student_id, page=1, page_size=100),
        headers=headers,
    )
    assert ok_max.status_code == 200
    assert ok_max.json()["data"]["page_size"] == 100
    assert ok_max.json()["data"]["total"] == 3

    too_large = client.get(
        _history_url(student_id, page=1, page_size=101),
        headers=headers,
    )
    assert too_large.status_code == 422
    _assert_no_storage_leak(data1)
    _assert_no_storage_leak(data2)


def test_history_counselor_inactive_assignment_denied(
    client: TestClient,
    db,
    pdf_student,
    sample_institution,
    reports_dir,
):
    student_headers, student_id, _ = pdf_student
    session_id = _finish_session(client, student_headers)
    assert (
        client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=student_headers,
        ).status_code
        == 200
    )

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"hist_c_inact_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Inactivo",
        role=UserRole.COUNSELOR,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    assignment = CounselorAssignment(
        counselor_id=counselor.id,
        student_id=student_id,
        institution_id=sample_institution.id,
        status=AssignmentStatus.INACTIVE,
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
        denied_history = client.get(
            _history_url(student_id),
            headers=counselor_headers,
        )
        assert denied_history.status_code == 403
        _assert_no_storage_leak(denied_history.json())

        denied_pdf = client.get(
            f"/api/v1/reports/{session_id}/pdf",
            headers=counselor_headers,
        )
        assert denied_pdf.status_code == 403
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)
