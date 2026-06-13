# AVOV - Restauracion de backups MySQL + Qdrant + storage (Fase 45)
param(
    [string]$MySqlFile = "",
    [string]$QdrantFile = "",
    [string]$StorageFile = "",
    [ValidateSet("prod", "staging", "prod-local")]
    [string]$Target = "prod",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if ([string]::IsNullOrWhiteSpace($MySqlFile) -and [string]::IsNullOrWhiteSpace($QdrantFile) -and [string]::IsNullOrWhiteSpace($StorageFile)) {
    Write-Host "Uso: .\scripts\restore-backup.ps1 -MySqlFile backups\mysql\archivo.sql [-QdrantFile ...] [-Force]"
    exit 1
}

$compose = "docker-compose.prod.yml"
$project = if ($env:AVOV_PROD_PROJECT) { $env:AVOV_PROD_PROJECT } else { "avov-prod" }
$envFile = ".env"
$composeArgs = @("-f", $compose)

if ($Target -eq "staging") {
    $project = if ($env:AVOV_STAGING_PROJECT) { $env:AVOV_STAGING_PROJECT } else { "avov-staging" }
    $envFile = ".env.staging"
    $composeArgs += "-f", "docker-compose.staging.yml", "--env-file", $envFile
} elseif ($Target -eq "prod-local") {
    $project = if ($env:AVOV_PROD_LOCAL_PROJECT) { $env:AVOV_PROD_LOCAL_PROJECT } else { "avov-prod-local" }
    $envFile = ".env.prod-local"
    $composeArgs += "-f", "docker-compose.prod-local.yml", "--env-file", $envFile
} else {
    $composeArgs += "-f", "docker-compose.prod.web.yml", "-f", "docker-compose.prod.web.ssl.yml"
    if (Test-Path $envFile) { $composeArgs += "--env-file", $envFile }
}
if ($project) { $composeArgs += "-p", $project }

$rootPassword = $env:MYSQL_ROOT_PASSWORD
$dbName = $env:MYSQL_DATABASE
if (Test-Path $envFile) {
    if (-not $rootPassword) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^MYSQL_ROOT_PASSWORD=' } | Select-Object -First 1
        if ($line) { $rootPassword = ($line -split '=', 2)[1].Trim() }
    }
    if (-not $dbName) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^MYSQL_DATABASE=' } | Select-Object -First 1
        if ($line) { $dbName = ($line -split '=', 2)[1].Trim() }
    }
}
$rootPassword = if ($rootPassword) { $rootPassword } else { "avov_root_secret" }
$dbName = if ($dbName) { $dbName } else { "avov_db" }

Write-Host "=== AVOV Restore Backup ($Target) ===" -ForegroundColor Cyan
Write-Host "ADVERTENCIA: sobrescribe datos actuales." -ForegroundColor Yellow
if (-not $Force) {
    $confirm = Read-Host "Confirmar restauracion (escriba SI)"
    if ($confirm -ne "SI") {
        Write-Host "Cancelado."
        exit 1
    }
}

if (-not [string]::IsNullOrWhiteSpace($MySqlFile)) {
    if (-not (Test-Path $MySqlFile)) { throw "No existe $MySqlFile" }
    Write-Host "Restaurando MySQL..." -ForegroundColor Cyan
    Get-Content $MySqlFile -Raw | docker compose @composeArgs exec -T mysql `
        mysql -uroot -p"$rootPassword" $dbName
    Write-Host "MySQL restaurado." -ForegroundColor Green
}

if (-not [string]::IsNullOrWhiteSpace($QdrantFile)) {
    if (-not (Test-Path $QdrantFile)) { throw "No existe $QdrantFile" }
    Write-Host "Restaurando Qdrant..." -ForegroundColor Cyan
    docker compose @composeArgs exec -T qdrant sh -c "rm -rf /qdrant/storage/*" 2>$null
    $resolved = (Resolve-Path $QdrantFile).Path
    cmd /c "type `"$resolved`" | docker compose $($composeArgs -join ' ') exec -T qdrant tar xzf - -C /qdrant"
    if ($LASTEXITCODE -ne 0) { throw "Fallo restauracion Qdrant" }
    Write-Host "Qdrant restaurado." -ForegroundColor Green
}

if (-not [string]::IsNullOrWhiteSpace($StorageFile)) {
    if (-not (Test-Path $StorageFile)) { throw "No existe $StorageFile" }
    Write-Host "Restaurando storage..." -ForegroundColor Cyan
    docker compose @composeArgs exec -T backend sh -c "rm -rf /app/storage/*" 2>$null
    $resolved = (Resolve-Path $StorageFile).Path
    cmd /c "type `"$resolved`" | docker compose $($composeArgs -join ' ') exec -T backend tar xzf - -C /app"
    if ($LASTEXITCODE -ne 0) { throw "Fallo restauracion storage" }
    Write-Host "Storage restaurado." -ForegroundColor Green
}

Write-Host "Restauracion completada." -ForegroundColor Green
exit 0
