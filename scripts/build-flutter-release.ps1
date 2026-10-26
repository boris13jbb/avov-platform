# Compila Flutter Web y/o APK con API_BASE_URL explícita.
# No publica ni despliega. No incluye secretos de backend.
#
# Uso:
#   .\scripts\build-flutter-release.ps1 -ApiBaseUrl "https://HOST/api/v1" -Target web
#   .\scripts\build-flutter-release.ps1 -ApiBaseUrl "https://HOST/api/v1" -Target apk
#   .\scripts\build-flutter-release.ps1 -ApiBaseUrl "https://HOST/api/v1" -Target both

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,

    [ValidateSet("web", "apk", "both")]
    [string]$Target = "both"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$frontend = Join-Path $root "frontend"

if ($ApiBaseUrl -notmatch '^https://.+/api/v1/?$') {
    Write-Host "ADVERTENCIA: se esperaba una URL HTTPS que termine en /api/v1"
}

if ($ApiBaseUrl -match '127\.0\.0\.1|localhost|10\.0\.2\.2|192\.168\.') {
    Write-Host "ERROR: no uses una URL local para un build de 'release' destinado a Internet."
    exit 1
}

Set-Location $frontend
flutter pub get

$define = "--dart-define=API_BASE_URL=$ApiBaseUrl"

if ($Target -eq "web" -or $Target -eq "both") {
    Write-Host ">>> flutter build web --release $define"
    flutter build web --release $define
}

if ($Target -eq "apk" -or $Target -eq "both") {
    Write-Host ">>> flutter build apk --release $define"
    flutter build apk --release $define
}

Write-Host "Build local terminado. Hosting/Play Store requieren autorizacion aparte."
