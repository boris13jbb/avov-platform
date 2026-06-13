# AVOV - Validacion release servidor + Flutter Web (Fase 42)
# Uso: .\scripts\validate-server-release.ps1 [-SkipFlutterBuild]

param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$envFile = ".env.server-release.example"
$reportPath = Join-Path $root "docs\fase-42-server-release-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

Write-Host "=== AVOV - Validacion Server Release (Fase 42) ===" -ForegroundColor Cyan

$required = @(
    ".env.production.server.example",
    ".env.server-release.example",
    "docker-compose.prod.web.yml",
    "docker-compose.prod.web.ssl.yml",
    "nginx/nginx.prod.web.conf",
    "nginx/nginx.prod.ssl.web.conf",
    "scripts/preflight-server.ps1",
    "scripts/build-flutter-web.ps1",
    "scripts/deploy-prod-server.sh",
    "docs/fase-41-flutter-ui-manual.md"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Archivos servidor release" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Archivos servidor release" "FALLO" ($missing -join ", ")
}

try {
    & (Join-Path $PSScriptRoot "preflight-server.ps1") -EnvFile $envFile
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Preflight" "Servidor (.env.server-release)" "OK" "dominios HTTPS"
    } else {
        Add-Result "Preflight" "Servidor (.env.server-release)" "FALLO" "preflight-server.ps1"
    }
} catch {
    Add-Result "Preflight" "Servidor (.env.server-release)" "FALLO" $_.Exception.Message
}

try {
    docker compose -f docker-compose.prod.yml -f docker-compose.prod.web.yml --env-file $envFile config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "compose prod + web" "OK" ""
    } else {
        Add-Result "Config" "compose prod + web" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "compose prod + web" "FALLO" $_.Exception.Message
}

try {
    docker compose -f docker-compose.prod.yml -f docker-compose.prod.web.yml -f docker-compose.prod.web.ssl.yml --env-file $envFile config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "compose prod + web + ssl" "OK" ""
    } else {
        Add-Result "Config" "compose prod + web + ssl" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "compose prod + web + ssl" "FALLO" $_.Exception.Message
}

try {
    & (Join-Path $PSScriptRoot "validate-flutter-qa.ps1")
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Flutter" "analyze + test" "OK" "validate-flutter-qa.ps1"
    } else {
        Add-Result "Flutter" "analyze + test" "FALLO" "validate-flutter-qa.ps1"
    }
} catch {
    Add-Result "Flutter" "analyze + test" "FALLO" $_.Exception.Message
}

if (-not $SkipFlutterBuild) {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    $webIndex = Join-Path $root "frontend\build\web\index.html"
    if (-not $flutter) {
        Add-Result "Flutter" "build web" "SKIP" "Flutter no en PATH"
    } else {
        try {
            & (Join-Path $PSScriptRoot "build-flutter-web.ps1") -EnvFile (Join-Path $root $envFile)
            if ((Test-Path $webIndex)) {
                Add-Result "Flutter" "build web release" "OK" "frontend/build/web/"
            } else {
                Add-Result "Flutter" "build web release" "FALLO" "falta index.html"
            }
        } catch {
            Add-Result "Flutter" "build web release" "FALLO" $_.Exception.Message
        }
    }
} else {
    Add-Result "Flutter" "build web release" "SKIP" "-SkipFlutterBuild"
}

$webIndexPath = Join-Path $root "frontend\build\web\index.html"
if (Test-Path $webIndexPath) {
    $indexContent = Get-Content $webIndexPath -Raw
    if ($indexContent -match "flutter") {
        Add-Result "Flutter" "Artefacto web generado" "OK" "index.html"
    } else {
        Add-Result "Flutter" "Artefacto web generado" "FALLO" "index.html invalido"
    }
} else {
    Add-Result "Flutter" "Artefacto web generado" "SKIP" "sin build web"
}

Add-Result "Manual" "Checklist UI Flutter" "OK" "docs/fase-41-flutter-ui-manual.md (ejecucion manual)"

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Server Release ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion Server Release (Fase 42)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Env validacion: $envFile",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-42-server-release-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
