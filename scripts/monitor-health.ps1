# AVOV - Monitoreo de salud API + servicios (Fase 43)
# Uso: .\scripts\monitor-health.ps1 [-BaseUrl "http://localhost:8000/api/v1"]

param(
    [string]$BaseUrl = "http://localhost:8000/api/v1",
    [int]$DiskWarnPercent = 85,
    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Name = $Name; Status = $Status; Detail = $Detail })
    $color = if ($Status -eq "OK") { "Green" } else { "Red" }
    Write-Host "[$Status] $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

Write-Host "=== AVOV Monitor Health ===" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

try {
    $live = Invoke-RestMethod -Uri "$BaseUrl/health/live" -TimeoutSec 15
    if ($live.success -eq $true) {
        Add-Check "Health live" "OK" "success=true"
    } else {
        Add-Check "Health live" "FALLO" "success no es true"
    }
} catch {
    Add-Check "Health live" "FALLO" $_.Exception.Message
}

try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 20
    $svc = $health.data.services
    $ok = ($svc.mysql -eq $true) -and ($svc.redis -eq $true) -and ($svc.qdrant -eq $true)
    if ($ok) {
        Add-Check "Servicios MySQL/Redis/Qdrant" "OK" "todos up"
    } else {
        Add-Check "Servicios MySQL/Redis/Qdrant" "FALLO" ($svc | ConvertTo-Json -Compress)
    }
} catch {
    Add-Check "Servicios MySQL/Redis/Qdrant" "FALLO" $_.Exception.Message
}

try {
    $driveLetter = $root.Substring(0, 1)
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${driveLetter}:'" -ErrorAction SilentlyContinue
    if ($disk -and $disk.Size -gt 0) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
        if ($usedPercent -ge $DiskWarnPercent) {
            Add-Check "Espacio en disco" "FALLO" "${usedPercent}% usado (umbral ${DiskWarnPercent}%)"
        } else {
            Add-Check "Espacio en disco" "OK" "${usedPercent}% usado"
        }
    } else {
        Add-Check "Espacio en disco" "OK" "no evaluado"
    }
} catch {
    Add-Check "Espacio en disco" "OK" "no evaluado en este SO"
}

$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count
$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count

Write-Host ""
Write-Host "=== Resumen Monitor ===" -ForegroundColor Cyan
Write-Host "OK: $ok | FALLO: $fail"

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $root "docs\fase-43-monitor-report.txt"
}

$lines = @(
    "AVOV - Monitor Health (Fase 43)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl: $BaseUrl",
    "OK: $ok | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $ReportPath -Encoding UTF8
Write-Host "Reporte: $ReportPath" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
