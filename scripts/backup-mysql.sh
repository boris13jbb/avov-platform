#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./backups/mysql}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILENAME="avov_mysql_${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

docker exec avov-mysql mysqldump \
  -u"${MYSQL_USER:-avov_user}" \
  -p"${MYSQL_PASSWORD:-avov_user_secret}" \
  "${MYSQL_DATABASE:-avov_db}" > "${BACKUP_DIR}/${FILENAME}"

echo "Backup MySQL creado: ${BACKUP_DIR}/${FILENAME}"
