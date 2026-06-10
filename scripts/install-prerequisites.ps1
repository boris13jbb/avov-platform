# AVOV — Instalación de prerequisitos del sistema
# Ejecutar como Administrador: clic derecho → "Ejecutar con PowerShell como administrador"
$ErrorActionPreference = "Stop"

Write-Host "=== AVOV: Instalación de prerequisitos ===" -ForegroundColor Cyan

function Test-Admin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "ERROR: Este script debe ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "Clic derecho en el archivo → Ejecutar con PowerShell como administrador"
    exit 1
}

Write-Host "`n[1/4] Instalando WSL2..." -ForegroundColor Yellow
wsl --install --no-distribution
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL puede requerir reinicio. Continuando..." -ForegroundColor Yellow
}

Write-Host "`n[2/4] Instalando Git (si no está)..." -ForegroundColor Yellow
winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null

Write-Host "`n[3/4] Instalando Docker Desktop..." -ForegroundColor Yellow
winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements --disable-interactivity

Write-Host "`n[4/4] Configurando Flutter en PATH..." -ForegroundColor Yellow
$flutterBin = "C:\Users\BRS\develop\flutter\bin"
if (Test-Path $flutterBin) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
        Write-Host "Flutter agregado al PATH del usuario."
    }
} else {
    Write-Host "Flutter no encontrado en $flutterBin. Ejecuta install-flutter.ps1 primero." -ForegroundColor Yellow
}

Write-Host "`n=== Instalación completada ===" -ForegroundColor Green
Write-Host "IMPORTANTE: Reinicia el equipo para activar WSL2 y Docker Desktop."
Write-Host "Después del reinicio:"
Write-Host "  1. Abre Docker Desktop y acepta los términos"
Write-Host "  2. Ejecuta: .\scripts\dev-up.ps1"
Write-Host "  3. Ejecuta: .\scripts\install-project-deps.ps1"
