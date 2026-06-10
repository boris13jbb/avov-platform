from sqlalchemy.orm import Session

from app.core.enums import TestSessionStatus, UserRole
from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.models.riasec import TestSession
from app.models.user import User
from app.repositories.question_repository import QuestionRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.test_session_repository import TestSessionRepository
from app.schemas.test_session import (
    QuestionForTest,
    RiasecResultResponse,
    SessionQuestionsResponse,
    TestAnswerCreate,
    TestAnswerResponse,
    TestSessionResponse,
)
from app.services.riasec_calculator import TIE_BREAK_ORDER, calculate_riasec


class TestSessionService:
    RESULT_VIEW_ROLES = {
        UserRole.STUDENT,
        UserRole.COUNSELOR,
        UserRole.INSTITUTION_ADMIN,
        UserRole.SUPER_ADMIN,
    }

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = TestSessionRepository(db)
        self.student_repo = StudentRepository(db)
        self.question_repo = QuestionRepository(db)

    def start_test(self, current_user: User) -> TestSessionResponse:
        if current_user.role != UserRole.STUDENT:
            raise ForbiddenException("Solo los estudiantes pueden iniciar el test vocacional")

        student = self._get_student_profile(current_user)
        existing = self.repo.get_open_session_for_student(student.id)
        if existing:
            return self._build_session_response(existing)

        active_count = self.question_repo.count_active()
        if active_count == 0:
            raise ValidationException("No hay preguntas activas disponibles para el test")

        session = self.repo.create_session(student.id, active_count)
        return self._build_session_response(session)

    def get_session_questions(
        self,
        session_id: int,
        current_user: User,
    ) -> SessionQuestionsResponse:
        session = self._get_or_404(session_id)
        self._ensure_session_owner(session, current_user)

        if session.status == TestSessionStatus.COMPLETED:
            raise ValidationException("El test ya fue completado")

        questions = self.repo.list_active_questions()
        answers = {
            answer.question_id: answer.answer_value
            for answer in self.repo.list_answers_for_session(session_id)
        }

        question_items = [
            QuestionForTest(
                id=question.id,
                category_id=question.category_id,
                category=question.category,
                text=question.text,
                order_number=question.order_number,
                answer_value=answers.get(question.id),
            )
            for question in questions
        ]

        return SessionQuestionsResponse(
            session=self._build_session_response(session),
            questions=question_items,
        )

    def save_answer(
        self,
        session_id: int,
        payload: TestAnswerCreate,
        current_user: User,
    ) -> TestAnswerResponse:
        session = self._get_or_404(session_id)
        self._ensure_session_owner(session, current_user)
        self._ensure_session_editable(session)

        active_ids = self.repo.get_active_question_ids()
        if payload.question_id not in active_ids:
            raise NotFoundException("Pregunta no encontrada o inactiva")

        answer = self.repo.upsert_answer(
            session_id,
            payload.question_id,
            payload.answer_value,
        )

        answered_count = self.repo.count_answers(session_id)
        next_status = (
            TestSessionStatus.IN_PROGRESS
            if session.status == TestSessionStatus.STARTED
            else session.status
        )
        self.repo.update_session_progress(
            session,
            status=next_status,
            current_question=min(answered_count + 1, session.total_questions),
        )

        return TestAnswerResponse.model_validate(answer)

    def finish_test(
        self,
        session_id: int,
        current_user: User,
    ) -> RiasecResultResponse:
        session = self._get_or_404(session_id)
        self._ensure_session_owner(session, current_user)

        if session.status == TestSessionStatus.COMPLETED:
            existing = self.repo.get_riasec_result(session_id)
            if existing:
                return self._build_result_response(existing)
            raise ValidationException("El test está completado pero no tiene resultado")

        if session.status not in TestSessionRepository.OPEN_STATUSES:
            raise ValidationException("La sesión de test no puede finalizarse en su estado actual")

        answers = self.repo.list_answers_for_session(session_id)
        active_ids = self.repo.get_active_question_ids()

        if len(answers) != len(active_ids):
            missing = len(active_ids) - len(answers)
            raise ValidationException(
                f"Faltan {missing} respuestas para completar el test"
            )

        answered_ids = {answer.question_id for answer in answers}
        if answered_ids != active_ids:
            raise ValidationException("Debes responder todas las preguntas activas del test")

        calculation = calculate_riasec(answers)

        if self.repo.get_riasec_result(session_id):
            raise ValidationException("El resultado RIASEC ya fue calculado para esta sesión")

        result = self.repo.create_riasec_result(
            test_session_id=session_id,
            student_id=session.student_id,
            score_r=calculation.score_r,
            score_i=calculation.score_i,
            score_a=calculation.score_a,
            score_s=calculation.score_s,
            score_e=calculation.score_e,
            score_c=calculation.score_c,
            dominant_profile=calculation.dominant_profile,
            secondary_profile=calculation.secondary_profile,
        )
        self.repo.complete_session(session)
        return self._build_result_response(result, calculation.combined_profile)

    def get_result(
        self,
        session_id: int,
        current_user: User,
    ) -> RiasecResultResponse:
        session = self._get_or_404(session_id)
        self._ensure_can_view_result(session, current_user)

        if session.status != TestSessionStatus.COMPLETED:
            raise ValidationException("El test aún no ha sido completado")

        result = self.repo.get_riasec_result(session_id)
        if result is None:
            raise NotFoundException("Resultado RIASEC no encontrado")

        return self._build_result_response(result)

    def _get_or_404(self, session_id: int) -> TestSession:
        session = self.repo.get_by_id(session_id)
        if session is None:
            raise NotFoundException("Sesión de test no encontrada")
        return session

    def _get_student_profile(self, current_user: User):
        student = self.student_repo.get_by_user_id(current_user.id)
        if student is None:
            raise ValidationException(
                "Tu usuario no tiene perfil de estudiante registrado"
            )
        return student

    def _ensure_session_owner(self, session: TestSession, current_user: User) -> None:
        if current_user.role != UserRole.STUDENT:
            raise ForbiddenException("Solo el estudiante dueño puede realizar esta acción")

        student = self._get_student_profile(current_user)
        if session.student_id != student.id:
            raise ForbiddenException("No tienes permisos para acceder a esta sesión de test")

    @staticmethod
    def _ensure_session_editable(session: TestSession) -> None:
        if session.status == TestSessionStatus.COMPLETED:
            raise ValidationException("No puedes modificar un test completado")
        if session.status == TestSessionStatus.CANCELLED:
            raise ValidationException("No puedes modificar un test cancelado")

    def _ensure_can_view_result(self, session: TestSession, current_user: User) -> None:
        if current_user.role not in self.RESULT_VIEW_ROLES:
            raise ForbiddenException("No tienes permisos para ver este resultado")

        if current_user.role == UserRole.STUDENT:
            student = self._get_student_profile(current_user)
            if session.student_id != student.id:
                raise ForbiddenException("No tienes permisos para ver este resultado")
            return

        if current_user.role == UserRole.SUPER_ADMIN:
            return

        student = self.student_repo.get_by_id(session.student_id)
        if student is None:
            raise NotFoundException("Estudiante no encontrado")

        if current_user.role == UserRole.INSTITUTION_ADMIN:
            if student.institution_id == current_user.institution_id:
                return
            raise ForbiddenException("No tienes permisos para ver este resultado")

        if current_user.role == UserRole.COUNSELOR:
            if (
                student.institution_id == current_user.institution_id
                and self.student_repo.is_assigned_to_counselor(
                    student.id,
                    current_user.id,
                )
            ):
                return
            raise ForbiddenException("No tienes permisos para ver este resultado")

        raise ForbiddenException("No tienes permisos para ver este resultado")

    def _build_session_response(self, session: TestSession) -> TestSessionResponse:
        answered_count = self.repo.count_answers(session.id)
        total = session.total_questions or 1
        progress_percent = round((answered_count / total) * 100, 2)

        return TestSessionResponse(
            id=session.id,
            student_id=session.student_id,
            status=session.status,
            started_at=session.started_at,
            finished_at=session.finished_at,
            total_questions=session.total_questions,
            current_question=session.current_question,
            answered_count=answered_count,
            progress_percent=progress_percent,
            created_at=session.created_at,
            updated_at=session.updated_at,
        )

    @staticmethod
    def _build_result_response(
        result,
        combined_profile: str | None = None,
    ) -> RiasecResultResponse:
        if combined_profile is None:
            combined_profile = TestSessionService._compute_combined_profile(result)

        return RiasecResultResponse(
            id=result.id,
            test_session_id=result.test_session_id,
            student_id=result.student_id,
            score_r=result.score_r,
            score_i=result.score_i,
            score_a=result.score_a,
            score_s=result.score_s,
            score_e=result.score_e,
            score_c=result.score_c,
            dominant_profile=result.dominant_profile,
            secondary_profile=result.secondary_profile,
            combined_profile=combined_profile,
            interpretation=result.interpretation,
            created_at=result.created_at,
            updated_at=result.updated_at,
        )

    @staticmethod
    def _compute_combined_profile(result) -> str:
        scores = {
            "R": result.score_r,
            "I": result.score_i,
            "A": result.score_a,
            "S": result.score_s,
            "E": result.score_e,
            "C": result.score_c,
        }
        ranked = sorted(
            TIE_BREAK_ORDER,
            key=lambda code: (-scores[code], TIE_BREAK_ORDER.index(code)),
        )
        return "".join(ranked[:3])
