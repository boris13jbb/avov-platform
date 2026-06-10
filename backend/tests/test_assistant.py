import uuid
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.models.career import Career
from app.repositories.career_repository import CareerRepository


def _delete_career_by_id(career_id: int) -> None:
    session = SessionLocal()
    try:
        career = session.get(Career, career_id)
        if career:
            CareerRepository(session).delete(career)
    finally:
        session.close()


def _student_payload(institution_id: int, **overrides) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    base = {
        "institution_id": institution_id,
        "user": {
            "email": f"asistente_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Luis",
            "last_name": "Asistente",
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


@pytest.fixture
def assistant_student(client: TestClient, super_admin_headers: dict[str, str], sample_institution):
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

    from app.models.student import Student
    from app.repositories.student_repository import StudentRepository
    from app.repositories.test_session_repository import (
        TestSessionRepository as VocationalTestSessionRepository,
    )

    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student:
            test_repo = VocationalTestSessionRepository(session)
            for test_session in student.test_sessions:
                test_repo.delete_session(test_session.id)
            StudentRepository(session).delete(student)
    finally:
        session.close()


def test_assistant_chat_forbidden_for_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/assistant/chat",
        headers=super_admin_headers,
        json={"message": "¿Qué carrera me recomiendas?"},
    )
    assert response.status_code == 403


def test_assistant_chat_as_student_fallback(client: TestClient, assistant_student):
    headers, session_id, _student_id = assistant_student
    response = client.post(
        "/api/v1/assistant/chat",
        headers=headers,
        json={
            "message": "¿Qué significa mi perfil vocacional?",
            "test_session_id": session_id,
        },
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["answer"]
    assert data["source"] in {"deepseek", "fallback"}
    assert "orientación profesional" in data["ethical_disclaimer"].lower()


def test_explain_profile_as_student(client: TestClient, assistant_student):
    headers, session_id, _student_id = assistant_student
    response = client.post(
        "/api/v1/assistant/explain-profile",
        headers=headers,
        json={"test_session_id": session_id},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["answer"]
    assert data["source"] in {"deepseek", "fallback"}


def test_explain_profile_without_completed_test(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
):
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

    response = client.post(
        "/api/v1/assistant/explain-profile",
        headers=headers,
        json={},
    )
    assert response.status_code == 422

    from app.models.student import Student
    from app.repositories.student_repository import StudentRepository

    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student:
            StudentRepository(session).delete(student)
    finally:
        session.close()


def test_explain_careers_as_student(
    client: TestClient,
    super_admin_headers: dict[str, str],
    assistant_student,
):
    headers, _session_id, _student_id = assistant_student
    career_payload = {
        "name": f"Carrera Asistente {uuid.uuid4().hex[:6]}",
        "area": "Tecnología",
        "description": "Carrera orientada al desarrollo de software y sistemas informáticos.",
        "riasec_profile": "IRC",
        "duration": "4 años",
        "degree_type": "INGENIERIA",
        "institution_type": "AMBAS",
        "employment_field": "Desarrollo de software",
        "status": "ACTIVE",
    }
    created = client.post(
        "/api/v1/careers",
        headers=super_admin_headers,
        json=career_payload,
    )
    career_id = created.json()["data"]["id"]

    response = client.post(
        "/api/v1/assistant/explain-careers",
        headers=headers,
        json={"career_ids": [career_id]},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert career_payload["name"] in data["answer"] or data["source"] == "deepseek"
    _delete_career_by_id(career_id)


@patch(
    "app.services.llm.llm_service.LLMService._complete",
    new_callable=AsyncMock,
    return_value="Explicación generada por DeepSeek para pruebas automatizadas.",
)
def test_explain_profile_uses_deepseek_when_available(
    mock_complete,
    client: TestClient,
    assistant_student,
):
    headers, session_id, _student_id = assistant_student
    response = client.post(
        "/api/v1/assistant/explain-profile",
        headers=headers,
        json={"test_session_id": session_id},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["source"] == "deepseek"
    assert "DeepSeek" in data["answer"]
    mock_complete.assert_awaited()
