"""seed riasec categories

Revision ID: c8a1e2f3b4d5
Revises: b34d6f5f4d1b
Create Date: 2026-06-09 21:00:00.000000
"""

from typing import Sequence, Union

from alembic import op

revision: str = "c8a1e2f3b4d5"
down_revision: Union[str, None] = "b34d6f5f4d1b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

RIASEC_CATEGORIES = [
    ("R", "Realista", "Personas con aptitudes mecánicas y habilidades físicas."),
    ("I", "Investigador", "Personas analíticas, curiosas y orientadas a la investigación."),
    ("A", "Artístico", "Personas creativas, expresivas e innovadoras."),
    ("S", "Social", "Personas empáticas, colaborativas y orientadas a ayudar."),
    ("E", "Emprendedor", "Personas persuasivas, líderes y orientadas a los negocios."),
    ("C", "Convencional", "Personas organizadas, detallistas y orientadas a procesos."),
]


def upgrade() -> None:
    for code, name, description in RIASEC_CATEGORIES:
        op.execute(
            f"""
            INSERT INTO riasec_categories (code, name, description, created_at, updated_at)
            SELECT '{code}', '{name}', '{description}', NOW(), NOW()
            FROM DUAL
            WHERE NOT EXISTS (
                SELECT 1 FROM riasec_categories WHERE code = '{code}'
            )
            """
        )


def downgrade() -> None:
    codes = ", ".join(f"'{code}'" for code, _, _ in RIASEC_CATEGORIES)
    op.execute(f"DELETE FROM riasec_categories WHERE code IN ({codes})")
