# AVOV - Validacion QA Flutter (Fase 37)
# Ejecuta analyze + tests y genera reporte.
# Uso: .\scripts\validate-flutter-qa.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $root "frontend"
$reportPath = Join-Path $root "docs\fase-37-flutter-qa-report.txt"

Set-Location $frontend

Write-Host "=== AVOV - Validacion Flutter QA (Fase 37) ===" -ForegroundColor Cyan
Write-Host "Directorio: $frontend"
Write-Host ""

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Name = $Name; Status = $Status; Detail = $Detail })
    $color = if ($Status -eq "OK") { "Green" } else { "Red" }
    Write-Host "[$Status] $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

Write-Host "Ejecutando flutter analyze..." -ForegroundColor DarkGray
$analyzeOutput = flutter analyze 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Add-Result "flutter analyze" "OK" "sin issues"
} else {
    Add-Result "flutter analyze" "FALLO" ($analyzeOutput -split "`n" | Select-Object -Last 3) -join " "
}

Write-Host "Ejecutando flutter test..." -ForegroundColor DarkGray
$testOutput = flutter test 2>&1 | Out-String
$passedMatch = [regex]::Match($testOutput, 'All tests passed!')
$testCountMatch = [regex]::Match($testOutput, '\+(\d+): All tests passed!')

if ($LASTEXITCODE -eq 0 -and $passedMatch.Success) {
    $count = if ($testCountMatch.Success) { $testCountMatch.Groups[1].Value } else { "?" }
    Add-Result "flutter test" "OK" "$count tests passed"
} else {
    Add-Result "flutter test" "FALLO" ($testOutput -split "`n" | Select-Object -Last 5) -join " "
}

$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host "OK: $ok | FALLO: $fail"

$lines = @(
    "AVOV - Reporte Flutter QA (Fase 37)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "OK: $ok | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
if ($fail -gt 0) {
    $lines += ""
    $lines += "--- Salida flutter test (ultimas lineas) ---"
    $lines += ($testOutput -split "`n" | Select-Object -Last 20)
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-37-flutter-qa-report.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
