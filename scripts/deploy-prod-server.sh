#!/usr/bin/env bash
# AVOV - Despliegue servidor real con API + Flutter Web (Fase 42)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${AVOV_ENV_FILE:-.env}"
PROJECT="${AVOV_PROD_PROJECT:-avov-prod}"
USE_SSL="${AVOV_PROD_SSL:-0}"
USE_WEB="${AVOV_PROD_WEB:-1}"

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f .env.production.server.example ]]; then
    cp .env.production.server.example "$ENV_FILE"
    echo "ADVERTENCIA: $ENV_FILE creado desde .env.production.server.example"
    echo "Edita dominios y claves antes de continuar."
    exit 1
  fi
  echo "ERROR: Falta $ENV_FILE"
  exit 1
fi

if [[ "$USE_WEB" == "1" ]]; then
  if [[ ! -f frontend/build/web/index.html ]]; then
    echo "=== Build Flutter Web ==="
    ENV_FILE="$ENV_FILE" "$ROOT/scripts/build-flutter-web.sh"
  fi
fi

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$ROOT/scripts/preflight-server.ps1" -EnvFile "$ENV_FILE"
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/preflight-server.ps1" -EnvFile "$ENV_FILE"
else
  echo "=== Preflight servidor (bash) ==="
  api_url="$(grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
  cors="$(grep -E '^BACKEND_CORS_ORIGINS=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
  frontend="$(grep -E '^FRONTEND_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
  [[ "$api_url" == https://* ]] || { echo "ERROR: API_BASE_URL debe ser HTTPS"; exit 1; }
  [[ "$frontend" == https://* ]] || { echo "ERROR: FRONTEND_BASE_URL debe ser HTTPS"; exit 1; }
  [[ "$cors" == *"${frontend%/}"* ]] || { echo "ERROR: CORS debe incluir FRONTEND_BASE_URL"; exit 1; }
  echo "Preflight servidor OK (bash)"
fi

COMPOSE=( -f docker-compose.prod.yml )
if [[ "$USE_WEB" == "1" ]]; then
  COMPOSE+=( -f docker-compose.prod.web.yml )
fi
if [[ "$USE_SSL" == "1" ]]; then
  if [[ "$USE_WEB" == "1" ]]; then
    COMPOSE+=( -f docker-compose.prod.web.ssl.yml )
  else
    COMPOSE+=( -f docker-compose.prod.ssl.yml )
  fi
  [[ -f nginx/certs/fullchain.pem ]] || { echo "ERROR: falta nginx/certs/fullchain.pem"; exit 1; }
fi

echo "=== Levantando stack $PROJECT ==="
docker compose "${COMPOSE[@]}" --env-file "$ENV_FILE" -p "$PROJECT" up --build -d

API_URL="$(grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || true)"
echo ""
echo "Stack iniciado."
echo "  API: ${API_URL:-/api/v1/health/live}"
if [[ "$USE_WEB" == "1" ]]; then
  FRONT="$(grep -E '^FRONTEND_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || true)"
  echo "  Web: ${FRONT:-https://app.tudominio.edu.co}"
fi
echo "  Post-deploy: ./scripts/post-deploy-prod.sh \"${API_URL}\""
