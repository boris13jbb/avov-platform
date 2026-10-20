# AVOV — API secundaria aislada para E2E QA (puerto 8001 → schema avov_test)
# No modifica ni reinicia la API activa en :8000 ni los contenedores Docker.
# No imprime DATABASE_URL ni credenciales.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$Port = 8001
$Schema = "avov_test"
$PidFile = Join-Path $env:TEMP "avov-e2e-api-8001.pid"
$OutLog = Join-Path $env:TEMP "avov-e2e-api-8001.out.log"
$ErrLog = Join-Path $env:TEMP "avov-e2e-api-8001.err.log"

$busy = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $Port }
if ($busy) {
    Write-Host "ERROR: el puerto $Port ya esta en uso. No se inicia la API secundaria." -ForegroundColor Red
    exit 1
}

$mysqlUser = (docker exec avov-mysql printenv MYSQL_USER).Trim()
$mysqlPassword = (docker exec avov-mysql printenv MYSQL_PASSWORD).Trim()
if (-not $mysqlUser -or -not $mysqlPassword) {
    Write-Host "ERROR: no se pudieron leer credenciales MySQL desde el contenedor avov-mysql." -ForegroundColor Red
    exit 1
}

# Host publicado de AVOV (3307). Schema fijo avov_test.
$databaseUrl = "mysql+pymysql://${mysqlUser}:${mysqlPassword}@127.0.0.1:3307/${Schema}"

$python = Join-Path $RepoRoot "backend\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Host "ERROR: falta el venv del backend (python)." -ForegroundColor Red
    exit 1
}

Write-Host "=== AVOV API E2E aislada ===" -ForegroundColor Cyan
Write-Host "MySQL objetivo: contenedor avov-mysql (host 127.0.0.1:3307)"
Write-Host "Schema autorizado: $Schema"
Write-Host "Puerto API: 127.0.0.1:$Port"
Write-Host "Redis DB index: 1 (aislado de la API :8000)"
Write-Host ""

$previousDatabaseUrl = $env:DATABASE_URL
$previousRedisUrl = $env:REDIS_URL
$previousCors = $env:BACKEND_CORS_ORIGINS

try {
    $env:DATABASE_URL = $databaseUrl
    $env:REDIS_URL = "redis://127.0.0.1:6380/1"
    $env:BACKEND_CORS_ORIGINS = "http://127.0.0.1:3001,http://localhost:3001,http://127.0.0.1:3000,http://localhost:3000"

    Push-Location (Join-Path $RepoRoot "backend")
    try {
        & $python scripts/assert_e2e_database.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: preflight de base de datos rechazo el arranque." -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }

    # Start-Process hereda el entorno actual (incluye DATABASE_URL → avov_test).
    # Usar `python -m uvicorn` (más fiable en Windows que uvicorn.exe + Start-Process).
    $proc = Start-Process -FilePath $python `
        -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$Port") `
        -WorkingDirectory (Join-Path $RepoRoot "backend") `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $OutLog `
        -RedirectStandardError $ErrLog

    $proc.Id | Set-Content -Path $PidFile -Encoding ascii
    Write-Host "PID: $($proc.Id) (archivo: $PidFile)"
    Write-Host "Logs: $OutLog | $ErrLog"
    Write-Host "Health: http://127.0.0.1:$Port/api/v1/health"
    Write-Host "Detener: .\scripts\stop-backend-e2e-isolated.ps1"
} finally {
    if ($null -eq $previousDatabaseUrl) {
        Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue
    } else {
        $env:DATABASE_URL = $previousDatabaseUrl
    }
    if ($null -eq $previousRedisUrl) {
        Remove-Item Env:REDIS_URL -ErrorAction SilentlyContinue
    } else {
        $env:REDIS_URL = $previousRedisUrl
    }
    if ($null -eq $previousCors) {
        Remove-Item Env:BACKEND_CORS_ORIGINS -ErrorAction SilentlyContinue
    } else {
        $env:BACKEND_CORS_ORIGINS = $previousCors
    }
}
