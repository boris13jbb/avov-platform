import asyncio
from dataclasses import dataclass

import httpx

from app.core.config import Settings, get_settings
from app.services.llm.fallback_provider import ETHICAL_DISCLAIMER, FallbackProvider
from app.services.llm.prompts import (
    build_chat_messages,
    build_explain_careers_messages,
    build_explain_profile_messages,
)


@dataclass(frozen=True)
class LLMResult:
    answer: str
    source: str
    ethical_disclaimer: str = ETHICAL_DISCLAIMER


class LLMService:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self._fallback = FallbackProvider()

    def is_configured(self) -> bool:
        return bool(self.settings.deepseek_api_key.strip())

    async def explain_riasec_profile(self, profile_data: dict) -> LLMResult:
        messages = build_explain_profile_messages(profile_data)
        answer = await self._complete(messages)
        if answer:
            return LLMResult(answer=answer, source="deepseek")
        fallback = await self._fallback.explain_riasec_profile(profile_data)
        return LLMResult(answer=fallback, source="fallback")

    async def explain_careers(self, careers_data: list[dict]) -> LLMResult:
        messages = build_explain_careers_messages(careers_data)
        answer = await self._complete(messages)
        if answer:
            return LLMResult(answer=answer, source="deepseek")
        fallback = await self._fallback.explain_careers(careers_data)
        return LLMResult(answer=fallback, source="fallback")

    async def answer_student_question(self, question: str, context: dict) -> LLMResult:
        messages = build_chat_messages(question, context)
        answer = await self._complete(messages)
        if answer:
            return LLMResult(answer=answer, source="deepseek")
        fallback = await self._fallback.answer_student_question(question, context)
        return LLMResult(answer=fallback, source="fallback")

    async def _complete(self, messages: list[dict]) -> str | None:
        if not self.is_configured():
            return None

        url = f"{self.settings.deepseek_api_base_url.rstrip('/')}/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.settings.deepseek_api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.settings.deepseek_model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 900,
        }

        for attempt in range(self.settings.deepseek_max_retries):
            try:
                async with httpx.AsyncClient(
                    timeout=self.settings.deepseek_timeout_seconds,
                ) as client:
                    response = await client.post(url, headers=headers, json=payload)
                    response.raise_for_status()
                    data = response.json()
                    content = data["choices"][0]["message"]["content"]
                    return str(content).strip()
            except Exception:
                if attempt >= self.settings.deepseek_max_retries - 1:
                    return None
                await asyncio.sleep(attempt + 1)

        return None
