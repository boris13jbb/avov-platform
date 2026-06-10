from abc import ABC, abstractmethod


class LLMProvider(ABC):
    @abstractmethod
    async def explain_riasec_profile(self, profile_data: dict) -> str:
        pass

    @abstractmethod
    async def explain_careers(self, careers_data: list[dict]) -> str:
        pass

    @abstractmethod
    async def generate_vocational_summary(self, context: dict) -> str:
        pass

    @abstractmethod
    async def answer_student_question(self, question: str, context: dict) -> str:
        pass
