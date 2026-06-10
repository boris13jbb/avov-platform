import asyncio

import httpx

from app.core.config import get_settings


async def main() -> None:
    settings = get_settings()
    url = f"{settings.deepseek_api_base_url.rstrip('/')}/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.deepseek_api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": settings.deepseek_model,
        "messages": [{"role": "user", "content": "Di hola en una palabra"}],
        "max_tokens": 20,
    }

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, headers=headers, json=payload)
            print("status:", response.status_code)
            print("body:", response.text[:800])
    except Exception as exc:
        print("error:", type(exc).__name__, exc)


if __name__ == "__main__":
    asyncio.run(main())
