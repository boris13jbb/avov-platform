# Imagen de producción para Cloud Run / contenedores inmutables.
# Desarrollo local: docker-compose.yml puede sobrescribir el comando con --reload.
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .

# Cloud Run inyecta PORT; localmente se puede fijar BACKEND_PORT vía Compose.
EXPOSE 8080

# Sin --reload. shell form para expandir PORT en tiempo de arranque.
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}
