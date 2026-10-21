# Detiene solo la API E2E aislada en :8001 (no toca :8000 ni Docker).

$ErrorActionPreference = "Stop"
$Port = 8001
$PidFile = Join-Path $env:TEMP "avov-e2e-api-8001.pid"
$stopped = $false

if (Test-Path $PidFile) {
    $raw = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($raw -match '^\d+$') {
        $procId = [int]$raw
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $procId -Force
            Write-Host "Proceso PID $procId detenido."
            $stopped = $true
        }
    }
    Remove-Item -Force $PidFile -ErrorAction SilentlyContinue
}

$listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $Port }
foreach ($listener in $listeners) {
    $owner = $listener.OwningProcess
    if ($owner) {
        Stop-Process -Id $owner -Force -ErrorAction SilentlyContinue
        Write-Host "Proceso en puerto $Port (PID $owner) detenido."
        $stopped = $true
    }
}

if (-not $stopped) {
    Write-Host "No habia API E2E escuchando en :$Port."
}
