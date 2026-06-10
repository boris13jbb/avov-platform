# AVOV — Instalacion completa de prerequisitos y dependencias
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AVOV — Instalacion completa" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Test-Admin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Paso 1: .env ---
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[OK] .env creado" -ForegroundColor Green
}

# --- Paso 2: Flutter PATH ---
$flutterBin = "C:\Users\BRS\develop\flutter\bin"
if (Test-Path "$flutterBin\flutter.bat") {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
        $env:Path = "$env:Path;$flutterBin"
        Write-Host "[OK] Flutter agregado al PATH" -ForegroundColor Green
    }
} else {
    Write-Host "[...] Instalando Flutter..." -ForegroundColor Yellow
    & "$PSScriptRoot\install-flutter.ps1"
}

# --- Paso 3: Docker PATH ---
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path "$dockerBin\docker.exe") {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$dockerBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$dockerBin", "User")
        $env:Path = "$env:Path;$dockerBin"
        Write-Host "[OK] Docker agregado al PATH" -ForegroundColor Green
    }
} else {
    Write-Host "[...] Instalando Docker Desktop..." -ForegroundColor Yellow
    winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements --disable-interactivity
}

# --- Paso 4: WSL2 (requiere admin) ---
$wslOk = $false
try {
    wsl --status 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $wslOk = $true }
} catch {}

if (-not $wslOk) {
    if (Test-Admin) {
        Write-Host "[...] Habilitando WSL2..." -ForegroundColor Yellow
        & "$PSScriptRoot\install-wsl-admin.ps1"
    } else {
        Write-Host "[PENDIENTE] WSL2 requiere permisos de Administrador." -ForegroundColor Yellow
        Write-Host "  Ejecuta como Admin: .\scripts\install-wsl-admin.ps1" -ForegroundColor Yellow
        Write-Host "  Luego REINICIA Windows." -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] WSL2 disponible" -ForegroundColor Green
}

# --- Paso 5: Dependencias del proyecto ---
Write-Host ""
Write-Host "[...] Instalando dependencias backend y frontend..." -ForegroundColor Yellow
& "$PSScriptRoot\install-project-deps.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumen de instalacion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git:      $(if (Get-Command git -EA SilentlyContinue) {'OK'} else {'FALTA'})"
Write-Host "Python:   $(if (Get-Command python -EA SilentlyContinue) {'OK'} else {'FALTA'})"
Write-Host "Flutter:  $(if (Test-Path '$flutterBin\flutter.bat') {'OK'} else {'FALTA'})"
Write-Host "Docker:   $(if (Test-Path '$dockerBin\docker.exe') {'OK'} else {'FALTA'})"
Write-Host "WSL2:     $(if ($wslOk) {'OK'} else {'PENDIENTE - reinicio requerido'})"
Write-Host ""
Write-Host "Si WSL esta pendiente:" -ForegroundColor Yellow
Write-Host "  1. Admin: .\scripts\install-wsl-admin.ps1"
Write-Host "  2. Reiniciar Windows"
Write-Host "  3. Abrir Docker Desktop"
Write-Host "  4. .\scripts\dev-up.ps1"
