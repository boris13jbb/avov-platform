# Detiene el stack de staging AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.staging.yml")
$envFile = ".env.staging"
$projectName = if ($env:AVOV_STAGING_PROJECT) { $env:AVOV_STAGING_PROJECT } else { "avov-staging" }

docker compose @composeFiles --env-file $envFile -p $projectName down
Write-Host "Stack de staging detenido (volúmenes conservados)." -ForegroundColor Green
