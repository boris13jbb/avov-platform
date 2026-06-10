"""seed riasec questions

Revision ID: f4b5c6d7e8f9
Revises: e1f2a3b4c5d6
Create Date: 2026-06-10 01:00:00.000000
"""

from typing import Sequence, Union

from alembic import op

from app.db.seeds.riasec_questions import RIASEC_QUESTIONS

revision: str = "f4b5c6d7e8f9"
down_revision: Union[str, None] = "e1f2a3b4c5d6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    for code, order_number, text in RIASEC_QUESTIONS:
        escaped_text = text.replace("'", "''")
        op.execute(
            f"""
            INSERT INTO questions (category_id, text, order_number, status, created_at, updated_at)
            SELECT c.id, '{escaped_text}', {order_number}, 'ACTIVE', NOW(), NOW()
            FROM riasec_categories c
            WHERE c.code = '{code}'
            AND NOT EXISTS (
                SELECT 1
                FROM questions q
                WHERE q.category_id = c.id AND q.order_number = {order_number}
            )
            """
        )


def downgrade() -> None:
    op.execute(
        """
        DELETE q FROM questions q
        INNER JOIN riasec_categories c ON q.category_id = c.id
        WHERE c.code IN ('R', 'I', 'A', 'S', 'E', 'C')
          AND q.order_number BETWEEN 1 AND 10
        """
    )
