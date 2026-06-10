# AVOV — Instalar Android SDK mínimo para Flutter (sin Android Studio completo)
$ErrorActionPreference = "Stop"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$cmdlineDir = Join-Path $sdkRoot "cmdline-tools\latest"
$zipPath = Join-Path $env:TEMP "commandlinetools-win.zip"
$extractRoot = Join-Path $env:TEMP "android-cmdline-extract"

Write-Host "=== Instalando Android SDK (cmdline-tools) ===" -ForegroundColor Cyan

New-Item -ItemType Directory -Path $sdkRoot -Force | Out-Null

if (-not (Test-Path (Join-Path $cmdlineDir "bin\sdkmanager.bat"))) {
    Write-Host "Descargando command line tools..." -ForegroundColor Yellow
    $url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

    New-Item -ItemType Directory -Path (Split-Path $cmdlineDir) -Force | Out-Null
    if (Test-Path $cmdlineDir) { Remove-Item $cmdlineDir -Recurse -Force }
    Move-Item (Join-Path $extractRoot "cmdline-tools") $cmdlineDir
}

$sdkmanager = Join-Path $cmdlineDir "bin\sdkmanager.bat"
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot

Write-Host "Instalando paquetes SDK necesarios..." -ForegroundColor Yellow
& $sdkmanager --sdk_root=$sdkRoot "platform-tools" "platforms;android-35" "build-tools;35.0.0" | Out-Host

flutter config --android-sdk $sdkRoot
Write-Host "Aceptando licencias Android..." -ForegroundColor Yellow
cmd /c "echo y| flutter doctor --android-licenses" 2>&1 | Out-Host

flutter doctor

Write-Host "`n=== Android SDK listo en $sdkRoot ===" -ForegroundColor Green
