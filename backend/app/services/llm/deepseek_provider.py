"""Adaptador DeepSeek — delega en LLMService para mantener compatibilidad."""

from app.services.llm.llm_service import LLMService
from app.services.llm.provider import LLMProvider


class DeepSeekProvider(LLMProvider):
    def __init__(self) -> None:
        self._service = LLMService()

    async def explain_riasec_profile(self, profile_data: dict) -> str:
        result = await self._service.explain_riasec_profile(profile_data)
        return result.answer

    async def explain_careers(self, careers_data: list[dict]) -> str:
        result = await self._service.explain_careers(careers_data)
        return result.answer

    async def generate_vocational_summary(self, context: dict) -> str:
        profile_data = context.get("profile_data", {})
        result = await self._service.explain_riasec_profile(profile_data)
        return result.answer

    async def answer_student_question(self, question: str, context: dict) -> str:
        result = await self._service.answer_student_question(question, context)
        return result.answer
