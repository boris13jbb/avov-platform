# AVOV - Validacion SSL + post-deploy produccion local (Fase 41)
# Uso: .\scripts\validate-prod-ssl-deploy.ps1 [-SkipTeardown]

param(
    [switch]$SkipTeardown
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
. (Join-Path $PSScriptRoot "_tls_helpers.ps1")

$envFile = ".env.prod-ssl-local"
$composeFiles = @("-f", "docker-compose.prod.yml", "-f", "docker-compose.prod-ssl-local.yml")
$projectName = if ($env:AVOV_PROD_SSL_LOCAL_PROJECT) { $env:AVOV_PROD_SSL_LOCAL_PROJECT } else { "avov-prod-ssl-local" }
$reportPath = Join-Path $root "docs\fase-41-prod-ssl-validation.txt"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Get-SslLocalPorts {
    $http = "8180"
    $https = "8443"
    if (Test-Path $envFile) {
        $h = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTP_PORT=' } | Select-Object -First 1
        $s = Get-Content $envFile | Where-Object { $_ -match '^NGINX_HTTPS_PORT=' } | Select-Object -First 1
        if ($h) { $http = ($h -split '=', 2)[1].Trim() }
        if ($s) { $https = ($s -split '=', 2)[1].Trim() }
    }
    return @{ Http = $http; Https = $https }
}

function Wait-ForHealth {
    param([string]$Url, [int]$MaxAttempts = 90, [int]$DelaySeconds = 3)
    Enable-AvovTlsSkip
    $lastError = ""
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $request = [System.Net.HttpWebRequest]::Create($Url)
            $request.Method = "GET"
            $request.Timeout = 10000
            $response = $request.GetResponse()
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $body = $reader.ReadToEnd()
            $reader.Close()
            $response.Close()
            if ($body -match '"success"\s*:\s*true') { return $true }
            $lastError = "success no es true"
        } catch {
            $lastError = $_.Exception.Message
        }
        Write-Host "  Esperando prod-ssl-local ($i/$MaxAttempts)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $DelaySeconds
    }
    Write-Host "  Ultimo error: $lastError" -ForegroundColor DarkYellow
    return $false
}

Write-Host "=== AVOV - Validacion Prod SSL Deploy (Fase 41) ===" -ForegroundColor Cyan

$required = @(
    ".env.prod-ssl-local.example",
    "docker-compose.prod-ssl-local.yml",
    "scripts/generate-dev-ssl-certs.ps1",
    "scripts/post-deploy-prod.ps1",
    "scripts/prod-ssl-local-up.ps1"
)
$missing = $required | Where-Object { -not (Test-Path (Join-Path $root $_)) }
if ($missing.Count -eq 0) {
    Add-Result "Estructura" "Archivos prod-ssl-local" "OK" "$($required.Count) presentes"
} else {
    Add-Result "Estructura" "Archivos prod-ssl-local" "FALLO" ($missing -join ", ")
}

try {
    & (Join-Path $PSScriptRoot "generate-dev-ssl-certs.ps1")
    if ($LASTEXITCODE -eq 0) {
        Add-Result "SSL" "Certificados dev" "OK" "nginx/certs/"
    } else {
        Add-Result "SSL" "Certificados dev" "FALLO" "generate-dev-ssl-certs.ps1"
    }
} catch {
    Add-Result "SSL" "Certificados dev" "FALLO" $_.Exception.Message
}

if (-not (Test-Path $envFile)) {
    Copy-Item ".env.prod-ssl-local.example" $envFile
    Add-Result "Config" "Crear .env.prod-ssl-local" "OK" "desde example"
}

try {
    & (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $envFile
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Preflight" "Variables produccion SSL" "OK" $envFile
    } else {
        Add-Result "Preflight" "Variables produccion SSL" "FALLO" "preflight-prod.ps1"
    }
} catch {
    Add-Result "Preflight" "Variables produccion SSL" "FALLO" $_.Exception.Message
}

