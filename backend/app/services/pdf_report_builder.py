"""Construcción de PDF vocacional con ReportLab (sin llamadas a IA externas)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ETHICAL_NOTE = (
    "Este resultado es orientativo y no reemplaza la orientación profesional "
    "de un psicólogo, docente u orientador educativo. La orientación vocacional "
    "es una herramienta de apoyo y no constituye una decisión definitiva sobre "
    "el futuro académico o profesional."
)


@dataclass(frozen=True)
class PdfCareerRow:
    name: str
    area: str
    riasec_profile: str
    match_percentage: float
    explanation: str | None


@dataclass(frozen=True)
class VocationalPdfData:
    report_code: str
    generated_at: datetime
    institution_name: str
    institution_city: str | None
    student_full_name: str
    student_identification: str
    student_grade: str
    student_parallel: str | None
    session_id: int
    started_at: datetime | None
    finished_at: datetime | None
    dominant_profile: str | None
    secondary_profile: str | None
    combined_profile: str | None
    score_r: int
    score_i: int
    score_a: int
    score_s: int
    score_e: int
    score_c: int
    interpretation: str | None
    careers: list[PdfCareerRow]
    counselor_observation: str | None
    generated_by_label: str


def build_vocational_pdf(data: VocationalPdfData) -> bytes:
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=1.8 * cm,
        bottomMargin=1.8 * cm,
        title=f"Informe vocacional {data.report_code}",
        author="AVOV",
    )

    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="AvovTitle",
            parent=styles["Heading1"],
            fontSize=16,
            alignment=TA_CENTER,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="AvovHeading",
            parent=styles["Heading2"],
            fontSize=12,
            spaceBefore=12,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="AvovBody",
            parent=styles["Normal"],
            fontSize=10,
            leading=13,
            alignment=TA_LEFT,
        )
    )
    styles.add(
        ParagraphStyle(
            name="AvovJustify",
            parent=styles["Normal"],
            fontSize=9,
            leading=12,
            alignment=TA_JUSTIFY,
        )
    )
    styles.add(
        ParagraphStyle(
            name="AvovSmall",
            parent=styles["Normal"],
            fontSize=8,
            leading=10,
            textColor=colors.HexColor("#444444"),
        )
    )

    story: list = []
    story.append(Paragraph("AVOV — Informe de orientación vocacional", styles["AvovTitle"]))
    story.append(
        Paragraph(
            f"Código de informe: <b>{_esc(data.report_code)}</b>",
            styles["AvovBody"],
        )
    )
    story.append(
        Paragraph(
            f"Generado: {_fmt_dt(data.generated_at)} · Por: {_esc(data.generated_by_label)}",
            styles["AvovSmall"],
        )
    )
    story.append(Spacer(1, 0.3 * cm))

    story.append(Paragraph("1. Institución", styles["AvovHeading"]))
    story.append(Paragraph(_esc(data.institution_name), styles["AvovBody"]))
    if data.institution_city:
        story.append(Paragraph(f"Ciudad: {_esc(data.institution_city)}", styles["AvovBody"]))

    story.append(Paragraph("2. Estudiante", styles["AvovHeading"]))
    story.append(Paragraph(f"Nombre: {_esc(data.student_full_name)}", styles["AvovBody"]))
    story.append(
        Paragraph(
            f"Identificación: {_esc(data.student_identification)}",
            styles["AvovBody"],
        )
    )
    grade_line = f"Curso: {_esc(data.student_grade)}"
    if data.student_parallel:
        grade_line += f" · Paralelo: {_esc(data.student_parallel)}"
    story.append(Paragraph(grade_line, styles["AvovBody"]))

    story.append(Paragraph("3. Evaluación", styles["AvovHeading"]))
    story.append(Paragraph(f"Sesión: {data.session_id}", styles["AvovBody"]))
    if data.started_at:
        story.append(
            Paragraph(f"Inicio: {_fmt_dt(data.started_at)}", styles["AvovBody"])
        )
    if data.finished_at:
        story.append(
            Paragraph(f"Finalización: {_fmt_dt(data.finished_at)}", styles["AvovBody"])
        )

    story.append(Paragraph("4. Perfil RIASEC", styles["AvovHeading"]))
    profile_bits = []
    if data.combined_profile:
        profile_bits.append(f"Combinado: {_esc(data.combined_profile)}")
    if data.dominant_profile:
        profile_bits.append(f"Dominante: {_esc(data.dominant_profile)}")
    if data.secondary_profile:
        profile_bits.append(f"Secundario: {_esc(data.secondary_profile)}")
    if profile_bits:
        story.append(Paragraph(" · ".join(profile_bits), styles["AvovBody"]))

    scores = [
        ["Categoría", "Puntaje"],
        ["Realista (R)", str(data.score_r)],
        ["Investigador (I)", str(data.score_i)],
        ["Artístico (A)", str(data.score_a)],
        ["Social (S)", str(data.score_s)],
        ["Emprendedor (E)", str(data.score_e)],
        ["Convencional (C)", str(data.score_c)],
    ]
    table = Table(scores, colWidths=[10 * cm, 4 * cm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1B3A5C")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.grey),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.whitesmoke, colors.white]),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    story.append(table)

    if data.interpretation:
        story.append(Spacer(1, 0.25 * cm))
        story.append(Paragraph("Interpretación registrada", styles["AvovHeading"]))
        story.append(Paragraph(_esc(data.interpretation), styles["AvovJustify"]))

    story.append(Paragraph("5. Carreras recomendadas", styles["AvovHeading"]))
    if not data.careers:
        story.append(
            Paragraph(
                "No hay carreras recomendadas persistidas para esta evaluación.",
                styles["AvovBody"],
            )
        )
    else:
        for index, career in enumerate(data.careers, start=1):
            story.append(
                Paragraph(
                    f"<b>{index}. {_esc(career.name)}</b> · "
                    f"{career.match_percentage:.0f}% · "
                    f"{_esc(career.area)} · Perfil {_esc(career.riasec_profile)}",
                    styles["AvovBody"],
                )
            )
            if career.explanation:
                story.append(Paragraph(_esc(career.explanation), styles["AvovJustify"]))
            story.append(Spacer(1, 0.15 * cm))

    if data.counselor_observation:
        story.append(Paragraph("6. Observación del orientador", styles["AvovHeading"]))
        story.append(Paragraph(_esc(data.counselor_observation), styles["AvovJustify"]))

    story.append(Paragraph("Nota ética", styles["AvovHeading"]))
    story.append(Paragraph(ETHICAL_NOTE, styles["AvovJustify"]))

    doc.build(story)
    return buffer.getvalue()


def _esc(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def _fmt_dt(value: datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M")
