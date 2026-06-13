# Detiene stack institutional-local AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @(
    "-f", "docker-compose.prod.yml",
    "-f", "docker-compose.prod.web.yml",
    "-f", "docker-compose.prod.institutional-local.yml"
)
$envFile = ".env.institutional-local"
$projectName = if ($env:AVOV_INSTITUTIONAL_LOCAL_PROJECT) { $env:AVOV_INSTITUTIONAL_LOCAL_PROJECT } else { "avov-institutional-local" }

docker compose @composeFiles --env-file $envFile -p $projectName down
Write-Host "Stack institutional-local detenido (volumenes conservados)." -ForegroundColor Green
