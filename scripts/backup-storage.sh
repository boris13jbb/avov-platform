#!/usr/bin/env bash
# AVOV - Backup storage del backend (PDFs, logos)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-avov-prod}"
BACKUP_DIR="${BACKUP_DIR:-./backups/storage}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="avov_storage_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

compose_args=(-f "${COMPOSE_FILE}")
if [[ -n "${COMPOSE_PROJECT}" ]]; then
  compose_args+=(-p "${COMPOSE_PROJECT}")
fi

if docker compose "${compose_args[@]}" exec -T backend tar czf - -C /app storage > "${BACKUP_DIR}/${ARCHIVE}" 2>/dev/null; then
  echo "Backup storage: ${BACKUP_DIR}/${ARCHIVE}"
else
  echo "Aviso: backup storage omitido (backend no disponible)"
  rm -f "${BACKUP_DIR}/${ARCHIVE}"
fi
