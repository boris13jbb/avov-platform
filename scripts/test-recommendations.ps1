# AVOV - Validar FASE 14 recomendaciones (PowerShell)
$ErrorActionPreference = "Stop"

$baseUrl = "http://localhost:8000/api/v1"
$email = "estudiante.test.fase11@instituto.edu.co"
$password = "Estud1234!"

Write-Host "=== AVOV - Test recomendaciones FASE 14 ===" -ForegroundColor Cyan

Write-Host "`n1. Esperando backend..." -ForegroundColor Yellow
$ready = $false
for ($i = 1; $i -le 15; $i++) {
    try {
        $health = Invoke-RestMethod -Uri "$baseUrl/health/live" -TimeoutSec 5
        if ($health.success) {
            $ready = $true
            Write-Host "   Backend listo." -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "   Intento $i/15 - backend aun no responde..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 2
    }
}
if (-not $ready) {
    throw "El backend no respondió en $baseUrl/health/live. Ejecuta: docker compose up -d"
}

Write-Host "`n2. Login estudiante..." -ForegroundColor Yellow
$login = Invoke-RestMethod `
    -Uri "$baseUrl/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body (@{ email = $email; password = $password } | ConvertTo-Json) `
    -TimeoutSec 30

if (-not $login.success) {
    throw "Login falló: $($login.message)"
}

$token = $login.data.access_token
if ([string]::IsNullOrWhiteSpace($token)) {
    throw "No se recibió access_token. ¿El login respondió antes de que el backend estuviera listo?"
}

$headers = @{ Authorization = "Bearer $token" }
Write-Host "   Login OK." -ForegroundColor Green

Write-Host "`n3. Generar recomendaciones..." -ForegroundColor Yellow
$gen = Invoke-RestMethod `
    -Uri "$baseUrl/recommendations/generate" `
    -Method POST `
    -Headers $headers `
    -ContentType "application/json" `
    -Body "{}" `
    -TimeoutSec 90

if (-not $gen.success) {
    throw "Generate falló: $($gen.message)"
}

Write-Host "   $($gen.message)" -ForegroundColor Green
Write-Host "   Sesión: $($gen.data.test_session_id) | Estudiante: $($gen.data.student_id)" -ForegroundColor Gray
Write-Host "   Carreras recomendadas: $($gen.data.items.Count)" -ForegroundColor Gray

$gen.data.items | ForEach-Object {
    Write-Host ("   - {0}: match={1}% riasec={2} qdrant={3}" -f `
        $_.career.name, $_.match_percentage, $_.riasec_score, $_.qdrant_score)
}

Write-Host "`n4. Listar por estudiante..." -ForegroundColor Yellow
$list = Invoke-RestMethod `
    -Uri "$baseUrl/recommendations/student/$($gen.data.student_id)" `
    -Headers $headers `
    -TimeoutSec 30

Write-Host "   $($list.message) - $($list.data.items.Count) items" -ForegroundColor Green
Write-Host "`n=== Prueba completada ===" -ForegroundColor Cyan
