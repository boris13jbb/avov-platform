#!/usr/bin/env bash
# Restaura un archivo tar del volumen Qdrant de AVOV a un directorio temporal
# de verificación. NO detiene el servicio en producción sin autorización.
# Uso: ./scripts/restore-qdrant.sh /ruta/qdrant-backup.tar.gz [dir_destino]

set -euo pipefail

BACKUP_FILE="${1:-}"
DEST_DIR="${2:-/tmp/avov-qdrant-restore-check}"

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
  echo "Uso: $0 <backup.tar.gz> [dir_destino]" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"
rm -rf "${DEST_DIR:?}/"*
tar -xzf "${BACKUP_FILE}" -C "${DEST_DIR}"
echo "Restore Qdrant expandido en ${DEST_DIR}."
echo "Validar contenido y, solo con autorización, sustituir el volumen avov_qdrant_data."
