"""Garantiza exactamente dos sesiones abiertas para el STUDENT QA en avov_test.

Idempotente: si ya hay 2+ abiertas, no crea más (si hay >2, sale con error
informativo sin borrar). Si hay 0 u 1, crea solo las faltantes.

No inserta respuestas. No imprime secretos. No limpia Redis ni avov_db.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import text  # noqa: E402

from app.core.enums import UserRole  # noqa: E402
from app.repositories.question_repository import QuestionRepository  # noqa: E402
from app.repositories.student_repository import StudentRepository  # noqa: E402
from app.repositories.test_session_repository import TestSessionRepository  # noqa: E402
from app.repositories.user_repository import UserRepository  # noqa: E402
from tests.db_isolation import (  # noqa: E402
    AUTHORIZED_TEST_DATABASE_NAME,
    assert_authorized_test_database,
    resolve_database_name,
)

QA_USER_ID = 900000
TARGET_OPEN = 2


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

    from app.db.session import SessionLocal

    db = SessionLocal()
    try:
        active = db.execute(text("SELECT DATABASE()")).scalar()
        if active != AUTHORIZED_TEST_DATABASE_NAME:
            print(f"ERROR: active={active}", file=sys.stderr)
            return 4

        user = UserRepository(db).get_by_id(QA_USER_ID)
        if user is None or user.role != UserRole.STUDENT:
            print("ERROR: cuenta QA STUDENT 900000 no encontrada", file=sys.stderr)
            return 5

        student = StudentRepository(db).get_by_user_id(QA_USER_ID)
        if student is None:
            print("ERROR: ficha estudiante QA ausente", file=sys.stderr)
            return 6

        repo = TestSessionRepository(db)
        open_sessions = repo.list_open_sessions(student.id)
        open_ids = [s.id for s in open_sessions]
        print(
            f"OK pre_open_count={len(open_ids)} pre_open_ids={open_ids} "
            f"student_id={student.id} schema={schema}"
        )

        if len(open_ids) > TARGET_OPEN:
            print(
                f"ERROR: hay {len(open_ids)} sesiones abiertas (>2); "
                "no se borran ni crean. Validar manualmente.",
                file=sys.stderr,
            )
            return 7

        if len(open_ids) == TARGET_OPEN:
            print(f"OK action=noop open_ids={open_ids}")
            return 0

        active_questions = QuestionRepository(db).count_active()
        if active_questions < 60:
            print(
                f"ERROR: preguntas activas={active_questions} (se esperaban >=60)",
                file=sys.stderr,
            )
            return 8

        created: list[int] = []
        while len(open_ids) + len(created) < TARGET_OPEN:
            session = repo.create_session(student.id, active_questions)
            if session.student_id != student.id:
                print("ERROR: sesión creada con student_id ajeno", file=sys.stderr)
                return 9
            created.append(session.id)

        final = repo.list_open_sessions(student.id)
        final_ids = [s.id for s in final]
        print(
            f"OK action=create created_ids={created} "
            f"final_open_count={len(final_ids)} final_open_ids={final_ids}"
        )
        if len(final_ids) != TARGET_OPEN:
            print("ERROR: conteo final distinto de 2", file=sys.stderr)
            return 10
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
