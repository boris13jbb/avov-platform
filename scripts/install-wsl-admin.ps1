# AVOV — Habilitar WSL2 (EJECUTAR COMO ADMINISTRADOR)
# Clic derecho → "Ejecutar con PowerShell como administrador"
$ErrorActionPreference = "Stop"

function Test-Admin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "ERROR: Ejecuta este script como Administrador." -ForegroundColor Red
    Write-Host "Clic derecho en install-wsl-admin.ps1 → Ejecutar con PowerShell como administrador"
    exit 1
}

Write-Host "=== Habilitando WSL2 para Docker Desktop ===" -ForegroundColor Cyan

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host ""
Write-Host "Instalando componente WSL..." -ForegroundColor Yellow
wsl --install --no-distribution

Write-Host ""
Write-Host "=== WSL2 configurado ===" -ForegroundColor Green
Write-Host "REINICIA Windows y luego:" -ForegroundColor Yellow
Write-Host "  1. Abre Docker Desktop (acepta terminos si aparece)"
Write-Host "  2. cd C:\Users\BRS\Documents\aplicstibi"
Write-Host "  3. .\scripts\dev-up.ps1"
