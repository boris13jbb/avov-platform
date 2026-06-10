# Levanta el entorno de desarrollo AVOV
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Archivo .env creado desde .env.example"
}

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    $dockerExe = "${env:ProgramFiles}\Docker\Docker\resources\bin\docker.exe"
    if (Test-Path $dockerExe) {
        $env:Path = "$env:Path;$([System.IO.Path]::GetDirectoryName($dockerExe))"
        $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    }
}

if (-not $dockerCmd) {
    Write-Host ""
    Write-Host "ERROR: Docker no esta instalado o no esta en el PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Yellow
    Write-Host "  1. Instalar Docker Desktop: winget install Docker.DockerDesktop"
    Write-Host "  2. Levantar solo el backend sin Docker: .\scripts\dev-backend-local.ps1"
    Write-Host ""
    exit 1
}

docker compose up --build -d
Write-Host "Servicios iniciados. API: http://localhost:8000/docs"
Write-Host "phpMyAdmin: http://localhost:8081"
