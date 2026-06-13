# AVOV - Validacion flujo vocacional E2E (Fase 38)
# Requiere backend activo (docker compose up -d).
# Uso: .\scripts\validate-vocational-e2e.ps1

param(
    [string]$BaseUrl = "http://localhost:8000/api/v1"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "docs\fase-38-vocational-e2e-report.txt"

Write-Host "=== AVOV - Validacion Flujo Vocacional (Fase 38) ===" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

& (Join-Path $PSScriptRoot "smoke-vocational-e2e.ps1") `
    -BaseUrl $BaseUrl `
    -EnsureStudentSeed `
    -EnsureCareersSeed `
    -ReportPath $reportPath `
    -ReportTitle "AVOV - Validacion Flujo Vocacional (Fase 38)"

exit $LASTEXITCODE
