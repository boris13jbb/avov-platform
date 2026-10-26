"""Generación y descarga segura de informes PDF vocacionales."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.enums import TestSessionStatus
from app.core.exceptions import NotFoundException, ValidationException
from app.models.counselor import CounselorObservation
from app.models.report import Report
from app.models.student import Student
from app.models.user import User
from app.repositories.audit_repository import AuditRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.report import PaginatedReports
from app.services.pdf_report_builder import (
    PdfCareerRow,
    VocationalPdfData,
    build_vocational_pdf,
)
from app.services.student_service import StudentService
from app.services.test_session_service import TestSessionService
from app.utils.file_storage import (
    get_report_blob_store,
    storage_object_name,
)


@dataclass(frozen=True)
class PdfDownload:
    content: bytes
    filename: str
    report_code: str
    regenerated: bool


class ReportService:
    ENTITY = "report"
    ACTION_GENERATED = "PDF_GENERATED"
    ACTION_DOWNLOADED = "PDF_DOWNLOADED"
    ACTION_REGENERATED = "PDF_REGENERATED"

    def __init__(self, db: Session) -> None:
        self.db = db
        self.reports = ReportRepository(db)
        self.sessions = TestSessionRepository(db)
        self.students = StudentRepository(db)
        self.recommendations = RecommendationRepository(db)
        self.audit = AuditRepository(db)
        self._session_service = TestSessionService(db)
        self._student_service = StudentService(db)

    def list_student_reports(
        self,
        student_id: int,
        current_user: User,
        *,
        page: int = 1,
        page_size: int = 20,
    ) -> PaginatedReports:
        """Lista metadatos de informes del estudiante (sin rutas de archivo).

        La autorización reutiliza ``StudentService.get_student`` / ``_ensure_can_view``:
        STUDENT solo su ficha, INSTITUTION_ADMIN misma institución, COUNSELOR
        asignado, SUPER_ADMIN todos.
        """
        # Valida existencia y permisos; 404/403 iguales que GET /students/{id}.
        self._student_service.get_student(student_id, current_user)

        total = self.reports.count_by_student(student_id)
        items = self.reports.list_by_student(
            student_id,
            page=page,
            page_size=page_size,
        )
        return PaginatedReports.build(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
        )

    def get_session_pdf(
        self,
        session_id: int,
        current_user: User,
        *,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> PdfDownload:
        session = self.sessions.get_by_id(session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        self._session_service._ensure_can_view_result(session, current_user)

        if session.status != TestSessionStatus.COMPLETED:
            raise ValidationException(
                "Solo se puede generar el informe PDF de una evaluación finalizada"
            )

        store = get_report_blob_store()
        existing = self.reports.get_latest_for_session(session_id)
        if existing is not None:
            try:
                stored_name = storage_object_name(Path(existing.file_path).name)
            except ValueError as exc:
                raise ValidationException(
                    "El registro del informe tiene una ruta inválida"
                ) from exc

            if store.exists(stored_name):
                content = store.read_bytes(stored_name)
                if not content.startswith(b"%PDF-"):
                    content = self._rewrite_file(existing, session_id, current_user)
                    regenerated = True
                    action = self.ACTION_REGENERATED
                else:
                    regenerated = False
                    action = self.ACTION_DOWNLOADED
                self._audit(
                    user_id=current_user.id,
                    action=action,
                    report_id=existing.id,
                    details={
                        "test_session_id": session_id,
                        "report_code": existing.report_code,
                        "regenerated": regenerated,
                    },
                    ip_address=ip_address,
                    user_agent=user_agent,
                )
                return PdfDownload(
                    content=content,
                    filename=self._download_filename(existing.report_code),
                    report_code=existing.report_code,
                    regenerated=regenerated,
                )

            # Registro sin archivo: regenerar bytes y actualizar ruta.
            content = self._build_pdf_bytes(
                session_id=session_id,
                report_code=existing.report_code,
                current_user=current_user,
            )
            filename = self._storage_filename(existing.report_code)
            try:
                relative = store.write_bytes(filename, content)
            except OSError as exc:
                raise ValidationException(
                    "No se pudo guardar el informe PDF en el almacenamiento"
                ) from exc
            self.reports.update_file_path(existing, relative)
            self._audit(
                user_id=current_user.id,
                action=self.ACTION_REGENERATED,
                report_id=existing.id,
                details={
                    "test_session_id": session_id,
                    "report_code": existing.report_code,
                    "reason": "missing_file",
                },
                ip_address=ip_address,
                user_agent=user_agent,
            )
            return PdfDownload(
                content=content,
                filename=self._download_filename(existing.report_code),
                report_code=existing.report_code,
                regenerated=True,
            )

        report_code = self._new_report_code(session_id)
        content = self._build_pdf_bytes(
            session_id=session_id,
            report_code=report_code,
            current_user=current_user,
        )
        filename = self._storage_filename(report_code)
        try:
            relative = store.write_bytes(filename, content)
        except OSError as exc:
            raise ValidationException(
                "No se pudo guardar el informe PDF en el almacenamiento"
            ) from exc

        report = Report(
            student_id=session.student_id,
            test_session_id=session_id,
            file_path=relative,
            report_code=report_code,
            generated_by=current_user.id,
        )
        try:
            created = self.reports.create(report)
        except Exception:
            store.delete(filename)
            raise

        try:
            self._audit(
                user_id=current_user.id,
                action=self.ACTION_GENERATED,
                report_id=created.id,
                details={
                    "test_session_id": session_id,
                    "report_code": report_code,
                },
                ip_address=ip_address,
                user_agent=user_agent,
            )
        except Exception:
            # El archivo y el registro ya existen; no borrar el PDF por fallo de auditoría.
            raise ValidationException(
                "El informe se generó pero no se pudo registrar la auditoría"
            )

        return PdfDownload(
            content=content,
            filename=self._download_filename(report_code),
            report_code=report_code,
            regenerated=False,
        )

    def _rewrite_file(
        self,
        report: Report,
        session_id: int,
        current_user: User,
    ) -> bytes:
        content = self._build_pdf_bytes(
            session_id=session_id,
            report_code=report.report_code,
            current_user=current_user,
        )
        filename = self._storage_filename(report.report_code)
        store = get_report_blob_store()
        relative = store.write_bytes(filename, content)
        if Path(report.file_path).name != filename:
            self.reports.update_file_path(report, relative)
        return content

    def _build_pdf_bytes(
        self,
        *,
        session_id: int,
        report_code: str,
        current_user: User,
    ) -> bytes:
        session = self.sessions.get_by_id(session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        result = self.sessions.get_riasec_result(session_id)
        if result is None:
            raise ValidationException(
                "La sesión no tiene resultado RIASEC. No se puede generar el informe."
            )

        student = self.db.execute(
            select(Student)
            .options(
                joinedload(Student.user),
                joinedload(Student.institution),
            )
            .where(Student.id == session.student_id)
        ).unique().scalar_one_or_none()
        if student is None:
            raise NotFoundException("Estudiante no encontrado")

        user = student.user
        institution = student.institution
        if user is None:
            raise NotFoundException("Usuario del estudiante no encontrado")
        recs = self.recommendations.list_for_session(session_id)
        careers = [
            PdfCareerRow(
                name=(row.career.name if row.career else f"Carrera {row.career_id}"),
                area=(row.career.area if row.career else "No disponible"),
                riasec_profile=(
                    row.career.riasec_profile if row.career else "N/D"
                ),
                match_percentage=float(row.match_percentage),
                explanation=row.ai_explanation,
            )
            for row in recs
        ]

        observation = self._latest_observation(session_id)
        combined = getattr(result, "combined_profile", None)
        if not combined:
            parts = [
                p
                for p in (result.dominant_profile, result.secondary_profile)
                if p
            ]
            combined = "".join(parts) or None

        payload = VocationalPdfData(
            report_code=report_code,
            generated_at=datetime.now(timezone.utc).replace(tzinfo=None),
            institution_name=institution.name if institution else "Institución",
            institution_city=institution.city if institution else None,
            student_full_name=f"{user.first_name} {user.last_name}".strip(),
            student_identification=student.identification,
            student_grade=student.grade,
            student_parallel=student.parallel,
            session_id=session_id,
            started_at=session.started_at,
            finished_at=session.finished_at,
            dominant_profile=result.dominant_profile,
            secondary_profile=result.secondary_profile,
            combined_profile=combined,
            score_r=result.score_r,
            score_i=result.score_i,
            score_a=result.score_a,
            score_s=result.score_s,
            score_e=result.score_e,
            score_c=result.score_c,
            interpretation=result.interpretation,
            careers=careers,
            counselor_observation=observation,
            generated_by_label=(
                f"{current_user.first_name} {current_user.last_name}".strip()
                or current_user.email
            ),
        )
        content = build_vocational_pdf(payload)
        if not content.startswith(b"%PDF-"):
            raise ValidationException("El generador PDF produjo un archivo inválido")
        return content

    def _latest_observation(self, session_id: int) -> str | None:
        stmt = (
            select(CounselorObservation)
            .where(CounselorObservation.test_session_id == session_id)
            .order_by(CounselorObservation.id.desc())
            .limit(1)
        )
        row = self.db.scalars(stmt).first()
        if row is None:
            return None
        text = (row.observation or "").strip()
        return text or None

    def _audit(
        self,
        *,
        user_id: int,
        action: str,
        report_id: int,
        details: dict,
        ip_address: str | None,
        user_agent: str | None,
    ) -> None:
        self.audit.create(
            user_id=user_id,
            action=action,
            entity=self.ENTITY,
            entity_id=report_id,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
        )

    @staticmethod
    def _new_report_code(session_id: int) -> str:
        return f"AVOV-S{session_id}-{uuid.uuid4().hex[:10].upper()}"

    @staticmethod
    def _storage_filename(report_code: str) -> str:
        # Solo caracteres seguros; el código ya es alfanumérico con guiones.
        safe = report_code.replace("/", "").replace("\\", "").replace("..", "")
        return f"{safe}.pdf"

    @staticmethod
    def _download_filename(report_code: str) -> str:
        return f"informe-vocacional-{report_code}.pdf"
