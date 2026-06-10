from sqlalchemy.orm import Session

from app.core.enums import UserStatus
from app.core.exceptions import UnauthorizedException, ValidationException
from app.models.user import User
from app.repositories.refresh_token_repository import RefreshTokenRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import ChangePasswordRequest, TokenData, UserProfileData
from app.security.jwt import (
    create_access_token,
    generate_refresh_token,
    hash_token,
    refresh_token_expires_at,
)
from app.security.password import hash_password, verify_password


class AuthService:
    INVALID_CREDENTIALS_MSG = "Credenciales incorrectas"
    INACTIVE_ACCOUNT_MSG = "Tu cuenta no está activa. Contacta al administrador."

    def __init__(self, db: Session) -> None:
        self.db = db
        self.user_repo = UserRepository(db)
        self.refresh_repo = RefreshTokenRepository(db)

    def login(self, email: str, password: str) -> TokenData:
        user = self.user_repo.get_by_email(email)

        if user is None or not verify_password(password, user.password_hash):
            raise UnauthorizedException(self.INVALID_CREDENTIALS_MSG)

        if user.status != UserStatus.ACTIVE:
            raise UnauthorizedException(self.INACTIVE_ACCOUNT_MSG)

        return self._issue_tokens(user)

    def refresh(self, refresh_token: str) -> TokenData:
        token_hash = hash_token(refresh_token)
        stored_token = self.refresh_repo.get_valid_by_hash(token_hash)

        if stored_token is None:
            raise UnauthorizedException("Refresh token inválido o expirado")

        user = self.user_repo.get_by_id(stored_token.user_id)
        if user is None or user.status != UserStatus.ACTIVE:
            raise UnauthorizedException(self.INACTIVE_ACCOUNT_MSG)

        self.refresh_repo.revoke(stored_token)
        return self._issue_tokens(user)

    def logout(self, refresh_token: str, user_id: int) -> None:
        token_hash = hash_token(refresh_token)
        stored_token = self.refresh_repo.get_valid_by_hash(token_hash)

        if stored_token is None or stored_token.user_id != user_id:
            raise UnauthorizedException("Refresh token inválido o expirado")

        self.refresh_repo.revoke(stored_token)

    def change_password(self, user: User, payload: ChangePasswordRequest) -> None:
        if not verify_password(payload.current_password, user.password_hash):
            raise UnauthorizedException("La contraseña actual es incorrecta")

        if verify_password(payload.new_password, user.password_hash):
            raise ValidationException(
                "La nueva contraseña debe ser diferente a la actual"
            )

        self.user_repo.update_password(user, hash_password(payload.new_password))
        self.refresh_repo.revoke_all_for_user(user.id)

    @staticmethod
    def build_profile(user: User) -> UserProfileData:
        return UserProfileData(
            id=user.id,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
            role=user.role.value,
            status=user.status.value,
            institution_id=user.institution_id,
            phone=user.phone,
            avatar_url=user.avatar_url,
            last_login_at=user.last_login_at,
        )

    def _issue_tokens(self, user: User) -> TokenData:
        access_token, expires_in = create_access_token(
            user.id,
            user.role.value,
            user.email,
        )
        refresh_token = generate_refresh_token()
        self.refresh_repo.create(
            user_id=user.id,
            token_hash=hash_token(refresh_token),
            expires_at=refresh_token_expires_at(),
        )
        self.user_repo.update_last_login(user)
        return TokenData(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in,
        )
