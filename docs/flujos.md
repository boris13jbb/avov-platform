# Flujos del sistema — AVOV

**Fase:** 0 — Análisis de flujos críticos

---

## 1. Flujo de usuario por rol

```mermaid
flowchart TD
    Start[Usuario abre app] --> Splash
    Splash --> CheckToken{Token valido?}
    CheckToken -->|No| Login
    CheckToken -->|Si| RoleRoute

    Login --> AuthAPI[POST /auth/login]
    AuthAPI --> SaveToken[Guardar JWT en Secure Storage]
    SaveToken --> RoleRoute{Rol del usuario}

    RoleRoute -->|SUPER_ADMIN| DashSA[Dashboard global]
    RoleRoute -->|INSTITUTION_ADMIN| DashIA[Dashboard institucional]
    RoleRoute -->|COUNSELOR| DashCO[Dashboard orientador]
    RoleRoute -->|STUDENT| DashST[Dashboard estudiante]

    DashSA --> CRUDInst[CRUD instituciones]
    DashSA --> CRUDUsers[CRUD usuarios global]
    DashSA --> Stats[Estadisticas globales]
    DashSA --> Audit[Auditoria]

    DashIA --> CRUDStudents[CRUD estudiantes]
    DashIA --> CRUDCounselors[Gestion orientadores]
    DashIA --> ReportsIA[Reportes institucion]

    DashCO --> ViewStudents[Ver estudiantes asignados]
    DashCO --> ReviewResults[Revisar resultados]
    DashCO --> AddObs[Agregar observaciones]
    DashCO --> DownloadPDF[Descargar PDF]

    DashST --> Profile[Completar perfil]
    DashST --> TestFlow[Flujo test vocacional]
    DashST --> Results[Ver resultados]
    DashST --> Assistant[Asistente virtual]
    DashST --> PDFStudent[Descargar PDF propio]
```

### Reglas de navegación

- Rutas públicas: `/`, `/login`
- Rutas protegidas: `auth_guard` verifica JWT válido
- Rutas por rol: `role_guard` verifica permisos
- Estudiante **no** accede a `/admin/*` ni `/institution/*`
- Orientador solo ve estudiantes en `counselor_assignments`
- INSTITUTION_ADMIN solo ve datos de su `institution_id`

---

## 2. Flujo del test vocacional RIASEC

```mermaid
sequenceDiagram
    participant ST as Estudiante
    participant FE as Flutter
    participant API as FastAPI
    participant DB as MySQL

    ST->>FE: Iniciar test
    FE->>API: POST /tests/start
    API->>DB: Buscar sesion IN_PROGRESS
    alt Sesion existente
        API-->>FE: session_id existente
    else Nueva sesion
        API->>DB: Crear test_session STARTED
        API-->>FE: session_id nuevo
    end

    FE->>API: GET /tests/{id}/questions
    API->>DB: 60 preguntas activas ordenadas
    API-->>FE: Lista preguntas + progreso

    loop Por cada pregunta
        ST->>FE: Responde escala 1-5
        FE->>API: POST /tests/{id}/answers
        API->>DB: Upsert test_answer
        API-->>FE: Progreso actualizado
    end

    ST->>FE: Confirmar finalizacion
    FE->>API: POST /tests/{id}/finish
    API->>DB: Validar 60 respuestas
    alt Incompleto
        API-->>FE: Error respuestas faltantes
    else Completo
        API->>API: Calcular puntajes RIASEC
        API->>DB: Guardar riasec_results
        API->>DB: Marcar session COMPLETED
        API-->>FE: Resultado RIASEC
    end

    FE->>API: POST /recommendations/generate
    Note over API: Motor recomendaciones Fase 14
```

### Algoritmo de cálculo RIASEC

1. Sumar `answer_value` (1-5) por categoría — 10 preguntas × 6 categorías.
2. Puntaje máximo por categoría: **50**. Mínimo: **10**.
3. `dominant_profile`: categoría con mayor puntaje.
4. Desempate: orden de prioridad **R > I > A > S > E > C**.
5. `secondary_profile`: segunda categoría más alta.
6. Perfil combinado: dominante + secundaria + tercera (ej. ISA, SEC, RIA).
7. Guardar en `riasec_results`; IA enriquece `interpretation` después.

### Escala de respuesta

| Valor | Significado |
|-------|-------------|
| 1 | No me gusta nada |
| 2 | Me gusta poco |
| 3 | Me es indiferente |
| 4 | Me gusta |
| 5 | Me gusta mucho |

### Reglas de negocio

- Un estudiante con test `IN_PROGRESS` continúa el mismo test.
- No puede finalizar sin las 60 respuestas.
- No puede modificar test `COMPLETED` sin permiso especial.
- No puede responder preguntas de otra sesión.
- `answer_value` siempre entre 1 y 5.

---

## 3. Flujo de recomendación (RIASEC + Qdrant + IA)

```mermaid
sequenceDiagram
    participant API as RecommendationService
    participant MySQL as MySQL
    participant Qdrant as Qdrant
    participant LLM as DeepSeek
    participant Redis as Redis

    API->>MySQL: Obtener riasec_results + student
    API->>Redis: Buscar cache
    alt Cache hit
        Redis-->>API: Recomendaciones cacheadas
    else Cache miss
        API->>Qdrant: POST /vector/search-careers
        Qdrant-->>API: Top N carreras + scores
        API->>MySQL: Enriquecer con careers activas
        API->>API: Calcular match_percentage hibrido
        Note over API: 60% RIASEC + 40% Qdrant
        API->>LLM: Explicar top 5 carreras
        alt LLM falla
            API->>API: Fallback explicacion estatica
        end
        API->>MySQL: Guardar recommendations
        API->>Redis: Cachear TTL 24h
    end
    API-->>API: Retornar min 5 carreras ordenadas
```

