"""Script de validación manual FASE 15 — no imprime tokens."""
import sys

import httpx

BASE = "http://localhost:8000/api/v1"
EMAIL = "estudiante.test.fase11@instituto.edu.co"
PASSWORD = "Estud1234!"
SESSION_ID = 17
STUDENT_ID = 81


def main() -> int:
    try:
        login = httpx.post(
            f"{BASE}/auth/login",
            json={"email": EMAIL, "password": PASSWORD},
            timeout=30,
        )
        print(f"login_status={login.status_code}")
        token = login.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        pdf = httpx.get(
            f"{BASE}/reports/{SESSION_ID}/pdf",
            headers=headers,
            timeout=60,
        )
        print(f"pdf_status={pdf.status_code}")
        print(f"content_type={pdf.headers.get('content-type')}")
        print(f"report_code={pdf.headers.get('x-report-code')}")
        print(f"generated={pdf.headers.get('x-report-generated')}")
        print(f"bytes={len(pdf.content)}")
        print(f"is_pdf={pdf.content[:4] == b'%PDF'}")

        history = httpx.get(
            f"{BASE}/reports/student/{STUDENT_ID}",
            headers=headers,
            timeout=30,
        )
        print(f"history_status={history.status_code}")
        print(f"history_count={len(history.json()['data']['items'])}")
        return 0
    except Exception as exc:
        print(f"ERROR={type(exc).__name__}: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
