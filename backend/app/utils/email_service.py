import logging
import smtplib
from email.message import EmailMessage

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class EmailService:
    def send_password_reset(self, *, to_email: str, reset_url: str) -> bool:
        settings = get_settings()
        subject = f"{settings.app_name} — Recuperación de contraseña"
        body = (
            f"Hola,\n\n"
            f"Recibimos una solicitud para restablecer la contraseña de tu cuenta en "
            f"{settings.app_name}.\n\n"
            f"Usa el siguiente enlace (válido por {settings.password_reset_expire_hours} hora(s)):\n"
            f"{reset_url}\n\n"
            f"Si no solicitaste este cambio, ignora este mensaje.\n\n"
            f"Equipo {settings.app_name}"
        )

        if not settings.smtp_enabled:
            logger.info(
                "SMTP deshabilitado — enlace de recuperación para %s: %s",
                to_email,
                reset_url,
            )
            return False

        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = settings.smtp_from_email
        message["To"] = to_email
        message.set_content(body)

        try:
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as server:
                if settings.smtp_use_tls:
                    server.starttls()
                if settings.smtp_username and settings.smtp_password:
                    server.login(settings.smtp_username, settings.smtp_password)
                server.send_message(message)
            logger.info("Correo de recuperación enviado a %s", to_email)
            return True
        except Exception:
            logger.exception("No se pudo enviar el correo de recuperación a %s", to_email)
            logger.info(
                "Enlace de recuperación alternativo para %s: %s",
                to_email,
                reset_url,
            )
            return False
