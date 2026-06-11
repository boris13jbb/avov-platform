import csv
import io
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.enums import AssignmentStatus, TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, ValidationException
from app.models.riasec import RiasecResult, TestSession
from app.models.student import CounselorAssignment, Student
from app.models.user import User
from app.repositories.student_repository import StudentRepository
from app.services.test_session_service import TestSessionService


@dataclass(frozen=True)
class CSVExportResult:
    filename: str
    content: str


class ExportService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.student_repo = StudentRepository(db)

    def export_students_csv(self, current_user: User) -> CSVExportResult:
        if current_user.role != UserRole.INSTITUTION_ADMIN:
            raise ForbiddenException("No tienes permisos para exportar estudiantes")
        if current_user.institution_id is None:
            raise ValidationException("Tu usuario no tiene institución asignada")

        students, _ = self.student_repo.list(
            page=1,
            page_size=10_000,
            institution_id=current_user.institution_id,
        )

        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(
            [
                "id",
                "identificacion",
                "nombres",
                "apellidos",
                "email",
                "grado",
                "paralelo",
                "estado",
            ]
        )
        for student in students:
            user = student.user
            writer.writerow(
                [
                    student.id,
                    student.identification,
                    user.first_name if user else "",
                    user.last_name if user else "",
                    user.email if user else "",
                    student.grade,
                    student.parallel or "",
                    user.status.value if user else "",
                ]
            )

        return CSVExportResult(
            filename=f"estudiantes_institucion_{current_user.institution_id}.csv",
            content=buffer.getvalue(),
        )

    def export_test_results_csv(self, current_user: User) -> CSVExportResult:
        if current_user.role not in {
            UserRole.INSTITUTION_ADMIN,
            UserRole.COUNSELOR,
        }:
            raise ForbiddenException("No tienes permisos para exportar resultados")

        institution_id, counselor_id = self._resolve_scope(current_user)
        sessions = self._list_completed_sessions(
            institution_id=institution_id,
            counselor_id=counselor_id,
        )

        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(
            [
                "test_session_id",
                "student_id",
                "estudiante",
                "identificacion",
                "fecha_finalizacion",
                "perfil_dominante",
                "perfil_secundario",
                "perfil_combinado",
                "score_r",
                "score_i",
                "score_a",
                "score_s",
                "score_e",
                "score_c",
            ]
        )

        for session in sessions:
            student = session.student
            user = student.user if student else None
            result = session.riasec_result
            if result is None:
                continue
            combined = TestSessionService._compute_combined_profile(result)
            writer.writerow(
                [
                    session.id,
                    session.student_id,
                    f"{user.first_name} {user.last_name}".strip() if user else "",
                    student.identification if student else "",
                    session.finished_at.isoformat() if session.finished_at else "",
                    result.dominant_profile,
                    result.secondary_profile,
                    combined,
                    result.score_r,
                    result.score_i,
                    result.score_a,
                    result.score_s,
                    result.score_e,
                    result.score_c,
                ]
            )

        suffix = (
            f"counselor_{current_user.id}"
            if counselor_id is not None
            else f"institution_{institution_id}"
        )
        return CSVExportResult(
            filename=f"resultados_test_{suffix}.csv",
            content=buffer.getvalue(),
        )

    def _resolve_scope(self, current_user: User) -> tuple[int | None, int | None]:
        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if current_user.institution_id is None:
                raise ValidationException("Tu usuario no tiene institución asignada")
            return current_user.institution_id, None
        return current_user.institution_id, current_user.id

    def _list_completed_sessions(
        self,
        *,
        institution_id: int | None,
        counselor_id: int | None,
    ) -> list[TestSession]:
        stmt = (
            select(TestSession)
            .join(Student, TestSession.student_id == Student.id)
            .options(
                joinedload(TestSession.student).joinedload(Student.user),
                joinedload(TestSession.riasec_result),
            )
            .where(TestSession.status == TestSessionStatus.COMPLETED)
            .order_by(TestSession.finished_at.desc())
        )
        if institution_id is not None:
            stmt = stmt.where(Student.institution_id == institution_id)
        if counselor_id is not None:
            stmt = stmt.join(
                CounselorAssignment,
                CounselorAssignment.student_id == Student.id,
            ).where(
                CounselorAssignment.counselor_id == counselor_id,
                CounselorAssignment.status == AssignmentStatus.ACTIVE,
            )

        return list(self.db.scalars(stmt).unique().all())
