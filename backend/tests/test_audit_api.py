import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.enums import InstitutionStatus, UserRole, UserStatus
from app.repositories.audit_repository import AuditRepository
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.institution import InstitutionCreate
from app.security.jwt import decode_token


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