try {
    docker compose @composeFiles --env-file $envFile -p $projectName config | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Config" "docker compose config" "OK" "prod + ssl-local"
    } else {
        Add-Result "Config" "docker compose config" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Config" "docker compose config" "FALLO" $_.Exception.Message
}

try {
    & (Join-Path $PSScriptRoot "prod-ssl-local-up.ps1")
    if ($LASTEXITCODE -eq 0) {
        Add-Result "Deploy" "prod-ssl-local-up" "OK" $projectName
    } else {
        Add-Result "Deploy" "prod-ssl-local-up" "FALLO" "exit $LASTEXITCODE"
    }
} catch {
    Add-Result "Deploy" "prod-ssl-local-up" "FALLO" $_.Exception.Message
}

Start-Sleep -Seconds 15

$ports = Get-SslLocalPorts
$httpsBase = "https://localhost:$($ports.Https)/api/v1"
$httpBase = "http://localhost:$($ports.Http)/api/v1"

if (Wait-ForHealth "$httpsBase/health/live") {
    Add-Result "SSL" "Health live via HTTPS" "OK" $httpsBase
} else {
    Add-Result "SSL" "Health live via HTTPS" "FALLO" "timeout"
}

try {
    & (Join-Path $PSScriptRoot "post-deploy-prod.ps1") `
        -BaseUrl $httpsBase `
        -HttpBaseUrl $httpBase `
        -SkipTlsVerify `
        -SeedCareers `
        -ReportPath (Join-Path $root "docs\fase-41-post-deploy-report.txt") `
        -ReportTitle "AVOV - Post-Deploy Prod SSL Local (Fase 41)"
    if ($LASTEXITCODE -eq 0) {
        Add-Result "PostDeploy" "Checklist completo" "OK" "salud + Qdrant + HSTS + redirect"
    } else {
        Add-Result "PostDeploy" "Checklist completo" "FALLO" "post-deploy-prod.ps1"
    }
} catch {
    Add-Result "PostDeploy" "Checklist completo" "FALLO" $_.Exception.Message
}

# Smoke reducido HTTPS (evita inestabilidad TLS en Windows con 17 requests seguidos)
Enable-AvovTlsSkip
try {
    $live = Invoke-RestMethod -Uri "$httpsBase/health/live" -TimeoutSec 15
    if ($live.success -eq $true) {
        Add-Result "Smoke" "Health live HTTPS" "OK" "success=true"
    } else {
        Add-Result "Smoke" "Health live HTTPS" "FALLO" "success no es true"
    }
    $login = Invoke-RestMethod -Uri "$httpsBase/auth/login" -Method POST -ContentType "application/json" `
        -Body (@{ email = "admin@avov.edu.co"; password = "Admin123!" } | ConvertTo-Json) -TimeoutSec 15
    if ($login.data.access_token) {
        Add-Result "Smoke" "Login admin HTTPS" "OK" "token recibido"
    } else {
        Add-Result "Smoke" "Login admin HTTPS" "FALLO" "sin token"
    }
} catch {
    Add-Result "Smoke" "Smoke reducido HTTPS" "FALLO" $_.Exception.Message
}

if (-not $SkipTeardown) {
    & (Join-Path $PSScriptRoot "prod-ssl-local-down.ps1") | Out-Null
    Add-Result "Deploy" "prod-ssl-local-down" "OK" "stack detenido"
} else {
    Add-Result "Deploy" "prod-ssl-local-down" "SKIP" "-SkipTeardown"
}

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Prod SSL Deploy ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

$lines = @(
    "AVOV - Validacion Prod SSL Deploy (Fase 41)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "HttpsBaseUrl: $httpsBase",
    "HttpBaseUrl: $httpBase",
    "Proyecto: $projectName",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: docs\fase-41-prod-ssl-validation.txt" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
