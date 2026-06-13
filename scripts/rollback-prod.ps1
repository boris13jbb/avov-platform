# AVOV - Rollback produccion al commit y backups registrados (Fase 45)
param(
    [string]$StateFile = "",
    [string]$GitRef = "",
    [switch]$RestoreDatabase,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if ([string]::IsNullOrWhiteSpace($StateFile)) {
    $StateFile = Join-Path $PWD ".deploy\release-state.json"
}

if (-not (Test-Path $StateFile)) {
    Write-Host "ERROR: no existe $StateFile" -ForegroundColor Red
    Write-Host "Ejecute primero .\scripts\update-prod-safe.ps1" -ForegroundColor Yellow
    exit 1
}

$state = Get-Content $StateFile -Raw | ConvertFrom-Json
$targetRef = if ($GitRef) { $GitRef } else { $state.previous_commit }

if ([string]::IsNullOrWhiteSpace($targetRef) -or $targetRef -eq "unknown") {
    Write-Host "ERROR: no hay commit previo en release-state.json" -ForegroundColor Red
    exit 1
}

Write-Host "=== AVOV Rollback Produccion (Fase 45) ===" -ForegroundColor Cyan
Write-Host "Commit destino: $targetRef"
Write-Host "Restaurar BD: $RestoreDatabase"
Write-Host "MySQL backup: $($state.mysql_backup)"

if (-not $Force) {
    $confirm = Read-Host "Confirmar rollback (escriba SI)"
    if ($confirm -ne "SI") {
        Write-Host "Cancelado."
        exit 1
    }
}

Write-Host "=== 1/4 git checkout ===" -ForegroundColor Cyan
git fetch --all 2>$null
git checkout $targetRef
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== 2/4 Redeploy (VPS Linux) ===" -ForegroundColor Cyan
Write-Host "En VPS: AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh" -ForegroundColor Yellow

if ($RestoreDatabase) {
    Write-Host "=== 3/4 Restaurar backups ===" -ForegroundColor Cyan
    $restoreParams = @{ Force = $true }
    if ($state.mysql_backup) { $restoreParams.MySqlFile = $state.mysql_backup }
    if ($state.qdrant_backup) { $restoreParams.QdrantFile = $state.qdrant_backup }
    if ($state.storage_backup) { $restoreParams.StorageFile = $state.storage_backup }
    & (Join-Path $PSScriptRoot "restore-backup.ps1") @restoreParams
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "=== 3/4 Restauracion BD omitida ===" -ForegroundColor Yellow
}

if ($state.api_url) {
    Write-Host "=== 4/4 Post-deploy ===" -ForegroundColor Cyan
    $skipTls = $state.api_url -match "localhost"
    & (Join-Path $PSScriptRoot "post-deploy-prod.ps1") -BaseUrl $state.api_url -SkipTlsVerify:$skipTls `
        -ReportPath (Join-Path $PWD "docs\fase-45-rollback-post-deploy.txt") `
        -ReportTitle "AVOV Rollback Post-Deploy (Fase 45)"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Rollback completado." -ForegroundColor Green
exit 0
