# AVOV - Crea estudiante de prueba documentado si no existe (smoke E2E / manual QA)
param(
    [string]$BaseUrl = "http://localhost:8000/api/v1",
    [switch]$SkipTlsVerify
)

$ErrorActionPreference = "Stop"
if ($SkipTlsVerify) {
    . (Join-Path $PSScriptRoot "_tls_helpers.ps1")
    Enable-AvovTlsSkip
}
$baseUrl = $BaseUrl
$studentEmail = "estudiante.test.fase11@instituto.edu.co"
$studentPassword = "Estud1234!"

Write-Host "=== AVOV - Seed estudiante de prueba ===" -ForegroundColor Cyan

function Test-StudentExists {
    try {
        $login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST `
            -ContentType "application/json" `
            -Body (@{ email = $studentEmail; password = $studentPassword } | ConvertTo-Json)
        return $null -ne $login.data.access_token
    } catch {
        return $false
    }
}

if (Test-StudentExists) {
    Write-Host "El estudiante $studentEmail ya existe." -ForegroundColor Green
    exit 0
}

$admin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST `
    -ContentType "application/json" `
    -Body '{"email":"admin@avov.edu.co","password":"Admin123!"}'
$headers = @{ Authorization = "Bearer $($admin.data.access_token)" }

$institutions = Invoke-RestMethod -Uri "$baseUrl/institutions?page_size=1" -Headers $headers
$institutionId = $institutions.data.items[0].id
if (-not $institutionId) {
    $code = "SMOKE-" + (Get-Random -Maximum 99999)
    $created = Invoke-RestMethod -Uri "$baseUrl/institutions" -Method POST -Headers $headers `
        -ContentType "application/json" `
        -Body (@{
            name     = "Instituto Smoke E2E"
            code     = $code
            province = "Pichincha"
            city     = "Quito"
            status   = "ACTIVE"
        } | ConvertTo-Json)
    $institutionId = $created.data.id
    Write-Host "Institucion creada: $institutionId" -ForegroundColor Yellow
}

$unique = -join ((65..90) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$payload = @{
    institution_id = $institutionId
    user           = @{
        email      = $studentEmail
        password   = $studentPassword
        first_name = "Estudiante"
        last_name  = "Smoke E2E"
        phone      = "0991112233"
    }
    identification       = "ID-$unique"
    birth_date             = "2008-05-15"
    gender                 = "MALE"
    grade                  = "10"
    parallel               = "A"
    representative_name    = "Representante Test"
    representative_phone   = "0992223344"
    representative_email   = "rep@instituto.edu.co"
    status                 = "ACTIVE"
}

Invoke-RestMethod -Uri "$baseUrl/students" -Method POST -Headers $headers `
    -ContentType "application/json" -Body ($payload | ConvertTo-Json -Depth 5) | Out-Null

Write-Host "Estudiante creado: $studentEmail / $studentPassword" -ForegroundColor Green
Write-Host "Institucion: $institutionId" -ForegroundColor Gray
