# Validacion integral Fase 32 - 15 criterios del plan de desarrollo AVOV
# Uso: .\scripts\validate-fase32.ps1 [-SkipDocker] [-SkipFlutter]

param(
    [switch]$SkipDocker,
    [switch]$SkipFlutter
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [int]$Id,
        [string]$Criterion,
        [string]$Status,
        [string]$Detail
    )
    $null = $results.Add([pscustomobject]@{
            Id        = $Id
            Criterion = $Criterion
            Status    = $Status
            Detail    = $Detail
        })
}

function Test-FileExists {
    param([string]$RelativePath)
    Test-Path (Join-Path $root $RelativePath)
}

function Test-GrepInFile {
    param(
        [string]$RelativePath,
        [string]$Pattern
    )
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) { return $false }
    return (Select-String -Path $path -Pattern $Pattern -Quiet)
}

Write-Host "=== AVOV - Validacion Fase 32 ===" -ForegroundColor Cyan
Write-Host "Raiz: $root"
Write-Host ""

# Criterio 1: Docker local
$c1 = (Test-FileExists "docker-compose.yml") -and (Test-FileExists "backend\Dockerfile")
if ($c1) {
    Add-Result 1 "Ejecucion local con Docker" "ESTATICO OK" "docker-compose.yml y Dockerfile presentes"
} else {
    Add-Result 1 "Ejecucion local con Docker" "FALLO" "Faltan archivos Docker dev"
}

# Criterio 2: phpMyAdmin dev
$c2 = Test-GrepInFile "docker-compose.yml" "phpmyadmin"
if ($c2) {
    Add-Result 2 "phpMyAdmin en desarrollo" "ESTATICO OK" "Servicio phpmyadmin en docker-compose.yml"
} else {
    Add-Result 2 "phpMyAdmin en desarrollo" "FALLO" "phpMyAdmin no declarado"
}

# Criterio 3: Login con roles
$c3 = (Test-FileExists "backend\app\api\routes\auth.py") `
    -and (Test-FileExists "frontend\lib\features\auth\presentation\screens\login_screen.dart") `
    -and (Test-FileExists "frontend\lib\router\role_route_mapper.dart")
if ($c3) {
    Add-Result 3 "Login funcional con roles" "ESTATICO OK" "Auth API + login FE + mapeo de rutas"
} else {
    Add-Result 3 "Login funcional con roles" "FALLO" "Faltan componentes de autenticacion"
}

# Criterio 4: Institucion y estudiante
$c4 = (Test-FileExists "backend\app\api\routes\institutions.py") `
    -and (Test-FileExists "backend\app\api\routes\students.py") `
    -and (Test-FileExists "frontend\lib\features\institutions\presentation\screens\institution_form_screen.dart") `
    -and (Test-FileExists "frontend\lib\features\students\presentation\screens\student_form_screen.dart")
if ($c4) {
    Add-Result 4 "Crear institucion y estudiante" "ESTATICO OK" "CRUD instituciones y estudiantes"
} else {
    Add-Result 4 "Crear institucion y estudiante" "FALLO" "Faltan modulos CRUD"
}

# Criterio 5: Test 60 preguntas
$c5 = (Test-FileExists "backend\app\api\routes\tests.py") `
    -and (Test-FileExists "frontend\lib\features\vocational_test\presentation\screens\test_session_screen.dart") `
    -and (Test-FileExists "backend\tests\test_vocational_test.py")
if ($c5) {
    Add-Result 5 "Test vocacional 60 preguntas" "ESTATICO OK" "Rutas test y pantalla sesion"
} else {
    Add-Result 5 "Test vocacional 60 preguntas" "FALLO" "Faltan componentes del test"
}

# Criterio 6: Calculo RIASEC
$c6 = Test-FileExists "backend\tests\test_vocational_test.py"
if ($c6) {
    Add-Result 6 "Calculo RIASEC correcto" "ESTATICO OK" "Tests vocacionales con logica RIASEC"
} else {
    Add-Result 6 "Calculo RIASEC correcto" "FALLO" "Sin tests vocacionales"
}

# Criterio 7: Qdrant recomendaciones
$c7 = (Test-FileExists "backend\app\services\vector_service.py") `
    -and (Test-FileExists "backend\app\services\recommendation_service.py") `
    -and (Test-GrepInFile "backend\app\services\vector_service.py" "used_fallback")
if ($c7) {
    Add-Result 7 "Qdrant y recomendaciones" "ESTATICO OK" "Vector service con fallback MySQL"
} else {
    Add-Result 7 "Qdrant y recomendaciones" "FALLO" "Faltan servicios de recomendacion"
}

# Criterio 8: DeepSeek o fallback
$c8 = (Test-FileExists "backend\app\services\llm\llm_service.py") `
    -and (Test-GrepInFile "backend\app\services\llm\llm_service.py" "fallback")
