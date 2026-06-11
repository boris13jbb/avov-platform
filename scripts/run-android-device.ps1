# AVOV - Ejecutar Flutter en telefono Android fisico
param(
    [string]$ApiIp
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendDir = Join-Path $projectRoot "frontend"

function Get-LanIpCandidates {
    $virtualInterfacePatterns = @(
        "*vEthernet*",
        "*WSL*",
        "*Hyper-V*",
        "*Docker*",
        "*VirtualBox*",
        "*VMware*",
        "*Loopback*",
        "*Bluetooth*",
        "*Npcap*",
        "*Teredo*"
    )

    $candidates = @()

    $addresses = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*"
        }

    foreach ($addr in $addresses) {
        $adapter = Get-NetAdapter -InterfaceIndex $addr.InterfaceIndex -ErrorAction SilentlyContinue
        if (-not $adapter -or $adapter.Status -ne "Up") {
            continue
        }

        $interfaceName = $adapter.Name
        $isVirtual = $false
        foreach ($pattern in $virtualInterfacePatterns) {
            if ($interfaceName -like $pattern) {
                $isVirtual = $true
                break
            }
        }

        $ip = $addr.IPAddress
        $isDockerRange = $ip -match "^172\.(1[6-9]|2[0-9]|3[0-1])\."
        if ($isVirtual -or ($isDockerRange -and $interfaceName -like "*vEthernet*")) {
            continue
        }

        $priority = 0
        if ($interfaceName -like "*Wi-Fi*" -or $interfaceName -like "*WiFi*" -or $interfaceName -like "*WLAN*") {
            $priority += 100
        }
        if ($interfaceName -like "*Ethernet*") {
            $priority += 80
        }
        if ($ip -like "192.168.*") {
            $priority += 50
        }
        elseif ($ip -like "10.*") {
            $priority += 30
        }

        $candidates += [PSCustomObject]@{
            IP        = $ip
            Interface = $interfaceName
            Priority  = $priority
        }
    }

    return $candidates | Sort-Object Priority -Descending
}

function Get-LanIp {
    param([string]$ManualIp)

    if ($ManualIp) {
        return $ManualIp
    }

    $candidates = Get-LanIpCandidates
    if ($candidates.Count -eq 0) {
        throw "No se detecto una IP LAN usable. Conecta la PC a WiFi y vuelve a intentar."
    }

    return ($candidates | Select-Object -First 1).IP
}

Write-Host "=== AVOV - Flutter en dispositivo Android ===" -ForegroundColor Cyan

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    throw "Flutter no esta en el PATH."
}

Push-Location $frontendDir

try {
    Write-Host ""
    Write-Host "1. Verificando dispositivos..." -ForegroundColor Yellow
    flutter devices --device-timeout 30

    $doctor = flutter doctor 2>&1 | Out-String
    if ($doctor -match "Unable to locate Android SDK") {
        Write-Host ""
        Write-Host "[AVISO] Android SDK no instalado." -ForegroundColor Red
        Write-Host "Instala Android Studio y Android SDK Command-line Tools." -ForegroundColor Yellow
        Write-Host "Luego ejecuta: flutter doctor --android-licenses" -ForegroundColor Yellow
        throw "No se puede compilar para Android sin SDK."
    }

    Write-Host ""
    Write-Host "2. Detectando IP de red local..." -ForegroundColor Yellow

    $candidates = Get-LanIpCandidates
    if ($candidates.Count -gt 0) {
        Write-Host "   Interfaces detectadas:" -ForegroundColor Gray
        foreach ($candidate in $candidates) {
            Write-Host "   - $($candidate.IP) ($($candidate.Interface))" -ForegroundColor Gray
        }
    }

    $lanIp = Get-LanIp -ManualIp $ApiIp
    $apiUrl = "http://${lanIp}:8000/api/v1"

    Write-Host ""
    Write-Host "   IP seleccionada: $lanIp" -ForegroundColor Green
    if ($ApiIp) {
        Write-Host "   (forzada con -ApiIp)" -ForegroundColor Gray
    }
    Write-Host "   API del backend: $apiUrl" -ForegroundColor Green
    Write-Host "   El telefono debe estar en la misma red WiFi que esta PC." -ForegroundColor Yellow
    Write-Host "   Prueba en el navegador del telefono: $apiUrl/health/live" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "3. Comprobando backend..." -ForegroundColor Yellow

    $healthUrl = "http://${lanIp}:8000/api/v1/health/live"
    $backendOk = $false

    try {
        $null = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 10
        $backendOk = $true
    }
    catch {
        Write-Host "   No se alcanza el backend en $healthUrl" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    if (-not $backendOk) {
        try {
            $null = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health/live" -TimeoutSec 10
            Write-Host ""
            Write-Host "   El backend responde en localhost pero no en la IP LAN." -ForegroundColor Yellow
            Write-Host "   Revisa el firewall de Windows (permitir puerto 8000 en red privada)." -ForegroundColor Yellow
        }
        catch {
            Write-Host ""
            Write-Host "   El backend tampoco responde en localhost." -ForegroundColor Yellow
            Write-Host "   Docker puede estar 'Running' pero la API fallo al iniciar." -ForegroundColor Yellow
            Write-Host "   Revisa logs: docker compose logs backend --tail 50" -ForegroundColor Yellow
            Write-Host "   Reinicia: docker compose restart backend" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "   Si necesitas otra IP: .\scripts\run-android-device.ps1 -ApiIp 192.168.x.x" -ForegroundColor Yellow
        throw "Backend no accesible en $healthUrl"
    }

    Write-Host "   Backend accesible en la red local." -ForegroundColor Green

    Write-Host ""
    Write-Host "4. Limpiando build anterior (evita APK cacheado)..." -ForegroundColor Yellow
    flutter clean | Out-Null
    flutter pub get

    Write-Host ""
    Write-Host "5. Desinstalando app previa del telefono..." -ForegroundColor Yellow
    adb uninstall com.example.avov_frontend 2>$null | Out-Null

    Write-Host ""
    Write-Host "6. Iniciando app en el telefono. Presiona Ctrl+C para detener." -ForegroundColor Yellow
    Write-Host "   Tras conectar, cierra sesion y vuelve a iniciar sesion para ir al dashboard." -ForegroundColor Yellow

    # --no-enable-impeller: evita pantalla negra en Xiaomi/MIUI con Vulkan
    flutter run --no-enable-impeller --dart-define=API_BASE_URL=$apiUrl --device-timeout 60
}
finally {
    Pop-Location
}
