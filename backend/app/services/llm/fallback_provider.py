from app.services.llm.provider import LLMProvider

ETHICAL_DISCLAIMER = (
    "Este resultado es orientativo y no reemplaza la orientación profesional "
    "de un psicólogo, docente u orientador educativo."
)


class FallbackProvider(LLMProvider):
    async def explain_riasec_profile(self, profile_data: dict) -> str:
        dominant = profile_data.get("dominant_profile", "N/A")
        return (
            f"Tu perfil vocacional dominante es {dominant}. "
            f"{ETHICAL_DISCLAIMER}"
        )

    async def explain_careers(self, careers_data: list[dict]) -> str:
        names = ", ".join(c.get("name", "") for c in careers_data[:3])
        return (
            f"Las carreras sugeridas incluyen: {names}. "
            f"{ETHICAL_DISCLAIMER}"
        )

    async def generate_vocational_summary(self, context: dict) -> str:
        return f"Resumen vocacional generado con datos disponibles. {ETHICAL_DISCLAIMER}"

    async def answer_student_question(self, question: str, context: dict) -> str:
        return (
            "El asistente no está disponible en este momento. "
            f"Consulta con tu orientador. {ETHICAL_DISCLAIMER}"
        )
