# AVOV - Checklist post-despliegue produccion (Fase 41)
# Valida salud, settings, login admin, rebuild Qdrant y cabeceras SSL.
# Uso: .\scripts\post-deploy-prod.ps1 -BaseUrl "https://api.dominio.edu.co/api/v1"

param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [string]$HttpBaseUrl = "",
    [string]$AdminEmail = "admin@avov.edu.co",
    [string]$AdminPassword = "Admin123!",
    [switch]$SkipTlsVerify,
    [switch]$SeedCareers,
    [string]$ReportPath = "",
    [string]$ReportTitle = "AVOV - Post-Deploy Produccion (Fase 41)"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "_tls_helpers.ps1")

if ($SkipTlsVerify) {
    Enable-AvovTlsSkip
}

$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Group, [string]$Name, [string]$Status, [string]$Detail = "")
    $null = $results.Add([pscustomobject]@{ Group = $Group; Name = $Name; Status = $Status; Detail = $Detail })
    $color = switch ($Status) { "OK" { "Green" } "SKIP" { "Yellow" } default { "Red" } }
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
    $uri = "$BaseUrl$Path"
    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = $Headers
        TimeoutSec  = 60
        ContentType = "application/json"
    }
    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
    }
    return Invoke-RestMethod @params
}

Write-Host "=== AVOV Post-Deploy Produccion ===" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

if ($SeedCareers) {
    try {
        & (Join-Path $PSScriptRoot "seed-careers-dev.ps1") -BaseUrl $BaseUrl -SkipTlsVerify:$SkipTlsVerify
        Add-Check "Seed" "Carreras desarrollo" "OK" "seed-careers-dev.ps1"
    } catch {
        Add-Check "Seed" "Carreras desarrollo" "FALLO" $_.Exception.Message
    }
}

try {
    $live = Invoke-Api -Path "/health/live"
    if ($live.success -eq $true) {
        Add-Check "Salud" "Health live" "OK" "success=true"
    } else {
        Add-Check "Salud" "Health live" "FALLO" "success no es true"
    }
} catch {
    Add-Check "Salud" "Health live" "FALLO" $_.Exception.Message
    exit 1
}

try {
    $health = Invoke-Api -Path "/health"
    $services = $health.data.services
    $svcOk = ($services.mysql -eq $true) -and ($services.redis -eq $true) -and ($services.qdrant -eq $true)
    if ($svcOk) {
        Add-Check "Salud" "Health completo (MySQL/Redis/Qdrant)" "OK" "todos up"
    } else {
        Add-Check "Salud" "Health completo (MySQL/Redis/Qdrant)" "FALLO" "services=$($services | ConvertTo-Json -Compress)"
    }
} catch {
    Add-Check "Salud" "Health completo (MySQL/Redis/Qdrant)" "FALLO" $_.Exception.Message
}

try {
    $public = Invoke-Api -Path "/settings/public"
    if ($null -ne $public.data.app_display_name) {
        Add-Check "Config" "Settings publicas" "OK" $public.data.app_display_name
    } else {
        Add-Check "Config" "Settings publicas" "FALLO" "sin app_display_name"
    }
} catch {
    Add-Check "Config" "Settings publicas" "FALLO" $_.Exception.Message
}

$adminHeaders = $null
try {
    $login = Invoke-Api -Method POST -Path "/auth/login" -Body @{
        email    = $AdminEmail
        password = $AdminPassword
    }
    if ($login.data.access_token) {
        $adminHeaders = @{ Authorization = "Bearer $($login.data.access_token)" }
        Add-Check "Auth" "Login super admin" "OK" $AdminEmail
    } else {
        Add-Check "Auth" "Login super admin" "FALLO" "sin access_token"
    }
} catch {
    Add-Check "Auth" "Login super admin" "FALLO" $_.Exception.Message
}

