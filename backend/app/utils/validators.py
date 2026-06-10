import re

EMAIL_PATTERN = re.compile(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$")
PHONE_PATTERN = re.compile(r"^\d{7,15}$")
PASSWORD_PATTERN = re.compile(
    r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).{8,}$"
)


def is_valid_email(value: str) -> bool:
    return bool(EMAIL_PATTERN.match(value.strip()))


def is_valid_phone(value: str) -> bool:
    return bool(PHONE_PATTERN.match(value.strip()))


def is_strong_password(value: str) -> bool:
    return bool(PASSWORD_PATTERN.match(value))
