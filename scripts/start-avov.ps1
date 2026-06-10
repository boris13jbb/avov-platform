# AVOV — Iniciar Docker Desktop y levantar el stack completo
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
$dockerExe = "$dockerBin\docker.exe"
$dockerDesktop = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (-not (Test-Path $dockerExe)) {
    Write-Host "ERROR: Docker Desktop no esta instalado." -ForegroundColor Red
    Write-Host "Instala con: winget install Docker.DockerDesktop"
    exit 1
}

$env:Path = "$dockerBin;" + $env:Path

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Archivo .env creado." -ForegroundColor Yellow
}

if (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue)) {
    Write-Host "Iniciando Docker Desktop..." -ForegroundColor Yellow
    Start-Process $dockerDesktop
}

Write-Host "Esperando que Docker este listo..." -ForegroundColor Yellow
$ready = $false
for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 5
    $version = & $dockerExe version --format "{{.Server.Version}}" 2>&1
    if ($LASTEXITCODE -eq 0 -and $version -and $version -notmatch "failed|error") {
        Write-Host "Docker listo (v$version)" -ForegroundColor Green
        $ready = $true
        break
    }
    if ($i % 6 -eq 0) {
        Write-Host "  Esperando... ($i/60)"
    }
}

if (-not $ready) {
    Write-Host "ERROR: Docker no respondio a tiempo." -ForegroundColor Red
    Write-Host "Abre Docker Desktop manualmente desde el menu Inicio y vuelve a ejecutar este script."
    exit 1
}

Write-Host "Levantando servicios AVOV..." -ForegroundColor Cyan
& $dockerExe compose up -d

Start-Sleep -Seconds 15
& $dockerExe compose ps

Write-Host ""
Write-Host "=== AVOV en ejecucion ===" -ForegroundColor Green
Write-Host "API:        http://localhost:8000"
Write-Host "Swagger:    http://localhost:8000/docs"
Write-Host "Health:     http://localhost:8000/api/v1/health"
Write-Host "phpMyAdmin: http://localhost:8081"
Write-Host "Qdrant:     http://localhost:6333/dashboard"
Write-Host ""
Write-Host "Verificar: curl http://localhost:8000/api/v1/health"
