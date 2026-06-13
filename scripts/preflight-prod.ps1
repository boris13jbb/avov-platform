# AVOV - Preflight de variables antes de despliegue produccion (Fase 40)
# Valida .env sin levantar Docker.
# Uso: .\scripts\preflight-prod.ps1 [-EnvFile ".env"]

param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$issues = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Get-EnvValue {
    param([string]$Key)
    if (-not (Test-Path $EnvFile)) { return $null }
    $line = Get-Content $EnvFile | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim().Trim('"').Trim("'")
}

function Test-Placeholder {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    return ($Value -match 'CAMBIAR|change-me|your-.*-here|placeholder|example\.com' -and $Value -notmatch 'prod-local-placeholder|prod-ssl-local-placeholder|server-release-placeholder')
}

Write-Host "=== AVOV Preflight Produccion ===" -ForegroundColor Cyan
Write-Host "Archivo: $EnvFile"
Write-Host ""

if (-not (Test-Path $EnvFile)) {
    Write-Host "FALLO: No existe $EnvFile" -ForegroundColor Red
    exit 1
}

$requiredKeys = @(
    "APP_SECRET_KEY",
    "JWT_SECRET_KEY",
    "MYSQL_ROOT_PASSWORD",
    "MYSQL_PASSWORD",
    "DATABASE_URL",
    "BACKEND_CORS_ORIGINS",
    "DEEPSEEK_API_KEY"
)

foreach ($key in $requiredKeys) {
    $val = Get-EnvValue $key
    if ([string]::IsNullOrWhiteSpace($val)) {
        $null = $issues.Add("$key no esta definida")
    }
}

$appSecret = Get-EnvValue "APP_SECRET_KEY"
$jwtSecret = Get-EnvValue "JWT_SECRET_KEY"
foreach ($pair in @(@{ Name = "APP_SECRET_KEY"; Value = $appSecret }, @{ Name = "JWT_SECRET_KEY"; Value = $jwtSecret })) {
    if ($pair.Value.Length -lt 32) {
        $null = $issues.Add("$($pair.Name) debe tener al menos 32 caracteres")
    }
    if (Test-Placeholder $pair.Value) {
        $null = $issues.Add("$($pair.Name) contiene placeholder sin cambiar")
    }
}

$mysqlPass = Get-EnvValue "MYSQL_PASSWORD"
$dbUrl = Get-EnvValue "DATABASE_URL"
if ($mysqlPass -and $dbUrl -and $dbUrl -notmatch [regex]::Escape($mysqlPass)) {
    $null = $issues.Add("DATABASE_URL no coincide con MYSQL_PASSWORD")
}

$cors = Get-EnvValue "BACKEND_CORS_ORIGINS"
if ($cors -and $cors -match '\*') {
    $null = $issues.Add("BACKEND_CORS_ORIGINS no puede incluir '*' en produccion")
}

$appDebug = Get-EnvValue "APP_DEBUG"
if ($appDebug -eq "true") {
    $null = $issues.Add("APP_DEBUG debe ser false en produccion")
}

$deepseek = Get-EnvValue "DEEPSEEK_API_KEY"
if (Test-Placeholder $deepseek) {
    $null = $warnings.Add("DEEPSEEK_API_KEY es placeholder - recomendaciones usaran fallback")
}

if ($warnings.Count -gt 0) {
    Write-Host "Advertencias:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "Errores de preflight:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Preflight OK: variables listas para despliegue." -ForegroundColor Green
exit 0
