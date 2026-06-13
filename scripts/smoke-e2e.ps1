# AVOV - Smoke E2E por API (Fase 35)
# Valida flujos críticos contra el backend en ejecución.
# Uso: .\scripts\smoke-e2e.ps1 [-BaseUrl "http://localhost:8000/api/v1"]

param(
    [string]$BaseUrl = "http://localhost:8000/api/v1",
    [switch]$EnsureStudentSeed,
    [switch]$SkipTlsVerify,
    [string]$ReportPath = "",
    [string]$ReportTitle = "AVOV - Reporte Smoke E2E (Fase 35)"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "_tls_helpers.ps1")

if ($SkipTlsVerify) {
    Enable-AvovTlsSkip
}
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Group,
        [string]$Name,
        [string]$Status,
        [string]$Detail
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
        [object]$Body = $null
    )
    if ($SkipTlsVerify) {
        Start-Sleep -Milliseconds 300
    }
    $uri = "$BaseUrl$Path"
    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = $Headers
        TimeoutSec  = 30
        ContentType = "application/json"
    }
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
    }
    return Invoke-RestMethod @params
}

function Get-HttpStatusCode {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)
    if ($null -ne $ErrorRecord.Exception.Response) {
        return [int]$ErrorRecord.Exception.Response.StatusCode
    }
    if ($ErrorRecord.Exception.Message -match 'HTTP (\d{3})') {
        return [int]$Matches[1]
    }
    return $null
}

function Login-User {
    param(
        [string]$Email,
        [string]$Password
    )
    $response = Invoke-Api -Method POST -Path "/auth/login" -Body @{
        email    = $Email
        password = $Password
    }
    return @{
        Token   = $response.data.access_token
        Refresh = $response.data.refresh_token
        Headers = @{ Authorization = "Bearer $($response.data.access_token)" }
    }
}

Write-Host "=== AVOV Smoke E2E ===" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl"
Write-Host ""

if ($EnsureStudentSeed) {
    $seedParams = @{ BaseUrl = $BaseUrl }
    if ($SkipTlsVerify) { $seedParams.SkipTlsVerify = $true }
    & (Join-Path $PSScriptRoot "seed-dev-student.ps1") @seedParams
}

# --- A. Infraestructura ---
try {
    $live = Invoke-Api -Path "/health/live"
    if ($live.success -eq $true) {
        Add-Check "Infra" "Health live" "OK" "success=true"
    } else {
        Add-Check "Infra" "Health live" "FALLO" "success no es true"
    }
} catch {
    Add-Check "Infra" "Health live" "FALLO" $_.Exception.Message
    Write-Host "`nBackend no disponible. Ejecuta: docker compose up -d" -ForegroundColor Red
    exit 1
}

try {
    $health = Invoke-Api -Path "/health"
    $detail = ($health.data.PSObject.Properties | ForEach-Object {
            if ($_.Name -ne "status") { "$($_.Name)=$($_.Value)" }
        }) -join ", "
    Add-Check "Infra" "Health completo" "OK" $detail
} catch {
    Add-Check "Infra" "Health completo" "FALLO" $_.Exception.Message
}

try {
    $apiRoot = Invoke-Api -Path "/"
    if ($apiRoot.success -eq $true) {
        Add-Check "Infra" "API root /api/v1/" "OK" $apiRoot.data.name
    } else {
        Add-Check "Infra" "API root /api/v1/" "FALLO" "sin success"
    }
} catch {
    Add-Check "Infra" "API root /api/v1/" "FALLO" $_.Exception.Message
}

try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/health/live" -UseBasicParsing -TimeoutSec 10
    $ctoHeader = $response.Headers.GetEnumerator() | Where-Object {
        $_.Key -ieq "X-Content-Type-Options"
    } | Select-Object -First 1
    $cto = if ($ctoHeader) { [string]$ctoHeader.Value } else { "" }
    if ($cto -match "nosniff") {
        Add-Check "Infra" "Cabeceras OWASP" "OK" "X-Content-Type-Options=nosniff"
    } else {
        Add-Check "Infra" "Cabeceras OWASP" "FALLO" "falta X-Content-Type-Options"
    }
} catch {
    Add-Check "Infra" "Cabeceras OWASP" "FALLO" $_.Exception.Message
}

# --- B. Auth ---
try {
    $public = Invoke-Api -Path "/settings/public"
    if ($null -ne $public.data.app_display_name) {
        Add-Check "Auth" "Settings publicas" "OK" $public.data.app_display_name
    } else {
        Add-Check "Auth" "Settings publicas" "FALLO" "sin app_display_name"
    }
} catch {
    Add-Check "Auth" "Settings publicas" "FALLO" $_.Exception.Message
}

try {
    Invoke-Api -Method POST -Path "/auth/login" -Body @{
        email    = "noexiste@instituto.edu.co"
        password = "WrongPass1!"
    } | Out-Null
    Add-Check "Auth" "Login invalido" "FALLO" "deberia rechazar credenciales"
} catch {
    if ((Get-HttpStatusCode $_) -eq 401) {
        Add-Check "Auth" "Login invalido" "OK" "401 credenciales incorrectas"
    } else {
        Add-Check "Auth" "Login invalido" "FALLO" $_.Exception.Message
    }
}

