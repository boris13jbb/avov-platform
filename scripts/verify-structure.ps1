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
    "docker-compose.yml",
    "docker-compose.prod.yml",
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
