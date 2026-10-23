# AVOV — API secundaria aislada para E2E QA (puerto configurable → schema avov_test)
# No modifica ni reinicia la API activa en :8000 ni los contenedores Docker.
# No imprime DATABASE_URL ni credenciales.
#
# Uso:
#   .\scripts\dev-backend-e2e-isolated.ps1
#   .\scripts\dev-backend-e2e-isolated.ps1 -Port 8002
#
# Supervisión:
# - Distingue wrapper (este script) del servidor (PID archivo / listener).
# - No espera indefinidamente al proceso persistente (Start-Process sin -Wait).
# - Si el puerto ya escucha, NO se reutiliza solo por health HTTP 200: eso no demuestra
#   schema avov_test. Sin DATABASE_URL verificable del proceso + assert_e2e_database.py,
#   se falla cerrado y se pide stop + relanzar (el arranque sí ejecuta el assert).
# - Tras arrancar, hace health check con timeout y resultado explícito.
# - Un wrapper abortado por el entorno NO implica servidor caído.
# - Este script no termina procesos ajenos ni el listener existente.

param(
    [int]$Port = 8001
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if ($Port -lt 1024 -or $Port -gt 65535) {
    Write-Host "ERROR: puerto invalido: $Port (use 1024-65535)." -ForegroundColor Red
    exit 2
}

$Schema = "avov_test"
$PidFile = Join-Path $env:TEMP "avov-e2e-api-$Port.pid"
$OutLog = Join-Path $env:TEMP "avov-e2e-api-$Port.out.log"
$ErrLog = Join-Path $env:TEMP "avov-e2e-api-$Port.err.log"
$ReportsDirStatusFile = Join-Path $env:TEMP "avov-e2e-api-$Port.reports-dir.txt"
$HealthUrl = "http://127.0.0.1:$Port/api/v1/health"
$HealthTimeoutSec = 20
$HealthPollMs = 500
$StopHint = ".\scripts\stop-backend-e2e-isolated.ps1 -Port $Port"

function Get-AvovE2eListenerPid {
    param([int]$ListenPort)
    $conn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $ListenPort } |
        Select-Object -First 1
    if ($null -eq $conn) { return $null }
    return [int]$conn.OwningProcess
}

function Test-AvovE2eHealth {
    param(
        [string]$Url,
        [int]$TimeoutSec = 5
    )
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
        return @{
            Ok         = ($resp.StatusCode -eq 200)
            StatusCode = [int]$resp.StatusCode
        }
    } catch {
        $code = 0
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $code = [int]$_.Exception.Response.StatusCode
        }
        return @{
            Ok         = $false
            StatusCode = $code
        }
    }
}

function Get-AvovE2eRecordedServerPid {
    if (-not (Test-Path $PidFile)) { return $null }
    $raw = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($raw -match '^\d+$') { return [int]$raw }
    return $null
}

function Write-AvovE2eStatus {
    param(
        [string]$WrapperStatus,
        [Nullable[int]]$ServerPid,
        [Nullable[int]]$ListenerPid,
        [string]$Health = "n/a",
        [string]$Mode = "n/a"
    )
    $sp = if ($null -eq $ServerPid) { "none" } else { "$ServerPid" }
    $lp = if ($null -eq $ListenerPid) { "none" } else { "$ListenerPid" }
    Write-Host "WRAPPER_STATUS=$WrapperStatus mode=$Mode port=$Port server_pid=$sp listener_pid=$lp health=$Health"
}

$ReportsDirOverride = ($env:AVOV_REPORTS_DIR | ForEach-Object { if ($null -eq $_) { "" } else { "$_".Trim() } })

$listenerPid = Get-AvovE2eListenerPid -ListenPort $Port
if ($null -ne $listenerPid) {
    $recorded = Get-AvovE2eRecordedServerPid
    $health = Test-AvovE2eHealth -Url $HealthUrl -TimeoutSec 5
    $healthLabel = "$($health.StatusCode)"

    # Un override de informes exige proceso nuevo: no reutilizar el listener existente.
    if ($ReportsDirOverride) {
        Write-Host "ERROR: puerto $Port ocupado y AVOV_REPORTS_DIR esta definido." -ForegroundColor Red
        Write-Host "Detenga con $StopHint y vuelva a lanzar para heredar el directorio."
        Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $recorded -ListenerPid $listenerPid -Health $healthLabel -Mode "reports_dir_requires_restart"
        exit 1
    }

    # F.3 — fail closed: health/PID/puerto no demuestran aislamiento a avov_test.
    # El contrato /api/v1/health solo indica si MySQL responde, no el nombre del schema.
    # assert_e2e_database.py es la verificacion fiable, pero requiere el DATABASE_URL
    # efectivo del proceso que escucha; reconstruir una URL local solo prueba esa URL,
    # no la del listener. Sin lectura fiable del entorno del proceso (fuera de alcance
    # seguro aqui), se bloquea la reutilizacion. No se termina el proceso automaticamente.
    Write-Host "ERROR: puerto $Port ya esta en uso (listener PID $listenerPid)." -ForegroundColor Red
    if ($health.Ok) {
        Write-Host "Health HTTP $($health.StatusCode) no basta: no demuestra schema '$Schema'."
    } else {
        Write-Host "Health no es sano (HTTP $($health.StatusCode))."
    }
    Write-Host "Reutilizacion bloqueada hasta verificar el entorno del proceso con assert_e2e_database.py."
    Write-Host "Accion: $StopHint y vuelva a lanzar este script (el arranque ejecuta el assert)."
    Write-Host "PID archivo: $(if ($null -eq $recorded) { 'ausente' } else { $recorded }) ($PidFile)"
    Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $recorded -ListenerPid $listenerPid -Health $healthLabel -Mode "reuse_blocked_unverified"
    exit 1
}

