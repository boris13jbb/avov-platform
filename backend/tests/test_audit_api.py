import json
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, UserRole, UserStatus
from app.models.audit import AuditLog
from app.repositories.audit_repository import AuditRepository
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.institution import InstitutionCreate
from app.security.audit_details import REDACTED_MARKER
from app.security.jwt import decode_token


FAKE_ACCESS_TOKEN = "fake-access-token-historical-001"
FAKE_REFRESH_TOKEN = "fake-refresh-token-historical-002"
FAKE_PASSWORD = "FakeHistoricalPass123!"
FAKE_API_KEY = "sk-fake-historical-api-key"
FAKE_CLIENT_SECRET = "fake-historical-client-secret"
FAKE_BEARER = "Bearer fake-historical-authorization"


@pytest.fixture
def audit_rows(db: Session, institution_admin_headers, sample_institution):
    audit_repo = AuditRepository(db)
    user_repo = UserRepository(db)
    inst_repo = InstitutionRepository(db)

    token = institution_admin_headers["Authorization"].split(" ", 1)[1]
    inst_admin_id = int(decode_token(token)["sub"])
    inst_admin = user_repo.get_by_id(inst_admin_id)
    assert inst_admin is not None

    other_institution = inst_repo.create(
        InstitutionCreate(
            name="Instituto Auditoría Remoto",
            code=f"AUD-{uuid.uuid4().hex[:8].upper()}",
            province="Pichincha",
            city="Quito",
            address="Remoto",
            phone="0990000000",
            email="audit@remoto.edu.co",
            status=InstitutionStatus.ACTIVE,
        )
    )
    other_user = user_repo.create_raw(
        email=f"audit_other_{uuid.uuid4().hex[:8]}@instituto.edu.co",
        password="Test1234!",
        first_name="Otro",
        last_name="Instituto",
        role=UserRole.STUDENT,
        status=UserStatus.ACTIVE,
        institution_id=other_institution.id,
    )

    log_visible = audit_repo.create(
        user_id=inst_admin.id,
        action="LOGIN",
        entity="auth",
        entity_id=None,
        details={"source": "test"},
    )
    log_other = audit_repo.create(
        user_id=other_user.id,
        action="LOGIN",
        entity="auth",
        entity_id=None,
        details={"source": "test"},
    )
    yield log_visible, log_other
    user_repo.delete(other_user)
    inst_repo.delete(other_institution)


def _sensitive_details_payload() -> dict:
    return {
        "access_token": FAKE_ACCESS_TOKEN,
        "refreshToken": FAKE_REFRESH_TOKEN,
        "Password": FAKE_PASSWORD,
        "api-key": FAKE_API_KEY,
        "nested": {
            "client_secret": FAKE_CLIENT_SECRET,
            "status": "ok",
        },
        "items": [
            {"Authorization": FAKE_BEARER, "step": 1},
            {"step": 2},
        ],
        "source": "login",
        "result": "success",
        "entity_ref": 99,
        "nullable": None,
        "empty_list": [],
    }


def _assert_no_sensitive_leak(body: object) -> None:
    rendered = json.dumps(body, ensure_ascii=False)
    for secret in (
        FAKE_ACCESS_TOKEN,
        FAKE_REFRESH_TOKEN,
        FAKE_PASSWORD,
        FAKE_API_KEY,
        FAKE_CLIENT_SECRET,
        FAKE_BEARER,
    ):
        assert secret not in rendered


