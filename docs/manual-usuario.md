# Manual de usuario — AVOV

**AVOV** (Asistente Virtual de Orientación Vocacional) es una plataforma para realizar el test RIASEC, obtener recomendaciones de carreras, consultar resultados, generar reportes PDF y conversar con un asistente de orientación con IA.

Este manual describe el uso por rol desde la aplicación Flutter (web, Android, Windows).

---

## 1. Acceso a la aplicación

### 1.1 Inicio de sesión

1. Abre la aplicación AVOV.
2. En la pantalla de **Inicio de sesión**, ingresa tu correo electrónico y contraseña.
3. Pulsa **Ingresar**.

Tras un login exitoso, el sistema te redirige automáticamente al panel correspondiente a tu rol.

### 1.2 Recuperación de contraseña

1. En la pantalla de inicio de sesión, pulsa **¿Olvidaste tu contraseña?**
2. Ingresa tu correo electrónico registrado y pulsa **Enviar enlace**.
3. Revisa tu bandeja de entrada (y spam). El enlace abre la app en `/reset-password`.
4. Define una contraseña nueva que cumpla los requisitos de seguridad.

Si el correo no llega (por ejemplo en desarrollo sin SMTP), el administrador puede consultar el enlace en los logs del backend o configurar las variables `SMTP_*` en `.env`.

### 1.3 Modo mantenimiento

Si el sistema está en mantenimiento, verás una pantalla informativa. Solo el **super administrador** puede iniciar sesión durante el mantenimiento. El resto de usuarios debe esperar a que finalice.

### 1.4 Cambio de contraseña

1. Ve a **Perfil** (menú o ruta `/profile`).
2. Selecciona **Cambiar contraseña**.
3. Completa contraseña actual, nueva y confirmación.
4. La nueva contraseña debe tener mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo.

### 1.5 Cerrar sesión

Desde el panel o perfil, usa la opción **Cerrar sesión**. Los tokens se eliminan del dispositivo de forma segura.

---

## 2. Estudiante

### 2.1 Panel principal

Ruta: `/student/dashboard`

El panel muestra:

- Estado del perfil (completo o pendiente).
- Progreso del test vocacional (sin iniciar, en progreso, completado).
- Accesos rápidos: continuar test, ver resultados, recomendaciones, asistente, descargar PDF.

### 2.2 Completar perfil

1. Si el panel indica **Completar perfil**, entra a **Mi perfil** (`/student/profile`).
2. Completa grado, grupo, fecha de nacimiento, teléfono y demás campos requeridos.
3. Guarda los cambios.

### 2.3 Test vocacional RIASEC

1. Desde el panel, selecciona **Iniciar test** o **Continuar test**.
2. Lee las instrucciones (60 preguntas, escala 1–5).
3. Responde todas las preguntas; no puedes finalizar con respuestas incompletas.
4. Al terminar, el sistema calcula tu perfil RIASEC (dominante y secundario).

### 2.4 Resultados

Ruta: `/student/results`

- Visualiza puntajes por categoría R, I, A, S, E, C.
- Consulta perfil dominante y secundario.
- Lee el **mensaje ético**: los resultados son orientativos y no reemplazan la orientación profesional de un especialista.

### 2.5 Recomendaciones

Ruta: `/student/recommendations`

1. Si aún no hay recomendaciones, genera desde el panel o resultados.
2. Revisa la lista de carreras sugeridas con explicación.
3. Puedes abrir el **Asistente virtual** para profundizar en dudas vocacionales.

### 2.6 Asistente virtual

Ruta: `/student/assistant`

- Chat contextualizado con tu perfil RIASEC y recomendaciones.
- Las respuestas son orientativas; incluyen advertencia ética.
- Requiere test completado y recomendaciones generadas.

### 2.7 Reporte PDF

1. Desde el panel o resultados, selecciona **Descargar PDF**.
2. El reporte incluye datos del estudiante, perfil RIASEC, carreras recomendadas, nota ética y código único.
3. Si ya existe un reporte, la descarga recupera el archivo generado.

---

## 3. Orientador (Counselor)

### 3.1 Panel

Ruta: `/counselor/dashboard`

Métricas de estudiantes asignados, tests completados y actividad reciente.

### 3.2 Estudiantes asignados

Ruta: `/counselor/students`

- Lista de estudiantes bajo tu supervisión.
- Acceso a resultados y observaciones por estudiante.

### 3.3 Resultados del estudiante

Ruta: `/counselor/students/:id/results`

- Perfil RIASEC del estudiante.
- Recomendaciones generadas.
- Opción para **agregar observación profesional** que se incluirá en reportes PDF.

### 3.4 Observación profesional

Ruta: `/counselor/students/:id/observation`

1. Redacta observaciones claras y profesionales.
2. Guarda; quedan asociadas al estudiante y al último test completado.
3. Las observaciones aparecen en el PDF institucional.

---

## 4. Administrador institucional

Ruta base: `/institution/dashboard`

Funciones principales:

| Módulo | Ruta | Descripción |
|--------|------|-------------|
| Estudiantes | `/institution/students` | Alta, edición y consulta de estudiantes de la institución |
| Usuarios / orientadores | `/institution/users` | Gestión de orientadores y usuarios institucionales |
| Reportes | `/institution/reports` | Consulta de reportes PDF generados |
| Exportaciones | `/institution/exports` | Descarga CSV de estudiantes y resultados |
| Configuración | `/institution/settings` | Datos de la institución y logo |

Solo puedes ver y modificar datos de **tu institución**.

---

## 5. Super administrador

El super administrador gestiona el catálogo global (instituciones, carreras, preguntas, vector Qdrant, auditoría y configuración del sistema). Consulta el [Manual de administrador](manual-administrador.md).

---

## 6. Mensajes y errores frecuentes

| Mensaje | Causa | Acción |
|---------|-------|--------|
| Credenciales incorrectas | Email o contraseña inválidos | Verifica datos; tras varios intentos fallidos se aplica bloqueo temporal |
| Demasiados intentos de inicio de sesión | Rate limit activo | Espera 15 minutos (por defecto) e intenta de nuevo |
| No autorizado | Rol sin permiso para la ruta | Vuelve al panel de tu rol |
| Tu cuenta no está activa | Usuario desactivado | Contacta al administrador |
| El sistema está en mantenimiento | `maintenance_mode=true` | Espera o contacta al super admin |

---

## 7. Soporte

Para incidencias técnicas en entorno institucional, contacta al administrador de tu colegio o instituto. Para problemas de plataforma global, al super administrador AVOV.

**Nota ética permanente:** *Este resultado es orientativo y no reemplaza la orientación profesional de un psicólogo, docente u orientador educativo.*
