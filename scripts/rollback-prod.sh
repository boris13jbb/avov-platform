#!/usr/bin/env bash
# AVOV - Rollback produccion al commit y backups registrados (Fase 45)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STATE_FILE="${AVOV_STATE_FILE:-$ROOT/.deploy/release-state.json}"
ENV_FILE="${AVOV_ENV_FILE:-.env}"
GIT_REF="${ROLLBACK_GIT_REF:-}"
RESTORE_DB="${ROLLBACK_RESTORE_DB:-0}"
FORCE="${FORCE:-0}"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "ERROR: no existe $STATE_FILE"
  echo "Ejecuta primero ./scripts/update-prod-safe.sh para registrar estado."
  exit 1
fi

PREV_COMMIT="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('previous_commit',''))" 2>/dev/null || true)"
MYSQL_BKP="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('mysql_backup',''))" 2>/dev/null || true)"
QDRANT_BKP="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('qdrant_backup',''))" 2>/dev/null || true)"
STORAGE_BKP="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('storage_backup',''))" 2>/dev/null || true)"
API_URL="$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('api_url',''))" 2>/dev/null || grep -E '^API_BASE_URL=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"

TARGET_REF="${GIT_REF:-$PREV_COMMIT}"
if [[ -z "$TARGET_REF" || "$TARGET_REF" == "unknown" ]]; then
  echo "ERROR: no hay commit previo en release-state.json"
  exit 1
fi

echo "=== AVOV Rollback Produccion (Fase 45) ==="
echo "Commit destino: $TARGET_REF"
echo "Restaurar BD: $RESTORE_DB"
echo "MySQL backup: $MYSQL_BKP"
if [[ "$FORCE" != "1" ]]; then
  read -r -p "Confirmar rollback (escriba SI): " confirm
  [[ "$confirm" == "SI" ]] || { echo "Cancelado."; exit 1; }
fi

echo "=== 1/4 git checkout ==="
git fetch --all 2>/dev/null || true
git checkout "$TARGET_REF"

echo "=== 2/4 Redeploy stack ==="
AVOV_ENV_FILE="$ENV_FILE" AVOV_PROD_WEB=1 AVOV_PROD_SSL=1 "$ROOT/scripts/deploy-prod-server.sh"

if [[ "$RESTORE_DB" == "1" ]]; then
  echo "=== 3/4 Restaurar backups ==="
  FORCE=1 AVOV_ENV_FILE="$ENV_FILE" "$ROOT/scripts/restore-backup.sh" "$MYSQL_BKP" "$QDRANT_BKP" "$STORAGE_BKP"
else
  echo "=== 3/4 Restauracion BD omitida (ROLLBACK_RESTORE_DB=0) ==="
fi

echo "=== 4/4 Post-deploy ==="
"$ROOT/scripts/post-deploy-prod.sh" "$API_URL"

echo ""
echo "Rollback completado. Valida con smoke-public-release.sh"
