# AVOV — Levantar solo el backend FastAPI sin Docker (modo desarrollo)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Archivo .env creado desde .env.example" -ForegroundColor Yellow
}

if (-not (Test-Path "backend\.venv\Scripts\uvicorn.exe")) {
    Write-Host "Creando entorno virtual del backend..." -ForegroundColor Yellow
    Set-Location backend
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    Set-Location ..
}

Write-Host ""
Write-Host "=== AVOV Backend (sin Docker) ===" -ForegroundColor Cyan
Write-Host "La API arrancara en: http://localhost:8000" -ForegroundColor Green
Write-Host "Swagger:            http://localhost:8000/docs" -ForegroundColor Green
Write-Host "Health:             http://localhost:8000/api/v1/health" -ForegroundColor Green
Write-Host ""
Write-Host "Nota: MySQL, Redis y Qdrant apareceran como 'degraded' hasta que instales Docker." -ForegroundColor Yellow
Write-Host "Presiona Ctrl+C para detener." -ForegroundColor Gray
Write-Host ""

Set-Location backend
.\.venv\Scripts\uvicorn.exe app.main:app --reload --host 127.0.0.1 --port 8000
