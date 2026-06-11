# AVOV - Seed orientador de prueba y asignación al estudiante fase11
$ErrorActionPreference = "Stop"

Write-Host "=== AVOV - Seed orientador FASE 26 ===" -ForegroundColor Cyan

Push-Location (Join-Path $PSScriptRoot "..\backend")
try {
    $env:PYTHONPATH = (Get-Location).Path
    python scripts/seed_counselor_dev.py
    if ($LASTEXITCODE -ne 0) {
        throw "El seed del orientador falló con código $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "`n=== Seed completado ===" -ForegroundColor Cyan
