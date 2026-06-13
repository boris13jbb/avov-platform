# AVOV - Validacion integral staging (Fase 36)
# Levanta stack produccion local (Nginx), valida proxy, seguridad y smoke E2E.
# Uso: .\scripts\validate-staging.ps1 [-SkipTeardown] [-SkipBackup]

param(
    [switch]$SkipTeardown,
    [switch]$SkipBackup
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$envFile = ".env.staging"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.staging.yml")
$projectName = if ($env:AVOV_STAGING_PROJECT) { $env:AVOV_STAGING_PROJECT } else { "avov-staging" }
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Group,
        [string]$Name,
        [string]$Status,
        [string]$Detail = ""
    )
    $null = $results.Add([pscustomobject]@{
            Group  = $Group
            Name   = $Name
            Status = $Status
            Detail = $Detail
        })
    $color = switch ($Status) {
        "OK" { "Green" }
        "SKIP" { "Yellow" }
        default { "Red" }
    }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Get-StagingPort {
    if (-not (Test-Path $envFile)) { return "8080" }
    $line = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1
    if ($line) { return ($line -split '=', 2)[1].Trim() }
    return "8080"
}

function Wait-ForHealth {
    param(
        [string]$Url,
        [int]$MaxAttempts = 60,
        [int]$DelaySeconds = 5
    )
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-RestMethod -Uri $Url -TimeoutSec 10
            if ($response.success -eq $true) { return $true }
        } catch {
            # reintento
        }
        Write-Host "  Esperando API staging ($i/$MaxAttempts)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

Write-Host "=== AVOV - Validacion Staging (Fase 36) ===" -ForegroundColor Cyan
Write-Host "Raiz: $root"
Write-Host ""

# --- Estructura ---
$required = @(
    "docker-compose.prod.yml",
    "docker-compose.staging.yml",
    ".env.staging.example",
    "nginx\nginx.prod.conf",
    "scripts\staging-up.ps1",
    "scripts\staging-down.ps1"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Archivos staging" "OK" ($required.Count.ToString() + " archivos presentes")
} else {
    Add-Result "Estructura" "Archivos staging" "FALLO" ("Faltan: " + ($missing -join ", "))
}

# --- Compose config ---
try {
    if (-not (Test-Path $envFile)) {
        Copy-Item ".env.staging.example" $envFile
        Add-Result "Config" "Crear .env.staging" "OK" "desde .env.staging.example"
    } else {
        Add-Result "Config" ".env.staging" "OK" "archivo existente"
    }

    docker compose @composeFiles --env-file $envFile -p $projectName config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "docker compose config" "OK" "sintaxis valida"
    } else {
        Add-Result "Config" "docker compose config" "FALLO" "exit code $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "docker compose config" "FALLO" $_.Exception.Message
}

# --- Levantar stack ---
try {
    & (Join-Path $PSScriptRoot "staging-up.ps1")
    if ($LASTEXITCODE -ne 0) {
        Add-Result "Deploy" "staging-up" "FALLO" "exit code $LASTEXITCODE"
    } else {
        Add-Result "Deploy" "staging-up" "OK" "proyecto $projectName"
    }
} catch {
    Add-Result "Deploy" "staging-up" "FALLO" $_.Exception.Message
}

$port = Get-StagingPort
$baseUrl = "http://localhost:$port/api/v1"
$nginxBase = "http://localhost:$port"

# --- Health via Nginx ---
if (Wait-ForHealth -Url "$baseUrl/health/live") {
    Add-Result "Nginx" "Health live via proxy" "OK" $baseUrl
} else {
    Add-Result "Nginx" "Health live via proxy" "FALLO" "timeout esperando $baseUrl"
}

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -TimeoutSec 15
    $mysqlOk = $health.data.services.mysql -eq $true
    if ($mysqlOk) {
        Add-Result "Nginx" "Health completo (MySQL)" "OK" "services.mysql=true"
    } else {
        Add-Result "Nginx" "Health completo (MySQL)" "FALLO" "mysql=$($health.data.services.mysql)"
    }
} catch {
    Add-Result "Nginx" "Health completo (DB)" "FALLO" $_.Exception.Message
}

