# Detiene solo la API E2E aislada del puerto indicado (no toca :8000 ni Docker).
# Por defecto: 8001. Ejemplo: .\scripts\stop-backend-e2e-isolated.ps1 -Port 8002
#
# No termina procesos solo por puerto o PID almacenado: exige identidad demostrable
# (uvicorn app.main:app, --port coincidente, python del .venv de este worktree).

param(
    [int]$Port = 8001
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if ($Port -lt 1024 -or $Port -gt 65535) {
    Write-Host "ERROR: puerto invalido: $Port (use 1024-65535)." -ForegroundColor Red
    exit 2
}

$PidFile = Join-Path $env:TEMP "avov-e2e-api-$Port.pid"
$ExpectedPython = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot "backend\.venv\Scripts\python.exe"))

function Get-AvovProcessCommandLine {
    param([int]$ProcessId)
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$ProcessId" -ErrorAction SilentlyContinue
    if ($null -eq $p) { return $null }
    return [string]$p.CommandLine
}

function Test-AvovE2eUvicornIdentity {
    param(
        [int]$ProcessId,
        [int]$ExpectedPort,
        [string]$ExpectedPythonPath
    )
    $cmd = Get-AvovProcessCommandLine -ProcessId $ProcessId
    if ([string]::IsNullOrWhiteSpace($cmd)) {
        return @{ Ok = $false; Reason = "no_cmdline"; CommandLine = $null }
    }

    $pyNorm = [System.IO.Path]::GetFullPath($ExpectedPythonPath)
    $pyAlt = $pyNorm -replace '\\', '/'
    $hasPython = ($cmd -like "*$pyNorm*") -or ($cmd -like "*$pyAlt*")
    if (-not $hasPython) {
        return @{ Ok = $false; Reason = "python_path_mismatch"; CommandLine = $cmd }
    }
    if ($cmd -notmatch 'uvicorn') {
        return @{ Ok = $false; Reason = "not_uvicorn"; CommandLine = $cmd }
    }
    if ($cmd -notmatch 'app\.main:app') {
        return @{ Ok = $false; Reason = "not_app_main"; CommandLine = $cmd }
    }
    if ($cmd -notmatch ("--port\s+$ExpectedPort\b")) {
        return @{ Ok = $false; Reason = "port_mismatch"; CommandLine = $cmd }
    }
    if ($cmd -notmatch '--host\s+127\.0\.0\.1') {
        return @{ Ok = $false; Reason = "host_mismatch"; CommandLine = $cmd }
    }
    return @{ Ok = $true; Reason = "ok"; CommandLine = $cmd }
}

function Get-AvovE2eListenerPid {
    param([int]$ListenPort)
    $conn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $ListenPort } |
        Select-Object -First 1
    if ($null -eq $conn) { return $null }
    return [int]$conn.OwningProcess
}

if (-not (Test-Path $ExpectedPython)) {
    Write-Host "STOP_FAIL reason=missing_venv_python port=$Port path=$ExpectedPython"
    exit 1
}

$recorded = $null
if (Test-Path $PidFile) {
    $raw = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($raw -match '^\d+$') { $recorded = [int]$raw }
}

if ($null -eq $recorded) {
    Write-Host "STOP_FAIL reason=no_pid_file port=$Port file=$PidFile"
    Write-Host "No se detiene ningun proceso: sin PID registrado no hay identidad demostrable."
    exit 1
}

$recordedAlive = $null -ne (Get-Process -Id $recorded -ErrorAction SilentlyContinue)
if (-not $recordedAlive) {
    Write-Host "STOP_FAIL reason=recorded_pid_not_alive port=$Port server_pid=$recorded"
    Write-Host "No se detiene ningun otro proceso del puerto (podria ser ajeno)."
    exit 1
}

$identity = Test-AvovE2eUvicornIdentity -ProcessId $recorded -ExpectedPort $Port -ExpectedPythonPath $ExpectedPython
if (-not $identity.Ok) {
    Write-Host "STOP_FAIL reason=identity_rejected detail=$($identity.Reason) port=$Port server_pid=$recorded"
    Write-Host "No se detiene el proceso: la identidad E2E de este worktree no pudo demostrarse."
    exit 1
}

$listenerPid = Get-AvovE2eListenerPid -ListenPort $Port
if ($null -ne $listenerPid) {
    if ($listenerPid -eq $recorded) {
        # mismo proceso
    } else {
        $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$listenerPid" -ErrorAction SilentlyContinue).ParentProcessId
        if ($parent -ne $recorded) {
            Write-Host "STOP_FAIL reason=listener_not_child_of_server port=$Port server_pid=$recorded listener_pid=$listenerPid"
            Write-Host "No se detiene: el listener no pertenece al PID registrado."
            exit 1
        }
        $listenerIdentity = Test-AvovE2eUvicornIdentity -ProcessId $listenerPid -ExpectedPort $Port -ExpectedPythonPath $ExpectedPython
        if (-not $listenerIdentity.Ok) {
            # En Windows el hijo a veces muestra el python del sistema en ExecutablePath,
            # pero CommandLine debe seguir citando el python del venv del worktree.
            Write-Host "STOP_FAIL reason=listener_identity_rejected detail=$($listenerIdentity.Reason) port=$Port listener_pid=$listenerPid"
            Write-Host "No se detiene: el listener no demuestra identidad E2E de este worktree."
            exit 1
        }
    }
}

Write-Host "STOP_OK identity=verified port=$Port server_pid=$recorded listener_pid=$(if ($null -eq $listenerPid) { 'none' } else { $listenerPid })"
Stop-Process -Id $recorded -Force
Write-Host "Proceso PID $recorded detenido."

# Si el listener hijo sobrevive, solo detenerlo tras revalidar identidad.
Start-Sleep -Milliseconds 500
$listenerAfter = Get-AvovE2eListenerPid -ListenPort $Port
if ($null -ne $listenerAfter) {
    $childIdentity = Test-AvovE2eUvicornIdentity -ProcessId $listenerAfter -ExpectedPort $Port -ExpectedPythonPath $ExpectedPython
    if ($childIdentity.Ok) {
        Stop-Process -Id $listenerAfter -Force -ErrorAction SilentlyContinue
        Write-Host "Listener residual PID $listenerAfter detenido tras revalidar identidad."
    } else {
        Write-Host "STOP_WARN reason=residual_listener_unverified port=$Port listener_pid=$listenerAfter"
        Write-Host "No se fuerza la detencion del residual (identidad no demostrada)."
        exit 1
    }
}

Remove-Item -Force $PidFile -ErrorAction SilentlyContinue
Write-Host "STOP_DONE port=$Port"
exit 0
