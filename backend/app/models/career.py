from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Enum,
    Float,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import CareerStatus, DegreeType, InstitutionType
from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class Career(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "careers"
    __table_args__ = (
        Index("ix_careers_riasec_profile", "riasec_profile"),
        Index("ix_careers_area", "area"),
        Index("ix_careers_status", "status"),
        Index("ix_careers_degree_type", "degree_type"),
    )

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    area: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    riasec_profile: Mapped[str] = mapped_column(String(10), nullable=False)
    duration: Mapped[str | None] = mapped_column(String(50), nullable=True)
    degree_type: Mapped[DegreeType] = mapped_column(
        Enum(DegreeType, name="degree_type"),
        nullable=False,
    )
    institution_type: Mapped[InstitutionType] = mapped_column(
        Enum(InstitutionType, name="institution_type"),
        nullable=False,
    )
    employment_field: Mapped[str] = mapped_column(String(200), nullable=False)
    status: Mapped[CareerStatus] = mapped_column(
        Enum(CareerStatus, name="career_status"),
        nullable=False,
        default=CareerStatus.ACTIVE,
    )

    recommendations = relationship("Recommendation", back_populates="career")


class Recommendation(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "recommendations"
    __table_args__ = (
        UniqueConstraint("test_session_id", "career_id", name="uq_recommendations_session_career"),
        CheckConstraint(
            "match_percentage >= 0 AND match_percentage <= 100",
            name="ck_recommendations_match_percentage",
        ),
        Index("ix_recommendations_student_id", "student_id"),
    )

    student_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )
    test_session_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    career_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("careers.id", ondelete="RESTRICT"),
        nullable=False,
    )
    match_percentage: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    ai_explanation: Mapped[str | None] = mapped_column(Text, nullable=True)
    qdrant_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    student = relationship("Student", back_populates="recommendations")
    test_session = relationship("TestSession", back_populates="recommendations")
    career = relationship("Career", back_populates="recommendations")
