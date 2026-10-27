#!/usr/bin/env bash
# Restaura un dump MySQL de AVOV en un esquema de verificación (no sobreescribe
# avov_db por defecto). Uso:
#   ./scripts/restore-mysql.sh /ruta/backup.sql [schema_destino]
# Requiere contenedor avov-mysql en marcha.

set -euo pipefail

BACKUP_FILE="${1:-}"
TARGET_SCHEMA="${2:-avov_restore_check}"

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
  echo "Uso: $0 <archivo.sql> [schema_destino]" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx 'avov-mysql'; then
  echo "El contenedor avov-mysql no está en ejecución." >&2
  exit 1
fi

echo "Creando/recreando esquema ${TARGET_SCHEMA}..."
docker exec -i avov-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD requerido}" \
  -e "DROP DATABASE IF EXISTS \`${TARGET_SCHEMA}\`; CREATE DATABASE \`${TARGET_SCHEMA}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Restaurando ${BACKUP_FILE} en ${TARGET_SCHEMA}..."
docker exec -i avov-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${TARGET_SCHEMA}" < "${BACKUP_FILE}"

echo "Conteo de tablas en ${TARGET_SCHEMA}:"
docker exec -i avov-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -N -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${TARGET_SCHEMA}';"

echo "Restore MySQL completado. Revisar y eliminar el esquema de prueba cuando corresponda."