$adminSession = $null
try {
    $adminSession = Login-User -Email "admin@avov.edu.co" -Password "Admin123!"
    if ($adminSession.Token) {
        Add-Check "Auth" "Login super admin" "OK" "access_token recibido"
    }
} catch {
    Add-Check "Auth" "Login super admin" "FALLO" $_.Exception.Message
}

if ($adminSession) {
    try {
        $me = Invoke-Api -Path "/auth/me" -Headers $adminSession.Headers
        if ($me.data.role -eq "SUPER_ADMIN") {
            Add-Check "Auth" "GET /auth/me" "OK" "rol SUPER_ADMIN"
        } else {
            Add-Check "Auth" "GET /auth/me" "FALLO" "rol inesperado: $($me.data.role)"
        }
    } catch {
        Add-Check "Auth" "GET /auth/me" "FALLO" $_.Exception.Message
    }

    try {
        $refreshed = Invoke-Api -Method POST -Path "/auth/refresh" -Body @{
            refresh_token = $adminSession.Refresh
        }
        if ($refreshed.data.access_token) {
            Add-Check "Auth" "Refresh token" "OK" "nuevo access_token"
        }
    } catch {
        Add-Check "Auth" "Refresh token" "FALLO" $_.Exception.Message
    }
}

# --- C. Roles y permisos ---
$studentSession = $null
$studentEmail = "estudiante.test.fase11@instituto.edu.co"
$studentPassword = "Estud1234!"

try {
    $studentSession = Login-User -Email $studentEmail -Password $studentPassword
    Add-Check "Roles" "Login estudiante seed" "OK" $studentEmail
} catch {
    Add-Check "Roles" "Login estudiante seed" "SKIP" "Crear estudiante de prueba o ejecutar flujos de test"
}

if ($studentSession) {
    try {
        Invoke-Api -Path "/students" -Headers $studentSession.Headers | Out-Null
        Add-Check "Roles" "Estudiante sin listado global" "FALLO" "deberia ser 403"
    } catch {
        if ((Get-HttpStatusCode $_) -eq 403) {
            Add-Check "Roles" "Estudiante sin listado global" "OK" "403 Forbidden"
        } else {
            Add-Check "Roles" "Estudiante sin listado global" "FALLO" $_.Exception.Message
        }
    }

    try {
        Invoke-Api -Path "/settings" -Headers $studentSession.Headers | Out-Null
        Add-Check "Roles" "Estudiante sin settings admin" "FALLO" "deberia ser 403"
    } catch {
        if ((Get-HttpStatusCode $_) -eq 403) {
            Add-Check "Roles" "Estudiante sin settings admin" "OK" "403 Forbidden"
        } else {
            Add-Check "Roles" "Estudiante sin settings admin" "FALLO" $_.Exception.Message
        }
    }
}

# --- D. Dashboards ---
if ($adminSession) {
    try {
        $dash = Invoke-Api -Path "/dashboard/super-admin" -Headers $adminSession.Headers
        Add-Check "Dashboard" "Super admin" "OK" "instituciones=$($dash.data.summary.institutions_total)"
    } catch {
        Add-Check "Dashboard" "Super admin" "FALLO" $_.Exception.Message
    }
}

if ($studentSession) {
    try {
        $dash = Invoke-Api -Path "/dashboard/student" -Headers $studentSession.Headers
        Add-Check "Dashboard" "Estudiante" "OK" "test=$($dash.data.test.status)"
    } catch {
        Add-Check "Dashboard" "Estudiante" "FALLO" $_.Exception.Message
    }
}

# --- E. Test vocacional ---
if ($adminSession) {
    try {
        $questions = Invoke-Api -Path "/questions?page_size=100" -Headers $adminSession.Headers
        $count = $questions.data.items.Count
        if ($count -ge 60) {
            Add-Check "Test RIASEC" "Preguntas activas (>=60)" "OK" "$count preguntas listadas"
        } else {
            Add-Check "Test RIASEC" "Preguntas activas (>=60)" "FALLO" "solo $count preguntas"
        }
    } catch {
        Add-Check "Test RIASEC" "60 preguntas activas" "FALLO" $_.Exception.Message
    }
}

if ($studentSession) {
    try {
        $start = Invoke-Api -Method POST -Path "/tests/start" -Headers $studentSession.Headers
        $sessionId = $start.data.id
        $qs = Invoke-Api -Path "/tests/$sessionId/questions" -Headers $studentSession.Headers
        $qCount = $qs.data.questions.Count
        if ($qCount -ge 60) {
            Add-Check "Test RIASEC" "Sesion de test (>=60 preguntas)" "OK" "session_id=$sessionId preguntas=$qCount"
        } else {
            Add-Check "Test RIASEC" "Sesion de test (>=60 preguntas)" "FALLO" "preguntas=$qCount"
        }
    } catch {
        Add-Check "Test RIASEC" "Sesion estudiante" "FALLO" $_.Exception.Message
    }
}

# --- F. CRUD instituciones (super admin) ---
if ($adminSession) {
    try {
        $inst = Invoke-Api -Path "/institutions?page_size=1" -Headers $adminSession.Headers
        Add-Check "CRUD" "Listar instituciones" "OK" "total=$($inst.data.total)"
    } catch {
        Add-Check "CRUD" "Listar instituciones" "FALLO" $_.Exception.Message
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
    $reportPath = Join-Path $root "docs\fase-35-e2e-smoke-report.txt"
} else {
    $reportPath = $ReportPath
}
$lines = @(
    $ReportTitle,
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "BaseUrl: $BaseUrl",
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
