from collections.abc import Generator

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.enums import UserRole, UserStatus
from app.core.exceptions import UnauthorizedException
from app.db.session import SessionLocal
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.security.jwt import decode_token
from app.services.system_setting_service import SystemSettingService

security = HTTPBearer(auto_error=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or not credentials.credentials:
        raise UnauthorizedException("Token de autenticación requerido")

    payload = decode_token(credentials.credentials, expected_type="access")
    user_id = int(payload["sub"])
    user = UserRepository(db).get_by_id(user_id)

    if user is None:
        raise UnauthorizedException("Usuario no encontrado")

    if user.status != UserStatus.ACTIVE:
        raise UnauthorizedException(
            "Tu cuenta no está activa. Contacta al administrador."
        )

    if SystemSettingService(db).is_maintenance_mode():
        if user.role != UserRole.SUPER_ADMIN:
            raise UnauthorizedException(
                "El sistema está en mantenimiento. Solo el super administrador puede acceder."
            )

    return user
