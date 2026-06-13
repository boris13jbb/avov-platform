# Genera certificados TLS autofirmados para validacion SSL local (Fase 41)
# Salida: nginx/certs/fullchain.pem y nginx/certs/privkey.pem

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$certsDir = Join-Path $root "nginx\certs"
$fullchain = Join-Path $certsDir "fullchain.pem"
$privkey = Join-Path $certsDir "privkey.pem"

New-Item -ItemType Directory -Force -Path $certsDir | Out-Null

if ((Test-Path $fullchain) -and (Test-Path $privkey)) {
    Write-Host "Certificados ya existen en nginx/certs/ (omitido)." -ForegroundColor Yellow
    Write-Host "  $fullchain"
    Write-Host "  $privkey"
    exit 0
}

function Find-OpenSslPath {
    $candidates = @(
        (Get-Command openssl -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "${env:ProgramFiles}\Git\usr\bin\openssl.exe",
        "${env:ProgramFiles(x86)}\Git\usr\bin\openssl.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }
    return $candidates | Select-Object -First 1
}

function New-CertsWithOpenSsl {
    param([string]$OpenSslPath)
    Write-Host "Generando certificado autofirmado con OpenSSL (365 dias, CN=localhost)..." -ForegroundColor Cyan
    & $OpenSslPath req -x509 -nodes -newkey rsa:2048 `
        -keyout $privkey `
        -out $fullchain `
        -days 365 `
        -subj "/CN=localhost/O=AVOV-Dev/C=CO"
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL fallo con codigo $LASTEXITCODE"
    }
}

function New-CertsWithDocker {
    Write-Host "OpenSSL no encontrado; generando certificados via Docker alpine/openssl..." -ForegroundColor Yellow
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        throw "Docker no disponible para generar certificados"
    }
    $mount = $certsDir -replace '\\', '/'
    if ($mount -match '^[A-Za-z]:') {
        $drive = $mount.Substring(0, 1).ToLower()
        $mount = "/$drive$($mount.Substring(2))"
    }
    docker run --rm -v "${mount}:/certs" alpine/openssl req -x509 -nodes -newkey rsa:2048 `
        -keyout /certs/privkey.pem `
        -out /certs/fullchain.pem `
        -days 365 `
        -subj "/CN=localhost/O=AVOV-Dev/C=CO" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker alpine/openssl fallo con codigo $LASTEXITCODE"
    }
}

try {
    $opensslPath = Find-OpenSslPath
    if ($opensslPath) {
        New-CertsWithOpenSsl -OpenSslPath $opensslPath
    } else {
        New-CertsWithDocker
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Instala Git for Windows (openssl) o ejecuta con Docker activo." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $fullchain) -or -not (Test-Path $privkey)) {
    Write-Host "ERROR: no se crearon los archivos PEM esperados." -ForegroundColor Red
    exit 1
}

Write-Host "Certificados creados:" -ForegroundColor Green
Write-Host "  $fullchain"
Write-Host "  $privkey"
Write-Host ""
Write-Host "Solo para desarrollo/validacion local. No usar en produccion real."
