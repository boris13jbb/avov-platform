# AVOV - Validacion integral de release (Fase 39)
# Orquesta todas las validaciones automatizadas y genera reporte consolidado.
#
# Uso:
#   .\scripts\validate-release.ps1           # Completa (incluye staging + vocacional)
#   .\scripts\validate-release.ps1 -Quick  # Rapida: estatico + flutter + smoke dev

param(
    [switch]$Quick,
    [switch]$SkipStaging,
    [switch]$SkipVocational,
    [switch]$SkipFlutter,
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$reportPath = Join-Path $root "docs\fase-39-release-validation.txt"
$results = New-Object System.Collections.Generic.List[object]
$startedAt = Get-Date

function Add-Step {
    param(
        [string]$Phase,
        [string]$Name,
        [string]$Status,
        [string]$Detail = "",
        [int]$ExitCode = 0
    )
    $null = $results.Add([pscustomobject]@{
            Phase    = $Phase
            Name     = $Name
            Status   = $Status
            Detail   = $Detail
            ExitCode = $ExitCode
        })
    $color = switch ($Status) {
        "OK" { "Green" }
        "SKIP" { "Yellow" }
        default { "Red" }
    }
    Write-Host "[$Status] $Phase - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Test-DockerDevReady {
    param([string]$BaseUrl = "http://localhost:8000/api/v1")
    try {
        $live = Invoke-RestMethod -Uri "$BaseUrl/health/live" -TimeoutSec 5
        return $live.success -eq $true
    } catch {
        return $false
    }
}

function Invoke-StepScript {
    param(
        [string]$Phase,
        [string]$Name,
        [string]$ScriptRelative,
        [string[]]$ScriptArgs = @()
    )
    $scriptPath = Join-Path $PSScriptRoot $ScriptRelative
    if (-not (Test-Path $scriptPath)) {
        Add-Step -Phase $Phase -Name $Name -Status "FALLO" -Detail "No existe $ScriptRelative"
        return 1
    }
    try {
        & $scriptPath @ScriptArgs
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 0 }
        if ($code -eq 0) {
            Add-Step -Phase $Phase -Name $Name -Status "OK" -ExitCode $code
        } else {
            Add-Step -Phase $Phase -Name $Name -Status "FALLO" -Detail "exit code $code" -ExitCode $code
        }
        return $code
    } catch {
        Add-Step -Phase $Phase -Name $Name -Status "FALLO" -Detail $_.Exception.Message -ExitCode 1
        return 1
    }
}

Write-Host "=== AVOV - Validacion Release (Fase 39) ===" -ForegroundColor Cyan
Write-Host "Raiz: $root"
if ($Quick) { Write-Host "Modo: Quick (sin staging ni vocacional)" -ForegroundColor Yellow }
Write-Host ""

# --- Fase 1: Estructura ---
$code = Invoke-StepScript -Phase "Estructura" -Name "verify-structure.ps1" -ScriptRelative "verify-structure.ps1"

# --- Fase 2: Criterios estaticos release ---
$gitignoreOk = Select-String -Path (Join-Path $root ".gitignore") -Pattern "^\.env$" -Quiet
if ($gitignoreOk) {
    Add-Step "Release" ".env en .gitignore" "OK"
} else {
    Add-Step "Release" ".env en .gitignore" "FALLO"
}

$prodComposePath = Join-Path $root "docker-compose.prod.yml"
$prodCompose = Get-Content $prodComposePath -Raw -ErrorAction SilentlyContinue
if ($prodCompose -and $prodCompose -notmatch "phpmyadmin") {
    Add-Step "Release" "Sin phpMyAdmin en prod" "OK"
} else {
    Add-Step "Release" "Sin phpMyAdmin en prod" "FALLO"
}

try {
    docker compose -f docker-compose.prod.yml config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Step "Release" "docker compose prod config" "OK"
    } else {
        Add-Step "Release" "docker compose prod config" "FALLO" -Detail "exit $LASTEXITCODE"
    }
} catch {
    Add-Step "Release" "docker compose prod config" "FALLO" -Detail $_.Exception.Message
}

