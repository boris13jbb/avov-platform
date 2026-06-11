# Detiene el stack de producción AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$composeFiles = @("-f", "docker-compose.prod.yml")
if ($env:AVOV_PROD_SSL -eq "1") {
    $composeFiles += "-f", "docker-compose.prod.ssl.yml"
}

$projectName = if ($env:AVOV_PROD_PROJECT) { $env:AVOV_PROD_PROJECT } else { "avov-prod" }

docker compose @composeFiles -p $projectName down
Write-Host "Stack de producción detenido (volúmenes conservados)." -ForegroundColor Green
