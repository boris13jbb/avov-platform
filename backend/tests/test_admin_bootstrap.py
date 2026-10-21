"""La aplicación no crea un superadministrador con la contraseña pública."""

from pathlib import Path

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.user import User
from app.security.admin_bootstrap import (
    PublicSeedPasswordError,
    assert_password_not_public_seed,
    create_initial_admin,
    read_historical_seed_password,
)


def test_rechaza_la_contrasena_publica_de_la_semilla() -> None:
    historical = read_historical_seed_password()
    assert historical

    with pytest.raises(PublicSeedPasswordError) as captured:
        assert_password_not_public_seed(historical)

    assert historical not in str(captured.value)


def test_el_codigo_de_aplicacion_no_repite_la_contrasena_publica() -> None:
    historical = read_historical_seed_password()
    assert historical
    app_dir = Path(__file__).resolve().parents[1] / "app"
    offenders = [
        str(path.relative_to(app_dir))
        for path in app_dir.rglob("*.py")
        if historical in path.read_text(encoding="utf-8")
    ]

    assert offenders == []


def test_no_inserta_superadministrador_con_la_contrasena_publica(db: Session) -> None:
    email = "alta-inicial-rechazada@avov.edu.co"
    before = db.scalar(select(func.count()).select_from(User).where(User.email == email))

    with pytest.raises(PublicSeedPasswordError):
        create_initial_admin(
            db,
            email=email,
            password=read_historical_seed_password() or "",
            first_name="Alta",
            last_name="Rechazada",
        )

    after = db.scalar(select(func.count()).select_from(User).where(User.email == email))
    assert before == 0
    assert after == 0


def test_alta_explicita_con_otra_contrasena_si_se_puede_borrar(db: Session) -> None:
    email = "alta-inicial-aislada@avov.edu.co"
    user = create_initial_admin(
        db,
        email=email,
        password="ClaveAislada-Avov-1!",
        first_name="Alta",
        last_name="Aislada",
    )
    try:
        assert user.role.value == "SUPER_ADMIN"
        assert user.email == email
    finally:
        db.delete(user)
        db.commit()


def test_no_sustituye_un_usuario_existente_ni_revela_el_correo(db: Session) -> None:
    email = "alta-inicial-existente@avov.edu.co"
    user = create_initial_admin(
        db,
        email=email,
        password="ClaveAislada-Avov-1!",
        first_name="Alta",
        last_name="Existente",
    )
    original_hash = user.password_hash
    try:
        with pytest.raises(ValueError) as captured:
            create_initial_admin(
                db,
                email=email,
                password="OtraClaveAislada-2!",
                first_name="Alta",
                last_name="Existente",
            )
        assert email not in str(captured.value)
        db.refresh(user)
        assert user.password_hash == original_hash
    finally:
        db.delete(user)
        db.commit()
