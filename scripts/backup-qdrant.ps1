# Backup volumen Qdrant
param(
    [string]$ComposeFile = "docker-compose.yml",
    [string]$Project = "",
    [switch]$Staging,
    [switch]$ProdLocal
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$backupDir = Join-Path $PWD "backups\qdrant"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archive = "avov_qdrant_$timestamp.tar.gz"
$outPath = Join-Path $backupDir $archive

$composeArgs = @("-f", $ComposeFile)
if ($Staging) {
    $composeArgs += "-f", "docker-compose.staging.yml"
    $composeArgs += "--env-file", ".env.staging"
}
if ($ProdLocal) {
    $composeArgs += "-f", "docker-compose.prod-local.yml"
    $composeArgs += "--env-file", ".env.prod-local"
}
if ($Project) { $composeArgs += "-p", $Project }

docker compose @composeArgs exec -T qdrant tar czf - -C /qdrant storage > $outPath

if ($LASTEXITCODE -ne 0) {
    Remove-Item -Force $outPath -ErrorAction SilentlyContinue
    Write-Host "ERROR: falló el backup Qdrant" -ForegroundColor Red
    exit 1
}

Write-Host "Backup Qdrant: $outPath" -ForegroundColor Green
