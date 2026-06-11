#!/bin/sh
set -e

echo "[AVOV] Aplicando migraciones de base de datos..."
attempt=0
max_attempts=30

until alembic upgrade head; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "[AVOV] ERROR: no se pudo aplicar migraciones tras ${max_attempts} intentos."
        exit 1
    fi
    echo "[AVOV] Esperando MySQL... (${attempt}/${max_attempts})"
    sleep 2
done

workers="${UVICORN_WORKERS:-2}"
echo "[AVOV] Iniciando API en modo producción (${workers} workers)..."

exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers "${workers}" \
    --proxy-headers \
    --forwarded-allow-ips='*'
