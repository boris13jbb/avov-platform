$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..
docker compose down
Write-Host "Servicios detenidos."
