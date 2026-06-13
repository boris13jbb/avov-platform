# Levanta stack produccion local aislado (simula prod-up.ps1 sin tocar .env dev)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$envFile = ".env.prod-local"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-local.yml")
$projectName = if ($env:AVOV_PROD_LOCAL_PROJECT) { $env:AVOV_PROD_LOCAL_PROJECT } else { "avov-prod-local" }

if (-not (Test-Path $envFile)) {
    if (Test-Path ".env.prod-local.example") {
        Copy-Item ".env.prod-local.example" $envFile
        Write-Host "ADVERTENCIA: $envFile creado desde .env.prod-local.example" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Falta $envFile" -ForegroundColor Red
        exit 1
    }
}

& (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $envFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Iniciando AVOV prod-local (proyecto: $projectName)..." -ForegroundColor Cyan
docker compose @composeFiles --env-file $envFile -p $projectName up --build -d

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$portLine = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1
$port = if ($portLine) { ($portLine -split '=', 2)[1].Trim() } else { "8090" }

Write-Host ""
Write-Host "Stack prod-local iniciado." -ForegroundColor Green
Write-Host "  API (Nginx): http://localhost:$port/api/v1/health/live"
Write-Host "  Preflight:   .\scripts\preflight-prod.ps1 -EnvFile .env.prod-local"
Write-Host "  Smoke:       .\scripts\smoke-e2e.ps1 -BaseUrl `"http://localhost:$port/api/v1`" -EnsureStudentSeed"
Write-Host "  Detener:     .\scripts\prod-local-down.ps1"
