# Levanta el stack de staging AVOV (producción local vía Nginx)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$envFile = ".env.staging"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.staging.yml")
$projectName = if ($env:AVOV_STAGING_PROJECT) { $env:AVOV_STAGING_PROJECT } else { "avov-staging" }

if (-not (Test-Path $envFile)) {
    if (Test-Path ".env.staging.example") {
        Copy-Item ".env.staging.example" $envFile
        Write-Host "ADVERTENCIA: $envFile creado desde .env.staging.example" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Falta $envFile. Copia .env.staging.example a $envFile" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Iniciando AVOV staging (proyecto: $projectName)..." -ForegroundColor Cyan
docker compose @composeFiles --env-file $envFile -p $projectName up --build -d

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$portLine = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1
$port = if ($portLine) { ($portLine -split '=', 2)[1].Trim() } else { "8080" }

Write-Host ""
Write-Host "Stack de staging iniciado." -ForegroundColor Green
Write-Host "  API (Nginx): http://localhost:$port/api/v1/health/live"
Write-Host "  Smoke:       .\scripts\smoke-e2e.ps1 -BaseUrl `"http://localhost:$port/api/v1`" -EnsureStudentSeed"
Write-Host "  Logs:        docker compose @composeFiles --env-file $envFile -p $projectName logs -f backend"
Write-Host "  Detener:     .\scripts\staging-down.ps1"
