"""S-21 / Fase 14: recomendaciones de carreras con Qdrant y fallback MySQL."""

from __future__ import annotations

import uuid
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.models.career import Career, Recommendation
from app.models.student import Student
from app.repositories.career_repository import CareerRepository
from app.repositories.test_session_repository import (
    TestSessionRepository as VocationalTestSessionRepository,
)
from app.repositories.student_repository import StudentRepository
from app.schemas.vector import CareerSearchResponse, CareerVectorMatch


def _student_payload(institution_id: int) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    return {
        "institution_id": institution_id,
        "user": {
            "email": f"rec_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Luis",
            "last_name": "Recomendado",
            "phone": "0991112244",
        },
        "identification": f"ID-{unique}",
        "birth_date": "2008-05-15",
        "gender": "MALE",
        "grade": "10",
        "parallel": "A",
        "status": "ACTIVE",
    }


def _delete_student_by_id(student_id: int) -> None:
    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student is None:
            return
        test_repo = VocationalTestSessionRepository(session)
        for test_session in list(student.test_sessions):
            session.query(Recommendation).filter(
                Recommendation.test_session_id == test_session.id
            ).delete()
            session.commit()
            test_repo.delete_session(test_session.id)
        StudentRepository(session).delete(student)
    finally:
        session.close()


def _delete_career_by_id(career_id: int) -> None:
    session = SessionLocal()
    try:
        session.query(Recommendation).filter(
            Recommendation.career_id == career_id
        ).delete()
        session.commit()
        career = session.get(Career, career_id)
        if career:
            CareerRepository(session).delete(career)
    finally:
        session.close()


def _career_payload(**overrides) -> dict:
    unique = uuid.uuid4().hex[:6]
    base = {
        "name": f"Carrera Rec {unique}",
        "area": "Tecnología",
        "description": "Carrera de prueba para recomendaciones vocacionales.",
        "riasec_profile": "RIA",
        "duration": "4 años",
        "degree_type": "INGENIERIA",
        "institution_type": "AMBAS",
        "employment_field": "TI",
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


@pytest.fixture
def rec_student(client: TestClient, super_admin_headers, sample_institution):
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
    yield headers, student_id
    _delete_student_by_id(student_id)


@pytest.fixture
def rec_careers(client: TestClient, super_admin_headers):
    ids: list[int] = []
    for payload in (
        _career_payload(name="Ing. Sistemas Rec", riasec_profile="RIA"),
        _career_payload(name="Medicina Rec", riasec_profile="ISA"),
        _career_payload(name="Diseño Rec", riasec_profile="AES"),
        _career_payload(name="Admin Rec", riasec_profile="ESC"),
        _career_payload(name="Psicología Rec", riasec_profile="SIA"),
        _career_payload(name="Contabilidad Rec", riasec_profile="CIE"),
    ):
        response = client.post(
            "/api/v1/careers",
            headers=super_admin_headers,
            json=payload,
        )
        assert response.status_code == 200
        ids.append(response.json()["data"]["id"])
    yield ids
    for career_id in ids:
        _delete_career_by_id(career_id)


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


def test_recommendations_router_is_registered():
    from app.main import app

    paths = {getattr(route, "path", "") for route in app.routes}
    assert any("/recommendations" in path for path in paths)
    openapi_paths = (app.openapi() or {}).get("paths") or {}
    assert any("recommendations" in path for path in openapi_paths)


def test_generate_recommendations_with_qdrant_path(
    client: TestClient,
    rec_student,
    rec_careers,
    super_admin_headers,
):
    headers, _student_id = rec_student
    client.post("/api/v1/vector/rebuild-careers", headers=super_admin_headers)
    session_id = _finish_session(client, headers)

    generated = client.post(
        f"/api/v1/recommendations/sessions/{session_id}/generate",
        headers=headers,
    )
    assert generated.status_code == 200
    body = generated.json()
    assert body["success"] is True
    data = body["data"]
    assert data["test_session_id"] == session_id
    assert data["total"] >= 1
    # Qdrant puede indexar otras carreras del schema; no exigir exclusividad.
    assert data["used_fallback"] is False
    assert all(0 <= item["match_percentage"] <= 100 for item in data["items"])
    assert any(item["career_id"] in rec_careers for item in data["items"])

    listed = client.get(
        f"/api/v1/recommendations/sessions/{session_id}",
        headers=headers,
    )
    assert listed.status_code == 200
    assert listed.json()["data"]["total"] == data["total"]


def test_generate_uses_mysql_fallback_when_qdrant_unavailable(
    client: TestClient,
    rec_student,
    rec_careers,
):
    headers, _student_id = rec_student
    session_id = _finish_session(client, headers)

    with patch(
        "app.services.qdrant_service.QdrantService.is_available",
        return_value=False,
    ):
        generated = client.post(
            f"/api/v1/recommendations/sessions/{session_id}/generate",
            headers=headers,
        )
    assert generated.status_code == 200
    data = generated.json()["data"]
    assert data["used_fallback"] is True
    assert data["total"] >= 1
    assert all(0 <= item["match_percentage"] <= 100 for item in data["items"])
    assert all(item.get("career_name") for item in data["items"])


def test_generate_empty_when_no_compatible_careers(
    client: TestClient,
    rec_student,
):
    headers, _student_id = rec_student
    session_id = _finish_session(client, headers)

    with patch(
        "app.services.recommendation_service.VectorService.search_careers",
        return_value=CareerSearchResponse(
            items=[],
            total=0,
            query_text="RIA",
            used_fallback=True,
        ),
    ):
        generated = client.post(
            f"/api/v1/recommendations/sessions/{session_id}/generate",
            headers=headers,
        )
    assert generated.status_code == 200
    data = generated.json()["data"]
    assert data["total"] == 0
    assert data["items"] == []


def test_student_cannot_access_other_student_recommendations(
    client: TestClient,
    rec_student,
    super_admin_headers,
    sample_institution,
    rec_careers,
):
    headers_a, _ = rec_student
    client.post("/api/v1/vector/rebuild-careers", headers=super_admin_headers)
    session_a = _finish_session(client, headers_a)
    assert (
        client.post(
            f"/api/v1/recommendations/sessions/{session_a}/generate",
            headers=headers_a,
        ).status_code
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
            f"/api/v1/recommendations/sessions/{session_a}",
            headers=headers_b,
        )
        assert forbidden.status_code == 403
    finally:
        _delete_student_by_id(student_b_id)


def test_generate_requires_completed_session(
    client: TestClient,
    rec_student,
):
    headers, _ = rec_student
    started = client.post("/api/v1/tests/start", headers=headers)
    session_id = started.json()["data"]["id"]
    response = client.post(
        f"/api/v1/recommendations/sessions/{session_id}/generate",
        headers=headers,
    )
    assert response.status_code == 422
