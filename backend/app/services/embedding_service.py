"""Generación local de embeddings determinísticos para carreras (MVP Fase 12)."""

import hashlib
import math
import re

from app.core.config import get_settings
from app.models.career import Career

RIASEC_LETTER_NAMES = {
    "R": "Realista",
    "I": "Investigador",
    "A": "Artístico",
    "S": "Social",
    "E": "Emprendedor",
    "C": "Convencional",
}


def build_career_embedding_text(career: Career) -> str:
    return (
        f"{career.name} | {career.area} | Perfil {career.riasec_profile} | "
        f"{career.description} | Campo: {career.employment_field}"
    )


def build_profile_search_text(
    *,
    riasec_profile: str | None = None,
    query: str | None = None,
) -> str:
    parts: list[str] = []

    if riasec_profile:
        normalized = re.sub(r"[^A-Za-z]", "", riasec_profile).upper()
        if normalized:
            labels = [
                RIASEC_LETTER_NAMES.get(letter, letter)
                for letter in normalized
            ]
            parts.append(
                f"Perfil vocacional {normalized} ({', '.join(labels)})"
            )

    if query:
        parts.append(query.strip())

    return " | ".join(part for part in parts if part)


def text_to_embedding(text: str, vector_size: int | None = None) -> list[float]:
    size = vector_size or get_settings().qdrant_vector_size
    vector = [0.0] * size
    normalized = text.lower().strip()

    if not normalized:
        return vector

    tokens = re.findall(r"[a-záéíóúñ0-9]+", normalized)
    for token in tokens:
        digest = hashlib.sha256(token.encode("utf-8")).digest()
        for index, byte_value in enumerate(digest):
            vector[index % size] += (byte_value / 255.0) - 0.5

    norm = math.sqrt(sum(value * value for value in vector))
    if norm == 0:
        return vector

    return [value / norm for value in vector]
