from sqlalchemy import BigInteger, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import BigIntPKMixin, TimestampMixin


class CounselorObservation(Base, BigIntPKMixin, TimestampMixin):
    __tablename__ = "counselor_observations"

    test_session_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    counselor_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    observation: Mapped[str] = mapped_column(Text, nullable=False)

    test_session = relationship("TestSession", back_populates="counselor_observations")
