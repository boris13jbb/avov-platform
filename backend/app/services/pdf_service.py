import uuid
from dataclasses import dataclass

from fastapi import Request
from sqlalchemy.orm import Session

from app.core.enums import TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.user import User
from app.repositories.institution_repository import InstitutionRepository
from app.repositories.recommendation_repository import RecommendationRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.report import ReportListResponse, ReportResponse
from app.services.audit_service import AuditService
from app.services.pdf_renderer import (
    PDFInstitutionData,
    PDFObservationData,
    PDFRecommendationData,
    PDFRenderer,
    PDFReportContext,
    PDFRiasecData,
    PDFStudentData,
)
from app.services.recommendation_service import RecommendationService
from app.services.test_session_service import TestSessionService
from app.utils.file_storage import read_report_file, save_report_file


@dataclass(frozen=True)
class PDFDownloadResult:
    content: bytes
    report_code: str
    generated: bool


class PDFService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.report_repo = ReportRepository(db)
        self.test_repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.institution_repo = InstitutionRepository(db)
        self.recommendation_repo = RecommendationRepository(db)
        self.user_repo = UserRepository(db)
        self.test_service = TestSessionService(db)
        self.recommendation_service = RecommendationService(db)
        self.audit = AuditService(db)
        self.renderer = PDFRenderer()

    def download_pdf(
        self,
        test_session_id: int,
        current_user: User,
        request: Request | None = None,
    ) -> PDFDownloadResult:
        session = self.test_repo.get_by_id(test_session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")

        self.test_service._ensure_can_view_result(session, current_user)

        if session.status != TestSessionStatus.COMPLETED:
            raise ValidationException("El test aún no ha sido completado")

        if not self.recommendation_repo.exists_for_session(test_session_id):
            raise ValidationException(
                "Debes generar recomendaciones antes de descargar el reporte PDF"
            )

        existing = self.report_repo.get_by_test_session(test_session_id)
        if existing is not None:
            try:
                content = read_report_file(existing.report_code)
                self._log_action(
                    action="PDF_DOWNLOADED",
                    user=current_user,
                    report_id=existing.id,
                    report_code=existing.report_code,
                    request=request,
                )
                return PDFDownloadResult(
                    content=content,
                    report_code=existing.report_code,
                    generated=False,
                )
            except FileNotFoundError:
                context = self._build_context(
                    session,
                    current_user,
                    report_code=existing.report_code,
                )
                pdf_bytes = self.renderer.render(context)
                save_report_file(existing.report_code, pdf_bytes)
                self._log_action(
                    action="PDF_GENERATED",
                    user=current_user,
                    report_id=existing.id,
                    report_code=existing.report_code,
                    request=request,
                )
                return PDFDownloadResult(
                    content=pdf_bytes,
                    report_code=existing.report_code,
                    generated=True,
                )

        context = self._build_context(session, current_user)
        pdf_bytes = self.renderer.render(context)
        file_path = save_report_file(context.report_code, pdf_bytes)
        report = self.report_repo.create(
            student_id=session.student_id,
            test_session_id=session.id,
            file_path=file_path,
            report_code=context.report_code,
            generated_by=current_user.id,
        )

        self._log_action(
            action="PDF_GENERATED",
            user=current_user,
            report_id=report.id,
            report_code=context.report_code,
            request=request,
        )

        return PDFDownloadResult(
            content=pdf_bytes,
            report_code=context.report_code,
            generated=True,
        )

    def list_by_student(
        self,
        student_id: int,
        current_user: User,
    ) -> ReportListResponse:
        student = self.student_repo.get_by_id(student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")

        self.recommendation_service._ensure_can_view_student_recommendations(
            student,
            current_user,
        )

        items = self.report_repo.list_by_student(student_id)
        return ReportListResponse(
            student_id=student_id,
            items=[ReportResponse.model_validate(item) for item in items],
        )

    def _build_context(
        self,
        session,
        current_user: User,
        report_code: str | None = None,
    ) -> PDFReportContext:
        student = self.student_repo.get_by_id(session.student_id)
        if student is None or student.user is None:
            raise NotFoundException("Estudiante no encontrado")

        institution = self.institution_repo.get_by_id(student.institution_id)
        if institution is None:
            raise NotFoundException("Institución no encontrada")

        riasec = self.test_repo.get_riasec_result(session.id)
        if riasec is None:
            raise NotFoundException("Resultado RIASEC no encontrado")

        recommendations = self.recommendation_repo.list_by_test_session(session.id)
        observations = self.recommendation_repo.list_observations_by_test_session(
            session.id
        )

        report_code = report_code or self._generate_report_code(session.id)
        full_name = f"{student.user.first_name} {student.user.last_name}".strip()

        return PDFReportContext(
            report_code=report_code,
            test_finished_at=session.finished_at,
            institution=PDFInstitutionData(
                name=institution.name,
                code=institution.code,
                city=institution.city,
                province=institution.province,
                address=institution.address,
                phone=institution.phone,
                email=institution.email,
            ),
            student=PDFStudentData(
                full_name=full_name,
                identification=student.identification,
                grade=student.grade,
                parallel=student.parallel,
            ),
            riasec=PDFRiasecData(
                score_r=riasec.score_r,
                score_i=riasec.score_i,
                score_a=riasec.score_a,
                score_s=riasec.score_s,
                score_e=riasec.score_e,
                score_c=riasec.score_c,
                dominant_profile=riasec.dominant_profile,
                secondary_profile=riasec.secondary_profile,
                combined_profile=TestSessionService._compute_combined_profile(riasec),
            ),
            recommendations=[
                PDFRecommendationData(
                    career_name=item.career.name if item.career else f"Carrera {item.career_id}",
                    area=item.career.area if item.career else "N/D",
                    match_percentage=float(item.match_percentage),
                    ai_explanation=item.ai_explanation,
                )
                for item in recommendations
                if item.career is not None
            ],
            observations=[
                PDFObservationData(
                    observation=obs.observation,
                    created_at=obs.created_at,
                )
                for obs in observations
            ],
            generator_name=(
                f"{current_user.first_name} {current_user.last_name}".strip()
            ),
            generator_role=current_user.role.value,
        )

    @staticmethod
    def _generate_report_code(test_session_id: int) -> str:
        suffix = uuid.uuid4().hex[:8].upper()
        return f"AVOV-{test_session_id}-{suffix}"

    def _log_action(
        self,
        *,
        action: str,
        user: User,
        report_id: int,
        report_code: str,
        request: Request | None,
    ) -> None:
        ip_address = None
        user_agent = None
        if request is not None and request.client is not None:
            ip_address = request.client.host
        if request is not None:
            user_agent = request.headers.get("user-agent")

        self.audit.log(
            action=action,
            entity="reports",
            user_id=user.id,
            entity_id=report_id,
            ip_address=ip_address,
            user_agent=user_agent,
            details={"report_code": report_code},
        )
