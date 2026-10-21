import uuid
from datetime import date
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.core.enums import AssignmentStatus, UserRole
from app.services.riasec_calculator import TIE_BREAK_ORDER
from app.db.session import SessionLocal
from app.models.student import CounselorAssignment, Student
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import (
    TestSessionRepository as VocationalTestSessionRepository,
)
from app.repositories.user_repository import UserRepository
from app.services.riasec_calculator import calculate_riasec


def _student_payload(institution_id: int, **overrides) -> dict:
    unique = uuid.uuid4().hex[:8].upper()
    base = {
        "institution_id": institution_id,
        "user": {
            "email": f"estudiante_{unique.lower()}@instituto.edu.co",
            "password": "Estud1234!",
            "first_name": "Ana",
            "last_name": "Vocacional",
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


def _delete_student_by_id(student_id: int) -> None:
    session = SessionLocal()
    try:
        student = session.get(Student, student_id)
        if student is None:
            return

        test_repo = VocationalTestSessionRepository(session)
        for test_session in student.test_sessions:
            test_repo.delete_session(test_session.id)

        StudentRepository(session).delete(student)
    finally:
        session.close()


@pytest.fixture
def student_headers(client: TestClient, super_admin_headers: dict[str, str], sample_institution):
    payload = _student_payload(sample_institution.id)
    created = client.post(
        "/api/v1/students",
        headers=super_admin_headers,
        json=payload,
    )
    assert created.status_code == 200
    student_id = created.json()["data"]["id"]
    email = payload["user"]["email"]
    password = payload["user"]["password"]

    login = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login.status_code == 200
    token = login.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    yield headers, student_id
    _delete_student_by_id(student_id)


def test_start_test_forbidden_for_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.post("/api/v1/tests/start", headers=super_admin_headers)
    assert response.status_code == 403


def test_start_test_creates_session(client: TestClient, student_headers):
    headers, _student_id = student_headers
    response = client.post("/api/v1/tests/start", headers=headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total_questions"] >= 60
    assert data["answered_count"] == 0


def test_start_test_returns_existing_open_session(client: TestClient, student_headers):
    headers, _student_id = student_headers
    first = client.post("/api/v1/tests/start", headers=headers)
    second = client.post("/api/v1/tests/start", headers=headers)
    assert first.json()["data"]["id"] == second.json()["data"]["id"]


def test_session_history_does_not_create_sessions(client: TestClient, student_headers):
    headers, _student_id = student_headers
    empty = client.get("/api/v1/tests", headers=headers)
    assert empty.status_code == 200
    assert empty.json()["data"]["total"] == 0

    started = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    listed = client.get("/api/v1/tests", headers=headers)
    assert listed.status_code == 200
    body = listed.json()["data"]
    assert body["total"] == 1
    assert body["items"][0]["id"] == started["id"]
    assert "answer_value" not in listed.text

    again = client.get("/api/v1/tests", headers=headers)
    assert again.json()["data"]["total"] == 1


def test_open_session_keeps_answers_when_resumed(client: TestClient, student_headers):
    headers, _student_id = student_headers
    session = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    question_id = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=headers,
    ).json()["data"]["questions"][0]["id"]
    saved = client.post(
        f"/api/v1/tests/{session['id']}/answers",
        headers=headers,
        json={"question_id": question_id, "answer_value": 4},
    )
    assert saved.status_code == 200

    resumed = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    assert resumed["id"] == session["id"]
    questions = client.get(
        f"/api/v1/tests/{resumed['id']}/questions",
        headers=headers,
    ).json()["data"]["questions"]
    saved_question = next(item for item in questions if item["id"] == question_id)
    assert saved_question["answer_value"] == 4


def test_completed_session_stays_in_history(client: TestClient, student_headers):
    headers, _student_id = student_headers
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
    finished = client.post(f"/api/v1/tests/{session['id']}/finish", headers=headers)
    assert finished.status_code == 200

    restarted = client.post("/api/v1/tests/start", headers=headers)
    assert restarted.status_code == 200
    assert restarted.json()["data"]["id"] != session["id"]

    history = client.get("/api/v1/tests?page_size=20", headers=headers).json()["data"]
    statuses = {item["id"]: item["status"] for item in history["items"]}
    assert statuses[session["id"]] == "COMPLETED"
    assert statuses[restarted.json()["data"]["id"]] == "STARTED"


def test_student_cannot_read_another_students_result(
    client: TestClient,
    super_admin_headers: dict[str, str],
    sample_institution,
    student_headers,
):
    owner_headers, _owner_id = student_headers
    owner_session = client.post("/api/v1/tests/start", headers=owner_headers).json()["data"]
    questions = client.get(
        f"/api/v1/tests/{owner_session['id']}/questions",
        headers=owner_headers,
    ).json()["data"]["questions"]
    for question in questions:
        client.post(
            f"/api/v1/tests/{owner_session['id']}/answers",
            headers=owner_headers,
            json={"question_id": question["id"], "answer_value": 5},
        )
    client.post(f"/api/v1/tests/{owner_session['id']}/finish", headers=owner_headers)

    other = _student_payload(sample_institution.id)
    created = client.post("/api/v1/students", headers=super_admin_headers, json=other)
    other_id = created.json()["data"]["id"]
    try:
        login = client.post(
            "/api/v1/auth/login",
            json={"email": other["user"]["email"], "password": other["user"]["password"]},
        )
        other_headers = {"Authorization": f"Bearer {login.json()['data']['access_token']}"}
        foreign = client.get(
            f"/api/v1/tests/{owner_session['id']}/result",
            headers=other_headers,
        )
        assert foreign.status_code == 403
        assert "score_r" not in foreign.text
        own_history = client.get("/api/v1/tests", headers=other_headers).json()["data"]
        assert all(item["id"] != owner_session["id"] for item in own_history["items"])
    finally:
        _delete_student_by_id(other_id)


def test_start_does_not_choose_among_multiple_open_sessions(
    client: TestClient,
    student_headers,
):
    headers, student_id = student_headers
    repo = VocationalTestSessionRepository(SessionLocal())
    first = None
    second = None
    try:
        first = repo.create_session(student_id, 60)
        second = repo.create_session(student_id, 60)
        response = client.post("/api/v1/tests/start", headers=headers)
        assert response.status_code == 422
        assert "más de una evaluación" in response.json()["message"]
        listed = client.get("/api/v1/tests", headers=headers).json()["data"]
        ids = {item["id"] for item in listed["items"]}
        assert ids == {first.id, second.id}
    finally:
        if first is not None:
            repo.delete_session(first.id)
        if second is not None:
            repo.delete_session(second.id)
        repo.db.close()


def test_history_without_student_profile_does_not_create_data(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/tests", headers=auth_headers)
    assert response.status_code == 404
    assert response.json()["message"] == "No tienes una ficha de estudiante registrada"


def test_concurrent_start_keeps_a_single_open_session(client: TestClient, student_headers):
    from concurrent.futures import ThreadPoolExecutor

    from app.services.test_session_service import TestSessionService

    headers, student_id = student_headers

    def start_in_own_session(_: int) -> int:
        db = SessionLocal()
        try:
            student = db.get(Student, student_id)
            assert student is not None
            return TestSessionService(db).start_test(student.user).id
        finally:
            db.close()

    with ThreadPoolExecutor(max_workers=2) as pool:
        session_ids = list(pool.map(start_in_own_session, (1, 2)))

    assert session_ids[0] == session_ids[1]
    history = client.get("/api/v1/tests", headers=headers).json()["data"]
    assert history["total"] == 1


def test_get_session_questions(client: TestClient, student_headers):
    headers, _student_id = student_headers
    session = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    response = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data["questions"]) == session["total_questions"]
    assert data["session"]["id"] == session["id"]


def test_save_answer_updates_progress(client: TestClient, student_headers):
    headers, _student_id = student_headers
    session = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    questions = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=headers,
    ).json()["data"]["questions"]
    question_id = questions[0]["id"]

    response = client.post(
        f"/api/v1/tests/{session['id']}/answers",
        headers=headers,
        json={"question_id": question_id, "answer_value": 4},
    )
    assert response.status_code == 200
    assert response.json()["data"]["answer_value"] == 4

    session_data = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=headers,
    ).json()["data"]["session"]
    assert session_data["answered_count"] == 1
    assert session_data["status"] == "IN_PROGRESS"


