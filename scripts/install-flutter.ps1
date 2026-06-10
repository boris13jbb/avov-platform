# AVOV — Instalar Flutter SDK sin permisos de administrador
$ErrorActionPreference = "Stop"

$flutterDir = "C:\Users\BRS\develop\flutter"
$flutterBin = "$flutterDir\bin"

Write-Host "=== Instalando Flutter SDK ===" -ForegroundColor Cyan

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git no encontrado. Instalando con winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --disable-interactivity
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (-not (Test-Path "$flutterBin\flutter.bat")) {
    New-Item -ItemType Directory -Path "C:\Users\BRS\develop" -Force | Out-Null
    Write-Host "Clonando Flutter (rama stable)..." -ForegroundColor Yellow
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $flutterDir
} else {
    Write-Host "Flutter ya está instalado en $flutterDir"
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
    $env:Path = "$env:Path;$flutterBin"
    Write-Host "Flutter agregado al PATH del usuario."
}

Write-Host "`nEjecutando flutter doctor..." -ForegroundColor Yellow
& "$flutterBin\flutter.bat" doctor

Write-Host "`n=== Flutter instalado ===" -ForegroundColor Green
Write-Host "Cierra y reabre la terminal, luego ejecuta: .\scripts\install-project-deps.ps1"
