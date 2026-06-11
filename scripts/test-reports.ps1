# AVOV - Validar FASE 15 reportes PDF (PowerShell)
$ErrorActionPreference = "Stop"

$baseUrl = "http://localhost:8000/api/v1"
$email = "estudiante.test.fase11@instituto.edu.co"
$password = "Estud1234!"
$sessionId = 17
$studentId = 81
$outputFile = Join-Path $PSScriptRoot "reporte-avov-fase15.pdf"

Write-Host "=== AVOV - Test reportes PDF FASE 15 ===" -ForegroundColor Cyan

Write-Host "`n1. Esperando backend..." -ForegroundColor Yellow
Invoke-RestMethod -Uri "$baseUrl/health/live" -TimeoutSec 10 | Out-Null
Write-Host "   Backend listo." -ForegroundColor Green

Write-Host "`n2. Login estudiante..." -ForegroundColor Yellow
$login = Invoke-RestMethod `
    -Uri "$baseUrl/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body (@{ email = $email; password = $password } | ConvertTo-Json) `
    -TimeoutSec 30
$headers = @{ Authorization = "Bearer $($login.data.access_token)" }
Write-Host "   Login OK." -ForegroundColor Green

Write-Host "`n3. Generar recomendaciones (si faltan)..." -ForegroundColor Yellow
try {
    $gen = Invoke-RestMethod `
        -Uri "$baseUrl/recommendations/generate" `
        -Method POST `
        -Headers $headers `
        -ContentType "application/json" `
        -Body "{}" `
        -TimeoutSec 90
    Write-Host "   $($gen.message)" -ForegroundColor Green
} catch {
    Write-Host "   Recomendaciones ya existentes o error controlado." -ForegroundColor DarkYellow
}

Write-Host "`n4. Descargar PDF sesion $sessionId..." -ForegroundColor Yellow
$token = $login.data.access_token
$statusCode = & curl.exe -sS `
    -H "Authorization: Bearer $token" `
    -o $outputFile `
    -w "%{http_code}" `
    "$baseUrl/reports/$sessionId/pdf"

if ($statusCode -ne "200") {
    throw "Descarga PDF fallo con HTTP $statusCode"
}

$bytes = [System.IO.File]::ReadAllBytes($outputFile)
if ($bytes.Length -lt 4 -or [System.Text.Encoding]::ASCII.GetString($bytes[0..3]) -ne "%PDF") {
    throw "El archivo descargado no parece un PDF valido"
}

Write-Host "   PDF guardado en: $outputFile" -ForegroundColor Green
Write-Host "   Tamano: $($bytes.Length) bytes" -ForegroundColor Gray

Write-Host "`n5. Historial de reportes..." -ForegroundColor Yellow
$history = Invoke-RestMethod `
    -Uri "$baseUrl/reports/student/$studentId" `
    -Headers $headers `
    -TimeoutSec 30
Write-Host "   $($history.message) - $($history.data.items.Count) reporte(s)" -ForegroundColor Green

Write-Host "`n=== Prueba completada ===" -ForegroundColor Cyan
