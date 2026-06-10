"""Construcción de prompts seguros para el asistente vocacional."""

from app.services.llm.fallback_provider import ETHICAL_DISCLAIMER

SYSTEM_PROMPT = (
    "Eres un asistente de orientación vocacional para estudiantes de bachillerato. "
    "Explica de forma clara, educativa, empática y no determinista. "
    "Las recomendaciones son orientativas y no reemplazan la orientación profesional "
    "de un psicólogo u orientador educativo. "
    "No inventes carreras ni datos que no estén en el contexto proporcionado. "
    "Responde siempre en español."
)

RIASEC_NAMES = {
    "R": "Realista",
    "I": "Investigador",
    "A": "Artístico",
    "S": "Social",
    "E": "Emprendedor",
    "C": "Convencional",
}


def _format_profile_letter(letter: str | None) -> str:
    if not letter:
        return "No definido"
    code = letter.upper()
    return f"{code} ({RIASEC_NAMES.get(code, code)})"


def build_explain_profile_messages(profile_data: dict) -> list[dict]:
    dominant = _format_profile_letter(profile_data.get("dominant_profile"))
    secondary = _format_profile_letter(profile_data.get("secondary_profile"))
    combined = profile_data.get("combined_profile", "")

    user_content = (
        "Explica el siguiente perfil vocacional RIASEC de forma comprensible para un "
        "estudiante de bachillerato:\n"
        f"- Perfil dominante: {dominant}\n"
        f"- Perfil secundario: {secondary}\n"
        f"- Perfil combinado: {combined or 'No disponible'}\n"
        f"- Puntajes: R={profile_data.get('score_r', 0)}, "
        f"I={profile_data.get('score_i', 0)}, A={profile_data.get('score_a', 0)}, "
        f"S={profile_data.get('score_s', 0)}, E={profile_data.get('score_e', 0)}, "
        f"C={profile_data.get('score_c', 0)}\n\n"
        "Incluye fortalezas, estilo de trabajo y áreas de interés. "
        f"Cierra con esta advertencia: {ETHICAL_DISCLAIMER}"
    )

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_content},
    ]


def build_explain_careers_messages(careers_data: list[dict]) -> list[dict]:
    lines = []
    for index, career in enumerate(careers_data, start=1):
        lines.append(
            f"{index}. {career.get('name')} | Área: {career.get('area')} | "
            f"Perfil RIASEC: {career.get('riasec_profile')} | "
            f"Título: {career.get('degree_type')} | "
            f"Campo laboral: {career.get('employment_field')}"
        )

    user_content = (
        "Explica por qué estas carreras pueden ser adecuadas para un estudiante, "
        "usando únicamente la información listada:\n"
        + "\n".join(lines)
        + f"\n\nCierra con esta advertencia: {ETHICAL_DISCLAIMER}"
    )

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_content},
    ]


def build_chat_messages(question: str, context: dict) -> list[dict]:
    profile_summary = context.get("profile_summary", "Sin perfil RIASEC completado aún.")
    careers_summary = context.get("careers_summary", "Sin carreras sugeridas en contexto.")

    user_content = (
        "Contexto del estudiante:\n"
        f"- Perfil RIASEC: {profile_summary}\n"
        f"- Carreras de referencia: {careers_summary}\n\n"
        f"Pregunta del estudiante: {question}\n\n"
        "Responde de forma breve, clara y orientativa. "
        f"Incluye al final: {ETHICAL_DISCLAIMER}"
    )

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_content},
    ]
