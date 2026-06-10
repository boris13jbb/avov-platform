"""Cálculo de puntajes y perfiles RIASEC a partir de respuestas del test."""

from dataclasses import dataclass

from app.models.riasec import TestAnswer

TIE_BREAK_ORDER = ("R", "I", "A", "S", "E", "C")
CATEGORY_CODES = TIE_BREAK_ORDER


@dataclass(frozen=True)
class RiasecCalculation:
    score_r: int
    score_i: int
    score_a: int
    score_s: int
    score_e: int
    score_c: int
    dominant_profile: str
    secondary_profile: str
    combined_profile: str

    def as_scores_dict(self) -> dict[str, int]:
        return {
            "R": self.score_r,
            "I": self.score_i,
            "A": self.score_a,
            "S": self.score_s,
            "E": self.score_e,
            "C": self.score_c,
        }


def calculate_riasec(answers: list[TestAnswer]) -> RiasecCalculation:
    scores = {code: 0 for code in CATEGORY_CODES}

    for answer in answers:
        code = answer.question.category.code.upper()
        if code in scores:
            scores[code] += answer.answer_value

    ranked = sorted(
        CATEGORY_CODES,
        key=lambda code: (-scores[code], TIE_BREAK_ORDER.index(code)),
    )

    dominant = ranked[0]
    secondary = ranked[1]
    combined = "".join(ranked[:3])

    return RiasecCalculation(
        score_r=scores["R"],
        score_i=scores["I"],
        score_a=scores["A"],
        score_s=scores["S"],
        score_e=scores["E"],
        score_c=scores["C"],
        dominant_profile=dominant,
        secondary_profile=secondary,
        combined_profile=combined,
    )
