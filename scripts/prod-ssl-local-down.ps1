# Detiene stack prod-ssl-local AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-ssl-local.yml")
$envFile = ".env.prod-ssl-local"
$projectName = if ($env:AVOV_PROD_SSL_LOCAL_PROJECT) { $env:AVOV_PROD_SSL_LOCAL_PROJECT } else { "avov-prod-ssl-local" }

docker compose @composeFiles --env-file $envFile -p $projectName down
Write-Host "Stack prod-ssl-local detenido (volumenes conservados)." -ForegroundColor Green
