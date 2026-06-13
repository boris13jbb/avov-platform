# AVOV - Build Flutter Web para produccion (Fase 42)
# Uso: .\scripts\build-flutter-web.ps1 [-ApiBaseUrl "https://api.dominio.edu.co/api/v1"]

param(
    [string]$ApiBaseUrl = "",
    [string]$EnvFile = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $root "frontend"
Set-Location $frontend

function Get-EnvValueFromFile {
    param([string]$File, [string]$Key)
    if (-not (Test-Path $File)) { return $null }
    $line = Get-Content $File | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim().Trim('"').Trim("'")
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $candidates = @($EnvFile, ".env", ".env.server-release.example", ".env.production.server.example") | Where-Object { $_ }
    foreach ($file in $candidates) {
        $path = if ([System.IO.Path]::IsPathRooted($file)) { $file } else { Join-Path $root $file }
        $val = Get-EnvValueFromFile -File $path -Key "API_BASE_URL"
        if ($val) {
            $ApiBaseUrl = $val
            Write-Host "API_BASE_URL desde: $path" -ForegroundColor DarkGray
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    Write-Host "ERROR: Indica -ApiBaseUrl o define API_BASE_URL en un .env" -ForegroundColor Red
    exit 1
}

if ($ApiBaseUrl -match 'tudominio\.edu\.co|CAMBIAR') {
    Write-Host "ERROR: API_BASE_URL contiene placeholder. Edita el .env del servidor." -ForegroundColor Red
    exit 1
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "ERROR: Flutter no esta en PATH." -ForegroundColor Red
    exit 1
}

Write-Host "=== AVOV Build Flutter Web ===" -ForegroundColor Cyan
Write-Host "API_BASE_URL: $ApiBaseUrl"
Write-Host ""

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$indexPath = Join-Path $frontend "build\web\index.html"
if (-not (Test-Path $indexPath)) {
    Write-Host "ERROR: No se genero build/web/index.html" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build web OK: frontend/build/web/" -ForegroundColor Green
Write-Host "Despliega con docker compose -f docker-compose.prod.yml -f docker-compose.prod.web.yml"
Set-Location $root
exit 0
