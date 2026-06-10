# AVOV — Instalar dependencias del proyecto (backend + frontend)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "=== AVOV: Dependencias del proyecto ===" -ForegroundColor Cyan

# Backend
Write-Host "`n[Backend] Creando venv e instalando requirements..." -ForegroundColor Yellow
Set-Location backend
if (-not (Test-Path ".venv")) {
    python -m venv .venv
}
.\.venv\Scripts\python.exe -m pip install --upgrade pip -q
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -q
.\.venv\Scripts\python -m pytest -v
Set-Location ..

# Frontend
Write-Host "`n[Frontend] flutter pub get..." -ForegroundColor Yellow
$flutterBin = "C:\Users\BRS\develop\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBin)) {
  $flutterBin = "flutter"
}
Set-Location frontend
& $flutterBin pub get
& $flutterBin analyze
& $flutterBin test
Set-Location ..

# .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Archivo .env creado desde .env.example"
}

Write-Host "`n=== Dependencias del proyecto instaladas ===" -ForegroundColor Green
