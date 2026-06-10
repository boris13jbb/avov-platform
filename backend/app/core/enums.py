from enum import StrEnum


class UserRole(StrEnum):
    SUPER_ADMIN = "SUPER_ADMIN"
    INSTITUTION_ADMIN = "INSTITUTION_ADMIN"
    COUNSELOR = "COUNSELOR"
    STUDENT = "STUDENT"


class UserStatus(StrEnum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    BLOCKED = "BLOCKED"


class InstitutionStatus(StrEnum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class QuestionStatus(StrEnum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class TestSessionStatus(StrEnum):
    STARTED = "STARTED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class Gender(StrEnum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    OTHER = "OTHER"
    NOT_SPECIFIED = "NOT_SPECIFIED"


class DegreeType(StrEnum):
    TECNOLOGICO = "TECNOLOGICO"
    TERCER_NIVEL = "TERCER_NIVEL"
    LICENCIATURA = "LICENCIATURA"
    INGENIERIA = "INGENIERIA"
    OTRO = "OTRO"


class InstitutionType(StrEnum):
    PUBLICA = "PUBLICA"
    PRIVADA = "PRIVADA"
    AMBAS = "AMBAS"


class CareerStatus(StrEnum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class AssignmentStatus(StrEnum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
