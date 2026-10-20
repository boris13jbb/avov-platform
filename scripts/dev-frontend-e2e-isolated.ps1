# AVOV — Flutter Web de prueba apuntando a la API E2E en :8001
# No modifica la instancia en :3000. Puerto web de prueba: 3001.
# No inicia sesion ni crea evaluaciones.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $RepoRoot "frontend")

$WebPort = 3001
$ApiBase = "http://127.0.0.1:8001/api/v1"

$busy = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $WebPort }
if ($busy) {
    Write-Host "ERROR: el puerto $WebPort ya esta en uso." -ForegroundColor Red
    exit 1
}

Write-Host "=== AVOV Flutter E2E aislado ===" -ForegroundColor Cyan
Write-Host "Web:  http://127.0.0.1:$WebPort"
Write-Host "API:  $ApiBase (dart-define API_BASE_URL)"
Write-Host "Requisito: API secundaria en :8001 (.\scripts\dev-backend-e2e-isolated.ps1)"
Write-Host "Presiona Ctrl+C para detener solo esta instancia."
Write-Host ""

# remote-allow-origins permite CDP local para login QA automatizado (sin tocar :3000).
flutter run -d chrome `
    --web-port=$WebPort `
    --web-browser-flag=--remote-allow-origins=* `
    --dart-define=API_BASE_URL=$ApiBase
