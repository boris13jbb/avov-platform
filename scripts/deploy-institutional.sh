#!/usr/bin/env bash
# AVOV - Despliegue institucional completo en VPS Linux (Fase 44)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${AVOV_ENV_FILE:-.env}"
PROJECT="${AVOV_PROD_PROJECT:-avov-prod}"
RUN_LETSENCRYPT="${RUN_LETSENCRYPT:-0}"
INSTALL_CRON="${INSTALL_CRON:-1}"
SKIP_SMOKE="${SKIP_SMOKE:-0}"

echo "=== AVOV Despliegue Institucional (Fase 44) ==="
echo "Directorio: $ROOT"
echo "Env: $ENV_FILE"
echo ""

command -v docker >/dev/null 2>&1 || { echo "ERROR: instala Docker"; exit 1; }

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f .env.production.server.example ]]; then
    cp .env.production.server.example "$ENV_FILE"
    echo "ADVERTENCIA: $ENV_FILE creado. Edita dominios y claves antes de continuar."
    exit 1
  fi
  echo "ERROR: falta $ENV_FILE"
  exit 1
fi

API_URL="$(grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
FRONTEND_URL="$(grep -E '^FRONTEND_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
HTTP_PORT="$(grep -E '^NGINX_HTTP_PORT=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || echo 80)"
API_DOMAIN="$(grep -E '^API_DOMAIN=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || true)"

if [[ "$API_URL" == *tudominio.edu.co* ]]; then
  echo "ERROR: reemplaza placeholders en $ENV_FILE (dominios y claves)"
  exit 1
fi

echo "=== 1/6 Build Flutter Web ==="
ENV_FILE="$ENV_FILE" "$ROOT/scripts/build-flutter-web.sh"

if [[ "$RUN_LETSENCRYPT" == "1" ]]; then
  echo "=== 2/6 Let's Encrypt ==="
  if [[ -z "${LETSENCRYPT_EMAIL:-}" ]]; then
    echo "ERROR: define LETSENCRYPT_EMAIL para certbot"
    exit 1
  fi
  "$ROOT/scripts/setup-letsencrypt.sh"
else
  echo "=== 2/6 Certificados SSL ==="
  if [[ ! -f nginx/certs/fullchain.pem ]]; then
    echo "ERROR: falta nginx/certs/fullchain.pem (RUN_LETSENCRYPT=1 o copia certs)"
    exit 1
  fi
  echo "Certificados presentes."
fi

echo "=== 3/6 Deploy stack prod + web + ssl ==="
AVOV_ENV_FILE="$ENV_FILE" AVOV_PROD_PROJECT="$PROJECT" AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 \
  "$ROOT/scripts/deploy-prod-server.sh"

echo "=== 4/6 Post-deploy API ==="
"$ROOT/scripts/post-deploy-prod.sh" "$API_URL"

echo "=== 5/6 Smoke public release ==="
if [[ "$SKIP_SMOKE" == "1" ]]; then
  echo "Smoke omitido (SKIP_SMOKE=1)"
else
  HTTP_API_URL=""
  if [[ -n "$API_DOMAIN" ]]; then
    HTTP_API_URL="http://${API_DOMAIN}/api/v1"
  else
    HTTP_API_URL="http://localhost:${HTTP_PORT}/api/v1"
  fi
  "$ROOT/scripts/smoke-public-release.sh" "$API_URL" "$FRONTEND_URL" "$HTTP_API_URL"
fi

if [[ "$INSTALL_CRON" == "1" ]]; then
  echo "=== 6/6 Cron backups + monitor ==="
  INSTALL=1 AVOV_ROOT="$ROOT" "$ROOT/scripts/install-vps-cron.sh"
else
  echo "=== 6/6 Cron omitido (INSTALL_CRON=0) ==="
fi

echo ""
echo "=== Despliegue institucional completado ==="
echo "  Frontend: $FRONTEND_URL"
echo "  API:      $API_URL"
echo ""
echo "Siguiente paso manual obligatorio:"
echo "  Completar checklist UI: docs/fase-41-flutter-ui-manual.md"
echo "  Plantilla reporte: docs/fase-44-ui-checklist-report.template.md"
