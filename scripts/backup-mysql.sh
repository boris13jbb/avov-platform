#!/usr/bin/env bash
# Respaldo lógico MySQL vía contenedor Docker local/laboratorio (avov-mysql).
# No sustituye los respaldos administrados de Cloud SQL en producción GCP.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./backups/mysql}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILENAME="avov_mysql_${TIMESTAMP}.sql"

# Obligatorias: fallan si faltan o están vacías (mensaje = nombre de variable, sin valor).
: "${MYSQL_USER:?Falta MYSQL_USER}"
: "${MYSQL_PASSWORD:?Falta MYSQL_PASSWORD}"
: "${MYSQL_DATABASE:?Falta MYSQL_DATABASE}"

mkdir -p "${BACKUP_DIR}"

docker exec avov-mysql mysqldump \
  -u"${MYSQL_USER}" \
  -p"${MYSQL_PASSWORD}" \
  "${MYSQL_DATABASE}" > "${BACKUP_DIR}/${FILENAME}"

echo "Backup MySQL creado: ${BACKUP_DIR}/${FILENAME}"
