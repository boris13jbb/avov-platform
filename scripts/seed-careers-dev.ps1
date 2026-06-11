# AVOV — Sembrar carreras de desarrollo (mínimo 5 activas para recomendaciones)
$ErrorActionPreference = "Stop"

$baseUrl = "http://localhost:8000/api/v1"

$login = Invoke-RestMethod `
    -Uri "$baseUrl/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"email":"admin@avov.edu.co","password":"Admin123!"}' `
    -TimeoutSec 30

$headers = @{ Authorization = "Bearer $($login.data.access_token)" }

$careers = @(
    @{
        name = "Diseño Gráfico"
        area = "Arte y diseño"
        description = "Formación en comunicación visual, branding y medios digitales."
        riasec_profile = "AES"
        duration = "3 años"
        degree_type = "TECNICO"
        institution_type = "INSTITUTO"
        employment_field = "Diseño, publicidad, medios"
        status = "ACTIVE"
    },
    @{
        name = "Administración de Empresas"
        area = "Negocios"
        description = "Gestión empresarial, finanzas y emprendimiento."
        riasec_profile = "ESC"
        duration = "4 años"
        degree_type = "TECNICO_SUPERIOR"
        institution_type = "UNIVERSIDAD"
        employment_field = "Gestión, finanzas, comercio"
        status = "ACTIVE"
    },
    @{
        name = "Enfermería"
        area = "Salud"
        description = "Atención integral del paciente y cuidados clínicos."
        riasec_profile = "SIC"
        duration = "4 años"
        degree_type = "TECNICO_SUPERIOR"
        institution_type = "INSTITUTO"
        employment_field = "Hospitales, clínicas, salud comunitaria"
        status = "ACTIVE"
    }
)

Write-Host "Creando carreras de desarrollo..." -ForegroundColor Cyan
foreach ($career in $careers) {
    $body = $career | ConvertTo-Json -Depth 5
    $response = Invoke-RestMethod `
        -Uri "$baseUrl/careers" `
        -Method POST `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 30
    Write-Host "  + $($response.data.name) (id=$($response.data.id))" -ForegroundColor Green
}

Write-Host "`nListo. Ejecuta: .\scripts\test-recommendations.ps1" -ForegroundColor Yellow
