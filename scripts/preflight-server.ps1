# AVOV - Preflight servidor real (Fase 42)
# Valida dominios, HTTPS, CORS y coherencia API/frontend.
# Uso: .\scripts\preflight-server.ps1 [-EnvFile ".env"]

param(
    [string]$EnvFile = ".env",
    [switch]$AllowLocalhost
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& (Join-Path $PSScriptRoot "preflight-prod.ps1") -EnvFile $EnvFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

function Get-EnvValue {
    param([string]$Key)
    if (-not (Test-Path $EnvFile)) { return $null }
    $line = Get-Content $EnvFile | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim().Trim('"').Trim("'")
}

$issues = New-Object System.Collections.Generic.List[string]

Write-Host ""
Write-Host "=== AVOV Preflight Servidor (Fase 42) ===" -ForegroundColor Cyan

$apiBase = Get-EnvValue "API_BASE_URL"
$frontendBase = Get-EnvValue "FRONTEND_BASE_URL"
$cors = Get-EnvValue "BACKEND_CORS_ORIGINS"
$allowedHosts = Get-EnvValue "BACKEND_ALLOWED_HOSTS"

if ([string]::IsNullOrWhiteSpace($apiBase)) {
    $null = $issues.Add("API_BASE_URL no esta definida")
} elseif ($apiBase -notmatch '^https://') {
    $null = $issues.Add("API_BASE_URL debe usar HTTPS en servidor real")
} elseif ($apiBase -match 'tudominio\.edu\.co|localhost|127\.0\.0\.1') {
    if (-not $AllowLocalhost) {
        $null = $issues.Add("API_BASE_URL contiene placeholder o host local")
    }
}

if ([string]::IsNullOrWhiteSpace($frontendBase)) {
    $null = $issues.Add("FRONTEND_BASE_URL no esta definida")
} elseif ($frontendBase -notmatch '^https://') {
    $null = $issues.Add("FRONTEND_BASE_URL debe usar HTTPS en servidor real")
}

if ($cors -and -not $AllowLocalhost) {
    if ($cors -match 'localhost|127\.0\.0\.1') {
        $null = $issues.Add("BACKEND_CORS_ORIGINS no debe incluir localhost en servidor real")
    }
    if ($frontendBase -and $cors -notmatch [regex]::Escape(($frontendBase -replace '/$', ''))) {
        $null = $issues.Add("BACKEND_CORS_ORIGINS debe incluir FRONTEND_BASE_URL")
    }
}

if ($apiBase -and $allowedHosts) {
    try {
        $apiHost = ([Uri]$apiBase).Host
        if ($allowedHosts -notmatch [regex]::Escape($apiHost)) {
            $null = $issues.Add("BACKEND_ALLOWED_HOSTS debe incluir el host de API_BASE_URL ($apiHost)")
        }
    } catch {
        $null = $issues.Add("API_BASE_URL no es una URL valida")
    }
}

if ($issues.Count -gt 0) {
    Write-Host "Errores preflight servidor:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Preflight servidor OK: dominios y CORS coherentes." -ForegroundColor Green
exit 0