def test_finish_test_requires_all_answers(client: TestClient, student_headers):
    headers, _student_id = student_headers
    session = client.post("/api/v1/tests/start", headers=headers).json()["data"]
    response = client.post(
        f"/api/v1/tests/{session['id']}/finish",
        headers=headers,
    )
    assert response.status_code == 422


def test_finish_test_calculates_riasec(client: TestClient, student_headers):
    headers, _student_id = student_headers
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

    finish = client.post(
        f"/api/v1/tests/{session['id']}/finish",
        headers=headers,
    )
    assert finish.status_code == 200
    result = finish.json()["data"]

    from collections import Counter

    category_counts = Counter(
        question["category"]["code"] for question in questions
    )
    for code, count in category_counts.items():
        assert result[f"score_{code.lower()}"] == count * 3

    scores = {code: count * 3 for code, count in category_counts.items()}
    ranked = sorted(
        scores.keys(),
        key=lambda code: (-scores[code], TIE_BREAK_ORDER.index(code)),
    )
    top_code = ranked[0]
    assert result["dominant_profile"] == top_code
    assert len(result["combined_profile"]) == 3

    get_result = client.get(
        f"/api/v1/tests/{session['id']}/result",
        headers=headers,
    )
    assert get_result.status_code == 200
    assert get_result.json()["data"]["dominant_profile"] == top_code


