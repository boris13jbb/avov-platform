# AVOV - Validar FASE 19 dashboards (PowerShell)
$ErrorActionPreference = "Stop"
$baseUrl = "http://localhost:8000/api/v1"

Write-Host "=== AVOV - Test dashboards FASE 19 ===" -ForegroundColor Cyan

Invoke-RestMethod -Uri "$baseUrl/health/live" -TimeoutSec 10 | Out-Null

$admin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST `
  -ContentType "application/json" -Body '{"email":"admin@avov.edu.co","password":"Admin123!"}'
$adminHeaders = @{ Authorization = "Bearer $($admin.data.access_token)" }

$super = Invoke-RestMethod -Uri "$baseUrl/dashboard/super-admin" -Headers $adminHeaders
Write-Host "Super admin - instituciones: $($super.data.summary.institutions_total)" -ForegroundColor Green
Write-Host "Super admin - estudiantes: $($super.data.summary.students_total)" -ForegroundColor Green

$student = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST `
  -ContentType "application/json" `
  -Body '{"email":"estudiante.test.fase11@instituto.edu.co","password":"Estud1234!"}'
$studentHeaders = @{ Authorization = "Bearer $($student.data.access_token)" }

$dash = Invoke-RestMethod -Uri "$baseUrl/dashboard/student" -Headers $studentHeaders
Write-Host "Estudiante - test status: $($dash.data.test.status)" -ForegroundColor Green
Write-Host "Estudiante - recomendaciones: $($dash.data.recommendations_count)" -ForegroundColor Green
Write-Host "Estudiante - next_actions: $($dash.data.next_actions -join ', ')" -ForegroundColor Gray

Write-Host "`n=== Prueba completada ===" -ForegroundColor Cyan
