# Levanta simulacion local de despliegue institucional (Web + API + SSL)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$envFile = ".env.institutional-local"
$composeFiles = @(
    "-f", "docker-compose.prod.yml",
    "-f", "docker-compose.prod.web.yml",
    "-f", "docker-compose.prod.institutional-local.yml"
)
$projectName = if ($env:AVOV_INSTITUTIONAL_LOCAL_PROJECT) { $env:AVOV_INSTITUTIONAL_LOCAL_PROJECT } else { "avov-institutional-local" }

if (-not (Test-Path $envFile)) {
    if (Test-Path ".env.institutional-local.example") {
        Copy-Item ".env.institutional-local.example" $envFile
        Write-Host "ADVERTENCIA: $envFile creado desde .env.institutional-local.example" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Falta $envFile" -ForegroundColor Red
        exit 1
    }
}

& (Join-Path $PSScriptRoot "generate-dev-ssl-certs.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $envFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== Build Flutter Web (institutional-local) ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build-flutter-web.ps1") -EnvFile $envFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Iniciando AVOV institutional-local (proyecto: $projectName)..." -ForegroundColor Cyan
docker compose @composeFiles --env-file $envFile -p $projectName up --build -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$https = (Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTPS_PORT=' } | Select-Object -First 1)
$httpsPort = if ($https) { ($https -split '=', 2)[1].Trim() } else { "8443" }
$http = (Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1)
$httpPort = if ($http) { ($http -split '=', 2)[1].Trim() } else { "8180" }

Write-Host ""
Write-Host "Stack institutional-local iniciado." -ForegroundColor Green
Write-Host "  Frontend: https://localhost:$httpsPort"
Write-Host "  API:      https://localhost:$httpsPort/api/v1/health/live"
Write-Host "  Smoke:    .\scripts\smoke-public-release.ps1 -ApiUrl `"https://localhost:$httpsPort/api/v1`" -FrontendUrl `"https://localhost:$httpsPort`" -SkipTlsVerify -HttpApiUrl `"http://localhost:$httpPort/api/v1`""
Write-Host "  Validar:  .\scripts\validate-institutional-deploy.ps1 -SkipTlsVerify"
Write-Host "  Detener:  .\scripts\prod-institutional-local-down.ps1"
