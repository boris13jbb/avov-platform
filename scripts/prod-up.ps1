# Levanta el stack de producción AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @("-f", "docker-compose.prod.yml")
$useSsl = $env:AVOV_PROD_SSL -eq "1" -or ($args -contains "-Ssl")

if (-not (Test-Path ".env")) {
    if (Test-Path ".env.production.example") {
        Copy-Item ".env.production.example" ".env"
        Write-Host "ADVERTENCIA: .env creado desde .env.production.example — edita las claves antes de producción real." -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Falta .env. Copia .env.production.example a .env" -ForegroundColor Red
        exit 1
    }
}

& "$PSScriptRoot\preflight-prod.ps1" -EnvFile ".env"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($useSsl) {
    $composeFiles += "-f", "docker-compose.prod.ssl.yml"
    if (-not (Test-Path "nginx\certs\fullchain.pem")) {
        Write-Host "ERROR: SSL activado pero falta nginx\certs\fullchain.pem" -ForegroundColor Red
        exit 1
    }
}

$projectName = if ($env:AVOV_PROD_PROJECT) { $env:AVOV_PROD_PROJECT } else { "avov-prod" }

Write-Host "Iniciando AVOV producción (proyecto: $projectName)..." -ForegroundColor Cyan
docker compose @composeFiles -p $projectName up --build -d

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$port = if ($env:NGINX_HTTP_PORT) { $env:NGINX_HTTP_PORT } else { "80" }
Write-Host ""
Write-Host "Stack de producción iniciado." -ForegroundColor Green
Write-Host "  API:     http://localhost:$port/api/v1/health/live"
Write-Host "  Logs:    docker compose @composeFiles -p $projectName logs -f backend"
Write-Host "  Detener: .\scripts\prod-down.ps1"
