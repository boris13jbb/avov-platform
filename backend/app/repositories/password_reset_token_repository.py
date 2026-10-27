from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import PasswordResetToken


class PasswordResetTokenRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        *,
        user_id: int,
        token_hash: str,
        expires_at: datetime,
    ) -> PasswordResetToken:
        row = PasswordResetToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

    def get_valid_by_hash(self, token_hash: str) -> PasswordResetToken | None:
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        stmt = select(PasswordResetToken).where(
            PasswordResetToken.token_hash == token_hash,
            PasswordResetToken.used_at.is_(None),
            PasswordResetToken.expires_at > now,
        )
        return self.db.scalar(stmt)

    def mark_used(self, token: PasswordResetToken) -> None:
        token.used_at = datetime.now(timezone.utc).replace(tzinfo=None)
        self.db.add(token)
        self.db.commit()