if ($adminHeaders) {
    try {
        $me = Invoke-Api -Path "/auth/me" -Headers $adminHeaders
        if ($me.data.role -eq "SUPER_ADMIN") {
            Add-Check "Auth" "Rol super admin" "OK" "SUPER_ADMIN"
        } else {
            Add-Check "Auth" "Rol super admin" "FALLO" "rol=$($me.data.role)"
        }
    } catch {
        Add-Check "Auth" "Rol super admin" "FALLO" $_.Exception.Message
    }

    try {
        $rebuild = Invoke-Api -Method POST -Path "/vector/rebuild-careers" -Headers $adminHeaders
        $indexed = $rebuild.data.indexed
        Add-Check "Qdrant" "Rebuild indice carreras" "OK" "indexed=$indexed"
    } catch {
        Add-Check "Qdrant" "Rebuild indice carreras" "FALLO" $_.Exception.Message
    }

    try {
        $search = Invoke-Api -Method POST -Path "/vector/search-careers" -Headers $adminHeaders -Body @{
            query = "diseno grafico"
            limit = 3
        }
        $hits = $search.data.items.Count
        Add-Check "Qdrant" "Busqueda semantica" "OK" "resultados=$hits"
    } catch {
        Add-Check "Qdrant" "Busqueda semantica" "FALLO" $_.Exception.Message
    }
}

if ($BaseUrl -match "^https://") {
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/health/live" -UseBasicParsing -TimeoutSec 15
        $hsts = $response.Headers.GetEnumerator() | Where-Object { $_.Key -ieq "Strict-Transport-Security" } | Select-Object -First 1
        if ($hsts) {
            $hstsValue = if ($hsts.Value) { [string]$hsts.Value } else { [string]$hsts }
            Add-Check "SSL" "Cabecera HSTS" "OK" $hstsValue
        } else {
            Add-Check "SSL" "Cabecera HSTS" "FALLO" "falta Strict-Transport-Security"
        }
    } catch {
        Add-Check "SSL" "Cabecera HSTS" "FALLO" $_.Exception.Message
    }
}

if (-not [string]::IsNullOrWhiteSpace($HttpBaseUrl)) {
    try {
        $request = [System.Net.HttpWebRequest]::Create("$HttpBaseUrl/health/live")
        $request.AllowAutoRedirect = $false
        $request.Method = "GET"
        $request.Timeout = 15000
        $response = $request.GetResponse()
        $code = [int]$response.StatusCode
        $location = $response.Headers["Location"]
        $response.Close()
        if ($code -in @(301, 302, 307, 308) -and $location -match "^https://") {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "OK" "status $code -> $location"
        } else {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" "status $code location=$location"
        }
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($resp) {
            $code = [int]$resp.StatusCode
            $location = $resp.Headers["Location"]
            $resp.Close()
            if ($code -in @(301, 302, 307, 308) -and $location -match "^https://") {
                Add-Check "SSL" "Redirect HTTP a HTTPS" "OK" "status $code -> $location"
            } else {
                Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" "status $code location=$location"
            }
        } else {
            Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" $_.Exception.Message
        }
    } catch {
        Add-Check "SSL" "Redirect HTTP a HTTPS" "FALLO" $_.Exception.Message
    }
} elseif ($BaseUrl -match "^https://") {
    Add-Check "SSL" "Redirect HTTP a HTTPS" "SKIP" "HttpBaseUrl no indicado"
}

$docsRoot = $BaseUrl -replace "/api/v1$", ""
try {
    Invoke-WebRequest -Uri "$docsRoot/docs" -UseBasicParsing -TimeoutSec 10 | Out-Null
    Add-Check "Seguridad" "OpenAPI bloqueado" "FALLO" "docs accesible"
} catch {
    $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { $null }
    if ($code -eq 404) {
        Add-Check "Seguridad" "OpenAPI bloqueado" "OK" "404"
    } else {
        Add-Check "Seguridad" "OpenAPI bloqueado" "FALLO" "codigo $code"
    }
}

$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$skip = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$fail = ($results | Where-Object { $_.Status -eq "FALLO" }).Count

Write-Host ""
Write-Host "=== Resumen Post-Deploy ===" -ForegroundColor Cyan
Write-Host "OK: $ok | SKIP: $skip | FALLO: $fail"

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportPath = Join-Path $root "docs\fase-41-post-deploy-report.txt"
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