def test_cannot_save_answer_on_completed_test(client: TestClient, student_headers):
    headers, _student_id = student_headers
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

    response = client.post(
        f"/api/v1/tests/{session['id']}/answers",
        headers=headers,
        json={"question_id": questions[0]["id"], "answer_value": 5},
    )
    assert response.status_code == 422


def test_riasec_tie_break_prefers_r_over_i():
    answers = []
    for code in ("R", "I"):
        for index in range(10):
            answers.append(
                SimpleNamespace(
                    answer_value=3,
                    question=SimpleNamespace(category=SimpleNamespace(code=code)),
                )
            )

    result = calculate_riasec(answers)
    assert result.score_r == 30
    assert result.score_i == 30
    assert result.dominant_profile == "R"
    assert result.secondary_profile == "I"


def test_counselor_can_view_student_result(
    client: TestClient,
    db,
    super_admin_headers: dict[str, str],
    sample_institution,
    student_headers,
):
    student_auth, student_id = student_headers
    session = client.post("/api/v1/tests/start", headers=student_auth).json()["data"]
    questions = client.get(
        f"/api/v1/tests/{session['id']}/questions",
        headers=student_auth,
    ).json()["data"]["questions"]

    for question in questions:
        client.post(
            f"/api/v1/tests/{session['id']}/answers",
            headers=student_auth,
            json={"question_id": question["id"], "answer_value": 4},
        )
    client.post(f"/api/v1/tests/{session['id']}/finish", headers=student_auth)

    user_repo = UserRepository(db)
    counselor = user_repo.create_raw(
        email=f"counselor_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Counsel1234!",
        first_name="Orientador",
        last_name="Prueba",
        role=UserRole.COUNSELOR,
        status="ACTIVE",
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
            f"/api/v1/tests/{session['id']}/result",
            headers=counselor_headers,
        )
        assert response.status_code == 200
    finally:
        db.delete(assignment)
        db.commit()
        user_repo.delete(counselor)