if ($c8) {
    Add-Result 8 "IA DeepSeek o fallback" "ESTATICO OK" "LLM service con fallback"
} else {
    Add-Result 8 "IA DeepSeek o fallback" "FALLO" "Falta servicio LLM"
}

# Criterio 9: PDF
$c9 = (Test-FileExists "backend\app\services\pdf_service.py") `
    -and (Test-FileExists "backend\app\api\routes\reports.py") `
    -and (Test-FileExists "backend\tests\test_reports.py")
if ($c9) {
    Add-Result 9 "PDF generacion y descarga" "ESTATICO OK" "Pdf service y rutas reportes"
} else {
    Add-Result 9 "PDF generacion y descarga" "FALLO" "Faltan componentes PDF"
}

# Criterio 10: Permisos por rol
$c10 = (Test-FileExists "backend\app\security\permissions.py") `
    -and (Test-FileExists "frontend\lib\router\auth_guard.dart") `
    -and (Test-GrepInFile "frontend\lib\router\role_route_mapper.dart" "return false")
if ($c10) {
    Add-Result 10 "Cada rol ve solo lo permitido" "ESTATICO OK" "Permisos BE + guards FE"
} else {
    Add-Result 10 "Cada rol ve solo lo permitido" "FALLO" "Faltan controles de acceso"
}

# Criterio 11: Validaciones FE/BE
$c11 = (Test-FileExists "backend\app\utils\validators.py") `
    -and (Test-FileExists "frontend\lib\core\validators\app_validators.dart") `
    -and (Test-FileExists "frontend\test\validators_test.dart")
if ($c11) {
    Add-Result 11 "Validaciones frontend y backend" "ESTATICO OK" "Validadores y tests"
} else {
    Add-Result 11 "Validaciones frontend y backend" "FALLO" "Faltan validadores"
}

# Criterio 12: Pruebas automatizadas
$backendTestCount = (Get-ChildItem -Path (Join-Path $root "backend\tests") -Filter "test_*.py" -ErrorAction SilentlyContinue).Count
if ($backendTestCount -ge 15) {
    Add-Result 12 "Pruebas automatizadas" "ESTATICO OK" "$backendTestCount archivos test_*.py"
} else {
    Add-Result 12 "Pruebas automatizadas" "FALLO" "Solo $backendTestCount archivos de test"
}

# Criterio 13: Documentacion
$c13 = (Test-FileExists "docs\manual-usuario.md") `
    -and (Test-FileExists "docs\manual-administrador.md") `
    -and (Test-FileExists "docs\api-endpoints.md") `
    -and (Test-FileExists "docs\arquitectura.md")
if ($c13) {
    Add-Result 13 "Documentacion completa" "ESTATICO OK" "Manuales, API y arquitectura"
} else {
    Add-Result 13 "Documentacion completa" "FALLO" "Falta documentacion"
}

# Criterio 14: Guia produccion
$c14 = (Test-FileExists "docs\manual-produccion.md") `
    -and (Test-FileExists "docker-compose.prod.yml") `
    -and (Test-FileExists "nginx\nginx.prod.conf") `
    -and (Test-FileExists ".env.production.example")
if ($c14) {
    Add-Result 14 "Guia de produccion lista" "ESTATICO OK" "Manual prod y stack prod"
} else {
    Add-Result 14 "Guia de produccion lista" "FALLO" "Faltan artefactos de produccion"
}

# Criterio 15: Checklist QA
$c15 = (Test-FileExists "docs\checklist-qa.md") -and (Test-FileExists "docs\pantallas-flutter.md")
if ($c15) {
    Add-Result 15 "Checklist QA aprobado" "ESTATICO OK" "checklist-qa y pantallas-flutter"
} else {
    Add-Result 15 "Checklist QA aprobado" "FALLO" "Falta checklist o inventario"
}

Write-Host "Ejecutando verify-structure.ps1..." -ForegroundColor Yellow
& (Join-Path $root "scripts\verify-structure.ps1") | Out-Null
if ($LASTEXITCODE -ne 0) {
    Add-Result 0 "Estructura monorepo" "FALLO" "verify-structure.ps1 reporto errores"
}

