# AVOV - Validacion operaciones VPS (Fase 43)
# Uso: .\scripts\validate-vps-readiness.ps1 [-BaseUrl "http://localhost:8000/api/v1"]

param(
    [string]$BaseUrl = "",
    [switch]$SkipBackupTest
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$reportPath = Join-Path $root "docs\fase-43-vps-readiness-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

Write-Host "=== AVOV - Validacion VPS Readiness (Fase 43) ===" -ForegroundColor Cyan

$required = @(
    "scripts/backup-all.sh",
    "scripts/backup-storage.sh",
    "scripts/prune-backups.sh",
    "scripts/prune-backups.ps1",
    "scripts/monitor-health.sh",
    "scripts/monitor-health.ps1",
    "scripts/install-vps-cron.sh",
    "scripts/setup-vps.sh",
    "docs/fase-41-flutter-ui-manual.md"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Scripts operaciones VPS" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Scripts operaciones VPS" "FALLO" ($missing -join ", ")
}

$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
    $syntaxOk = $true
    $syntaxDetail = "bash -n"
    foreach ($sh in @("backup-all.sh", "prune-backups.sh", "monitor-health.sh", "install-vps-cron.sh", "setup-vps.sh")) {
        try {
            & bash -n (Join-Path $root "scripts\$sh") 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                $syntaxOk = $false
                $syntaxDetail = "fallo en $sh"
                break
            }
        } catch {
            $syntaxOk = $false
            $syntaxDetail = "bash no ejecutable ($sh)"
            break
        }
    }
    if ($syntaxOk) {
        Add-Result "Scripts" "Sintaxis bash" "OK" $syntaxDetail
    } else {
        Add-Result "Scripts" "Sintaxis bash" "SKIP" $syntaxDetail
    }
} else {
    Add-Result "Scripts" "Sintaxis bash" "SKIP" "bash no en PATH"
}

try {
    & (Join-Path $PSScriptRoot "prune-backups.ps1") -DryRun -RetentionDays 14 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Backup" "Prune dry-run" "OK" "retencion 14 dias"
    } else {
        Add-Result "Backup" "Prune dry-run" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Backup" "Prune dry-run" "FALLO" $_.Exception.Message
}

if (-not $SkipBackupTest) {
    $prodLocal = docker ps --format "{{.Names}}" 2>$null | Where-Object { $_ -match "avov-prod-local" } | Select-Object -First 1
    if ($prodLocal) {
        try {
            & (Join-Path $PSScriptRoot "backup-all.ps1") -Target prod-local
            if ($LASTEXITCODE -eq 0) {
                Add-Result "Backup" "backup-all prod-local" "OK" "./backups/"
            } else {
                Add-Result "Backup" "backup-all prod-local" "FALLO" "exit $LASTEXITCODE"
            }
        } catch {
            Add-Result "Backup" "backup-all prod-local" "FALLO" $_.Exception.Message
        }
    } else {
        Add-Result "Backup" "backup-all prod-local" "SKIP" "stack prod-local no activo"
    }
} else {
    Add-Result "Backup" "backup-all prod-local" "SKIP" "-SkipBackupTest"
}

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    $devUp = $false
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/health/live" -TimeoutSec 3
        if ($r.success -eq $true) { $devUp = $true; $BaseUrl = "http://localhost:8000/api/v1" }
    } catch { }
    if (-not $devUp) {
        $BaseUrl = "http://localhost:8000/api/v1"
    }
}

try {
    & (Join-Path $PSScriptRoot "monitor-health.ps1") -BaseUrl $BaseUrl -ReportPath (Join-Path $root "docs\fase-43-monitor-report.txt")
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Monitor" "Health API" "OK" $BaseUrl
    } else {
        Add-Result "Monitor" "Health API" "FALLO" "monitor-health.ps1 ($BaseUrl)"
    }
} catch {
    Add-Result "Monitor" "Health API" "FALLO" $_.Exception.Message
}

$cronExample = Join-Path $root "docs\cron\avov-backup.cron.example"
$cronPreview = ""
if (Get-Command bash -ErrorAction SilentlyContinue) {
    try {
        $cronPreview = & bash -c "INSTALL=0 AVOV_ROOT='$($root -replace '\\','/')' bash '$($root -replace '\\','/')/scripts/install-vps-cron.sh'" 2>&1 | Out-String
    } catch {
        $cronPreview = ""
    }
}
if ($cronPreview -match "Backup completo diario") {
    Add-Result "Cron" "Plantilla install-vps-cron" "OK" "preview generado"
} elseif ((Test-Path $cronExample) -and (Select-String -Path $cronExample -Pattern "backup-all.sh prod" -Quiet)) {
    Add-Result "Cron" "Plantilla install-vps-cron" "OK" "docs/cron/avov-backup.cron.example"
} elseif (Get-Command bash -ErrorAction SilentlyContinue) {
    Add-Result "Cron" "Plantilla install-vps-cron" "SKIP" "bash no ejecutable en este entorno"
} else {
    Add-Result "Cron" "Plantilla install-vps-cron" "SKIP" "bash no disponible"
}

Add-Result "Manual" "Checklist UI Flutter" "OK" "docs/fase-41-flutter-ui-manual.md"

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen VPS Readiness ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion VPS Readiness (Fase 43)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl monitor: $BaseUrl",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-43-vps-readiness-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
