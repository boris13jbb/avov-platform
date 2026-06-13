# AVOV - Actualizacion segura produccion (Fase 45)
param(
    [string]$EnvFile = ".env",
    [switch]$SkipPull,
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$stateDir = Join-Path $PWD ".deploy"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

if (-not (Test-Path $EnvFile)) {
    Write-Host "ERROR: falta $EnvFile" -ForegroundColor Red
    exit 1
}

function Get-EnvVal([string]$Key) {
    $line = Get-Content $EnvFile | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if ($line) { return ($line -split '=', 2)[1].Trim().Trim('"').Trim("'") }
    return $null
}

$apiUrl = Get-EnvVal "API_BASE_URL"
$frontendUrl = Get-EnvVal "FRONTEND_BASE_URL"
$httpPort = Get-EnvVal "NGINX_HTTP_PORT"
if (-not $httpPort) { $httpPort = "80" }
$apiDomain = Get-EnvVal "API_DOMAIN"

$prevCommit = try { (git rev-parse HEAD).Trim() } catch { "unknown" }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=== AVOV Update Prod Safe (Fase 45) ===" -ForegroundColor Cyan
Write-Host "Commit actual: $prevCommit"
Write-Host ""

Write-Host "=== 1/5 Backup pre-actualizacion ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "backup-all.ps1") -Target prod
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$mysqlBkp = Get-ChildItem -Path "backups\mysql\avov_mysql_*.sql" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$qdrantBkp = Get-ChildItem -Path "backups\qdrant\avov_qdrant_*.tar.gz" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$storageBkp = Get-ChildItem -Path "backups\storage\avov_storage_*.tar.gz" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$state = [ordered]@{
    timestamp        = $ts
    previous_commit  = $prevCommit
    mysql_backup     = if ($mysqlBkp) { $mysqlBkp.FullName.Replace("$PWD\", "").Replace("\", "/") } else { "" }
    qdrant_backup    = if ($qdrantBkp) { $qdrantBkp.FullName.Replace("$PWD\", "").Replace("\", "/") } else { "" }
    storage_backup   = if ($storageBkp) { $storageBkp.FullName.Replace("$PWD\", "").Replace("\", "/") } else { "" }
    api_url          = $apiUrl
    frontend_url     = $frontendUrl
}
$state | ConvertTo-Json | Set-Content -Path (Join-Path $stateDir "release-state.json") -Encoding UTF8
Write-Host "Estado guardado en .deploy/release-state.json" -ForegroundColor Green

if (-not $SkipPull) {
    Write-Host "=== 2/5 git pull ===" -ForegroundColor Cyan
    git pull --ff-only
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "=== 2/5 git pull omitido ===" -ForegroundColor Yellow
}

$newCommit = try { (git rev-parse HEAD).Trim() } catch { "unknown" }
Write-Host "Commit nuevo: $newCommit"

Write-Host "=== 3/5 Deploy (manual en Windows) ===" -ForegroundColor Cyan
Write-Host "En VPS Linux use: AVOV_PROD_SSL=1 AVOV_PROD_WEB=1 ./scripts/deploy-prod-server.sh" -ForegroundColor Yellow
Write-Host "En Windows local: .\scripts\prod-up.ps1 -Ssl (segun entorno)" -ForegroundColor Yellow

if (-not [string]::IsNullOrWhiteSpace($apiUrl)) {
    Write-Host "=== 4/5 Post-deploy ===" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "post-deploy-prod.ps1") -BaseUrl $apiUrl -SkipTlsVerify:($apiUrl -match "localhost")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $SkipSmoke -and -not [string]::IsNullOrWhiteSpace($apiUrl)) {
    Write-Host "=== 5/5 Smoke ===" -ForegroundColor Cyan
    $httpApi = if ($apiDomain) { "http://${apiDomain}/api/v1" } else { "http://localhost:${httpPort}/api/v1" }
    $smokeParams = @{
        ApiUrl       = $apiUrl
        FrontendUrl  = $frontendUrl
        HttpApiUrl   = $httpApi
        ReportPath   = (Join-Path $PWD "docs\fase-45-update-smoke.txt")
    }
    if ($apiUrl -match "localhost") { $smokeParams.SkipTlsVerify = $true }
    & (Join-Path $PSScriptRoot "smoke-public-release.ps1") @smokeParams
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Actualizacion segura completada." -ForegroundColor Green
Write-Host "Rollback: .\scripts\rollback-prod.ps1" -ForegroundColor Cyan
exit 0
