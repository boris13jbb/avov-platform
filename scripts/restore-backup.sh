#!/usr/bin/env bash
# AVOV - Restauracion de backups MySQL + Qdrant + storage (Fase 45)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MYSQL_FILE="${1:-}"
QDRANT_FILE="${2:-}"
STORAGE_FILE="${3:-}"
TARGET="${TARGET:-prod}"
FORCE="${FORCE:-0}"

if [[ -z "$MYSQL_FILE" && -z "$QDRANT_FILE" && -z "$STORAGE_FILE" ]]; then
  echo "Uso: $0 <mysql.sql> [qdrant.tar.gz] [storage.tar.gz]"
  echo "Variables: TARGET=prod|staging FORCE=1 AVOV_PROD_WEB=1 AVOV_PROD_SSL=1"
  exit 1
fi

COMPOSE_FILE="docker-compose.prod.yml"
COMPOSE_PROJECT="${AVOV_PROD_PROJECT:-avov-prod}"
ENV_FILE="${AVOV_ENV_FILE:-.env}"
compose_args=(-f "$COMPOSE_FILE")

if [[ "$TARGET" == "staging" ]]; then
  COMPOSE_PROJECT="${AVOV_STAGING_PROJECT:-avov-staging}"
  ENV_FILE=".env.staging"
  compose_args+=(-f docker-compose.staging.yml)
else
  if [[ "${AVOV_PROD_WEB:-1}" == "1" ]]; then
    compose_args+=(-f docker-compose.prod.web.yml)
  fi
  if [[ "${AVOV_PROD_SSL:-1}" == "1" ]]; then
    if [[ "${AVOV_PROD_WEB:-1}" == "1" ]]; then
      compose_args+=(-f docker-compose.prod.web.ssl.yml)
    else
      compose_args+=(-f docker-compose.prod.ssl.yml)
    fi
  fi
fi

compose_args+=(-p "$COMPOSE_PROJECT")
if [[ -f "$ENV_FILE" ]]; then
  compose_args+=(--env-file "$ENV_FILE")
fi

root_password="$(grep -E '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' || echo avov_root_secret)"
database="$(grep -E '^MYSQL_DATABASE=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' || echo avov_db)"

echo "=== AVOV Restore Backup ($TARGET) ==="
echo "ADVERTENCIA: sobrescribe datos actuales."
if [[ "$FORCE" != "1" ]]; then
  read -r -p "Confirmar restauracion (escriba SI): " confirm
  [[ "$confirm" == "SI" ]] || { echo "Cancelado."; exit 1; }
fi

if [[ -n "$MYSQL_FILE" ]]; then
  [[ -f "$MYSQL_FILE" ]] || { echo "ERROR: no existe $MYSQL_FILE"; exit 1; }
  echo "Restaurando MySQL desde $MYSQL_FILE ..."
  docker compose "${compose_args[@]}" exec -T mysql \
    mysql -uroot -p"${root_password}" "${database}" < "$MYSQL_FILE"
  echo "MySQL restaurado."
fi

if [[ -n "$QDRANT_FILE" ]]; then
  [[ -f "$QDRANT_FILE" ]] || { echo "ERROR: no existe $QDRANT_FILE"; exit 1; }
  echo "Restaurando Qdrant desde $QDRANT_FILE ..."
  docker compose "${compose_args[@]}" exec -T qdrant \
    sh -c 'rm -rf /qdrant/storage/*' 2>/dev/null || true
  docker compose "${compose_args[@]}" exec -T qdrant \
    tar xzf - -C /qdrant < "$QDRANT_FILE"
  echo "Qdrant restaurado."
fi

if [[ -n "$STORAGE_FILE" ]]; then
  [[ -f "$STORAGE_FILE" ]] || { echo "ERROR: no existe $STORAGE_FILE"; exit 1; }
  echo "Restaurando storage backend desde $STORAGE_FILE ..."
  docker compose "${compose_args[@]}" exec -T backend \
    sh -c 'rm -rf /app/storage/*' 2>/dev/null || true
  docker compose "${compose_args[@]}" exec -T backend \
    tar xzf - -C /app < "$STORAGE_FILE"
  echo "Storage restaurado."
fi

echo ""
echo "Restauracion completada. Ejecuta post-deploy y rebuild Qdrant si aplica:"
echo "  ./scripts/post-deploy-prod.sh \"\$(grep ^API_BASE_URL= $ENV_FILE | cut -d= -f2-)\""
