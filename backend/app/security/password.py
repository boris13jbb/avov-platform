import logging

from passlib.context import CryptContext
from passlib.exc import UnknownHashError

logger = logging.getLogger(__name__)

# Passlib 1.7.4 intenta leer bcrypt.__about__ y bcrypt 4.2 ya no lo expone.
# El aviso queda atrapado por Passlib. Los hashes siguen siendo bcrypt $2b$.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Comprueba una contraseña contra un hash bcrypt.

    Un hash con formato desconocido se rechaza como no coincidente para
    evitar un error HTTP no controlado. No se registra el hash ni la
    contraseña. Cualquier otro error se propaga.
    """
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except UnknownHashError:
        logger.warning("Hash de contraseña con formato no reconocido")
        return False