@pytest.fixture
def historical_sensitive_log(db: Session, institution_admin_headers):
    """Simula un registro histórico con secretos ya persistidos (sin pasar por create)."""
    token = institution_admin_headers["Authorization"].split(" ", 1)[1]
    inst_admin_id = int(decode_token(token)["sub"])
    row = AuditLog(
        user_id=inst_admin_id,
        action="LOGIN",
        entity="auth",
        entity_id=None,
        details=_sensitive_details_payload(),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    yield row
    db.delete(row)
    db.commit()


def test_audit_list_super_admin_sees_all(
    client: TestClient,
    super_admin_headers,
    audit_rows,
):
    log_visible, log_other = audit_rows
    response = client.get("/api/v1/audit/logs", headers=super_admin_headers)
    assert response.status_code == 200
    ids = {item["id"] for item in response.json()["data"]["items"]}
    assert log_visible.id in ids
    assert log_other.id in ids


def test_audit_list_institution_admin_scoped(
    client: TestClient,
    institution_admin_headers,
    audit_rows,
):
    log_visible, log_other = audit_rows
    response = client.get("/api/v1/audit/logs", headers=institution_admin_headers)
    assert response.status_code == 200
    ids = {item["id"] for item in response.json()["data"]["items"]}
    assert log_visible.id in ids
    assert log_other.id not in ids


def test_audit_get_by_id(
    client: TestClient,
    super_admin_headers,
    audit_rows,
):
    log_visible, _ = audit_rows
    response = client.get(
        f"/api/v1/audit/logs/{log_visible.id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    assert response.json()["data"]["action"] == "LOGIN"


def test_audit_detail_redacts_sensitive_historical_details(
    client: TestClient,
    super_admin_headers,
    historical_sensitive_log,
):
    response = client.get(
        f"/api/v1/audit/logs/{historical_sensitive_log.id}",
        headers=super_admin_headers,
    )
    assert response.status_code == 200
    body = response.json()
    data = body["data"]
    details = data["details"]
    assert details["access_token"] == REDACTED_MARKER
    assert details["refreshToken"] == REDACTED_MARKER
    assert details["Password"] == REDACTED_MARKER
    assert details["api-key"] == REDACTED_MARKER
    assert details["nested"]["client_secret"] == REDACTED_MARKER
    assert details["nested"]["status"] == "ok"
    assert details["items"][0]["Authorization"] == REDACTED_MARKER
    assert details["items"][0]["step"] == 1
    assert details["items"][1]["step"] == 2
    assert details["source"] == "login"
    assert details["result"] == "success"
    assert details["entity_ref"] == 99
    assert details["nullable"] is None
    assert details["empty_list"] == []
    assert data["action"] == "LOGIN"
    assert data["entity"] == "auth"
    _assert_no_sensitive_leak(body)


def test_audit_list_redacts_sensitive_historical_details(
    client: TestClient,
    super_admin_headers,
    historical_sensitive_log,
):
    response = client.get(
        "/api/v1/audit/logs",
        headers=super_admin_headers,
        params={"action": "LOGIN", "page_size": 100},
    )
    assert response.status_code == 200
    body = response.json()
    items = body["data"]["items"]
    match = next(item for item in items if item["id"] == historical_sensitive_log.id)
    details = match["details"]
    assert details["access_token"] == REDACTED_MARKER
    assert details["api-key"] == REDACTED_MARKER
    assert details["source"] == "login"
    _assert_no_sensitive_leak(body)


def test_audit_create_sanitizes_before_persist(db: Session, institution_admin_headers):
    token = institution_admin_headers["Authorization"].split(" ", 1)[1]
    inst_admin_id = int(decode_token(token)["sub"])
    repo = AuditRepository(db)
    created = repo.create(
        user_id=inst_admin_id,
        action="LOGIN",
        entity="auth",
        entity_id=None,
        details=_sensitive_details_payload(),
    )
    stored = db.get(AuditLog, created.id)
    assert stored is not None
    assert stored.details is not None
    assert stored.details["access_token"] == REDACTED_MARKER
    assert stored.details["Password"] == REDACTED_MARKER
    assert stored.details["source"] == "login"
    _assert_no_sensitive_leak(stored.details)
    db.delete(stored)
    db.commit()


@pytest.fixture
def audit_student_headers(client: TestClient, db: Session, sample_institution):
    user_repo = UserRepository(db)
    email = f"audit_student_{uuid.uuid4().hex[:8]}@instituto.edu.co"
    user = user_repo.create_raw(
        email=email,
        password="Test1234!",
        first_name="Estudiante",
        last_name="Auditoria",
        role=UserRole.STUDENT,
        status=UserStatus.ACTIVE,
        institution_id=sample_institution.id,
    )
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "Test1234!"},
    )
    assert response.status_code == 200
    token = response.json()["data"]["access_token"]
    yield {"Authorization": f"Bearer {token}"}
    user_repo.delete(user)


def test_audit_student_forbidden(client: TestClient, audit_student_headers):
    response = client.get("/api/v1/audit/logs", headers=audit_student_headers)
    assert response.status_code == 403


def test_audit_unauthenticated_rejected(client: TestClient):
    response = client.get("/api/v1/audit/logs")
    assert response.status_code in {401, 403}


def test_audit_pagination_and_date_filters(
    client: TestClient,
    super_admin_headers,
    audit_rows,
):
    log_visible, _ = audit_rows
    response = client.get(
        "/api/v1/audit/logs",
        headers=super_admin_headers,
        params={"page": 1, "page_size": 1},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["page"] == 1
    assert data["page_size"] == 1
    assert len(data["items"]) <= 1

    oversized = client.get(
        "/api/v1/audit/logs",
        headers=super_admin_headers,
        params={"page_size": 101},
    )
    assert oversized.status_code == 422

    by_user = client.get(
        "/api/v1/audit/logs",
        headers=super_admin_headers,
        params={"user_id": log_visible.user_id},
    )
    assert by_user.status_code == 200
    ids = {item["id"] for item in by_user.json()["data"]["items"]}
    assert log_visible.id in ids


def test_institution_admin_cannot_filter_foreign_user(
    client: TestClient,
    institution_admin_headers,
    audit_rows,
):
    _, log_other = audit_rows
    response = client.get(
        "/api/v1/audit/logs",
        headers=institution_admin_headers,
        params={"user_id": log_other.user_id},
    )
    assert response.status_code == 403


def test_institution_admin_cannot_view_foreign_log_detail(
    client: TestClient,
    institution_admin_headers,
    audit_rows,
):
    _, log_other = audit_rows
    response = client.get(
        f"/api/v1/audit/logs/{log_other.id}",
        headers=institution_admin_headers,
    )
    assert response.status_code == 403
