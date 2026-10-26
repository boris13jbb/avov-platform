# Valida que la preparación cloud local esté completa (sin llamar a GCP).
# Uso: desde la raíz del worktree AVOV-cloud-gcp
#   powershell -File deploy\gcp\scripts\validate-cloud-config.ps1

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
Set-Location $root

$required = @(
    "backend\Dockerfile",
    "backend\.dockerignore",
    "deploy\gcp\cloudbuild.yaml",
    "deploy\gcp\cloud-run-service.yaml",
    "deploy\gcp\vm-redis-qdrant\docker-compose.yml",
    "deploy\gcp\vm-redis-qdrant\.env.example",
    "firebase.json",
    ".firebaserc.example",
    "docs\despliegue-gcp-firebase.md",
    ".env.example"
)

$missing = @()
foreach ($rel in $required) {
    if (-not (Test-Path (Join-Path $root $rel))) {
        $missing += $rel
    }
}

$envExample = Get-Content (Join-Path $root ".env.example") -Raw
$needles = @(
    "AVOV_REPORTS_BACKEND",
    "AVOV_GCS_BUCKET",
    "AVOV_GCS_PREFIX"
)
$envMissing = @()
foreach ($n in $needles) {
    if ($envExample -notmatch [regex]::Escape($n)) {
        $envMissing += $n
    }
}

$dockerfileLines = Get-Content (Join-Path $root "backend\Dockerfile")
$cmdLines = $dockerfileLines | Where-Object { $_ -match '^\s*CMD\b' }
if (-not $cmdLines) {
    Write-Host "ERROR: Dockerfile sin instruccion CMD"
    exit 1
}
foreach ($line in $cmdLines) {
    if ($line -match "--reload") {
        Write-Host "ERROR: CMD de produccion no debe incluir --reload"
        exit 1
    }
}
$dockerfile = ($dockerfileLines -join "`n")
if ($dockerfile -notmatch '\$\{PORT') {
    Write-Host "ERROR: Dockerfile debe respetar la variable PORT"
    exit 1
}

if ($missing.Count -gt 0 -or $envMissing.Count -gt 0) {
    if ($missing.Count -gt 0) {
        Write-Host "Faltan archivos:"
        $missing | ForEach-Object { Write-Host "  - $_" }
    }
    if ($envMissing.Count -gt 0) {
        Write-Host "Faltan variables en .env.example:"
        $envMissing | ForEach-Object { Write-Host "  - $_" }
    }
    exit 1
}

Write-Host "OK: preparacion cloud local coherente en $root"
Write-Host "Recuerda: no desplegar ni crear recursos de pago sin autorizacion."
exit 0
