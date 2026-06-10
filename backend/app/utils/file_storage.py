from pathlib import Path

REPORTS_DIR = Path("storage/reports")


def ensure_reports_directory() -> Path:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    return REPORTS_DIR
