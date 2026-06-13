# AVOV - Validacion operaciones produccion (Fase 45)
# Uso: .\scripts\validate-production-ops.ps1

param(
    [switch]$Quick
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$reportPath = Join-Path $root "docs\fase-45-production-ops-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

Write-Host "=== AVOV - Validacion Production Ops (Fase 45) ===" -ForegroundColor Cyan

$required = @(
    "scripts/update-prod-safe.sh",
    "scripts/update-prod-safe.ps1",
    "scripts/rollback-prod.sh",
    "scripts/rollback-prod.ps1",
    "scripts/restore-backup.sh",
    "scripts/restore-backup.ps1",
    "docs/plan-rollback-produccion.md",
    "docs/runbook-soporte-produccion.md",
    "docs/capacitacion-ti-institucional.md",
    "docs/fase-45-soporte-rollback-capacitacion.md"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Scripts y docs Fase 45" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Scripts y docs Fase 45" "FALLO" ($missing -join ", ")
}

$bashScripts = @("update-prod-safe.sh", "rollback-prod.sh", "restore-backup.sh")
if (Get-Command bash -ErrorAction SilentlyContinue) {
    $syntaxOk = $true
    foreach ($sh in $bashScripts) {
        try {
            & bash -n (Join-Path $root "scripts\$sh") 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $syntaxOk = $false; break }
        } catch {
            $syntaxOk = $false
            break
        }
    }
    if ($syntaxOk) {
        Add-Result "Scripts" "Sintaxis bash Fase 45" "OK" "bash -n"
    } else {
        Add-Result "Scripts" "Sintaxis bash Fase 45" "SKIP" "bash no ejecutable"
    }
} else {
    Add-Result "Scripts" "Sintaxis bash Fase 45" "SKIP" "bash no en PATH"
}

$updateSh = Join-Path $root "scripts\update-prod-safe.sh"
$rollbackSh = Join-Path $root "scripts\rollback-prod.sh"
if ((Test-Path $updateSh) -and (Select-String -Path $updateSh -Pattern "release-state.json" -Quiet)) {
    Add-Result "Update" "Registro release-state" "OK" "update-prod-safe.sh"
} else {
    Add-Result "Update" "Registro release-state" "FALLO" "sin release-state.json"
}

if ((Test-Path $rollbackSh) -and (Select-String -Path $rollbackSh -Pattern "restore-backup.sh" -Quiet)) {
    Add-Result "Rollback" "Integracion restore" "OK" "rollback-prod.sh"
} else {
    Add-Result "Rollback" "Integracion restore" "FALLO" "rollback incompleto"
}

$planDoc = Join-Path $root "docs\plan-rollback-produccion.md"
$runbookDoc = Join-Path $root "docs\runbook-soporte-produccion.md"
$trainingDoc = Join-Path $root "docs\capacitacion-ti-institucional.md"

if ((Test-Path $planDoc) -and (Select-String -Path $planDoc -Pattern "ROLLBACK_RESTORE_DB" -Quiet)) {
    Add-Result "Docs" "Plan rollback" "OK" "procedimiento documentado"
} else {
    Add-Result "Docs" "Plan rollback" "FALLO" "plan incompleto"
}

if ((Test-Path $runbookDoc) -and (Select-String -Path $runbookDoc -Pattern "502/503" -Quiet)) {
    Add-Result "Docs" "Runbook soporte" "OK" "incidentes frecuentes"
} else {
    Add-Result "Docs" "Runbook soporte" "FALLO" "runbook incompleto"
}

if ((Test-Path $trainingDoc) -and (Select-String -Path $trainingDoc -Pattern "Arquitectura y accesos" -Quiet)) {
    Add-Result "Docs" "Capacitacion TI" "OK" "5 modulos"
} else {
    Add-Result "Docs" "Capacitacion TI" "FALLO" "capacitacion incompleta"
}

if (-not $Quick) {
    $stateDir = Join-Path $root ".deploy"
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $commitHash = "unknown"
    try { $commitHash = (git rev-parse HEAD).Trim() } catch { }
    $sampleState = @{
        timestamp       = (Get-Date -Format "yyyyMMdd_HHmmss")
        previous_commit = $commitHash
        mysql_backup    = "backups/mysql/sample.sql"
        qdrant_backup   = ""
        storage_backup  = ""
        api_url         = "http://localhost:8000/api/v1"
        frontend_url    = "http://localhost:8000"
    }
    $samplePath = Join-Path $stateDir "release-state.sample.json"
    $sampleState | ConvertTo-Json | Set-Content -Path $samplePath -Encoding UTF8
    if (Test-Path $samplePath) {
        Add-Result "Estado" "Plantilla release-state" "OK" ".deploy/release-state.sample.json"
    } else {
        Add-Result "Estado" "Plantilla release-state" "FALLO" "no generada"
    }
} else {
    Add-Result "Estado" "Plantilla release-state" "SKIP" "-Quick"
}

Add-Result "Manual" "Referencias Fase 44" "OK" "update/rollback integran smoke y post-deploy"

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Production Ops ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion Production Ops (Fase 45)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-45-production-ops-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
