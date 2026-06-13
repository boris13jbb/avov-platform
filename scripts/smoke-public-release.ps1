# AVOV - Smoke release publico (API + Flutter Web) — Fase 44
# Uso: .\scripts\smoke-public-release.ps1 -ApiUrl "https://api.dominio.edu.co/api/v1" -FrontendUrl "https://app.dominio.edu.co"

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,
    [string]$FrontendUrl = "",
    [string]$HttpApiUrl = "",
    [string]$CorsOrigin = "",
    [switch]$SkipTlsVerify,
    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "_tls_helpers.ps1")

if ($SkipTlsVerify) {
    Enable-AvovTlsSkip
}

$ApiUrl = $ApiUrl.TrimEnd('/')
if ($ApiUrl -notmatch '/api/v1$') {
    if ($ApiUrl -match '/api/v1/') {
        $ApiUrl = ($ApiUrl -replace '/api/v1/.*$', '/api/v1')
    }
}
if ([string]::IsNullOrWhiteSpace($FrontendUrl)) {
    $FrontendUrl = ($ApiUrl -replace '/api/v1$', '')
}
if ([string]::IsNullOrWhiteSpace($CorsOrigin)) {
    $CorsOrigin = $FrontendUrl.TrimEnd('/')
}

$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
    Write-Host "[$Status] $Group - $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
}

function Invoke-ApiJson {
    param(
        [string]$Method = "GET",
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    $uri = "$ApiUrl$Path"
    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $request = [System.Net.HttpWebRequest]::Create($uri)
            $request.Method = $Method
            $request.ProtocolVersion = [Version]"1.1"
            $request.Timeout = 45000
            $request.ContentType = "application/json"
            foreach ($key in $Headers.Keys) {
                $request.Headers[$key] = [string]$Headers[$key]
            }
            if ($null -ne $Body) {
                $payload = ($Body | ConvertTo-Json -Depth 8 -Compress)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
                $request.ContentLength = $bytes.Length
                $stream = $request.GetRequestStream()
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Close()
            }
            $response = $request.GetResponse()
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $json = $reader.ReadToEnd()
            $reader.Close()
            $response.Close()
            return ($json | ConvertFrom-Json)
        } catch {
            $lastError = $_
            Start-Sleep -Seconds 2
        }
    }
    throw $lastError
}

Write-Host "=== AVOV Smoke Public Release (Fase 44) ===" -ForegroundColor Cyan
Write-Host "ApiUrl: $ApiUrl"
Write-Host "FrontendUrl: $FrontendUrl"
Write-Host ""

try {
    $live = Invoke-ApiJson -Path "/health/live"
    if ($live.success -eq $true) {
        Add-Check "API" "Health live" "OK" "success=true"
    } else {
        Add-Check "API" "Health live" "FALLO" "success no es true"
    }
} catch {
    Add-Check "API" "Health live" "FALLO" $_.Exception.Message
}

try {
    $health = Invoke-ApiJson -Path "/health"
    $svc = $health.data.services
    if (($svc.mysql -eq $true) -and ($svc.redis -eq $true) -and ($svc.qdrant -eq $true)) {
        Add-Check "API" "Servicios backend" "OK" "mysql/redis/qdrant"
    } else {
        Add-Check "API" "Servicios backend" "FALLO" ($svc | ConvertTo-Json -Compress)
    }
} catch {
    Add-Check "API" "Servicios backend" "FALLO" $_.Exception.Message
}

try {
    $public = Invoke-ApiJson -Path "/settings/public"
    if ($null -ne $public.data.app_display_name) {
        Add-Check "API" "Settings publicas" "OK" $public.data.app_display_name
    } else {
        Add-Check "API" "Settings publicas" "FALLO" "sin app_display_name"
    }
} catch {
    Add-Check "API" "Settings publicas" "FALLO" $_.Exception.Message
}

try {
    $login = Invoke-ApiJson -Method POST -Path "/auth/login" -Body @{
        email    = "admin@avov.edu.co"
        password = "Admin123!"
    }
    if ($login.data.access_token) {
        Add-Check "API" "Login super admin" "OK" "token recibido"
    } else {
        Add-Check "API" "Login super admin" "FALLO" "sin token"
    }
} catch {
    Add-Check "API" "Login super admin" "FALLO" $_.Exception.Message
}

