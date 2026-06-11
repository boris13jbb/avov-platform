#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-}"
BACKUP_DIR="${BACKUP_DIR:-./backups/qdrant}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="avov_qdrant_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

compose_args=(-f "${COMPOSE_FILE}")
if [[ -n "${COMPOSE_PROJECT}" ]]; then
  compose_args+=(-p "${COMPOSE_PROJECT}")
fi

docker compose "${compose_args[@]}" exec -T qdrant \
  tar czf - -C /qdrant storage > "${BACKUP_DIR}/${ARCHIVE}"

echo "Backup Qdrant creado: ${BACKUP_DIR}/${ARCHIVE}"
