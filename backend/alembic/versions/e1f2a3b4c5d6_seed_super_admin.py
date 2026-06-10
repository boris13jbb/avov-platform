"""seed super admin user

Revision ID: e1f2a3b4c5d6
Revises: c8a1e2f3b4d5
Create Date: 2026-06-09 22:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
from passlib.context import CryptContext

revision: str = "e1f2a3b4c5d6"
down_revision: Union[str, None] = "c8a1e2f3b4d5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

ADMIN_EMAIL = "admin@avov.edu.co"
ADMIN_PASSWORD = "Admin123!"


def upgrade() -> None:
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    password_hash = pwd_context.hash(ADMIN_PASSWORD)

    op.execute(
        f"""
        INSERT INTO users (
            institution_id, first_name, last_name, email, password_hash,
            role, phone, avatar_url, status, last_login_at, created_at, updated_at
        )
        SELECT NULL, 'Super', 'Admin', '{ADMIN_EMAIL}', '{password_hash}',
               'SUPER_ADMIN', NULL, NULL, 'ACTIVE', NULL, NOW(), NOW()
        WHERE NOT EXISTS (
            SELECT 1 FROM users WHERE email = '{ADMIN_EMAIL}'
        )
        """
    )


def downgrade() -> None:
    op.execute(f"DELETE FROM users WHERE email = '{ADMIN_EMAIL}'")
