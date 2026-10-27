import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt

from app.core.config import get_settings
from app.core.exceptions import UnauthorizedException


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def generate_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def create_access_token(user_id: int, role: str, email: str) -> tuple[str, int]:
    settings = get_settings()
    expires_delta = timedelta(minutes=settings.jwt_access_token_expire_minutes)
    expire = datetime.now(timezone.utc) + expires_delta
    payload = {
        "sub": str(user_id),
        "role": role,
        "email": email,
        "exp": expire,
        "type": "access",
    }
    token = jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )
    return token, int(expires_delta.total_seconds())


def decode_token(token: str, *, expected_type: str = "access") -> dict:
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as exc:
        raise UnauthorizedException("Token inválido o expirado") from exc

    if payload.get("type") != expected_type:
        raise UnauthorizedException("Token inválido o expirado")

    return payload


def refresh_token_expires_at() -> datetime:
    settings = get_settings()
    expires = datetime.now(timezone.utc) + timedelta(
        days=settings.jwt_refresh_token_expire_days
    )
    return expires.replace(tzinfo=None)


def password_reset_token_expires_at() -> datetime:
    settings = get_settings()
    expires = datetime.now(timezone.utc) + timedelta(
        hours=settings.password_reset_token_expire_hours
    )
    return expires.replace(tzinfo=None)
