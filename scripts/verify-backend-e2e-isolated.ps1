# AVOV — Verificación reproducible de la API E2E (solo lectura).
# No arranca ni detiene procesos. No imprime secretos.
# Códigos: 0 = sano y coherente a nivel de supervisión/health; 1 = fallo; 2 = uso incorrecto.
#
# Uso:
#   .\scripts\verify-backend-e2e-isolated.ps1
#   .\scripts\verify-backend-e2e-isolated.ps1 -Port 8002
#
# Nota: schema_contract es una etiqueta declarativa. Este script NO demuestra que
# MySQL use avov_test; eso lo hace assert_e2e_database.py en el arranque.

param(
    [int]$Port = 8001
)

$ErrorActionPreference = "Stop"

if ($Port -lt 1024 -or $Port -gt 65535) {
    Write-Host "VERIFY_FAIL reason=invalid_port port=$Port"
    exit 2
}

$PidFile = Join-Path $env:TEMP "avov-e2e-api-$Port.pid"
$HealthUrl = "http://127.0.0.1:$Port/api/v1/health"
$SchemaExpected = "avov_test"

function Get-ListenerPid {
    $conn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $Port } |
        Select-Object -First 1
    if ($null -eq $conn) { return $null }
    return [int]$conn.OwningProcess
}

$listenerPid = Get-ListenerPid
if ($null -eq $listenerPid) {
    Write-Host "VERIFY_FAIL reason=no_listener port=$Port"
    exit 1
}

$recorded = $null
if (Test-Path $PidFile) {
    $raw = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($raw -match '^\d+$') { $recorded = [int]$raw }
}

try {
    $resp = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 5
    $code = [int]$resp.StatusCode
} catch {
    Write-Host "VERIFY_FAIL reason=health_error port=$Port listener_pid=$listenerPid"
    exit 1
}

if ($code -ne 200) {
    Write-Host "VERIFY_FAIL reason=health_http port=$Port health=$code listener_pid=$listenerPid"
    exit 1
}

$listenerAlive = $null -ne (Get-Process -Id $listenerPid -ErrorAction SilentlyContinue)
$serverAlive = $false
if ($null -ne $recorded) {
    $serverAlive = $null -ne (Get-Process -Id $recorded -ErrorAction SilentlyContinue)
}

# El listener puede ser hijo del PID registrado (uvicorn). Ambos casos son válidos si health=200.
$relation = "unrelated"
if ($null -ne $recorded) {
    if ($recorded -eq $listenerPid) {
        $relation = "same"
    } elseif ($serverAlive) {
        $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$listenerPid" -ErrorAction SilentlyContinue).ParentProcessId
        if ($parent -eq $recorded) { $relation = "child_of_server" }
    }
}

Write-Host "VERIFY_OK port=$Port schema_contract=$SchemaExpected health=$code server_pid=$(if ($null -eq $recorded) { 'none' } else { $recorded }) server_alive=$serverAlive listener_pid=$listenerPid listener_alive=$listenerAlive relation=$relation"
Write-Host "VERIFY_NOTE schema_contract_is_label=true does_not_prove_mysql_schema=true"
if (-not $listenerAlive) {
    Write-Host "VERIFY_FAIL reason=listener_missing_after_health port=$Port"
    exit 1
}
exit 0
