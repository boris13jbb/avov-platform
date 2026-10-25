import uuid
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.user import PasswordResetToken
from app.repositories.password_reset_token_repository import PasswordResetTokenRepository
from app.security.jwt import hash_token
from app.services.auth_service import AuthService


def test_forgot_password_uniform_response(client: TestClient, test_user):
    known = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": test_user.email},
    )
    unknown = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": f"noexiste_{uuid.uuid4().hex[:8]}@instituto.edu.co"},
    )
    assert known.status_code == 200
    assert unknown.status_code == 200
    assert known.json()["message"] == unknown.json()["message"]
    assert known.json()["message"] == AuthService.PASSWORD_RESET_REQUEST_MSG


def test_reset_password_success(client: TestClient, db: Session, test_user):
    forgot = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": test_user.email},
    )
    assert forgot.status_code == 200

    read_session = SessionLocal()
    try:
        row = read_session.scalar(
            select(PasswordResetToken)
            .where(PasswordResetToken.user_id == test_user.id)
            .order_by(PasswordResetToken.id.desc())
        )
        assert row is not None

        raw_token = "test-reset-token-value-123456789012345678901234567890"
        row.token_hash = hash_token(raw_token)
        read_session.add(row)
        read_session.commit()
    finally:
        read_session.close()

    reset = client.post(
        "/api/v1/auth/reset-password",
        json={
            "token": raw_token,
            "new_password": "Nueva1234!",
            "confirm_password": "Nueva1234!",
        },
    )
    assert reset.status_code == 200

    login_old = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "Test1234!"},
    )
    login_new = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "Nueva1234!"},
    )
    assert login_old.status_code == 401
    assert login_new.status_code == 200


def test_reset_password_rejects_reused_token(client: TestClient, db: Session, test_user):
    raw_token = "reuse-token-2-1234567890123456789012345678901234"
    PasswordResetTokenRepository(db).create(
        user_id=test_user.id,
        token_hash=hash_token(raw_token),
        expires_at=datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(hours=1),
    )

    first = client.post(
        "/api/v1/auth/reset-password",
        json={
            "token": raw_token,
            "new_password": "Otra1234!",
            "confirm_password": "Otra1234!",
        },
    )
    assert first.status_code == 200

    second = client.post(
        "/api/v1/auth/reset-password",
        json={
            "token": raw_token,
            "new_password": "Otra5678!",
            "confirm_password": "Otra5678!",
        },
    )
    assert second.status_code == 401
    assert second.json()["message"] == AuthService.INVALID_RESET_TOKEN_MSG


def test_reset_password_rejects_expired_token(client: TestClient, db: Session, test_user):
    raw_token = "expired-token-12345678901234567890123456789012345"
    PasswordResetTokenRepository(db).create(
        user_id=test_user.id,
        token_hash=hash_token(raw_token),
        expires_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(minutes=5),
    )

    response = client.post(
        "/api/v1/auth/reset-password",
        json={
            "token": raw_token,
            "new_password": "Nueva1234!",
            "confirm_password": "Nueva1234!",
        },
    )
    assert response.status_code == 401
    assert response.json()["message"] == AuthService.INVALID_RESET_TOKEN_MSG
