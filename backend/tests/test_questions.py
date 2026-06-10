import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.enums import QuestionStatus
from app.db.session import SessionLocal
from app.models.riasec import Question, RiasecCategory
from app.repositories.question_repository import QuestionRepository


@pytest.fixture
def riasec_category_id(db) -> int:
    category = db.scalar(select(RiasecCategory).where(RiasecCategory.code == "R"))
    assert category is not None
    return category.id


def _delete_question_by_id(question_id: int) -> None:
    session = SessionLocal()
    try:
        question = session.get(Question, question_id)
        if question:
            QuestionRepository(session).delete(question)
    finally:
        session.close()


def _question_payload(category_id: int, **overrides) -> dict:
    base = {
        "category_id": category_id,
        "text": "Pregunta de prueba para validación del módulo RIASEC.",
        "order_number": 99,
        "status": "ACTIVE",
    }
    base.update(overrides)
    return base


def test_list_questions_requires_auth(client: TestClient):
    response = client.get("/api/v1/questions")
    assert response.status_code == 401


def test_list_questions_as_authenticated_user(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get("/api/v1/questions", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["total"] >= 60
    assert len(data["items"]) >= 1


def test_seed_has_sixty_active_questions(db):
    repo = QuestionRepository(db)
    assert repo.count_active() >= 60


def test_create_question_as_super_admin(
    client: TestClient,
    super_admin_headers: dict[str, str],
    riasec_category_id: int,
):
    payload = _question_payload(
        riasec_category_id,
        order_number=88,
        text=f"Pregunta adicional {uuid.uuid4().hex[:6]} para pruebas del sistema.",
    )
    response = client.post(
        "/api/v1/questions",
        headers=super_admin_headers,
        json=payload,
    )
    assert response.status_code == 200
    _delete_question_by_id(response.json()["data"]["id"])


def test_create_question_forbidden_for_student(
    client: TestClient,
    auth_headers: dict[str, str],
    riasec_category_id: int,
):
    response = client.post(
        "/api/v1/questions",
        headers=auth_headers,
        json=_question_payload(riasec_category_id),
    )
    assert response.status_code == 403


def test_create_question_duplicate_order(
    client: TestClient,
    super_admin_headers: dict[str, str],
    riasec_category_id: int,
):
    response = client.post(
        "/api/v1/questions",
        headers=super_admin_headers,
        json=_question_payload(riasec_category_id, order_number=1),
    )
    assert response.status_code == 422


def test_update_question_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    riasec_category_id: int,
):
    created = client.post(
        "/api/v1/questions",
        headers=super_admin_headers,
        json=_question_payload(riasec_category_id, order_number=87),
    )
    question_id = created.json()["data"]["id"]

    response = client.put(
        f"/api/v1/questions/{question_id}",
        headers=super_admin_headers,
        json={"text": "Texto actualizado de la pregunta RIASEC para pruebas del sistema."},
    )
    assert response.status_code == 200
    _delete_question_by_id(question_id)


def test_update_question_status_success(
    client: TestClient,
    super_admin_headers: dict[str, str],
    riasec_category_id: int,
):
    created = client.post(
        "/api/v1/questions",
        headers=super_admin_headers,
        json=_question_payload(riasec_category_id, order_number=86),
    )
    question_id = created.json()["data"]["id"]

    response = client.patch(
        f"/api/v1/questions/{question_id}/status",
        headers=super_admin_headers,
        json={"status": "INACTIVE"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "INACTIVE"
    _delete_question_by_id(question_id)


def test_filter_questions_by_category_code(
    client: TestClient,
    auth_headers: dict[str, str],
):
    response = client.get(
        "/api/v1/questions",
        headers=auth_headers,
        params={"category_code": "R", "page_size": 100},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    items = data["items"]
    assert len(items) == data["total"]
    assert all(item["category"]["code"] == "R" for item in items)


def test_get_inactive_question_forbidden_for_student(
    client: TestClient,
    super_admin_headers: dict[str, str],
    auth_headers: dict[str, str],
    riasec_category_id: int,
):
    created = client.post(
        "/api/v1/questions",
        headers=super_admin_headers,
        json=_question_payload(riasec_category_id, order_number=85),
    )
    question_id = created.json()["data"]["id"]

    client.patch(
        f"/api/v1/questions/{question_id}/status",
        headers=super_admin_headers,
        json={"status": "INACTIVE"},
    )

    response = client.get(
        f"/api/v1/questions/{question_id}",
        headers=auth_headers,
    )
    assert response.status_code == 403
    _delete_question_by_id(question_id)


def test_super_admin_can_filter_inactive_questions(
    client: TestClient,
    super_admin_headers: dict[str, str],
):
    response = client.get(
        "/api/v1/questions",
        headers=super_admin_headers,
        params={"status": "INACTIVE", "page_size": 5},
    )
    assert response.status_code == 200