$requiredDocs = @(
    "docs\manual-produccion.md",
    "docs\checklist-qa.md",
    "docs\variables-entorno.md",
    "docs\api-endpoints.md"
)
$missingDocs = $requiredDocs | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missingDocs.Count -eq 0) {
    Add-Step "Release" "Documentacion obligatoria" "OK" "$($requiredDocs.Count) archivos"
} else {
    Add-Step "Release" "Documentacion obligatoria" "FALLO" ("Faltan: " + ($missingDocs -join ", "))
}

# --- Fase 3: Fase 32 (estatico + pytest opcional) ---
try {
    $f32Path = Join-Path $PSScriptRoot "validate-fase32.ps1"
    if ($Quick) {
        & $f32Path -SkipFlutter -SkipDocker
    } else {
        & $f32Path -SkipFlutter
    }
    $f32Code = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($f32Code -eq 0) {
        Add-Step "Fase32" "validate-fase32.ps1" "OK"
    } else {
        Add-Step "Fase32" "validate-fase32.ps1" "FALLO" "exit code $f32Code"
    }
} catch {
    Add-Step "Fase32" "validate-fase32.ps1" "FALLO" $_.Exception.Message
}

# --- Fase 4: Flutter ---
if (-not $SkipFlutter) {
    Invoke-StepScript -Phase "Flutter" -Name "validate-flutter-qa.ps1" -ScriptRelative "validate-flutter-qa.ps1" | Out-Null
} else {
    Add-Step "Flutter" "validate-flutter-qa.ps1" "SKIP" "-SkipFlutter"
}

# --- Fase 5: Smoke dev ---
if (-not $SkipSmoke) {
    if (Test-DockerDevReady) {
        try {
            $smokePath = Join-Path $PSScriptRoot "smoke-e2e.ps1"
            & $smokePath -EnsureStudentSeed
            $smokeCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
            if ($smokeCode -eq 0) {
                Add-Step "Smoke" "smoke-e2e.ps1" "OK"
            } else {
                Add-Step "Smoke" "smoke-e2e.ps1" "FALLO" "exit code $smokeCode"
            }
        } catch {
            Add-Step "Smoke" "smoke-e2e.ps1" "FALLO" $_.Exception.Message
        }
    } else {
        Add-Step "Smoke" "smoke-e2e.ps1" "SKIP" "Backend dev no disponible en :8000 (docker compose up -d)"
    }
} else {
    Add-Step "Smoke" "smoke-e2e.ps1" "SKIP" "-SkipSmoke"
}

# --- Fase 6: Staging ---
$runStaging = -not $SkipStaging -and -not $Quick
if ($runStaging) {
    Invoke-StepScript -Phase "Staging" -Name "validate-staging.ps1" -ScriptRelative "validate-staging.ps1" | Out-Null
} else {
    $reason = if ($Quick) { "modo Quick" } else { "-SkipStaging" }
    Add-Step "Staging" "validate-staging.ps1" "SKIP" $reason
}

# --- Fase 7: Vocacional ---
$runVocational = -not $SkipVocational -and -not $Quick
if ($runVocational) {
    if (Test-DockerDevReady) {
        Invoke-StepScript -Phase "Vocational" -Name "validate-vocational-e2e.ps1" -ScriptRelative "validate-vocational-e2e.ps1" | Out-Null
    } else {
        Add-Step "Vocacional" "validate-vocational-e2e.ps1" "SKIP" "Backend dev no disponible"
    }
} else {
    $reason = if ($Quick) { "modo Quick" } else { "-SkipVocational" }
    Add-Step "Vocacional" "validate-vocational-e2e.ps1" "SKIP" $reason
}

# --- Resumen ---
$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FALLO" }).Count
$elapsed = (Get-Date) - $startedAt

Write-Host ""
Write-Host "=== Resumen Release ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail | Duracion: $($elapsed.ToString('mm\:ss'))"

$lines = @(
    "AVOV - Validacion Release (Fase 39)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Modo: $(if ($Quick) { 'Quick' } else { 'Completo' })",
    "Duracion: $($elapsed.ToString('mm\:ss'))",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Phase) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-39-release-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
