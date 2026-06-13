$root = Split-Path -Parent $PSScriptRoot
$errors = @()

$requiredDirs = @(
    "backend\app\api\routes",
    "backend\app\core",
    "backend\app\db",
    "backend\app\models",
    "backend\app\schemas",
    "backend\app\repositories",
    "backend\app\services\llm",
    "backend\app\security",
    "backend\app\utils",
    "backend\alembic\versions",
    "backend\tests",
    "frontend\lib\core\network",
    "frontend\lib\core\storage",
    "frontend\lib\core\theme",
    "frontend\lib\core\validators",
    "frontend\lib\features\auth\presentation\screens",
    "frontend\lib\shared\widgets",
    "frontend\assets\images",
    "database\init",
    "database\seeds",
    "docker",
    "docs",
    "nginx",
    "qdrant",
    "scripts"
)

$requiredFiles = @(
    ".env.example",
    ".env.production.example",
    ".env.staging.example",
    ".env.prod-local.example",
    "docker-compose.yml",
    "docker-compose.prod.yml",
    "docker-compose.staging.yml",
    "docker-compose.prod-local.yml",
    "docker-compose.prod-ssl-local.yml",
    "scripts\validate-release.ps1",
    "scripts\validate-prod-deploy.ps1",
    "scripts\validate-prod-ssl-deploy.ps1",
    "scripts\post-deploy-prod.ps1",
    "scripts\preflight-prod.ps1",
    "scripts\prod-local-up.ps1",
    "scripts\prod-ssl-local-up.ps1",
    ".env.prod-ssl-local.example",
    ".env.production.server.example",
    ".env.server-release.example",
    "docker-compose.prod.web.yml",
    "docker-compose.prod.web.ssl.yml",
    "scripts\validate-server-release.ps1",
    "scripts\validate-vps-readiness.ps1",
    "scripts\backup-all.sh",
    "scripts\prune-backups.sh",
    "scripts\monitor-health.sh",
    "scripts\install-vps-cron.sh",
    "scripts\setup-vps.sh",
    "docs\fase-43-vps-operaciones.md",
    "docs\cron\avov-backup.cron.example",
    ".env.institutional-local.example",
    "docker-compose.prod.institutional-local.yml",
    "scripts\validate-institutional-deploy.ps1",
    "scripts\deploy-institutional.sh",
    "scripts\smoke-public-release.ps1",
    "scripts\prod-institutional-local-up.ps1",
    "docs\fase-44-despliegue-institucional.md",
    "docs\fase-44-ui-checklist-report.template.md",
    "scripts\update-prod-safe.sh",
    "scripts\rollback-prod.sh",
    "scripts\restore-backup.sh",
    "scripts\validate-production-ops.ps1",
    "docs\plan-rollback-produccion.md",
    "docs\runbook-soporte-produccion.md",
    "docs\capacitacion-ti-institucional.md",
    "docs\fase-45-soporte-rollback-capacitacion.md",
    "scripts\preflight-server.ps1",
    "scripts\build-flutter-web.ps1",
    "scripts\deploy-prod-server.sh",
    "README.md",
    "backend\requirements.txt",
    "backend\Dockerfile",
    "backend\Dockerfile.prod",
    "frontend\pubspec.yaml"
)

foreach ($dir in $requiredDirs) {
    $path = Join-Path $root $dir
    if (-not (Test-Path $path)) {
        $errors += "Falta directorio: $dir"
    }
}

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path $path)) {
        $errors += "Falta archivo: $file"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Estructura INCOMPLETA:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

Write-Host "Estructura del monorepo AVOV: OK" -ForegroundColor Green
Write-Host "Validacion integral: .\scripts\validate-fase32.ps1" -ForegroundColor Cyan
exit 0
