from dataclasses import dataclass
from datetime import datetime
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.services.llm.fallback_provider import ETHICAL_DISCLAIMER
from app.services.llm.prompts import RIASEC_NAMES


@dataclass(frozen=True)
class PDFInstitutionData:
    name: str
    code: str
    city: str
    province: str
    address: str | None
    phone: str | None
    email: str | None


@dataclass(frozen=True)
class PDFStudentData:
    full_name: str
    identification: str
    grade: str
    parallel: str | None


@dataclass(frozen=True)
class PDFRiasecData:
    score_r: int
    score_i: int
    score_a: int
    score_s: int
    score_e: int
    score_c: int
    dominant_profile: str
    secondary_profile: str
    combined_profile: str


@dataclass(frozen=True)
class PDFRecommendationData:
    career_name: str
    area: str
    match_percentage: float
    ai_explanation: str | None


@dataclass(frozen=True)
class PDFObservationData:
    observation: str
    created_at: datetime


@dataclass(frozen=True)
class PDFReportContext:
    report_code: str
    test_finished_at: datetime | None
    institution: PDFInstitutionData
    student: PDFStudentData
    riasec: PDFRiasecData
    recommendations: list[PDFRecommendationData]
    observations: list[PDFObservationData]
    generator_name: str
    generator_role: str


class PDFRenderer:
    PRIMARY_COLOR = colors.HexColor("#1E3A5F")
    ACCENT_COLOR = colors.HexColor("#2E6DA4")

    def render(self, context: PDFReportContext) -> bytes:
        buffer = BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            leftMargin=2 * cm,
            rightMargin=2 * cm,
            topMargin=2 * cm,
            bottomMargin=2 * cm,
            title=f"Reporte AVOV {context.report_code}",
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            "ReportTitle",
            parent=styles["Heading1"],
            textColor=self.PRIMARY_COLOR,
            spaceAfter=12,
        )
        section_style = ParagraphStyle(
            "SectionTitle",
            parent=styles["Heading2"],
            textColor=self.ACCENT_COLOR,
            spaceBefore=14,
            spaceAfter=8,
        )
        body_style = ParagraphStyle(
            "Body",
            parent=styles["BodyText"],
            leading=14,
            spaceAfter=6,
        )
        disclaimer_style = ParagraphStyle(
            "Disclaimer",
            parent=styles["BodyText"],
            fontSize=9,
            textColor=colors.grey,
            leading=12,
        )

        story: list = []
        story.append(Paragraph("AVOV — Reporte de Orientación Vocacional", title_style))
        story.append(
            Paragraph(
                f"<b>Institución:</b> {context.institution.name} "
                f"({context.institution.code})<br/>"
                f"<b>Ciudad:</b> {context.institution.city}, "
                f"{context.institution.province}<br/>"
                f"<b>Contacto:</b> {context.institution.phone or 'N/D'} | "
                f"{context.institution.email or 'N/D'}",
                body_style,
            )
        )
        story.append(Spacer(1, 0.4 * cm))

        finished_label = (
            context.test_finished_at.strftime("%d/%m/%Y %H:%M")
            if context.test_finished_at
            else "N/D"
        )
        story.append(Paragraph("Datos del estudiante", section_style))
        story.append(
            Paragraph(
                f"<b>Nombre:</b> {context.student.full_name}<br/>"
                f"<b>Identificación:</b> {context.student.identification}<br/>"
                f"<b>Grado/Paralelo:</b> {context.student.grade}"
                f"{f' / {context.student.parallel}' if context.student.parallel else ''}<br/>"
                f"<b>Fecha del test:</b> {finished_label}<br/>"
                f"<b>Código del reporte:</b> {context.report_code}",
                body_style,
            )
        )

        story.append(Paragraph("Perfil RIASEC", section_style))
        dominant = self._format_profile(context.riasec.dominant_profile)
        secondary = self._format_profile(context.riasec.secondary_profile)
        story.append(
            Paragraph(
                f"<b>Perfil dominante:</b> {dominant}<br/>"
                f"<b>Perfil secundario:</b> {secondary}<br/>"
                f"<b>Perfil combinado:</b> {context.riasec.combined_profile}",
                body_style,
            )
        )

        scores_table = Table(
            [
                ["Categoría", "Nombre", "Puntaje"],
                ["R", RIASEC_NAMES["R"], str(context.riasec.score_r)],
                ["I", RIASEC_NAMES["I"], str(context.riasec.score_i)],
                ["A", RIASEC_NAMES["A"], str(context.riasec.score_a)],
                ["S", RIASEC_NAMES["S"], str(context.riasec.score_s)],
                ["E", RIASEC_NAMES["E"], str(context.riasec.score_e)],
                ["C", RIASEC_NAMES["C"], str(context.riasec.score_c)],
            ],
            colWidths=[2.5 * cm, 6 * cm, 3 * cm],
        )
        scores_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), self.PRIMARY_COLOR),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.whitesmoke]),
                    ("ALIGN", (2, 1), (2, -1), "CENTER"),
                ]
            )
        )
        story.append(scores_table)

        story.append(Paragraph("Carreras recomendadas", section_style))
        if context.recommendations:
            rec_rows = [["#", "Carrera", "Área", "Compatibilidad"]]
            for index, item in enumerate(context.recommendations, start=1):
                rec_rows.append(
                    [
                        str(index),
                        item.career_name,
                        item.area,
                        f"{item.match_percentage:.1f}%",
                    ]
                )
            rec_table = Table(
                rec_rows,
                colWidths=[1 * cm, 7 * cm, 4 * cm, 3 * cm],
            )
            rec_table.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), self.ACCENT_COLOR),
                        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                        ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.whitesmoke]),
                    ]
                )
            )
            story.append(rec_table)

            story.append(Spacer(1, 0.3 * cm))
            for index, item in enumerate(context.recommendations, start=1):
                explanation = item.ai_explanation or "Sin explicación adicional."
                story.append(
                    Paragraph(
                        f"<b>{index}. {item.career_name}</b> — {explanation}",
                        body_style,
                    )
                )
        else:
            story.append(
                Paragraph("No hay recomendaciones registradas para esta sesión.", body_style)
            )

        if context.observations:
            story.append(Paragraph("Observaciones del orientador", section_style))
            for obs in context.observations:
                date_label = obs.created_at.strftime("%d/%m/%Y")
                story.append(
                    Paragraph(
                        f"<b>{date_label}:</b> {obs.observation}",
                        body_style,
                    )
                )

        story.append(Paragraph("Responsable del reporte", section_style))
        story.append(
            Paragraph(
                f"<b>Generado por:</b> {context.generator_name} ({context.generator_role})",
                body_style,
            )
        )

        story.append(Spacer(1, 0.5 * cm))
        story.append(Paragraph(f"<i>{ETHICAL_DISCLAIMER}</i>", disclaimer_style))

        doc.build(story)
        return buffer.getvalue()

    @staticmethod
    def _format_profile(code: str) -> str:
        if not code:
            return "N/D"
        letter = code.upper()
        return f"{letter} ({RIASEC_NAMES.get(letter, letter)})"
