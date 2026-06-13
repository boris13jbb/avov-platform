# AVOV - Elimina backups antiguos (retencion configurable)
param(
    [string]$BackupRoot = "",
    [int]$RetentionDays = 14,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $root "backups"
}

Write-Host "=== AVOV Prune Backups ===" -ForegroundColor Cyan
Write-Host "Directorio: $BackupRoot"
Write-Host "Retencion: $RetentionDays dias"
Write-Host ""

if (-not (Test-Path $BackupRoot)) {
    Write-Host "Sin directorio de backups."
    exit 0
}

$cutoff = (Get-Date).AddDays(-$RetentionDays)
$patterns = @("*.sql", "*.tar.gz")
$removed = 0

Get-ChildItem -Path $BackupRoot -Recurse -File -Include $patterns | ForEach-Object {
    if ($_.LastWriteTime -lt $cutoff) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Eliminar: $($_.FullName)" -ForegroundColor Yellow
        } else {
            Remove-Item -Force $_.FullName
            Write-Host "Eliminado: $($_.FullName)" -ForegroundColor DarkGray
        }
        $removed++
    }
}

Write-Host ""
Write-Host "Archivos afectados: $removed" -ForegroundColor Cyan
exit 0
