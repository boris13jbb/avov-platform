# Levanta stack produccion SSL local (cert autofirmado + Nginx HTTPS)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$envFile = ".env.prod-ssl-local"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-ssl-local.yml")
$projectName = if ($env:AVOV_PROD_SSL_LOCAL_PROJECT) { $env:AVOV_PROD_SSL_LOCAL_PROJECT } else { "avov-prod-ssl-local" }

if (-not (Test-Path $envFile)) {
    if (Test-Path ".env.prod-ssl-local.example") {
        Copy-Item ".env.prod-ssl-local.example" $envFile
        Write-Host "ADVERTENCIA: $envFile creado desde .env.prod-ssl-local.example" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Falta $envFile" -ForegroundColor Red
        exit 1
    }
}

& (Join-Path $PSScriptRoot "generate-dev-ssl-certs.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $envFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Iniciando AVOV prod-ssl-local (proyecto: $projectName)..." -ForegroundColor Cyan
docker compose @composeFiles --env-file $envFile -p $projectName up --build -d

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$httpPort = (Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1)
$httpsPort = (Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTPS_PORT=' } | Select-Object -First 1)
$http = if ($httpPort) { ($httpPort -split '=', 2)[1].Trim() } else { "8180" }
$https = if ($httpsPort) { ($httpsPort -split '=', 2)[1].Trim() } else { "8443" }

Write-Host ""
Write-Host "Stack prod-ssl-local iniciado." -ForegroundColor Green
Write-Host "  HTTPS API: https://localhost:$https/api/v1/health/live"
Write-Host "  HTTP redirect: http://localhost:$http/api/v1/health/live"
Write-Host "  Post-deploy: .\scripts\post-deploy-prod.ps1 -BaseUrl `"https://localhost:$https/api/v1`" -SkipTlsVerify"
Write-Host "  Detener:     .\scripts\prod-ssl-local-down.ps1"
