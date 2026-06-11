import uuid
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus, UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.career import Career
from app.models.student import CounselorAssignment
from app.repositories.career_repository import CareerRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.user_repository import UserRepository
from app.services.llm.llm_service import LLMResult
from app.services.recommendation_service import RecommendationService


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
        "name": f"Carrera Recomendación {unique}",
        "area": "Tecnología",
        "description": "Carrera de prueba para motor de recomendaciones.",
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
            "email": f"recom_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Ana",
            "last_name": "Recomendaciones",
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
    from app.repositories.student_repository import StudentRepository
    from app.repositories.test_session_repository import TestSessionRepository

    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if not student:
            return
        test_repo = TestSessionRepository(session)
        recommendation_repo = RecommendationRepository(session)
        for test_session in student.test_sessions:
            recommendation_repo.delete_by_test_session(test_session.id)
            test_repo.delete_session(test_session.id)
        StudentRepository(session).delete(student)
    finally:
        session.close()


@pytest.fixture
def recommendation_career_ids(client: TestClient, super_admin_headers: dict[str, str]):
    created_ids: list[int] = []
    payloads = [
        _career_payload(name="Ing. Software Rec", riasec_profile="IRC"),
        _career_payload(name="Medicina Rec", riasec_profile="ISA"),
        _career_payload(name="Diseño Gráfico Rec", riasec_profile="AES"),
        _career_payload(name="Administración Rec", riasec_profile="ESC"),
        _career_payload(name="Enfermería Rec", riasec_profile="SIC"),
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
def recommendation_student(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    recommendation_career_ids,
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


def test_generate_recommendations_forbidden_for_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/recommendations/generate",
        headers=super_admin_headers,
        json={},
    )
    assert response.status_code == 403


def test_generate_without_completed_test(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    recommendation_career_ids,
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

    try:
        response = client.post(
            "/api/v1/recommendations/generate",
            headers=headers,
            json={},
        )
        assert response.status_code == 422
    finally:
        _cleanup_student(student_id)


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_generate_recommendations_success(
    mock_explain,
    client: TestClient,
    recommendation_student,
):
    mock_explain.return_value = LLMResult(
        answer="Estas carreras se alinean con tu perfil vocacional actual.",
        source="fallback",
    )
    headers, session_id, student_id = recommendation_student

    response = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["test_session_id"] == session_id
    assert data["student_id"] == student_id
    assert len(data["items"]) >= RecommendationService.MIN_CAREERS
    assert data["items"][0]["match_percentage"] >= data["items"][-1]["match_percentage"]
    assert data["ethical_disclaimer"]
    assert data["items"][0]["ai_explanation"]
    assert data["ai_summary"]

    for item in data["items"]:
        assert 0 <= item["match_percentage"] <= 100
        assert item["career"]["name"]
        assert item["riasec_score"] >= 0


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_generate_recommendations_is_idempotent(
    mock_explain,
    client: TestClient,
    recommendation_student,
):
    mock_explain.return_value = LLMResult(answer="Resumen IA", source="fallback")
    headers, session_id, _student_id = recommendation_student

    first = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    second = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )

    assert first.status_code == 200
    assert second.status_code == 200
    assert len(first.json()["data"]["items"]) == len(second.json()["data"]["items"])
    assert mock_explain.call_count == 1


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_list_student_recommendations(
    mock_explain,
    client: TestClient,
    recommendation_student,
):
    mock_explain.return_value = LLMResult(answer="Resumen IA", source="fallback")
    headers, session_id, student_id = recommendation_student

    generated = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    assert generated.status_code == 200

    listed = client.get(
        f"/api/v1/recommendations/student/{student_id}",
        headers=headers,
    )
    assert listed.status_code == 200
    data = listed.json()["data"]
    assert data["student_id"] == student_id
    assert len(data["items"]) >= RecommendationService.MIN_CAREERS


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_counselor_can_add_observation(
    mock_explain,
    client: TestClient,
    db,
    super_admin_headers: dict[str, str],
    sample_institution,
    recommendation_student,
):
    mock_explain.return_value = LLMResult(answer="Resumen IA", source="fallback")
    headers, session_id, student_id = recommendation_student

    generated = client.post(
        "/api/v1/recommendations/generate",
        headers=headers,
        json={"test_session_id": session_id},
    )
    recommendation_id = generated.json()["data"]["items"][0]["id"]

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_rec_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Rec",
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

    observation_id = None
    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": counselor.email, "password": "Counsel1234!"},
        )
        counselor_headers = {
            "Authorization": f"Bearer {login.json()['data']['access_token']}"
        }

        response = client.post(
            f"/api/v1/recommendations/{recommendation_id}/observations",
            headers=counselor_headers,
            json={"observation": "El estudiante muestra buen encaje con carreras técnicas."},
        )
        assert response.status_code == 200
        data = response.json()["data"]
        observation_id = data["id"]
        assert data["test_session_id"] == session_id
        assert data["counselor_id"] == counselor.id
        assert "técnicas" in data["observation"]
    finally:
        from sqlalchemy import delete

        from app.models.counselor import CounselorObservation

        db.execute(
            delete(CounselorObservation).where(
                CounselorObservation.test_session_id == session_id
            )
        )
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)


def test_list_student_recommendations_without_generated_items(
    client: TestClient,
    recommendation_student,
):
    headers, session_id, student_id = recommendation_student

    listed = client.get(
        f"/api/v1/recommendations/student/{student_id}",
        headers=headers,
    )
    assert listed.status_code == 200
    data = listed.json()["data"]
    assert data["student_id"] == student_id
    assert data["test_session_id"] == session_id
    assert data["items"] == []


@patch(
    "app.services.recommendation_service.LLMService.explain_careers",
    new_callable=AsyncMock,
)
def test_counselor_can_add_observation_by_test_session(
    mock_explain,
    client: TestClient,
    db,
    super_admin_headers: dict[str, str],
    sample_institution,
    recommendation_student,
):
    headers, session_id, student_id = recommendation_student

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_obs_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Obs",
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

        response = client.post(
            f"/api/v1/tests/{session_id}/observations",
            headers=counselor_headers,
            json={"observation": "Seguimiento vocacional sin recomendaciones previas."},
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["test_session_id"] == session_id
        assert data["counselor_id"] == counselor.id
    finally:
        from sqlalchemy import delete

        from app.models.counselor import CounselorObservation

        db.execute(
            delete(CounselorObservation).where(
                CounselorObservation.test_session_id == session_id
            )
        )
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)


def test_hybrid_match_formula():
    hybrid = RecommendationService._compute_hybrid_match(80.0, 60.0)
    assert hybrid == 72.0
