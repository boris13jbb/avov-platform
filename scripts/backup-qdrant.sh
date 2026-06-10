#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./backups/qdrant}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="avov_qdrant_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

docker run --rm \
  -v avov_qdrant_data:/qdrant/storage:ro \
  -v "$(pwd)/${BACKUP_DIR}:/backup" \
  alpine tar czf "/backup/${ARCHIVE}" -C /qdrant storage

echo "Backup Qdrant creado: ${BACKUP_DIR}/${ARCHIVE}"
