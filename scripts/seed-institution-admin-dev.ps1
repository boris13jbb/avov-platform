# AVOV - Seed administrador institucional de prueba (FASE 28)
$ErrorActionPreference = "Stop"

Write-Host "=== AVOV - Seed admin institucional FASE 28 ===" -ForegroundColor Cyan

Push-Location (Join-Path $PSScriptRoot "..\backend")
try {
    $env:PYTHONPATH = (Get-Location).Path
    python scripts/seed_institution_admin_dev.py
    if ($LASTEXITCODE -ne 0) {
        throw "El seed del admin institucional falló con código $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "`n=== Seed completado ===" -ForegroundColor Cyan
Write-Host "Email:    admin.institucion.test.fase28@instituto.edu.co" -ForegroundColor Green
Write-Host "Password: InstAdmin1234!" -ForegroundColor Green
