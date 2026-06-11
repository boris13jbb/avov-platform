from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import PasswordResetToken


class PasswordResetRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, *, user_id: int, token_hash: str, expires_at: datetime) -> PasswordResetToken:
        self.invalidate_active_for_user(user_id)
        reset_token = PasswordResetToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        self.db.add(reset_token)
        self.db.commit()
        self.db.refresh(reset_token)
        return reset_token

    def get_valid_by_hash(self, token_hash: str) -> PasswordResetToken | None:
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        stmt = select(PasswordResetToken).where(
            PasswordResetToken.token_hash == token_hash,
            PasswordResetToken.used_at.is_(None),
            PasswordResetToken.expires_at > now,
        )
        return self.db.scalar(stmt)

    def mark_used(self, reset_token: PasswordResetToken) -> None:
        reset_token.used_at = datetime.now(timezone.utc).replace(tzinfo=None)
        self.db.add(reset_token)
        self.db.commit()

    def invalidate_active_for_user(self, user_id: int) -> None:
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        stmt = select(PasswordResetToken).where(
            PasswordResetToken.user_id == user_id,
            PasswordResetToken.used_at.is_(None),
        )
        tokens = self.db.scalars(stmt).all()
        for token in tokens:
            token.used_at = now
            self.db.add(token)
        self.db.commit()
