#!/usr/bin/env bash
# AVOV - Backup completo Linux (MySQL + Qdrant + storage)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-prod}"
COMPOSE_FILE="docker-compose.prod.yml"
COMPOSE_PROJECT="${AVOV_PROD_PROJECT:-avov-prod}"
ENV_FILE="${AVOV_ENV_FILE:-.env}"
compose_args=(-f "$COMPOSE_FILE")

case "$TARGET" in
  prod)
    if [[ "${AVOV_PROD_WEB:-0}" == "1" ]]; then
      compose_args+=(-f docker-compose.prod.web.yml)
    fi
    if [[ "${AVOV_PROD_SSL:-0}" == "1" ]]; then
      if [[ "${AVOV_PROD_WEB:-0}" == "1" ]]; then
        compose_args+=(-f docker-compose.prod.web.ssl.yml)
      else
        compose_args+=(-f docker-compose.prod.ssl.yml)
      fi
    fi
    ;;
  staging)
    COMPOSE_PROJECT="${AVOV_STAGING_PROJECT:-avov-staging}"
    ENV_FILE=".env.staging"
    compose_args+=(-f docker-compose.staging.yml)
    ;;
  prod-local)
    COMPOSE_PROJECT="${AVOV_PROD_LOCAL_PROJECT:-avov-prod-local}"
    ENV_FILE=".env.prod-local"
    compose_args+=(-f docker-compose.prod-local.yml)
    ;;
  dev)
    COMPOSE_FILE="docker-compose.yml"
    COMPOSE_PROJECT=""
    ENV_FILE=".env"
    compose_args=(-f "$COMPOSE_FILE")
    ;;
esac

if [[ -n "$COMPOSE_PROJECT" ]]; then
  compose_args+=(-p "$COMPOSE_PROJECT")
fi
if [[ -f "$ENV_FILE" ]]; then
  compose_args+=(--env-file "$ENV_FILE")
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
mkdir -p backups/mysql backups/qdrant backups/storage

root_password="${MYSQL_ROOT_PASSWORD:-}"
database="${MYSQL_DATABASE:-avov_db}"
if [[ -z "$root_password" && -f "$ENV_FILE" ]]; then
  root_password="$(grep -E '^MYSQL_ROOT_PASSWORD=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')"
  database="$(grep -E '^MYSQL_DATABASE=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' || echo avov_db)"
fi
root_password="${root_password:-avov_root_secret}"
database="${database:-avov_db}"

echo "=== Backup AVOV ($TARGET) ==="

mysql_out="backups/mysql/avov_mysql_${timestamp}.sql"
docker compose "${compose_args[@]}" exec -T mysql \
  mysqldump -uroot -p"${root_password}" --single-transaction --routines --triggers "${database}" \
  > "$mysql_out"
echo "Backup MySQL: $mysql_out"

qdrant_out="backups/qdrant/avov_qdrant_${timestamp}.tar.gz"
docker compose "${compose_args[@]}" exec -T qdrant \
  tar czf - -C /qdrant storage > "$qdrant_out"
echo "Backup Qdrant: $qdrant_out"

storage_out="backups/storage/avov_storage_${timestamp}.tar.gz"
if docker compose "${compose_args[@]}" exec -T backend tar czf - -C /app storage > "$storage_out" 2>/dev/null; then
  echo "Backup storage: $storage_out"
else
  rm -f "$storage_out"
  echo "Aviso: backup storage omitido"
fi

echo "Backups completados en ./backups/"