### Fórmula de compatibilidad híbrida

```
match_percentage = (riasec_score * 0.60) + (qdrant_score * 0.40)
```

- `riasec_score`: coincidencia de letras del perfil dominante/secundario con `career.riasec_profile`.
- `qdrant_score`: score de similitud vectorial normalizado a 0-100.

### Fallback sin Qdrant

Filtrar carreras MySQL activas cuyo `riasec_profile` contenga letras del perfil dominante del estudiante. Ordenar por coincidencia de letras.

### Reglas

- Mínimo **5 carreras** recomendadas.
- Solo carreras con `status = ACTIVE`.
- Sin duplicados por sesión (`UNIQUE test_session_id + career_id`).
- `match_percentage` entre 0 y 100.
- Orientador puede agregar observaciones en `counselor_observations`.

---

## 4. Flujo de generación PDF

```mermaid
sequenceDiagram
    participant User as Usuario autorizado
    participant API as PDFService
    participant DB as MySQL
    participant FS as FileStorage
    participant Audit as AuditService

    User->>API: GET /reports/{session_id}/pdf
    API->>API: Validar permisos por rol
    API->>DB: Verificar test COMPLETED
    API->>DB: Cargar datos completos
    API->>API: Generar report_code unico
    API->>API: Render PDF ReportLab
    API->>FS: Guardar storage/reports/{code}.pdf
    API->>DB: Insertar registro reports
    API->>Audit: Log PDF_GENERATED
    API-->>User: Stream application/pdf
```

### Contenido obligatorio del PDF

1. Logo y datos de la institución
2. Datos del estudiante (sin datos sensibles)
3. Fecha del test y código único del reporte
4. Perfil RIASEC dominante y secundario
5. Puntajes por categoría (gráfico o tabla)
6. Top 5+ carreras recomendadas con compatibilidad
7. Explicación IA (o fallback estático)
8. Observación del orientador (si existe)
9. Nota ética obligatoria
10. Datos del responsable / generador

### Seguridad PDF

- Solo usuarios autorizados por rol y ownership
- Test debe estar `COMPLETED`
- Almacenamiento fuera de webroot (`storage/reports/`)
- Sin path traversal en `file_path`
- Registro en `reports` y `audit_logs`
- Auditoría de descarga

---

## 5. Flujo del asistente virtual (chat)

```mermaid
sequenceDiagram
    participant ST as Estudiante
    participant FE as Flutter
    participant API as AssistantService
    participant LLM as DeepSeek

    ST->>FE: Escribe pregunta
    FE->>FE: Validar no vacio max chars
    FE->>API: POST /assistant/chat
    API->>API: Sanitizar entrada
    API->>API: Cargar contexto estudiante RIASEC
    API->>LLM: Prompt con contexto seguro
    alt LLM responde
        LLM-->>API: Respuesta orientativa
    else LLM falla
        API-->>API: Respuesta fallback
    end
    API-->>FE: Respuesta + advertencia etica
    FE-->>ST: Mostrar en chat
```

### Restricciones del asistente

- No enviar datos sensibles innecesarios a DeepSeek
- Incluir advertencia ética en cada respuesta
- Límite de caracteres por mensaje
- Rate limiting por estudiante (Redis)
- Flutter **nunca** llama DeepSeek directamente

---

## 6. Flujo de despliegue

```mermaid
flowchart LR
    subgraph dev [Desarrollo Local]
        DC1[docker compose up]
        DC1 --> MySQL1[MySQL phpMyAdmin]
        DC1 --> Redis1[Redis]
        DC1 --> Qdrant1[Qdrant]
        DC1 --> API1[FastAPI hot-reload]
        DC1 --> Flutter1[flutter run]
    end

    subgraph staging [Staging]
        DC2[docker compose prod.yml]
        DC2 --> Nginx2[Nginx]
        Nginx2 --> API2[Backend]
        Nginx2 --> Web2[Flutter Web]
        DC2 --> Backup2[Backups]
    end

    subgraph prod [Produccion]
        SSL[Let's Encrypt]
        Nginx3[Nginx SSL]
        API3[Uvicorn workers]
        Web3[Flutter Web static]
        MySQL3[MySQL volume]
        Qdrant3[Qdrant volume]
        Redis3[Redis volume]
        Monitor[Health checks logs]
        Backup3[Cron backups]
    end

    dev --> staging --> prod
```

### Servicios Docker producción (Fase 31)

| Servicio | Configuración |
|----------|---------------|
| nginx | Proxy `/api` → backend, `/` → Flutter web, SSL |
| backend | Imagen optimizada, sin volumen de código |
| mysql | Volumen persistente, backups cron |
| redis | Volumen persistente |
| qdrant | Volumen persistente, backups documentados |
| phpmyadmin | **NO expuesto** en producción |

### Health checks

- Backend: `GET /api/v1/health`
- MySQL: `mysqladmin ping`
- Redis: `redis-cli ping`
- Qdrant: `GET /healthz`
