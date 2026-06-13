# AVOV - Smoke E2E flujo vocacional completo (Fase 38)
# Completa test RIASEC, genera recomendaciones y descarga PDF.
# Uso: .\scripts\smoke-vocational-e2e.ps1 [-BaseUrl "http://localhost:8000/api/v1"]

param(
    [string]$BaseUrl = "http://localhost:8000/api/v1",
    [string]$StudentEmail = "estudiante.test.fase11@instituto.edu.co",
    [string]$StudentPassword = "Estud1234!",
    [switch]$EnsureStudentSeed,
    [switch]$EnsureCareersSeed,
    [string]$ReportPath = "",
    [string]$ReportTitle = "AVOV - Reporte Flujo Vocacional E2E (Fase 38)",
    [string]$PdfOutputPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Group,
        [string]$Name,
        [string]$Status,
        [string]$Detail = ""
    )
    $null = $results.Add([pscustomobject]@{
            Group  = $Group
            Name   = $Name
            Status = $Status
            Detail = $Detail
        })
    $color = switch ($Status) {
        "OK" { "Green" }
        "SKIP" { "Yellow" }
        default { "Red" }
    }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Invoke-Api {
    param(
        [string]$Method = "GET",
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$TimeoutSec = 30
    )
    $uri = "$BaseUrl$Path"
    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = $Headers
        TimeoutSec  = $TimeoutSec
        ContentType = "application/json"
    }
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
    }
    return Invoke-RestMethod @params
}

function Get-HttpStatusCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)
    if ($null -eq $ErrorRecord.Exception.Response) { return $null }
    return [int]$ErrorRecord.Exception.Response.StatusCode
}

Write-Host "=== AVOV Smoke E2E Vocacional ===" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl"
Write-Host ""

if ($EnsureStudentSeed) {
    & (Join-Path $PSScriptRoot "seed-dev-student.ps1") -BaseUrl $BaseUrl
}

if ($EnsureCareersSeed) {
    & (Join-Path $PSScriptRoot "seed-careers-dev.ps1") -BaseUrl $BaseUrl
}

# --- Health ---
try {
    $live = Invoke-Api -Path "/health/live"
    if ($live.success -eq $true) {
        Add-Check "Infra" "Backend disponible" "OK" "health/live"
    } else {
        Add-Check "Infra" "Backend disponible" "FALLO" "success=false"
    }
} catch {
    Add-Check "Infra" "Backend disponible" "FALLO" $_.Exception.Message
    Write-Host "`nEjecuta: docker compose up -d" -ForegroundColor Red
    exit 1
}

# --- Login estudiante ---
$headers = $null
try {
    $login = Invoke-Api -Method POST -Path "/auth/login" -Body @{
        email    = $StudentEmail
        password = $StudentPassword
    }
    $headers = @{ Authorization = "Bearer $($login.data.access_token)" }
    Add-Check "Auth" "Login estudiante" "OK" $StudentEmail
} catch {
    Add-Check "Auth" "Login estudiante" "FALLO" $_.Exception.Message
    exit 1
}

# --- Iniciar / continuar test ---
$sessionId = $null
$studentId = $null
try {
    $start = Invoke-Api -Method POST -Path "/tests/start" -Headers $headers
    $sessionId = $start.data.id
    $studentId = $start.data.student_id
    Add-Check "Test RIASEC" "Iniciar sesion" "OK" "session_id=$sessionId"
} catch {
    Add-Check "Test RIASEC" "Iniciar sesion" "FALLO" $_.Exception.Message
    exit 1
}

try {
    $resume = Invoke-Api -Method POST -Path "/tests/start" -Headers $headers
    if ($resume.data.id -eq $sessionId) {
        Add-Check "Test RIASEC" "Continuar sesion en progreso" "OK" "misma session_id=$sessionId"
    } else {
        Add-Check "Test RIASEC" "Continuar sesion en progreso" "FALLO" "esperaba $sessionId obtuvo $($resume.data.id)"
    }
} catch {
    Add-Check "Test RIASEC" "Continuar sesion en progreso" "FALLO" $_.Exception.Message
}

# --- Obtener preguntas ---
$questions = @()
try {
    $qs = Invoke-Api -Path "/tests/$sessionId/questions" -Headers $headers
    $questions = @($qs.data.questions)
    if ($questions.Count -ge 60) {
        Add-Check "Test RIASEC" "Preguntas activas (>=60)" "OK" "$($questions.Count) preguntas"
    } else {
        Add-Check "Test RIASEC" "Preguntas activas (>=60)" "FALLO" "solo $($questions.Count)"
    }
} catch {
    Add-Check "Test RIASEC" "Preguntas activas (>=60)" "FALLO" $_.Exception.Message
    exit 1
}

# --- Responder todas (escala 1-5) ---
$answered = 0
try {
    foreach ($question in $questions) {
        Invoke-Api -Method POST -Path "/tests/$sessionId/answers" -Headers $headers -Body @{
            question_id  = $question.id
            answer_value = 3
        } | Out-Null
        $answered++
    }
    Add-Check "Test RIASEC" "Guardar respuestas 1-5" "OK" "$answered respuestas"
} catch {
    Add-Check "Test RIASEC" "Guardar respuestas 1-5" "FALLO" $_.Exception.Message
    exit 1
}

