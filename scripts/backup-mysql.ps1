# Backup MySQL — desarrollo o producción
param(
    [string]$ComposeFile = "docker-compose.yml",
    [string]$Project = "",
    [switch]$Staging,
    [switch]$ProdLocal
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$backupDir = Join-Path $PWD "backups\mysql"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$filename = "avov_mysql_$timestamp.sql"
$outPath = Join-Path $backupDir $filename

$composeArgs = @("-f", $ComposeFile)
if ($Staging) {
    $composeArgs += "-f", "docker-compose.staging.yml"
    $composeArgs += "--env-file", ".env.staging"
}
if ($ProdLocal) {
    $composeArgs += "-f", "docker-compose.prod-local.yml"
    $composeArgs += "--env-file", ".env.prod-local"
}
if ($Project) { $composeArgs += "-p", $Project }

$envPath = if ($Staging) { ".env.staging" } elseif ($ProdLocal) { ".env.prod-local" } else { ".env" }
$rootPassword = $env:MYSQL_ROOT_PASSWORD
if (-not $rootPassword -and (Test-Path $envPath)) {
    $line = Get-Content $envPath | Where-Object { $_ -match '^MYSQL_ROOT_PASSWORD=' } | Select-Object -First 1
    if ($line) { $rootPassword = ($line -split '=', 2)[1].Trim() }
}
if (-not $rootPassword) { $rootPassword = "avov_root_secret" }

$dbName = $env:MYSQL_DATABASE
if (-not $dbName -and (Test-Path $envPath)) {
    $dbLine = Get-Content $envPath | Where-Object { $_ -match '^MYSQL_DATABASE=' } | Select-Object -First 1
    if ($dbLine) { $dbName = ($dbLine -split '=', 2)[1].Trim() }
}
if (-not $dbName) { $dbName = "avov_db" }

docker compose @composeArgs exec -T mysql `
    mysqldump -uroot -p"$rootPassword" --single-transaction --routines --triggers $dbName `
    > $outPath

if ($LASTEXITCODE -ne 0) {
    Remove-Item -Force $outPath -ErrorAction SilentlyContinue
    Write-Host "ERROR: falló el backup MySQL" -ForegroundColor Red
    exit 1
}

Write-Host "Backup MySQL: $outPath" -ForegroundColor Green
