"""Crea (o reutiliza) un STUDENT QA solo en avov_test.

Requisitos:
  - DATABASE_URL con schema exactamente avov_test (preflight fail-closed).
  - IDs de usuario/institución/estudiante en rango >= 900000 para evitar
    colisión de ``sub`` JWT con filas de avov_db (misma JWT_SECRET compartida).

No imprime contraseñas. Las credenciales se guardan fuera del repo en
%LOCALAPPDATA%\\AVOV\\e2e\\qa-student.json (Windows).
"""

from __future__ import annotations

import json
import os
import secrets
import string
import sys
from datetime import date
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import text  # noqa: E402

from app.core.enums import Gender, InstitutionStatus, UserRole, UserStatus  # noqa: E402
from app.repositories.institution_repository import InstitutionRepository  # noqa: E402
from app.repositories.student_repository import StudentRepository  # noqa: E402
from app.repositories.user_repository import UserRepository  # noqa: E402
from app.schemas.institution import InstitutionCreate  # noqa: E402
from app.schemas.student import StudentCreate, StudentUserInput  # noqa: E402
from tests.db_isolation import (  # noqa: E402
    AUTHORIZED_TEST_DATABASE_NAME,
    assert_authorized_test_database,
    resolve_database_name,
)

QA_EMAIL = "e2e.student.qa@instituto-qa.edu.co"
QA_TAG = "E2E-STUDENT-QA"
QA_IDENTIFICATION = "E2E-QA-STUDENT-001"
ID_FLOOR = 900000
QA_INSTITUTION_EMAIL = "e2e.institution.qa@instituto-qa.edu.co"


def _credentials_path() -> Path:
    base = Path(os.environ.get("LOCALAPPDATA") or Path.home() / "AppData" / "Local")
    folder = base / "AVOV" / "e2e"
    folder.mkdir(parents=True, exist_ok=True)
    return folder / "qa-student.json"


def _strong_password() -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%&*"
    while True:
        pwd = "".join(secrets.choice(alphabet) for _ in range(16))
        if (
            any(c.isupper() for c in pwd)
            and any(c.islower() for c in pwd)
            and any(c.isdigit() for c in pwd)
            and any(c in "!@#$%&*" for c in pwd)
        ):
            return pwd


def _ensure_id_floor(session, table: str) -> None:
    """Eleva AUTO_INCREMENT para reducir colisión de sub JWT con avov_db."""
    current = session.execute(
        text(
            "SELECT AUTO_INCREMENT FROM information_schema.TABLES "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t"
        ),
        {"t": table},
    ).scalar()
    if current is None or int(current) < ID_FLOOR:
        session.execute(text(f"ALTER TABLE {table} AUTO_INCREMENT = {ID_FLOOR}"))
        session.commit()


def main() -> int:
    url = os.environ.get("DATABASE_URL")
    if not url:
        print("ERROR: DATABASE_URL ausente", file=sys.stderr)
        return 2

    assert_authorized_test_database(url)
    schema = resolve_database_name(url)
    if schema != AUTHORIZED_TEST_DATABASE_NAME:
        print(f"ERROR: schema={schema}", file=sys.stderr)
        return 3

    # Import diferido: create_engine solo tras la guardia.
    from app.db.session import SessionLocal

    db = SessionLocal()
    try:
        active = db.execute(text("SELECT DATABASE()")).scalar()
        if active != AUTHORIZED_TEST_DATABASE_NAME:
            print(f"ERROR: active={active}", file=sys.stderr)
            return 4

        user_repo = UserRepository(db)
        existing = user_repo.get_by_email(QA_EMAIL)
        cred_path = _credentials_path()

        if existing is not None:
            if existing.role != UserRole.STUDENT:
                print(
                    f"ERROR: {QA_TAG} email ocupado por rol={existing.role.value}",
                    file=sys.stderr,
                )
                return 5
            if existing.id < ID_FLOOR:
                print(
                    f"ERROR: user_id={existing.id} < {ID_FLOOR} (riesgo JWT vs avov_db)",
                    file=sys.stderr,
                )
                return 6
            student_repo = StudentRepository(db)
            student = student_repo.get_by_user_id(existing.id)
            print(
                f"OK action=reuse qa_tag={QA_TAG} schema={schema} "
                f"user_id={existing.id} role={existing.role.value} "
                f"has_student_profile={student is not None} "
                f"credentials_file={'yes' if cred_path.exists() else 'no'}"
            )
            return 0

        for table in ("institutions", "users", "students"):
            _ensure_id_floor(db, table)

        institution = InstitutionRepository(db).create(
            InstitutionCreate(
                name="Institucion E2E QA Aislada",
                code=f"E2E-QA-{ID_FLOOR}",
                province="Pichincha",
                city="Quito",
                address="QA aislado — no usar en produccion",
                phone="0990000001",
                email=QA_INSTITUTION_EMAIL,
                status=InstitutionStatus.ACTIVE,
            )
        )
        if institution.id < ID_FLOOR:
            print(
                f"ERROR: institution_id={institution.id} < {ID_FLOOR}",
                file=sys.stderr,
            )
            return 7

        password = _strong_password()
        student = StudentRepository(db).create_with_user(
            StudentCreate(
                institution_id=institution.id,
                user=StudentUserInput(
                    email=QA_EMAIL,
                    password=password,
                    first_name="Estudiante",
                    last_name="E2E-QA",
                    phone=None,
                ),
                identification=QA_IDENTIFICATION,
                birth_date=date(2008, 1, 15),
                gender=Gender.NOT_SPECIFIED,
                grade="3ro BGU",
                parallel="A",
                representative_name=None,
                representative_phone=None,
                representative_email=None,
                status=UserStatus.ACTIVE,
            )
        )

        if student.user_id < ID_FLOOR or student.id < ID_FLOOR:
            print(
                f"ERROR: ids bajos user={student.user_id} student={student.id}",
                file=sys.stderr,
            )
            return 8

        payload = {
            "qa_tag": QA_TAG,
            "schema": schema,
            "email": QA_EMAIL,
            "password": password,
            "user_id": student.user_id,
            "student_id": student.id,
            "institution_id": institution.id,
            "role": UserRole.STUDENT.value,
            "api_base": "http://127.0.0.1:8001/api/v1",
        }
        cred_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        try:
            os.chmod(cred_path, 0o600)
        except OSError:
            pass

        print(
            f"OK action=create qa_tag={QA_TAG} schema={schema} "
            f"user_id={student.user_id} student_id={student.id} "
            f"role={UserRole.STUDENT.value} credentials_stored=local_appdata"
        )
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
