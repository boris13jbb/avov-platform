#!/usr/bin/env bash
# AVOV — Despliegue produccion Linux (Fase 40)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${AVOV_ENV_FILE:-.env}"
PROJECT="${AVOV_PROD_PROJECT:-avov-prod}"
USE_SSL="${AVOV_PROD_SSL:-0}"

preflight() {
  local file="$1"
  [[ -f "$file" ]] || { echo "ERROR: Falta $file"; exit 1; }
  local errors=()
  while IFS='=' read -r key value; do
    key="${key%%*( )}"
    value="${value%%*( )}"
    case "$key" in
      APP_SECRET_KEY|JWT_SECRET_KEY)
        [[ ${#value} -ge 32 ]] || errors+=("$key debe tener >=32 caracteres")
        [[ "$value" != *CAMBIAR* ]] || errors+=("$key sin cambiar")
        ;;
      APP_DEBUG)
        [[ "$value" != "true" ]] || errors+=("APP_DEBUG debe ser false")
        ;;
      BACKEND_CORS_ORIGINS)
        [[ "$value" != *"*"* ]] || errors+=("CORS no puede ser *")
        ;;
    esac
  done < <(grep -E '^[A-Z_]+=' "$file" | tr -d '\r')
  if ((${#errors[@]})); then
    printf 'Errores preflight:\n' >&2
    printf ' - %s\n' "${errors[@]}" >&2
    exit 1
  fi
  echo "Preflight OK"
}

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f .env.production.example ]]; then
    cp .env.production.example "$ENV_FILE"
  else
    echo "ERROR: Falta $ENV_FILE"
    exit 1
  fi
  echo "ADVERTENCIA: $ENV_FILE creado — edita las claves antes de produccion real."
fi

preflight "$ENV_FILE"

COMPOSE=( -f docker-compose.prod.yml )
if [[ "$USE_SSL" == "1" ]]; then
  COMPOSE+=( -f docker-compose.prod.ssl.yml )
  [[ -f nginx/certs/fullchain.pem ]] || { echo "ERROR: falta nginx/certs/fullchain.pem"; exit 1; }
fi

echo "=== Levantando stack $PROJECT ==="
docker compose "${COMPOSE[@]}" --env-file "$ENV_FILE" -p "$PROJECT" up --build -d

PORT="$(grep -E '^NGINX_HTTP_PORT=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || true)"
PORT="${PORT:-80}"
echo ""
echo "Stack iniciado."
echo "  Health: http://localhost:${PORT}/api/v1/health/live"
