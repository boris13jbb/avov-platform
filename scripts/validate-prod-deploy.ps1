# AVOV - Validacion despliegue produccion local (Fase 40)
# Uso: .\scripts\validate-prod-deploy.ps1 [-SkipTeardown]

param(
    [switch]$SkipTeardown
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$envFile = ".env.prod-local"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-local.yml")
$projectName = if ($env:AVOV_PROD_LOCAL_PROJECT) { $env:AVOV_PROD_LOCAL_PROJECT } else { "avov-prod-local" }
$reportPath = Join-Path $root "docs\fase-40-prod-deploy-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Get-ProdLocalPort {
    if (-not (Test-Path $envFile)) { return "8090" }
    $line = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1
    if ($line) { return ($line -split '=', 2)[1].Trim() }
    return "8090"
}

function Wait-ForHealth {
    param([string]$Url, [int]$MaxAttempts = 60, [int]$DelaySeconds = 5)
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $r = Invoke-RestMethod -Uri $Url -TimeoutSec 10
            if ($r.success -eq $true) { return $true }
        } catch { }
        Write-Host "  Esperando prod-local ($i/$MaxAttempts)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

Write-Host "=== AVOV - Validacion Prod Deploy (Fase 40) ===" -ForegroundColor Cyan

# Estructura
$required = @(".env.prod-local.example", "docker-compose.prod-local.yml", "scripts\preflight-prod.ps1", "scripts\prod-local-up.ps1")
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Archivos prod-local" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Archivos prod-local" "FALLO" ($missing -join ", ")
}

if (-not (Test-Path $envFile)) {
    Copy-Item ".env.prod-local.example" $envFile
    Add-Result "Config" "Crear .env.prod-local" "OK" "desde example"
}

try {
    & (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $envFile
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Preflight" "Variables produccion" "OK" $envFile
    } else {
        Add-Result "Preflight" "Variables produccion" "FALLO" "preflight-prod.ps1"
    }
} catch {
    Add-Result "Preflight" "Variables produccion" "FALLO" $_.Exception.Message
}

try {
    docker compose @composeFiles --env-file $envFile -p $projectName config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "docker compose config" "OK" "prod + prod-local"
    } else {
        Add-Result "Config" "docker compose config" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "docker compose config" "FALLO" $_.Exception.Message
}

try {
    & (Join-Path $PSScriptRoot "prod-local-up.ps1")
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Deploy" "prod-local-up" "OK" $projectName
    } else {
        Add-Result "Deploy" "prod-local-up" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Deploy" "prod-local-up" "FALLO" $_.Exception.Message
}

$port = Get-ProdLocalPort
$baseUrl = "http://localhost:$port/api/v1"

if (Wait-ForHealth "$baseUrl/health/live") {
    Add-Result "Nginx" "Health live via proxy" "OK" $baseUrl
} else {
    Add-Result "Nginx" "Health live via proxy" "FALLO" "timeout"
}

try {
    $docs = Invoke-WebRequest -Uri "http://localhost:$port/docs" -UseBasicParsing -TimeoutSec 10
    Add-Result "Seguridad" "OpenAPI bloqueado" "FALLO" "status $($docs.StatusCode)"
} catch {
    $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { $null }
    if ($code -eq 404) {
        Add-Result "Seguridad" "OpenAPI bloqueado" "OK" "404"
    } else {
        Add-Result "Seguridad" "OpenAPI bloqueado" "FALLO" "codigo $code"
    }
}

try {
    & (Join-Path $PSScriptRoot "smoke-e2e.ps1") `
        -BaseUrl $baseUrl `
        -EnsureStudentSeed `
        -ReportPath (Join-Path $root "docs\fase-40-prod-smoke-report.txt") `
        -ReportTitle "AVOV - Smoke Prod Local (Fase 40)"
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Smoke" "E2E via Nginx prod-local" "OK" "17 checks"
    } else {
        Add-Result "Smoke" "E2E via Nginx prod-local" "FALLO" "smoke-e2e"
    }
} catch {
    Add-Result "Smoke" "E2E via Nginx prod-local" "FALLO" $_.Exception.Message
}

try {
    & (Join-Path $PSScriptRoot "backup-all.ps1") -Target prod-local
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Backup" "MySQL + Qdrant + storage" "OK" "./backups/"
    } else {
        Add-Result "Backup" "MySQL + Qdrant + storage" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Backup" "MySQL + Qdrant + storage" "FALLO" $_.Exception.Message
}

if (-not $SkipTeardown) {
    & (Join-Path $PSScriptRoot "prod-local-down.ps1") | Out-Null
    Add-Result "Deploy" "prod-local-down" "OK" "stack detenido"
} else {
    Add-Result "Deploy" "prod-local-down" "SKIP" "-SkipTeardown"
}

$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Prod Deploy ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion Prod Deploy (Fase 40)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl: $baseUrl",
    "Proyecto: $projectName",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-40-prod-deploy-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
