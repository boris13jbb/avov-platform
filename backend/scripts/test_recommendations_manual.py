"""Script de validación manual para FASE 14 — no imprime tokens."""
import json
import sys

import httpx

BASE = "http://localhost:8000/api/v1"
EMAIL = "estudiante.test.fase11@instituto.edu.co"
PASSWORD = "Estud1234!"


def main() -> int:
    try:
        login = httpx.post(
            f"{BASE}/auth/login",
            json={"email": EMAIL, "password": PASSWORD},
            timeout=30,
        )
        print(f"login_status={login.status_code}")
        if login.status_code != 200:
            print(login.text[:500])
            return 1

        token = login.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        generate = httpx.post(
            f"{BASE}/recommendations/generate",
            headers=headers,
            json={},
            timeout=60,
        )
        print(f"generate_status={generate.status_code}")
        payload = generate.json()
        print(f"generate_success={payload.get('success')}")
        print(f"message={payload.get('message')}")

        data = payload.get("data")
        if not data:
            print(json.dumps(payload, indent=2)[:800])
            return 1

        items = data.get("items", [])
        print(f"items_count={len(items)}")
        print(f"student_id={data.get('student_id')}")
        print(f"test_session_id={data.get('test_session_id')}")
        for item in items:
            career = item["career"]["name"]
            print(
                f"- {career}: match={item['match_percentage']} "
                f"riasec={item['riasec_score']} qdrant={item['qdrant_score']}"
            )
        return 0
    except Exception as exc:
        print(f"ERROR={type(exc).__name__}: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