# --- Seguridad Nginx ---
try {
    $docs = Invoke-WebRequest -Uri "$nginxBase/docs" -UseBasicParsing -TimeoutSec 10
    Add-Result "Seguridad" "OpenAPI /docs bloqueado" "FALLO" "status $($docs.StatusCode)"
} catch {
    $code = $null
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    if ($code -eq 404) {
        Add-Result "Seguridad" "OpenAPI /docs bloqueado" "OK" "404 desde Nginx"
    } else {
        Add-Result "Seguridad" "OpenAPI /docs bloqueado" "FALLO" "codigo $code"
    }
}

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health/live" -UseBasicParsing -TimeoutSec 10
    $cto = ($response.Headers.GetEnumerator() | Where-Object { $_.Key -ieq "X-Content-Type-Options" } | Select-Object -First 1).Value
    $xfo = ($response.Headers.GetEnumerator() | Where-Object { $_.Key -ieq "X-Frame-Options" } | Select-Object -First 1).Value
    if ([string]$cto -match "nosniff" -and [string]$xfo -match "SAMEORIGIN") {
        Add-Result "Seguridad" "Cabeceras Nginx" "OK" "nosniff + SAMEORIGIN"
    } else {
        Add-Result "Seguridad" "Cabeceras Nginx" "FALLO" "cto=$cto xfo=$xfo"
    }
} catch {
    Add-Result "Seguridad" "Cabeceras Nginx" "FALLO" $_.Exception.Message
}

# --- Sin phpMyAdmin en prod compose ---
$prodCompose = Get-Content "docker-compose.prod.yml" -Raw
if ($prodCompose -notmatch "phpmyadmin") {
    Add-Result "Seguridad" "Sin phpMyAdmin en prod" "OK" "no expuesto en staging"
} else {
    Add-Result "Seguridad" "Sin phpMyAdmin en prod" "FALLO" "phpmyadmin encontrado"
}

# --- Smoke E2E via Nginx ---
$reportPath = Join-Path $root "docs\fase-36-staging-report.txt"
try {
    & (Join-Path $PSScriptRoot "smoke-e2e.ps1") `
        -BaseUrl $baseUrl `
        -EnsureStudentSeed `
        -ReportPath $reportPath `
        -ReportTitle "AVOV - Reporte Staging (Fase 36)"
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Smoke" "E2E API via Nginx" "OK" "ver $reportPath"
    } else {
        Add-Result "Smoke" "E2E API via Nginx" "FALLO" "smoke-e2e fallo"
    }
} catch {
    Add-Result "Smoke" "E2E API via Nginx" "FALLO" $_.Exception.Message
}

# --- Backup staging ---
if (-not $SkipBackup) {
    try {
        & (Join-Path $PSScriptRoot "backup-all.ps1") -Target staging
        if ($LASTEXITCODE -eq 0) {
            Add-Result "Backup" "MySQL + Qdrant + storage" "OK" "./backups/"
        } else {
            Add-Result "Backup" "MySQL + Qdrant + storage" "FALLO" "exit code $LASTEXITCODE"
        }
    } catch {
        Add-Result "Backup" "MySQL + Qdrant + storage" "FALLO" $_.Exception.Message
    }
} else {
    Add-Result "Backup" "MySQL + Qdrant + storage" "SKIP" "-SkipBackup"
}

# --- Teardown opcional ---
if (-not $SkipTeardown) {
    & (Join-Path $PSScriptRoot "staging-down.ps1") | Out-Null
    Add-Result "Deploy" "staging-down" "OK" "stack detenido tras validacion"
} else {
    Add-Result "Deploy" "staging-down" "SKIP" "stack sigue activo (-SkipTeardown)"
}

# --- Reporte final ---
$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FAIL" -or $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Staging ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$summaryPath = Join-Path $root "docs\fase-36-staging-validation.txt"
$lines = @(
    "AVOV - Validacion Staging (Fase 36)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl: $baseUrl",
    "Proyecto Docker: $projectName",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "Reporte: docs\fase-36-staging-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
