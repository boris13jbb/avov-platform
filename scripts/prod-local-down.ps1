# Detiene stack prod-local AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-local.yml")
$envFile = ".env.prod-local"
$projectName = if ($env:AVOV_PROD_LOCAL_PROJECT) { $env:AVOV_PROD_LOCAL_PROJECT } else { "avov-prod-local" }

docker compose @composeFiles --env-file $envFile -p $projectName down
Write-Host "Stack prod-local detenido (volumenes conservados)." -ForegroundColor Green
