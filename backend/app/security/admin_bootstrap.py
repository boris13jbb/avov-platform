"""Alta explícita del primer superadministrador.

La migración histórica e1f2a3b4c5d6 ya está aplicada y no se reescribe.
Este módulo no se ejecuta al arrancar ni desde Alembic. Rechaza la
contraseña pública de esa semilla antes de insertar.
"""

import ast
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.user import User
from app.repositories.user_repository import UserRepository

_SEED_MIGRATION = (
    Path(__file__).resolve().parents[2]
    / "alembic"
    / "versions"
    / "e1f2a3b4c5d6_seed_super_admin.py"
)


class PublicSeedPasswordError(ValueError):
    """La contraseña indicada es la de la semilla histórica versionada."""


def read_historical_seed_password() -> str | None:
    if not _SEED_MIGRATION.is_file():
        return None
    tree = ast.parse(_SEED_MIGRATION.read_text(encoding="utf-8"))
    for node in tree.body:
        if not isinstance(node, ast.Assign) or len(node.targets) != 1:
            continue
        target = node.targets[0]
        if (
            isinstance(target, ast.Name)
            and target.id == "ADMIN_PASSWORD"
            and isinstance(node.value, ast.Constant)
            and isinstance(node.value.value, str)
        ):
            return node.value.value
    return None


def assert_password_not_public_seed(password: str) -> None:
    historical = read_historical_seed_password()
    if historical is None:
        raise PublicSeedPasswordError(
            "No se pudo comprobar la contraseña pública de la semilla histórica"
        )
    if password == historical:
        raise PublicSeedPasswordError(
            "La contraseña inicial pública de la semilla no está permitida"
        )


def create_initial_admin(
    db: Session,
    *,
    email: str,
    password: str,
    first_name: str,
    last_name: str,
) -> User:
    """Crea un superadministrador solo cuando la llamada es explícita.

    No sustituye a la migración ya aplicada y no modifica cuentas existentes.
    """
    assert_password_not_public_seed(password)
    normalized = email.strip().lower()
    existing = db.scalar(select(func.count()).select_from(User).where(User.email == normalized))
    if existing:
        raise ValueError("No se creó el administrador inicial")
    return UserRepository(db).create_raw(
        email=normalized,
        password=password,
        first_name=first_name,
        last_name=last_name,
        role=UserRole.SUPER_ADMIN,
    )
