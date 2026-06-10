# AVOV — Ejecutar Flutter en teléfono Android físico (misma red WiFi que la PC)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendDir = Join-Path $projectRoot "frontend"

function Get-LanIp {
    $ip = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Sort-Object InterfaceMetric |
        Select-Object -First 1 -ExpandProperty IPAddress

    if (-not $ip) {
        throw "No se detectó una IP LAN. Conecta la PC a WiFi y vuelve a intentar."
    }
    return $ip
}

Write-Host "=== AVOV — Flutter en dispositivo Android ===" -ForegroundColor Cyan

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    throw "Flutter no está en el PATH. Ejecuta primero .\scripts\install-flutter.ps1"
}

Push-Location $frontendDir
try {
    Write-Host "`n1. Verificando dispositivos..." -ForegroundColor Yellow
    flutter devices --device-timeout 30

    $doctor = flutter doctor 2>&1 | Out-String
    if ($doctor -match "Unable to locate Android SDK") {
        Write-Host "`n[AVISO] Android SDK no instalado." -ForegroundColor Red
        Write-Host "Instala Android Studio: https://developer.android.com/studio" -ForegroundColor Yellow
        Write-Host "Luego abre Android Studio > SDK Manager y acepta licencias." -ForegroundColor Yellow
        Write-Host "En terminal: flutter doctor --android-licenses" -ForegroundColor Yellow
        throw "No se puede compilar para Android sin SDK."
    }

    $lanIp = Get-LanIp
    $apiUrl = "http://${lanIp}:8000/api/v1"

    Write-Host "`n2. IP detectada: $lanIp" -ForegroundColor Green
    Write-Host "   API del backend: $apiUrl" -ForegroundColor Green
    Write-Host "   El teléfono debe estar en la MISMA red WiFi que esta PC." -ForegroundColor Yellow

    Write-Host "`n3. Comprobando backend..." -ForegroundColor Yellow
    try {
        $health = Invoke-RestMethod -Uri "http://${lanIp}:8000/api/v1/health/live" -TimeoutSec 5
        Write-Host "   Backend accesible en la red local." -ForegroundColor Green
    } catch {
        Write-Host "   No se alcanza el backend en $apiUrl" -ForegroundColor Red
        Write-Host "   Asegúrate de tener Docker corriendo: docker compose up -d" -ForegroundColor Yellow
        throw $_
    }

    Write-Host "`n4. Preparando dependencias Flutter..." -ForegroundColor Yellow
    flutter pub get

    Write-Host "`n5. Iniciando app en el teléfono (Ctrl+C para detener)..." -ForegroundColor Yellow
    flutter run `
        --dart-define=API_BASE_URL=$apiUrl `
        --device-timeout 60
}
finally {
    Pop-Location
}