# --- Finalizar test ---
$dominantProfile = $null
try {
    $finish = Invoke-Api -Method POST -Path "/tests/$sessionId/finish" -Headers $headers
    $dominantProfile = $finish.data.dominant_profile
    if ($dominantProfile) {
        Add-Check "Test RIASEC" "Finalizar y calcular RIASEC" "OK" "dominante=$dominantProfile secundario=$($finish.data.secondary_profile)"
    } else {
        Add-Check "Test RIASEC" "Finalizar y calcular RIASEC" "FALLO" "sin perfil dominante"
    }
} catch {
    Add-Check "Test RIASEC" "Finalizar y calcular RIASEC" "FALLO" $_.Exception.Message
    exit 1
}

# --- Resultado RIASEC ---
try {
    $result = Invoke-Api -Path "/tests/$sessionId/result" -Headers $headers
    if ($result.data.dominant_profile -eq $dominantProfile) {
        Add-Check "Test RIASEC" "GET resultado RIASEC" "OK" "perfil=$($result.data.dominant_profile)"
    } else {
        Add-Check "Test RIASEC" "GET resultado RIASEC" "FALLO" "perfil inconsistente"
    }
} catch {
    Add-Check "Test RIASEC" "GET resultado RIASEC" "FALLO" $_.Exception.Message
}

# --- No editar test finalizado ---
try {
    Invoke-Api -Method POST -Path "/tests/$sessionId/answers" -Headers $headers -Body @{
        question_id  = $questions[0].id
        answer_value = 5
    } | Out-Null
    Add-Check "Test RIASEC" "Bloqueo edicion post-finalizar" "FALLO" "deberia rechazar"
} catch {
    if ((Get-HttpStatusCode $_) -eq 422) {
        Add-Check "Test RIASEC" "Bloqueo edicion post-finalizar" "OK" "422 Validation"
    } else {
        Add-Check "Test RIASEC" "Bloqueo edicion post-finalizar" "FALLO" $_.Exception.Message
    }
}

# --- Recomendaciones ---
$recCount = 0
$ethicalOk = $false
try {
    $gen = Invoke-Api -Method POST -Path "/recommendations/generate" -Headers $headers -Body @{} -TimeoutSec 120
    $recCount = @($gen.data.items).Count
    $disclaimer = $gen.data.ethical_disclaimer
    $ethicalOk = $disclaimer -match "orientativ"
    if ($recCount -gt 0 -and $ethicalOk) {
        Add-Check "Recomendaciones" "Generar post-test" "OK" "$recCount carreras + disclaimer etico"
    } elseif ($recCount -gt 0) {
        Add-Check "Recomendaciones" "Generar post-test" "FALLO" "falta disclaimer etico"
    } else {
        Add-Check "Recomendaciones" "Generar post-test" "FALLO" "0 carreras (ejecuta seed-careers-dev.ps1)"
    }
} catch {
    Add-Check "Recomendaciones" "Generar post-test" "FALLO" $_.Exception.Message
}

if ($studentId) {
    try {
        $list = Invoke-Api -Path "/recommendations/student/$studentId" -Headers $headers
        $listCount = @($list.data.items).Count
        if ($listCount -ge $recCount) {
            Add-Check "Recomendaciones" "Listar por estudiante" "OK" "$listCount items"
        } else {
            Add-Check "Recomendaciones" "Listar por estudiante" "FALLO" "esperado >= $recCount"
        }
    } catch {
        Add-Check "Recomendaciones" "Listar por estudiante" "FALLO" $_.Exception.Message
    }
}

# --- PDF ---
if ([string]::IsNullOrWhiteSpace($PdfOutputPath)) {
    $PdfOutputPath = Join-Path $root "docs\fase-38-vocational-sample.pdf"
}

try {
    $pdfUri = "$BaseUrl/reports/$sessionId/pdf"
    Invoke-WebRequest -Uri $pdfUri -Headers $headers -OutFile $PdfOutputPath -TimeoutSec 120 | Out-Null
    $bytes = [System.IO.File]::ReadAllBytes($PdfOutputPath)
    $header = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
    if ($header -eq "%PDF" -and $bytes.Length -gt 1000) {
        Add-Check "Reportes PDF" "Descarga PDF valida" "OK" "$($bytes.Length) bytes -> $PdfOutputPath"
    } else {
        Add-Check "Reportes PDF" "Descarga PDF valida" "FALLO" "archivo invalido"
    }
} catch {
    Add-Check "Reportes PDF" "Descarga PDF valida" "FALLO" $_.Exception.Message
}

if ($studentId) {
    try {
        $history = Invoke-Api -Path "/reports/student/$studentId" -Headers $headers
        $reportCount = @($history.data.items).Count
        if ($reportCount -ge 1) {
            Add-Check "Reportes PDF" "Historial reportes" "OK" "$reportCount reporte(s)"
        } else {
            Add-Check "Reportes PDF" "Historial reportes" "FALLO" "sin reportes"
        }
    } catch {
        Add-Check "Reportes PDF" "Historial reportes" "FALLO" $_.Exception.Message
    }
}

# --- Reporte ---
$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportPath = Join-Path $root "docs\fase-38-vocational-e2e-report.txt"
} else {
    $reportPath = $ReportPath
}

$lines = @(
    $ReportTitle,
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl: $BaseUrl",
    "Estudiante: $StudentEmail",
    "SessionId: $sessionId",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Reporte: $reportPath" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
