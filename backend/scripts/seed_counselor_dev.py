"""Seed orientador de prueba y asignación al estudiante fase11."""

from __future__ import annotations

import sys

from sqlalchemy import select

from app.core.enums import UserRole, UserStatus
from app.db.session import SessionLocal
from app.models.student import Student
from app.models.user import User
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository
from app.security.password import hash_password

COUNSELOR_EMAIL = "orientador.test.fase26@instituto.edu.co"
COUNSELOR_PASSWORD = "Counsel1234!"
STUDENT_EMAIL = "estudiante.test.fase11@instituto.edu.co"


def main() -> int:
    session = SessionLocal()
    try:
        student = session.scalar(
            select(Student)
            .join(User, Student.user_id == User.id)
            .where(User.email == STUDENT_EMAIL)
        )
        if student is None:
            print(
                f"No se encontró el estudiante {STUDENT_EMAIL}. "
                "Créalo primero en el entorno de desarrollo."
            )
            return 1

        user_repo = UserRepository(session)
        student_repo = StudentRepository(session)

        counselor = user_repo.get_by_email(COUNSELOR_EMAIL)
        if counselor is None:
            counselor = user_repo.create_raw(
                email=COUNSELOR_EMAIL,
                password=COUNSELOR_PASSWORD,
                first_name="Orientador",
                last_name="Fase26",
                role=UserRole.COUNSELOR,
                status=UserStatus.ACTIVE,
                institution_id=student.institution_id,
            )
            print(f"Orientador creado: {COUNSELOR_EMAIL}")
        else:
            counselor.institution_id = student.institution_id
            counselor.status = UserStatus.ACTIVE
            counselor.password_hash = hash_password(COUNSELOR_PASSWORD)
            session.add(counselor)
            session.commit()
            print(f"Orientador actualizado: {COUNSELOR_EMAIL}")

        student_repo.assign_counselor(
            student_id=student.id,
            counselor_id=counselor.id,
            institution_id=student.institution_id,
        )

        print(
            "Asignación activa creada entre orientador "
            f"{counselor.id} y estudiante {student.id}"
        )
        print(f"Credenciales orientador: {COUNSELOR_EMAIL} / {COUNSELOR_PASSWORD}")
        return 0
    finally:
        session.close()


if __name__ == "__main__":
    sys.exit(main())