$mysqlUser = (docker exec avov-mysql printenv MYSQL_USER).Trim()
$mysqlPassword = (docker exec avov-mysql printenv MYSQL_PASSWORD).Trim()
if (-not $mysqlUser -or -not $mysqlPassword) {
    Write-Host "ERROR: no se pudieron leer credenciales MySQL desde el contenedor avov-mysql." -ForegroundColor Red
    Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $null -ListenerPid $null -Health "n/a" -Mode "mysql_creds"
    exit 1
}

# Host publicado de AVOV (3307). Schema fijo avov_test.
$databaseUrl = "mysql+pymysql://${mysqlUser}:${mysqlPassword}@127.0.0.1:3307/${Schema}"

$python = Join-Path $RepoRoot "backend\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Host "ERROR: falta el venv del backend (python)." -ForegroundColor Red
    Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $null -ListenerPid $null -Health "n/a" -Mode "missing_venv"
    exit 1
}

Write-Host "=== AVOV API E2E aislada ===" -ForegroundColor Cyan
Write-Host "MySQL objetivo: contenedor avov-mysql (host 127.0.0.1:3307)"
Write-Host "Schema autorizado: $Schema"
Write-Host "Puerto API: 127.0.0.1:$Port"
Write-Host "Redis DB index: 1 (aislado de la API :8000)"
Write-Host "Python: $python"
if ($ReportsDirOverride) {
    Write-Host "AVOV_REPORTS_DIR: override activo (heredado por Uvicorn al arrancar)"
} else {
    Write-Host "AVOV_REPORTS_DIR: sin override (fallback storage/reports del cwd)"
}
Write-Host ""

$previousDatabaseUrl = $env:DATABASE_URL
$previousRedisUrl = $env:REDIS_URL
$previousCors = $env:BACKEND_CORS_ORIGINS

try {
    $env:DATABASE_URL = $databaseUrl
    $env:REDIS_URL = "redis://127.0.0.1:6380/1"
    $env:BACKEND_CORS_ORIGINS = "http://127.0.0.1:3001,http://localhost:3001,http://127.0.0.1:3000,http://localhost:3000"
    # AVOV_REPORTS_DIR se deja tal cual si el llamador la definio; Start-Process la hereda.

    Push-Location (Join-Path $RepoRoot "backend")
    try {
        Write-Host "ASSERT_E2E_DATABASE: ejecutando preflight..."
        & $python scripts/assert_e2e_database.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: preflight de base de datos rechazo el arranque." -ForegroundColor Red
            Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $null -ListenerPid $null -Health "n/a" -Mode "preflight"
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }

    # Start-Process hereda el entorno actual (incluye DATABASE_URL → avov_test, REDIS_URL → /1).
    # Sin -Wait: el wrapper no se queda bloqueado por el servidor persistente.
    $proc = Start-Process -FilePath $python `
        -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$Port") `
        -WorkingDirectory (Join-Path $RepoRoot "backend") `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $OutLog `
        -RedirectStandardError $ErrLog

    $proc.Id | Set-Content -Path $PidFile -Encoding ascii
    if ($ReportsDirOverride) {
        $ReportsDirOverride | Set-Content -Path $ReportsDirStatusFile -Encoding utf8
    } elseif (Test-Path $ReportsDirStatusFile) {
        Remove-Item -Force $ReportsDirStatusFile -ErrorAction SilentlyContinue
    }
    Write-Host "PID: $($proc.Id) (archivo: $PidFile)"
    Write-Host "Logs: $OutLog | $ErrLog"
    Write-Host "Health: $HealthUrl"
    Write-Host "Detener: $StopHint"

    $deadline = [DateTime]::UtcNow.AddSeconds($HealthTimeoutSec)
    $lastHealth = @{ Ok = $false; StatusCode = 0 }
    $readyListener = $null
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($proc.HasExited) {
            $exitCode = $proc.ExitCode
            Write-Host "ERROR: el proceso servidor termino antes del health (exit=$exitCode)." -ForegroundColor Red
            Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $proc.Id -ListenerPid $null -Health "process_exited:$exitCode" -Mode "start"
            exit 1
        }
        $readyListener = Get-AvovE2eListenerPid -ListenPort $Port
        if ($null -ne $readyListener) {
            $lastHealth = Test-AvovE2eHealth -Url $HealthUrl -TimeoutSec 3
            if ($lastHealth.Ok) { break }
        }
        Start-Sleep -Milliseconds $HealthPollMs
    }

    if (-not $lastHealth.Ok) {
        Write-Host "ERROR: health check no alcanzo HTTP 200 en ${HealthTimeoutSec}s (ultimo=$($lastHealth.StatusCode))." -ForegroundColor Red
        Write-AvovE2eStatus -WrapperStatus "fail" -ServerPid $proc.Id -ListenerPid $readyListener -Health "$($lastHealth.StatusCode)" -Mode "start"
        exit 1
    }

    Write-Host "HEALTH=$(($lastHealth.StatusCode)) (listo)"
    Write-AvovE2eStatus -WrapperStatus "ok" -ServerPid $proc.Id -ListenerPid $readyListener -Health "$($lastHealth.StatusCode)" -Mode "start"
    exit 0
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