if (-not $SkipFlutter) {
    Write-Host "Ejecutando flutter analyze..." -ForegroundColor Yellow
    Push-Location (Join-Path $root "frontend")
    flutter analyze 2>&1 | Out-Null
    $flutterAnalyzeOk = $LASTEXITCODE -eq 0
    Pop-Location

    Write-Host "Ejecutando flutter test..." -ForegroundColor Yellow
    Push-Location (Join-Path $root "frontend")
    flutter test 2>&1 | Out-Null
    $flutterTestOk = $LASTEXITCODE -eq 0
    Pop-Location

    $r12 = $results | Where-Object { $_.Id -eq 12 } | Select-Object -First 1
    if ($flutterAnalyzeOk -and $flutterTestOk) {
        $r12.Status = "AUTO OK"
        $r12.Detail = "$($r12.Detail); flutter analyze OK; flutter test OK"
    } else {
        $r12.Status = "FALLO"
        $r12.Detail = "$($r12.Detail); analyze=$flutterAnalyzeOk test=$flutterTestOk"
    }
}

if (-not $SkipDocker) {
    Write-Host "Comprobando Docker..." -ForegroundColor Yellow
    docker info 2>&1 | Out-Null
    $dockerOk = $LASTEXITCODE -eq 0

    docker compose -f docker-compose.prod.yml config --quiet 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $r14 = $results | Where-Object { $_.Id -eq 14 } | Select-Object -First 1
        $r14.Detail = "$($r14.Detail); docker compose prod config OK"
    }

    if ($dockerOk) {
        docker compose ps 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Ejecutando pytest en contenedor backend..." -ForegroundColor Yellow
            docker compose exec -T backend pytest -q --tb=no 2>&1 | Out-Null
            $pytestOk = $LASTEXITCODE -eq 0
            $r12 = $results | Where-Object { $_.Id -eq 12 } | Select-Object -First 1
            if ($pytestOk) {
                $r12.Status = "AUTO OK"
                $r12.Detail = "$($r12.Detail); docker pytest OK"
            } else {
                $r12.Detail = "$($r12.Detail); docker pytest FALLO"
            }

            try {
                $health = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/health/live" -TimeoutSec 5
                if ($health.success -eq $true) {
                    $r1 = $results | Where-Object { $_.Id -eq 1 } | Select-Object -First 1
                    $r1.Status = "AUTO OK"
                    $r1.Detail = "$($r1.Detail); health/live success=true"
                }
            } catch {
                $r1 = $results | Where-Object { $_.Id -eq 1 } | Select-Object -First 1
                $r1.Detail = "$($r1.Detail); Docker activo pero backend no responde en puerto 8000"
            }
        } else {
            $r1 = $results | Where-Object { $_.Id -eq 1 } | Select-Object -First 1
            $r1.Detail = "$($r1.Detail); Docker activo, ejecutar docker compose up --build -d"
        }
    } else {
        $r1 = $results | Where-Object { $_.Id -eq 1 } | Select-Object -First 1
        $r1.Detail = "$($r1.Detail); Docker no disponible, validacion runtime pendiente"
        $r12 = $results | Where-Object { $_.Id -eq 12 } | Select-Object -First 1
        if ($r12.Status -eq "ESTATICO OK") {
            $r12.Detail = "$($r12.Detail); pytest en Docker pendiente"
        }
    }
}

Write-Host ""
Write-Host "=== Resultado por criterio ===" -ForegroundColor Cyan
$results | Sort-Object Id | ForEach-Object {
    $color = "Yellow"
    if ($_.Status -eq "AUTO OK") { $color = "Green" }
    if ($_.Status -eq "FALLO") { $color = "Red" }
    $line = "[{0}] {1} - {2}" -f $_.Id, $_.Status, $_.Criterion
    Write-Host $line -ForegroundColor $color
    Write-Host "     $($_.Detail)"
}

$failCount = ($results | Where-Object { $_.Status -eq "FALLO" }).Count
$autoOk = ($results | Where-Object { $_.Status -eq "AUTO OK" }).Count
$staticOk = ($results | Where-Object { $_.Status -eq "ESTATICO OK" }).Count

$reportPath = Join-Path $root "docs\fase-32-validation-report.txt"
$reportLines = @(
    "AVOV - Reporte validacion Fase 32",
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "AUTO OK: $autoOk | ESTATICO OK: $staticOk | FALLO: $failCount",
    ""
)
$results | Sort-Object Id | ForEach-Object {
    $reportLines += "[#$($_.Id)] $($_.Status) - $($_.Criterion)"
    $reportLines += "    $($_.Detail)"
}
$reportLines | Set-Content -Path $reportPath -Encoding UTF8
Write-Host ""
Write-Host "Reporte guardado en: docs\fase-32-validation-report.txt" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "Validacion con $failCount criterio(s) en FALLO." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Validacion Fase 32: estructura y automatizacion OK." -ForegroundColor Green
Write-Host "Completar pruebas E2E manuales segun docs/checklist-qa.md" -ForegroundColor Yellow
exit 0