try {
    $request = [System.Net.HttpWebRequest]::Create("$ApiUrl/settings/public")
    $request.Method = "GET"
    $request.Headers.Add("Origin", $CorsOrigin)
    $request.Timeout = 15000
    $response = $request.GetResponse()
    $acao = $response.Headers["Access-Control-Allow-Origin"]
    $response.Close()
    if ($acao -and ($acao -eq "*" -or $acao -match [regex]::Escape($CorsOrigin))) {
        Add-Check "API" "CORS origin frontend" "OK" $acao
    } else {
        Add-Check "API" "CORS origin frontend" "FALLO" "Allow-Origin=$acao"
    }
} catch {
    Add-Check "API" "CORS origin frontend" "SKIP" "no evaluado: $($_.Exception.Message)"
}

try {
    $fe = Invoke-WebRequest -Uri $FrontendUrl -UseBasicParsing -TimeoutSec 30
    if ($fe.StatusCode -eq 200 -and ($fe.Content -match 'flutter|main\.dart\.js|<!DOCTYPE html>')) {
        Add-Check "Web" "Frontend raiz" "OK" "HTTP $($fe.StatusCode)"
    } else {
        Add-Check "Web" "Frontend raiz" "FALLO" "HTTP $($fe.StatusCode)"
    }
} catch {
    Add-Check "Web" "Frontend raiz" "FALLO" $_.Exception.Message
}

try {
    $spa = Invoke-WebRequest -Uri "$($FrontendUrl.TrimEnd('/'))/login" -UseBasicParsing -TimeoutSec 30
    if ($spa.StatusCode -eq 200 -and ($spa.Content -match 'flutter|main\.dart\.js|<!DOCTYPE html>')) {
        Add-Check "Web" "SPA fallback /login" "OK" "index servido"
    } else {
        Add-Check "Web" "SPA fallback /login" "FALLO" "HTTP $($spa.StatusCode)"
    }
} catch {
    Add-Check "Web" "SPA fallback /login" "FALLO" $_.Exception.Message
}

if ($ApiUrl -match '^https://') {
    try {
        $tls = Invoke-WebRequest -Uri "$ApiUrl/health/live" -UseBasicParsing -TimeoutSec 20
        $hsts = $tls.Headers["Strict-Transport-Security"]
        if ($hsts) {
            Add-Check "SSL" "HSTS API" "OK" $hsts
        } else {
            Add-Check "SSL" "HSTS API" "FALLO" "sin HSTS"
        }
    } catch {
        Add-Check "SSL" "HSTS API" "FALLO" $_.Exception.Message
    }
} else {
    Add-Check "SSL" "HSTS API" "SKIP" "ApiUrl no HTTPS"
}

if (-not [string]::IsNullOrWhiteSpace($HttpApiUrl)) {
    try {
        $request = [System.Net.HttpWebRequest]::Create("$($HttpApiUrl.TrimEnd('/'))/health/live")
        $request.AllowAutoRedirect = $false
        $request.Method = "GET"
        $request.Timeout = 15000
        $response = $request.GetResponse()
        $code = [int]$response.StatusCode
        $location = $response.Headers["Location"]
        $response.Close()
        if ($code -in @(301, 302, 307, 308) -and $location -match '^https://') {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "OK" "$code -> $location"
        } else {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" "status $code"
        }
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($resp) {
            $code = [int]$resp.StatusCode
            $location = $resp.Headers["Location"]
            $resp.Close()
            if ($code -in @(301, 302, 307, 308) -and $location -match '^https://') {
                Add-Check "SSL" "Redirect HTTP a HTTPS" "OK" "$code -> $location"
            } else {
                Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" "status $code"
            }
        } else {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" $_.Exception.Message
        }
    }
} elseif ($ApiUrl -match '^https://') {
    Add-Check "SSL" "Redirect HTTP a HTTPS" "SKIP" "HttpApiUrl no indicado"
}

$ok = @($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = @($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Smoke Public Release ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $root "docs\fase-44-smoke-public-release.txt"
}
$lines = @(
    "AVOV - Smoke Public Release (Fase 44)",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "ApiUrl: $ApiUrl",
    "FrontendUrl: $FrontendUrl",
    "OK: $ok | SKIP: $skip | FALLO: $fail",
    ""
)
$results | ForEach-Object {
    $lines += "[$($_.Status)] $($_.Group) - $($_.Name)"
    if ($_.Detail) { $lines += "    $($_.Detail)" }
}
$lines | Set-Content -Path $ReportPath -Encoding UTF8
Write-Host "Reporte: $ReportPath" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0
