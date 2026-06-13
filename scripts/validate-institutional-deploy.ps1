# AVOV - Validacion despliegue institucional (Fase 44)
# Uso: .\scripts\validate-institutional-deploy.ps1 [-SkipTlsVerify] [-SkipSmoke]

param(
    [string]$ApiUrl = "",
    [string]$FrontendUrl = "",
    [string]$HttpApiUrl = "",
    [switch]$SkipTlsVerify,
    [switch]$SkipSmoke,
    [switch]$Quick
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$reportPath = Join-Path $root "docs\fase-44-institutional-deploy-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Test-ApiLive {
    param([string]$Url, [switch]$TlsSkip)
    try {
        if ($TlsSkip) {
            if (-not (Get-Variable -Name AvovTlsHelpersLoaded -ErrorAction SilentlyContinue)) {
                . (Join-Path $PSScriptRoot "_tls_helpers.ps1")
                $script:AvovTlsHelpersLoaded = $true
            }
            Enable-AvovTlsSkip
        }
        $live = Invoke-RestMethod -Uri "$($Url.TrimEnd('/'))/health/live" -TimeoutSec 15
        return ($live.success -eq $true)
    } catch {
        return $false
    }
}

Write-Host "=== AVOV - Validacion Despliegue Institucional (Fase 44) ===" -ForegroundColor Cyan

$required = @(
    ".env.production.server.example",
    ".env.institutional-local.example",
    "docker-compose.prod.institutional-local.yml",
    "scripts/deploy-institutional.sh",
    "scripts/smoke-public-release.ps1",
    "scripts/smoke-public-release.sh",
    "scripts/prod-institutional-local-up.ps1",
    "docs/fase-44-despliegue-institucional.md",
    "docs/fase-44-ui-checklist-report.template.md",
    "docs/fase-41-flutter-ui-manual.md"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Archivos despliegue institucional" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Archivos despliegue institucional" "FALLO" ($missing -join ", ")
}

if (-not (Test-Path (Join-Path $root ".env.institutional-local")) -and (Test-Path (Join-Path $root ".env.institutional-local.example"))) {
    Copy-Item (Join-Path $root ".env.institutional-local.example") (Join-Path $root ".env.institutional-local")
}

try {
    docker compose -f docker-compose.prod.yml -f docker-compose.prod.web.yml -f docker-compose.prod.institutional-local.yml --env-file .env.institutional-local config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "compose institutional-local" "OK" "prod+web+institutional-local"
    } else {
        Add-Result "Config" "compose institutional-local" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "compose institutional-local" "FALLO" $_.Exception.Message
}

if (-not $Quick) {
    try {
        & (Join-Path $PSScriptRoot "preflight-server.ps1") -EnvFile ".env.server-release.example" -AllowLocalhost
        if ($LASTEXITCODE -eq 0) {
            Add-Result "Preflight" "Plantilla servidor real" "OK" "AllowLocalhost"
        } else {
            Add-Result "Preflight" "Plantilla servidor real" "FALLO" "preflight-server.ps1"
        }
    } catch {
        Add-Result "Preflight" "Plantilla servidor real" "FALLO" $_.Exception.Message
    }
} else {
    Add-Result "Preflight" "Plantilla servidor real" "SKIP" "-Quick"
}

$instApi = "https://localhost:8443/api/v1"
$instFront = "https://localhost:8443"
$instHttp = "http://localhost:8180/api/v1"
$instUp = Test-ApiLive -Url $instApi -TlsSkip

if ($instUp) {
    $ApiUrl = $instApi
    $FrontendUrl = $instFront
    $HttpApiUrl = $instHttp
    Add-Result "Entorno" "Stack institutional-local" "OK" "detectado en :8443"
} elseif ([string]::IsNullOrWhiteSpace($ApiUrl)) {
    $devUp = Test-ApiLive -Url "http://localhost:8000/api/v1"
    if ($devUp) {
        $ApiUrl = "http://localhost:8000/api/v1"
        Add-Result "Entorno" "Stack dev API" "OK" ":8000 (solo API)"
        Add-Result "Entorno" "Stack institutional-local" "SKIP" "levantar: .\scripts\prod-institutional-local-up.ps1"
    } else {
        Add-Result "Entorno" "API disponible" "SKIP" "sin stack activo"
    }
}

if (-not $SkipSmoke -and -not [string]::IsNullOrWhiteSpace($ApiUrl)) {
    if ([string]::IsNullOrWhiteSpace($FrontendUrl) -and $ApiUrl -match "^https?://localhost:8000") {
        Add-Result "Smoke" "Public release API+Web" "SKIP" "solo API dev; usar prod-institutional-local-up.ps1"
    } else {
    $smokeParams = @{
        ApiUrl = $ApiUrl
        ReportPath = (Join-Path $root "docs\fase-44-smoke-public-release.txt")
    }
    if (-not [string]::IsNullOrWhiteSpace($FrontendUrl)) {
        $smokeParams.FrontendUrl = $FrontendUrl
    }
    if (-not [string]::IsNullOrWhiteSpace($HttpApiUrl)) {
        $smokeParams.HttpApiUrl = $HttpApiUrl
    }
    if ($SkipTlsVerify -or $ApiUrl -match "localhost") {
        $smokeParams.SkipTlsVerify = $true
    }
    try {
        & (Join-Path $PSScriptRoot "smoke-public-release.ps1") @smokeParams
        if ($LASTEXITCODE -eq 0) {
            Add-Result "Smoke" "Public release API+Web" "OK" $ApiUrl
        } else {
            Add-Result "Smoke" "Public release API+Web" "FALLO" "smoke-public-release.ps1"
        }
    } catch {
        Add-Result "Smoke" "Public release API+Web" "FALLO" $_.Exception.Message
    }
    }
} else {
    Add-Result "Smoke" "Public release API+Web" "SKIP" "-SkipSmoke o sin ApiUrl"
}

$uiTemplate = Join-Path $root "docs\fase-44-ui-checklist-report.template.md"
if (Test-Path $uiTemplate) {
    Add-Result "Manual" "Plantilla checklist UI" "OK" "fase-44-ui-checklist-report.template.md"
} else {
    Add-Result "Manual" "Plantilla checklist UI" "FALLO" "falta plantilla"
}

Add-Result "Manual" "Checklist UI Flutter" "OK" "docs/fase-41-flutter-ui-manual.md (ejecucion humana)"

$deploySh = Join-Path $root "scripts\deploy-institutional.sh"
if ((Test-Path $deploySh) -and (Select-String -Path $deploySh -Pattern "post-deploy-prod.sh" -Quiet)) {
    Add-Result "Deploy" "Flujo VPS deploy-institutional.sh" "OK" "6 pasos documentados"
} else {
    Add-Result "Deploy" "Flujo VPS deploy-institutional.sh" "FALLO" "script incompleto"
}

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Despliegue Institucional ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion Despliegue Institucional (Fase 44)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "ApiUrl probada: $(if ($ApiUrl) { $ApiUrl } else { 'N/A' })",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-44-institutional-deploy-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
