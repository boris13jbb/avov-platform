#!/usr/bin/env bash
# AVOV - Elimina backups antiguos (retencion configurable)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${BACKUP_ROOT:-$ROOT/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
DRY_RUN="${DRY_RUN:-0}"

echo "=== AVOV Prune Backups ==="
echo "Directorio: $BACKUP_ROOT"
echo "Retencion: ${RETENTION_DAYS} dias"
echo ""

if [[ ! -d "$BACKUP_ROOT" ]]; then
  echo "Sin directorio de backups."
  exit 0
fi

removed=0
while IFS= read -r -d '' file; do
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY-RUN] Eliminar: $file"
  else
    rm -f "$file"
    echo "Eliminado: $file"
  fi
  removed=$((removed + 1))
done < <(find "$BACKUP_ROOT" -type f \( -name '*.sql' -o -name '*.tar.gz' \) -mtime +"$RETENTION_DAYS" -print0)

echo ""
echo "Archivos afectados: $removed"
