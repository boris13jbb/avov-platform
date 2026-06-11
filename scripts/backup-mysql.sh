#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-}"
BACKUP_DIR="${BACKUP_DIR:-./backups/mysql}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILENAME="avov_mysql_${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

compose_args=(-f "${COMPOSE_FILE}")
if [[ -n "${COMPOSE_PROJECT}" ]]; then
  compose_args+=(-p "${COMPOSE_PROJECT}")
fi

root_password="${MYSQL_ROOT_PASSWORD:-avov_root_secret}"
database="${MYSQL_DATABASE:-avov_db}"

docker compose "${compose_args[@]}" exec -T mysql \
  mysqldump -uroot -p"${root_password}" --single-transaction --routines --triggers "${database}" \
  > "${BACKUP_DIR}/${FILENAME}"

echo "Backup MySQL creado: ${BACKUP_DIR}/${FILENAME}"
