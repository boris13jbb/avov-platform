import re
import uuid
from pathlib import Path

REPORTS_DIR = Path("storage/reports")
LOGOS_DIR = Path("storage/logos")
REPORT_CODE_PATTERN = re.compile(r"^[A-Z0-9\-]{8,50}$")
LOGO_FILENAME_PATTERN = re.compile(r"^institution_\d+_[a-f0-9]{12}\.(png|jpe?g|webp)$", re.I)
MAX_LOGO_BYTES = 2 * 1024 * 1024
ALLOWED_LOGO_CONTENT_TYPES = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/webp": ".webp",
}


def ensure_reports_directory() -> Path:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    return REPORTS_DIR


def validate_report_code(report_code: str) -> str:
    normalized = report_code.strip().upper()
    if not REPORT_CODE_PATTERN.match(normalized):
        raise ValueError("Código de reporte inválido")
    return normalized


def get_report_file_path(report_code: str) -> Path:
    safe_code = validate_report_code(report_code)
    base_dir = ensure_reports_directory().resolve()
    file_path = (base_dir / f"{safe_code}.pdf").resolve()
    if base_dir not in file_path.parents:
        raise ValueError("Ruta de reporte no permitida")
    return file_path


def save_report_file(report_code: str, content: bytes) -> str:
    file_path = get_report_file_path(report_code)
    file_path.write_bytes(content)
    return str(file_path)


def read_report_file(report_code: str) -> bytes:
    file_path = get_report_file_path(report_code)
    if not file_path.exists():
        raise FileNotFoundError(f"No existe el archivo PDF para {report_code}")
    return file_path.read_bytes()


def ensure_logos_directory() -> Path:
    LOGOS_DIR.mkdir(parents=True, exist_ok=True)
    return LOGOS_DIR


def validate_logo_filename(filename: str) -> str:
    normalized = filename.strip()
    if not LOGO_FILENAME_PATTERN.match(normalized):
        raise ValueError("Nombre de logo inválido")
    return normalized


def get_logo_file_path(filename: str) -> Path:
    safe_name = validate_logo_filename(filename)
    base_dir = ensure_logos_directory().resolve()
    file_path = (base_dir / safe_name).resolve()
    if base_dir not in file_path.parents:
        raise ValueError("Ruta de logo no permitida")
    return file_path


def save_institution_logo(
    institution_id: int,
    content: bytes,
    content_type: str,
) -> str:
    if institution_id < 1:
        raise ValueError("ID de institución inválido")

    normalized_type = content_type.split(";", 1)[0].strip().lower()
    extension = ALLOWED_LOGO_CONTENT_TYPES.get(normalized_type)
    if extension is None:
        raise ValueError("Formato de imagen no permitido. Use PNG, JPG o WEBP")

    if len(content) == 0:
        raise ValueError("El archivo de logo está vacío")

    if len(content) > MAX_LOGO_BYTES:
        raise ValueError("El logo no puede superar 2 MB")

    filename = f"institution_{institution_id}_{uuid.uuid4().hex[:12]}{extension}"
    file_path = get_logo_file_path(filename)
    file_path.write_bytes(content)
    return f"/api/v1/media/logos/{filename}"


def read_logo_file(filename: str) -> tuple[bytes, str]:
    file_path = get_logo_file_path(filename)
    if not file_path.exists():
        raise FileNotFoundError(f"No existe el logo {filename}")

    suffix = file_path.suffix.lower()
    media_type = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }.get(suffix, "application/octet-stream")
    return file_path.read_bytes(), media_type
