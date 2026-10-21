"""Prepara UNA sesión COMPLETED desechable en avov_test para E2E S-21.

- Solo schema avov_test (fail-closed).
- Student QA id 900000.
- No modifica respuestas, RIASEC ni status de 137/138/139.
- Crea sesión abierta (o reutiliza abierta != 137/138), carga 60 respuestas
  vía API :8001 y hace POST /finish.
- Credenciales desde %LOCALAPPDATA%\\AVOV\\e2e\\qa-student.json (no imprime secretos).
- Marca el id desechable en %LOCALAPPDATA%\\AVOV\\e2e\\s21-disposable-session.json.

Salida: session_id=... status=... answers=... (sin tokens).
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import httpx
from sqlalchemy import text

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.enums import TestSessionStatus, UserRole  # noqa: E402
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
PROTECTED_IDS = frozenset({137, 138, 139})
API_BASE = os.environ.get("AVOV_E2E_API_BASE", "http://127.0.0.1:8001/api/v1")


def _marker_path() -> Path:
    return Path(os.environ["LOCALAPPDATA"]) / "AVOV" / "e2e" / "s21-disposable-session.json"


def _qa_credentials() -> tuple[str, str]:
    base = Path(os.environ["LOCALAPPDATA"]) / "AVOV" / "e2e" / "qa-student.json"
    data = json.loads(base.read_text(encoding="utf-8"))
    email = str(data.get("email") or "").strip()
    password = str(data.get("password") or "")
    if not email or not password:
        raise RuntimeError("qa-student.json incompleto")
    return email, password


def _snapshot_protected(db) -> dict[int, tuple[str, int]]:
    rows = db.execute(
        text(
            "SELECT s.id, s.status, "
            "(SELECT COUNT(*) FROM test_answers a WHERE a.test_session_id = s.id) "
            "FROM test_sessions s WHERE s.id IN (137, 138, 139) ORDER BY s.id"
        )
    ).all()
    return {int(r[0]): (str(r[1]), int(r[2])) for r in rows}


def _save_marker(session_id: int) -> None:
    path = _marker_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps({"session_id": session_id, "purpose": "E2E-S21-DISPOSABLE"}),
        encoding="utf-8",
    )


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

        before = _snapshot_protected(db)
        for sid in PROTECTED_IDS:
            if sid not in before:
                print(f"ERROR: sesión protegida {sid} ausente", file=sys.stderr)
                return 5

        user = UserRepository(db).get_by_id(QA_USER_ID)
        if user is None or user.role != UserRole.STUDENT:
            print("ERROR: cuenta QA STUDENT 900000 no encontrada", file=sys.stderr)
            return 6

        student = StudentRepository(db).get_by_user_id(QA_USER_ID)
        if student is None:
            print("ERROR: ficha estudiante QA ausente", file=sys.stderr)
            return 7

        repo = TestSessionRepository(db)

        marker = _marker_path()
        if marker.is_file():
            try:
                prev_id = int(json.loads(marker.read_text(encoding="utf-8"))["session_id"])
            except (KeyError, TypeError, ValueError, json.JSONDecodeError):
                prev_id = 0
            if prev_id and prev_id not in PROTECTED_IDS:
                row = db.execute(
                    text(
                        "SELECT status, "
                        "(SELECT COUNT(*) FROM test_answers a "
                        " WHERE a.test_session_id = s.id) AS answers "
                        "FROM test_sessions s WHERE s.id = :id AND s.student_id = :sid"
                    ),
                    {"id": prev_id, "sid": student.id},
                ).first()
                if row is not None and str(row[0]) == TestSessionStatus.COMPLETED.value:
                    after = _snapshot_protected(db)
                    if after != before:
                        print("ERROR: evidencia 137/138/139 alterada", file=sys.stderr)
                        return 8
                    print(
                        f"OK action=reuse_completed session_id={prev_id} "
                        f"status=COMPLETED answers={int(row[1])} "
                        f"protected_intact=137,138,139"
                    )
                    return 0

        open_sessions = repo.list_open_sessions(student.id)
        open_ids = [s.id for s in open_sessions]
        for sid in (137, 138):
            if sid not in open_ids:
                print(
                    f"ERROR: sesión protegida {sid} no está abierta",
                    file=sys.stderr,
                )
                return 9

        extras = [i for i in open_ids if i not in (137, 138)]
        if extras:
            session_id = extras[0]
            action = "reuse_open"
        else:
            nq = QuestionRepository(db).count_active()
            if nq < 60:
                print(f"ERROR: preguntas activas={nq}", file=sys.stderr)
                return 10
            created = repo.create_session(student.id, nq)
            if created.id in PROTECTED_IDS:
                print("ERROR: id colisiona con protegida", file=sys.stderr)
                return 11
            session_id = created.id
            action = "create_open"
            db.commit()
    finally:
        db.close()

    email, password = _qa_credentials()
    with httpx.Client(base_url=API_BASE, timeout=90.0) as client:
        login = client.post("/auth/login", json={"email": email, "password": password})
        if login.status_code != 200:
            print(f"ERROR: login HTTP {login.status_code}", file=sys.stderr)
            return 13
        token = login.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        detail = client.get(f"/tests/{session_id}/questions", headers=headers)
        if detail.status_code != 200:
            print(f"ERROR: GET questions HTTP {detail.status_code}", file=sys.stderr)
            return 14
        payload = detail.json().get("data")
        if isinstance(payload, dict):
            questions = payload.get("questions") or payload.get("items") or []
        elif isinstance(payload, list):
            questions = payload
        else:
            questions = []
        if len(questions) < 60:
            print(f"ERROR: questions={len(questions)}", file=sys.stderr)
            return 15

        answered = 0
        for q in questions:
            qid = q["id"] if isinstance(q, dict) else q
            if isinstance(q, dict) and "question_id" in q and "id" not in q:
                qid = q["question_id"]
            resp = client.post(
                f"/tests/{session_id}/answers",
                headers=headers,
                json={"question_id": qid, "answer_value": 4},
            )
            if resp.status_code not in (200, 201):
                print(
                    f"ERROR: answer q={qid} HTTP {resp.status_code}",
                    file=sys.stderr,
                )
                return 16
            answered += 1

        finish = client.post(f"/tests/{session_id}/finish", headers=headers)
        if finish.status_code != 200:
            print(f"ERROR: finish HTTP {finish.status_code}", file=sys.stderr)
            return 17
        body = finish.json().get("data") or {}
        status = body.get("status") or "COMPLETED"

    db = SessionLocal()
    try:
        after = _snapshot_protected(db)
        if after != before:
            print(
                f"ERROR: evidencia 137/138/139 alterada before={before} after={after}",
                file=sys.stderr,
            )
            return 18
        answers = db.execute(
            text("SELECT COUNT(*) FROM test_answers WHERE test_session_id = :id"),
            {"id": session_id},
        ).scalar()
        has_riasec = db.execute(
            text("SELECT COUNT(*) FROM riasec_results WHERE test_session_id = :id"),
            {"id": session_id},
        ).scalar()
        _save_marker(session_id)
        print(
            f"OK action={action} session_id={session_id} status={status} "
            f"answers={answers} riasec_rows={has_riasec} answered_api={answered} "
            f"protected_intact=137,138,139"
        )
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
