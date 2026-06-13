#!/usr/bin/env bash
# AVOV - Actualizacion segura produccion: backup + pull + deploy + validacion (Fase 45)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${AVOV_ENV_FILE:-.env}"
STATE_DIR="${AVOV_STATE_DIR:-$ROOT/.deploy}"
SKIP_PULL="${SKIP_PULL:-0}"
SKIP_SMOKE="${SKIP_SMOKE:-0}"

mkdir -p "$STATE_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: falta $ENV_FILE"
  exit 1
fi

API_URL="$(grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
FRONTEND_URL="$(grep -E '^FRONTEND_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
HTTP_PORT="$(grep -E '^NGINX_HTTP_PORT=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || echo 80)"
API_DOMAIN="$(grep -E '^API_DOMAIN=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || true)"

PREV_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
TS="$(date +%Y%m%d_%H%M%S)"

echo "=== AVOV Update Prod Safe (Fase 45) ==="
echo "Commit actual: $PREV_COMMIT"
echo ""

echo "=== 1/5 Backup pre-actualizacion ==="
AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 AVOV_ENV_FILE="$ENV_FILE" "$ROOT/scripts/backup-all.sh" prod

MYSQL_BKP="$(ls -t backups/mysql/avov_mysql_*.sql 2>/dev/null | head -1 || true)"
QDRANT_BKP="$(ls -t backups/qdrant/avov_qdrant_*.tar.gz 2>/dev/null | head -1 || true)"
STORAGE_BKP="$(ls -t backups/storage/avov_storage_*.tar.gz 2>/dev/null | head -1 || true)"

cat > "$STATE_DIR/release-state.json" <<EOF
{
  "timestamp": "$TS",
  "previous_commit": "$PREV_COMMIT",
  "mysql_backup": "$MYSQL_BKP",
  "qdrant_backup": "$QDRANT_BKP",
  "storage_backup": "$STORAGE_BKP",
  "api_url": "$API_URL",
  "frontend_url": "$FRONTEND_URL"
}
EOF
echo "Estado guardado en $STATE_DIR/release-state.json"

if [[ "$SKIP_PULL" != "1" ]]; then
  echo "=== 2/5 git pull ==="
  git pull --ff-only
else
  echo "=== 2/5 git pull omitido (SKIP_PULL=1) ==="
fi

NEW_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Commit nuevo: $NEW_COMMIT"

echo "=== 3/5 Deploy ==="
AVOV_ENV_FILE="$ENV_FILE" AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 "$ROOT/scripts/deploy-prod-server.sh"

echo "=== 4/5 Post-deploy ==="
"$ROOT/scripts/post-deploy-prod.sh" "$API_URL"

echo "=== 5/5 Smoke public release ==="
if [[ "$SKIP_SMOKE" == "1" ]]; then
  echo "Smoke omitido"
else
  HTTP_API="http://${API_DOMAIN:-localhost}:${HTTP_PORT}/api/v1"
  "$ROOT/scripts/smoke-public-release.sh" "$API_URL" "$FRONTEND_URL" "$HTTP_API"
fi

echo ""
echo "Actualizacion completada."
echo "Rollback disponible: ./scripts/rollback-prod.sh"
