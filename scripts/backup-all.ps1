# Backup completo: MySQL + Qdrant + storage del backend (producción por defecto)
param(
    [ValidateSet("dev", "prod")]
    [string]$Target = "prod"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if ($Target -eq "prod") {
    $compose = "docker-compose.prod.yml"
    $project = if ($env:AVOV_PROD_PROJECT) { $env:AVOV_PROD_PROJECT } else { "avov-prod" }
} else {
    $compose = "docker-compose.yml"
    $project = ""
}

Write-Host "Backup AVOV ($Target)..." -ForegroundColor Cyan
& "$PSScriptRoot\backup-mysql.ps1" -ComposeFile $compose -Project $project
& "$PSScriptRoot\backup-qdrant.ps1" -ComposeFile $compose -Project $project

$storageBackupDir = Join-Path $PWD "backups\storage"
New-Item -ItemType Directory -Force -Path $storageBackupDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$storageArchive = Join-Path $storageBackupDir "avov_storage_$timestamp.tar.gz"

$composeArgs = @("-f", $compose)
if ($project) { $composeArgs += "-p", $project }

docker compose @composeArgs exec -T backend tar czf - -C /app storage 2>$null > $storageArchive
if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup storage: $storageArchive" -ForegroundColor Green
} else {
    Write-Host "Aviso: backup de storage omitido (backend no disponible o sin datos)." -ForegroundColor Yellow
}

Write-Host "Backups completados en ./backups/" -ForegroundColor Green
