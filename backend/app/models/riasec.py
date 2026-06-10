from datetime import datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import QuestionStatus, TestSessionStatus
from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class RiasecCategory(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "riasec_categories"

    code: Mapped[str] = mapped_column(String(1), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    questions = relationship("Question", back_populates="category")


class Question(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "questions"
    __table_args__ = (
        UniqueConstraint("category_id", "order_number", name="uq_questions_category_order"),
        Index("ix_questions_status", "status"),
    )

    category_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("riasec_categories.id", ondelete="RESTRICT"),
        nullable=False,
    )
    text: Mapped[str] = mapped_column(Text, nullable=False)
    order_number: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[QuestionStatus] = mapped_column(
        Enum(QuestionStatus, name="question_status"),
        nullable=False,
        default=QuestionStatus.ACTIVE,
    )

    category = relationship("RiasecCategory", back_populates="questions")
    answers = relationship("TestAnswer", back_populates="question")


class TestSession(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "test_sessions"
    __table_args__ = (Index("ix_test_sessions_student_status", "student_id", "status"),)

    student_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    status: Mapped[TestSessionStatus] = mapped_column(
        Enum(TestSessionStatus, name="test_session_status"),
        nullable=False,
        default=TestSessionStatus.STARTED,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )
    finished_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    total_questions: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    current_question: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    student = relationship("Student", back_populates="test_sessions")
    answers = relationship("TestAnswer", back_populates="test_session")
    riasec_result = relationship("RiasecResult", back_populates="test_session", uselist=False)
    recommendations = relationship("Recommendation", back_populates="test_session")
    reports = relationship("Report", back_populates="test_session")
    counselor_observations = relationship("CounselorObservation", back_populates="test_session")


class TestAnswer(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "test_answers"
    __table_args__ = (
        UniqueConstraint("test_session_id", "question_id", name="uq_test_answers_session_question"),
        CheckConstraint("answer_value >= 1 AND answer_value <= 5", name="ck_test_answers_value"),
    )

    test_session_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    question_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("questions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    answer_value: Mapped[int] = mapped_column(SmallInteger, nullable=False)

    test_session = relationship("TestSession", back_populates="answers")
    question = relationship("Question", back_populates="answers")


class RiasecResult(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "riasec_results"
    __table_args__ = (
        CheckConstraint("score_r >= 0", name="ck_riasec_score_r"),
        CheckConstraint("score_i >= 0", name="ck_riasec_score_i"),
        CheckConstraint("score_a >= 0", name="ck_riasec_score_a"),
        CheckConstraint("score_s >= 0", name="ck_riasec_score_s"),
        CheckConstraint("score_e >= 0", name="ck_riasec_score_e"),
        CheckConstraint("score_c >= 0", name="ck_riasec_score_c"),
    )

    test_session_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    student_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    score_r: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    score_i: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    score_a: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    score_s: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    score_e: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    score_c: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    dominant_profile: Mapped[str | None] = mapped_column(String(1), nullable=True)
    secondary_profile: Mapped[str | None] = mapped_column(String(1), nullable=True)
    interpretation: Mapped[str | None] = mapped_column(Text, nullable=True)

    test_session = relationship("TestSession", back_populates="riasec_result")
    student = relationship("Student", back_populates="riasec_results")
