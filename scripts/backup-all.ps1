# Backup completo: MySQL + Qdrant + storage del backend (producción por defecto)
param(
    [ValidateSet("dev", "prod", "staging", "prod-local")]
    [string]$Target = "prod"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$stagingSwitch = $false
$prodLocalSwitch = $false
if ($Target -eq "staging") {
    $compose = "docker-compose.prod.yml"
    $project = if ($env:AVOV_STAGING_PROJECT) { $env:AVOV_STAGING_PROJECT } else { "avov-staging" }
    $stagingSwitch = $true
} elseif ($Target -eq "prod-local") {
    $compose = "docker-compose.prod.yml"
    $project = if ($env:AVOV_PROD_LOCAL_PROJECT) { $env:AVOV_PROD_LOCAL_PROJECT } else { "avov-prod-local" }
    $prodLocalSwitch = $true
} elseif ($Target -eq "prod") {
    $compose = "docker-compose.prod.yml"
    $project = if ($env:AVOV_PROD_PROJECT) { $env:AVOV_PROD_PROJECT } else { "avov-prod" }
} else {
    $compose = "docker-compose.yml"
    $project = ""
}

Write-Host "Backup AVOV ($Target)..." -ForegroundColor Cyan
$backupParams = @{ ComposeFile = $compose; Project = $project }
if ($stagingSwitch) { $backupParams.Staging = $true }
if ($prodLocalSwitch) { $backupParams.ProdLocal = $true }
& "$PSScriptRoot\backup-mysql.ps1" @backupParams
& "$PSScriptRoot\backup-qdrant.ps1" @backupParams

$storageBackupDir = Join-Path $PWD "backups\storage"
New-Item -ItemType Directory -Force -Path $storageBackupDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$storageArchive = Join-Path $storageBackupDir "avov_storage_$timestamp.tar.gz"

$composeArgs = @("-f", $compose)
if ($stagingSwitch) {
    $composeArgs += "-f", "docker-compose.staging.yml"
    $composeArgs += "--env-file", ".env.staging"
}
if ($prodLocalSwitch) {
    $composeArgs += "-f", "docker-compose.prod-local.yml"
    $composeArgs += "--env-file", ".env.prod-local"
}
if ($project) { $composeArgs += "-p", $project }

docker compose @composeArgs exec -T backend tar czf - -C /app storage 2>$null > $storageArchive
if ($LASTEXITCODE -eq 0) {
    Write-Host "Backup storage: $storageArchive" -ForegroundColor Green
} else {
    Write-Host "Aviso: backup de storage omitido (backend no disponible o sin datos)." -ForegroundColor Yellow
}

Write-Host "Backups completados en ./backups/" -ForegroundColor Green
