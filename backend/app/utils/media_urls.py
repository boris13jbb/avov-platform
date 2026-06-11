import re
from urllib.parse import urlparse

MEDIA_LOGO_PATH_PREFIX = "/api/v1/media/logos/"
LOCAL_API_HOSTS = {"localhost", "127.0.0.1", "10.0.2.2", "::1"}
FULL_LOCAL_LOGO_URL_PATTERN = re.compile(
    r"^https?://[^/]+(/api/v1/media/logos/[^?\s#]+)",
    re.IGNORECASE,
)


def normalize_institution_logo_url(logo_url: str | None) -> str | None:
    """Unifica logos propios de la API como ruta relativa."""
    if logo_url is None:
        return None

    normalized = logo_url.strip()
    if not normalized:
        return None

    if normalized.startswith(MEDIA_LOGO_PATH_PREFIX):
        return normalized

    match = FULL_LOCAL_LOGO_URL_PATTERN.match(normalized)
    if match:
        return match.group(1)

    parsed = urlparse(normalized)
    if parsed.scheme in {"http", "https"} and parsed.path.startswith(MEDIA_LOGO_PATH_PREFIX):
        host = parsed.hostname or ""
        if host.lower() in LOCAL_API_HOSTS:
            return parsed.path

    return normalized
